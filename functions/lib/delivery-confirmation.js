/**
 * Delivery Confirmation Cloud Functions
 * Handles FCM notifications when orders are marked as delivered
 * AND processes referral bonuses
 */
import * as logger from 'firebase-functions/logger';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { sendOrderConfirmationEmail, sendOrderStatusUpdateEmail } from './email-service.js';
import { processReferralFirstOrderBonusInternal } from './referral.js';
const db = getFirestore();
const messaging = getMessaging();
/**
 * Statuses that are handled by a DEDICATED notification function and must be
 * excluded from the generic sendStatusFCMNotification to prevent duplicates.
 *
 * - 'delivered'  → handled by sendDeliveryConfirmationNotification (asks the
 *                  customer to confirm receipt; different copy + data payload).
 *
 * Add future special-cased statuses here instead of scattering exclusions
 * across the trigger body.
 */
const DEDICATED_FCM_STATUSES = new Set(['delivered']);
/**
 * Consolidated single trigger for all order status changes
 *
 * This is the ONLY trigger on the orders collection. All status-related logic
 * (notifications, emails, referral bonuses) is handled here to prevent duplicates.
 *
 * FCM dispatch rules (one notification per status change, no duplicates):
 *
 *  Status transition                  │ Who sends FCM
 * ────────────────────────────────────┼──────────────────────────────────────
 *  processing_payment → confirmed     │ Razorpay webhook (payment_success)
 *  * → delivered                      │ sendDeliveryConfirmationNotification
 *  any other change                   │ sendStatusFCMNotification
 */
export const onOrderStatusUpdated = onDocumentUpdated({
    document: 'orders/{orderId}',
    region: 'asia-south1',
}, async (event) => {
    var _a, _b, _c, _d, _e, _f;
    try {
        const orderId = event.params.orderId;
        const beforeData = (_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before) === null || _b === void 0 ? void 0 : _b.data();
        const afterData = (_d = (_c = event.data) === null || _c === void 0 ? void 0 : _c.after) === null || _d === void 0 ? void 0 : _d.data();
        const requestId = `${orderId}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
        logger.info(`[${requestId}] 🔍 Firestore trigger invoked for order ${orderId}`);
        if (!beforeData || !afterData) {
            logger.warn(`[${requestId}] ⚠️  Missing data for order ${orderId}`);
            return;
        }
        const beforeStatus = beforeData.status;
        const afterStatus = afterData.status;
        const statusChanged = beforeStatus !== afterStatus;
        const userId = afterData.userId;
        logger.info(`[${requestId}] Order ${orderId} status: ${beforeStatus} → ${afterStatus} (changed: ${statusChanged})`);
        // ── FCM ────────────────────────────────────────────────────────────────
        if (statusChanged) {
            const isRazorpayWebhookTransition = beforeStatus === 'processing_payment' && afterStatus === 'confirmed';
            logger.info(`[${requestId}] 📊 FCM Logic Check - isRazorpayWebhookTransition: ${isRazorpayWebhookTransition}, dedicatedStatus: ${DEDICATED_FCM_STATUSES.has(afterStatus)}`);
            if (isRazorpayWebhookTransition) {
                // Razorpay webhook already fired a payment_success notification.
                logger.info(`[${requestId}] ⏭️  Skipping FCM for ${beforeStatus} → ${afterStatus} — webhook will send payment_success notification`);
            }
            else if (DEDICATED_FCM_STATUSES.has(afterStatus)) {
                // Statuses with bespoke notification logic — do NOT also call
                // sendStatusFCMNotification, otherwise the customer gets two pings.
                if (afterStatus === 'delivered' && !afterData.deliveryConfirmed) {
                    logger.info(`[${requestId}] 🚚 Order ${orderId} delivered — sending delivery-confirmation notification`);
                    await sendDeliveryConfirmationNotification(orderId, afterData, requestId);
                }
                else if (afterStatus === 'delivered' && afterData.deliveryConfirmed) {
                    logger.info(`[${requestId}] ⏭️  Order ${orderId} already confirmed — skipping delivery FCM`);
                }
            }
            else {
                // Generic status update notification for every other transition.
                logger.info(`[${requestId}] 📲 Sending FCM for status: ${afterStatus}`);
                await sendStatusFCMNotification(orderId, afterData, afterStatus, requestId);
            }
        }
        // ── Referral Bonus Processing ──────────────────────────────────────────
        // When order is delivered, check if referral bonus should be processed
        if (statusChanged && beforeStatus !== 'delivered' && afterStatus === 'delivered') {
            logger.info(`[${requestId}] 🎁 Order ${orderId} delivered — processing referral bonus`);
            try {
                const orderAmount = ((_e = afterData.paymentSummary) === null || _e === void 0 ? void 0 : _e.totalOrderValue) ||
                    ((_f = afterData.pricingSummary) === null || _f === void 0 ? void 0 : _f.totalBeforePayment) || 0;
                await processReferralFirstOrderBonusInternal(userId, orderId, orderAmount);
            }
            catch (referralError) {
                logger.error(`[${requestId}] ⚠️  Error processing referral bonus for order ${orderId}:`, referralError);
                // Don't fail the whole operation if referral processing fails
            }
        }
        // ── Email ──────────────────────────────────────────────────────────────
        if (statusChanged) {
            logger.info(`[${requestId}] 📧 Sending status email for order ${orderId}: ${afterStatus}`);
            try {
                await sendOrderStatusUpdateEmail(orderId, afterData, beforeStatus, afterStatus);
            }
            catch (emailError) {
                logger.error(`[${requestId}] ⚠️  Error sending status update email for order ${orderId}:`, emailError);
            }
        }
        // Detailed confirmation email: placed → confirmed
        if (afterStatus === 'confirmed' && beforeStatus === 'placed') {
            logger.info(`[${requestId}] ✅ Order ${orderId} confirmed — sending detailed confirmation email`);
            let deliveryData = {};
            if (afterData.deliveryId) {
                const deliveryDoc = await db.collection('deliveries').doc(afterData.deliveryId).get();
                if (deliveryDoc.exists) {
                    deliveryData = deliveryDoc.data() || {};
                }
            }
            try {
                await sendOrderConfirmationEmail(afterData, deliveryData);
            }
            catch (emailError) {
                logger.error(`[${requestId}] ⚠️  Error sending confirmation email for order ${orderId}:`, emailError);
            }
        }
        logger.info(`[${requestId}] ✅ Trigger processing completed for order ${orderId}`);
    }
    catch (error) {
        logger.error(`Error processing order status update for ${event.params.orderId}:`, error);
    }
});
// ─────────────────────────────────────────────────────────────────────────────
// Internal helpers
// ─────────────────────────────────────────────────────────────────────────────
/**
 * Resolve the FCM token for a given userId.
 * Returns null (with a warning log) when the user or token cannot be found.
 */
async function getFcmToken(userId) {
    var _a, _b;
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
        logger.warn(`User not found: ${userId}`);
        return null;
    }
    const token = (_b = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.fcmToken) !== null && _b !== void 0 ? _b : null;
    if (!token)
        logger.warn(`No FCM token for user ${userId}`);
    return token;
}
/**
 * Persist a notification record to Firestore so the in-app notification
 * centre can display it.
 */
async function storeNotification(userId, payload) {
    try {
        await db.collection('notifications').add(Object.assign(Object.assign({ userId }, payload), { isRead: false, createdAt: new Date(), readAt: null }));
    }
    catch (err) {
        logger.error(`Error storing notification for order ${payload.orderId}:`, err);
    }
}
/**
 * Send FCM push notification for ALL standard order status changes.
 * This function must NOT be called for statuses listed in DEDICATED_FCM_STATUSES.
 */
async function sendStatusFCMNotification(orderId, orderData, status, requestId) {
    var _a;
    try {
        const userId = orderData.userId;
        logger.info(`[${requestId}] 📲 sendStatusFCMNotification called for order ${orderId}, status: ${status}, userId: ${userId}`);
        if (!userId) {
            logger.warn(`[${requestId}] ⚠️  No userId on order ${orderId}, skipping FCM`);
            return;
        }
        const fcmToken = await getFcmToken(userId);
        if (!fcmToken) {
            logger.warn(`[${requestId}] ⚠️  No FCM token for user ${userId}`);
            return;
        }
        const statusMessages = {
            confirmed: {
                title: '✅ Order Confirmed!',
                body: 'Your order has been confirmed and is being prepared.',
            },
            packed: {
                title: '📦 Order Packed!',
                body: 'Your order is packed and ready for dispatch.',
            },
            shipped: {
                title: '🚚 Order Shipped!',
                body: 'Your order is on its way to you!',
            },
            out_for_delivery: {
                title: '📍 Out for Delivery!',
                body: 'Your order is out for delivery today.',
            },
            cancelled: {
                title: '❌ Order Cancelled',
                body: 'Your order has been cancelled. Refund will be processed if applicable.',
            },
            returned: {
                title: '↩️ Return Initiated',
                body: 'Your return request has been initiated.',
            },
            refunded: {
                title: '💰 Refund Processed',
                body: 'Your refund has been successfully processed.',
            },
        };
        const msg = (_a = statusMessages[status]) !== null && _a !== void 0 ? _a : {
            title: 'Order Update',
            body: `Your order status has been updated to: ${status}`,
        };
        logger.info(`[${requestId}] 🚀 Sending FCM message - token exists, sending notification to ${userId}`);
        await messaging.send({
            token: fcmToken,
            notification: { title: msg.title, body: msg.body },
            data: {
                type: `order_${status}`,
                orderId,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
                priority: 'high',
                notification: {
                    channelId: 'orders',
                    defaultSound: true,
                    defaultVibrateTimings: true,
                },
            },
            apns: {
                payload: { aps: { sound: 'default', badge: 1 } },
            },
        });
        logger.info(`[${requestId}] ✅ FCM sent for order ${orderId} — status: ${status}`);
        await storeNotification(userId, {
            type: `order_${status}`,
            title: msg.title,
            body: msg.body,
            orderId,
        });
    }
    catch (error) {
        logger.error(`[${requestId}] ❌ Error in sendStatusFCMNotification for order ${orderId}:`, error);
    }
}
/**
 * Send FCM delivery-confirmation notification (asks the customer to confirm
 * receipt). This is intentionally different from the generic "delivered" status
 * update — it carries a distinct type ('order_confirmation') and CTA copy.
 */
async function sendDeliveryConfirmationNotification(orderId, orderData, requestId) {
    try {
        const userId = orderData.userId;
        const orderNumber = orderData.orderNumber || orderId;
        logger.info(`[${requestId}] 🚚 sendDeliveryConfirmationNotification called for order ${orderId}, userId: ${userId}`);
        if (!userId) {
            logger.warn(`[${requestId}] ⚠️  No userId found for order ${orderId}`);
            return;
        }
        const fcmToken = await getFcmToken(userId);
        if (!fcmToken) {
            logger.warn(`[${requestId}] ⚠️  No FCM token for user ${userId}`);
            return;
        }
        logger.info(`[${requestId}] 🚀 Sending delivery confirmation FCM to ${userId}`);
        await messaging.send({
            token: fcmToken,
            notification: {
                title: 'Confirm your delivery',
                body: `Please confirm receipt of order #${orderNumber}`,
            },
            data: {
                type: 'order_confirmation',
                orderId,
                orderNumber,
                userId,
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
                priority: 'high',
                notification: {
                    channelId: 'orders',
                    defaultSound: true,
                    defaultVibrateTimings: true,
                },
            },
            apns: {
                payload: {
                    aps: {
                        alert: {
                            title: 'Confirm your delivery',
                            body: `Please confirm receipt of order #${orderNumber}`,
                        },
                        sound: 'default',
                        badge: 1,
                    },
                },
            },
        });
        logger.info(`[${requestId}] ✅ Delivery confirmation FCM sent for order ${orderId}`);
        await storeNotification(userId, {
            type: 'order_confirmation',
            title: 'Confirm your delivery',
            body: `Please confirm receipt of order #${orderNumber}`,
            orderId,
            orderNumber,
        });
    }
    catch (error) {
        logger.error(`[${requestId}] ❌ Error sending delivery confirmation notification for order ${orderId}:`, error);
    }
}
// ─────────────────────────────────────────────────────────────────────────────
// Public / admin utilities
// ─────────────────────────────────────────────────────────────────────────────
/**
 * Manual trigger — send a delivery-confirmation notification for a specific order.
 * Callable from the admin dashboard or for testing purposes.
 */
export const sendManualDeliveryConfirmation = async (orderId) => {
    try {
        const requestId = `manual-${orderId}-${Date.now()}`;
        logger.info(`[${requestId}] 📱 Manual delivery confirmation requested for order: ${orderId}`);
        const orderDoc = await db.collection('orders').doc(orderId).get();
        if (!orderDoc.exists)
            throw new Error(`Order ${orderId} not found`);
        const orderData = orderDoc.data();
        if ((orderData === null || orderData === void 0 ? void 0 : orderData.status) !== 'delivered') {
            throw new Error(`Order ${orderId} is not delivered (status: ${orderData === null || orderData === void 0 ? void 0 : orderData.status})`);
        }
        if (orderData === null || orderData === void 0 ? void 0 : orderData.deliveryConfirmed) {
            throw new Error(`Order ${orderId} is already confirmed`);
        }
        await sendDeliveryConfirmationNotification(orderId, orderData, requestId);
        logger.info(`[${requestId}] ✅ Manual delivery confirmation sent for order: ${orderId}`);
        return { success: true, message: `Delivery confirmation sent for order ${orderId}` };
    }
    catch (error) {
        logger.error(`❌ Error sending manual delivery confirmation:`, error);
        throw error;
    }
};
/**
 * Batch — send delivery-confirmation notifications for up to 50 unconfirmed
 * delivered orders. Useful for backfill / migration runs.
 */
export const sendBatchDeliveryConfirmations = async () => {
    try {
        const batchId = `batch-${Date.now()}`;
        logger.info(`[${batchId}] 🔄 Starting batch delivery confirmation process...`);
        const unconfirmedOrders = await db
            .collection('orders')
            .where('status', '==', 'delivered')
            .where('deliveryConfirmed', '==', false)
            .limit(50)
            .get();
        if (unconfirmedOrders.empty) {
            logger.info(`[${batchId}] ✅ No unconfirmed delivered orders found`);
            return { processed: 0, message: 'No orders to process' };
        }
        let successCount = 0;
        let errorCount = 0;
        for (const orderDoc of unconfirmedOrders.docs) {
            try {
                const orderId = orderDoc.id;
                const requestId = `${batchId}-${orderId}`;
                logger.info(`[${requestId}] Processing batch order...`);
                await sendDeliveryConfirmationNotification(orderId, orderDoc.data(), requestId);
                successCount++;
                await new Promise(resolve => setTimeout(resolve, 100)); // avoid FCM rate-limiting
            }
            catch (error) {
                logger.error(`[${batchId}] ❌ Error processing batch order ${orderDoc.id}:`, error);
                errorCount++;
            }
        }
        logger.info(`[${batchId}] ✅ Batch delivery confirmation completed: ${successCount} sent, ${errorCount} errors`);
        return {
            processed: unconfirmedOrders.size,
            success: successCount,
            errors: errorCount,
            message: `Processed ${unconfirmedOrders.size} orders: ${successCount} successful, ${errorCount} errors`,
        };
    }
    catch (error) {
        logger.error('❌ Error in batch delivery confirmation process:', error);
        throw error;
    }
};
//# sourceMappingURL=delivery-confirmation.js.map