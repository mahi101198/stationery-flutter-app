/**
 * Delivery Confirmation Cloud Functions
 * Handles FCM notifications when orders are marked as delivered
 */
import * as logger from 'firebase-functions/logger';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { sendOrderConfirmationEmail, sendOrderStatusUpdateEmail } from './email-service.js';
const db = getFirestore();
const messaging = getMessaging();
/**
 * Triggers when an order document is updated
 * Sends FCM notification for delivery confirmation when status changes to 'delivered'
 */
export const onOrderStatusUpdated = onDocumentUpdated({
    document: 'orders/{orderId}',
    region: 'asia-south1', // Match your Firebase project region
}, async (event) => {
    var _a, _b, _c, _d;
    try {
        const orderId = event.params.orderId;
        const beforeData = (_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before) === null || _b === void 0 ? void 0 : _b.data();
        const afterData = (_d = (_c = event.data) === null || _c === void 0 ? void 0 : _c.after) === null || _d === void 0 ? void 0 : _d.data();
        if (!beforeData || !afterData) {
            logger.warn(`Missing data for order ${orderId}`);
            return;
        }
        const beforeStatus = beforeData.status;
        const afterStatus = afterData.status;
        const deliveryConfirmed = afterData.deliveryConfirmed;
        logger.info(`Order ${orderId} status changed: ${beforeStatus} → ${afterStatus}`);
        // Check if status changed to 'delivered' and not already confirmed
        if (afterStatus === 'delivered' && beforeStatus !== 'delivered' && !deliveryConfirmed) {
            logger.info(`🚚 Order ${orderId} marked as delivered, sending confirmation notification`);
            await sendDeliveryConfirmationNotification(orderId, afterData);
        }
        // Send email notification for any status change (except if it's the same status)
        if (beforeStatus !== afterStatus) {
            logger.info(`📧 Order ${orderId} status changed to ${afterStatus}, sending email notification`);
            try {
                await sendOrderStatusUpdateEmail(orderId, afterData, beforeStatus, afterStatus);
            }
            catch (emailError) {
                logger.error(`⚠️ Error sending status update email for order ${orderId}:`, emailError);
                // Don't throw here - we don't want email failures to break the order update flow
            }
        }
        // Check if status changed to 'confirmed' for initial confirmation email (kept for backwards compatibility)
        if (afterStatus === 'confirmed' && beforeStatus === 'placed') {
            logger.info(`✅ Order ${orderId} confirmed, sending detailed confirmation email`);
            // Fetch delivery details
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
                logger.error(`⚠️ Error sending confirmation email for order ${orderId}:`, emailError);
            }
        }
    }
    catch (error) {
        logger.error(`Error processing order status update for ${event.params.orderId}:`, error);
    }
});
/**
 * Send FCM notification for delivery confirmation
 */
async function sendDeliveryConfirmationNotification(orderId, orderData) {
    try {
        const userId = orderData.userId;
        const orderNumber = orderData.orderNumber || orderId;
        if (!userId) {
            logger.warn(`No userId found for order ${orderId}`);
            return;
        }
        // Get user's FCM token from users collection
        const userDoc = await db.collection('users').doc(userId).get();
        if (!userDoc.exists) {
            logger.warn(`User document not found for userId: ${userId}`);
            return;
        }
        const userData = userDoc.data();
        const fcmToken = userData === null || userData === void 0 ? void 0 : userData.fcmToken;
        if (!fcmToken) {
            logger.warn(`No FCM token found for user ${userId}`);
            return;
        }
        // Prepare FCM message
        const message = {
            token: fcmToken,
            notification: {
                title: 'Confirm your delivery',
                body: `Please confirm receipt of order #${orderNumber}`,
            },
            data: {
                type: 'order_confirmation',
                orderId: orderId,
                orderNumber: orderNumber,
                userId: userId,
            },
            android: {
                notification: {
                    channelId: 'orders',
                    priority: 'high',
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
        };
        // Send FCM notification
        const response = await messaging.send(message);
        logger.info(`✅ Delivery confirmation notification sent successfully: ${response}`);
        // Store notification in Firestore for user's notification history
        await storeDeliveryConfirmationNotification(userId, orderId, orderNumber);
    }
    catch (error) {
        logger.error(`❌ Error sending delivery confirmation notification for order ${orderId}:`, error);
        // If FCM fails, we could implement a retry mechanism or fallback
        // For now, we'll just log the error
    }
}
/**
 * Store delivery confirmation notification in user's notification history
 */
async function storeDeliveryConfirmationNotification(userId, orderId, orderNumber) {
    try {
        const notificationData = {
            userId: userId,
            type: 'order_confirmation',
            title: 'Confirm your delivery',
            body: `Please confirm receipt of order #${orderNumber}`,
            data: {
                orderId: orderId,
                orderNumber: orderNumber,
                type: 'order_confirmation',
            },
            read: false,
            createdAt: new Date(),
            updatedAt: new Date(),
        };
        await db.collection('notifications').add(notificationData);
        logger.info(`📝 Delivery confirmation notification stored for user ${userId}`);
    }
    catch (error) {
        logger.error(`❌ Error storing delivery confirmation notification:`, error);
    }
}
/**
 * Manual function to send delivery confirmation for a specific order
 * Can be called from admin dashboard or for testing
 */
export const sendManualDeliveryConfirmation = async (orderId) => {
    try {
        logger.info(`📱 Manual delivery confirmation requested for order: ${orderId}`);
        const orderDoc = await db.collection('orders').doc(orderId).get();
        if (!orderDoc.exists) {
            throw new Error(`Order ${orderId} not found`);
        }
        const orderData = orderDoc.data();
        if ((orderData === null || orderData === void 0 ? void 0 : orderData.status) !== 'delivered') {
            throw new Error(`Order ${orderId} is not delivered (status: ${orderData === null || orderData === void 0 ? void 0 : orderData.status})`);
        }
        if (orderData === null || orderData === void 0 ? void 0 : orderData.deliveryConfirmed) {
            throw new Error(`Order ${orderId} is already confirmed`);
        }
        await sendDeliveryConfirmationNotification(orderId, orderData);
        logger.info(`✅ Manual delivery confirmation sent for order: ${orderId}`);
        return { success: true, message: `Delivery confirmation sent for order ${orderId}` };
    }
    catch (error) {
        logger.error(`❌ Error sending manual delivery confirmation:`, error);
        throw error;
    }
};
/**
 * Batch function to send delivery confirmations for multiple unconfirmed delivered orders
 * Useful for migration or bulk operations
 */
export const sendBatchDeliveryConfirmations = async () => {
    try {
        logger.info('🔄 Starting batch delivery confirmation process...');
        // Find all delivered orders that haven't been confirmed
        const unconfirmedOrders = await db
            .collection('orders')
            .where('status', '==', 'delivered')
            .where('deliveryConfirmed', '==', false)
            .limit(50) // Process in batches to avoid timeouts
            .get();
        if (unconfirmedOrders.empty) {
            logger.info('✅ No unconfirmed delivered orders found');
            return { processed: 0, message: 'No orders to process' };
        }
        let successCount = 0;
        let errorCount = 0;
        for (const orderDoc of unconfirmedOrders.docs) {
            try {
                const orderId = orderDoc.id;
                const orderData = orderDoc.data();
                await sendDeliveryConfirmationNotification(orderId, orderData);
                successCount++;
                // Add small delay to avoid rate limiting
                await new Promise(resolve => setTimeout(resolve, 100));
            }
            catch (error) {
                logger.error(`❌ Error processing order ${orderDoc.id}:`, error);
                errorCount++;
            }
        }
        logger.info(`✅ Batch delivery confirmation completed: ${successCount} sent, ${errorCount} errors`);
        return {
            processed: unconfirmedOrders.size,
            success: successCount,
            errors: errorCount,
            message: `Processed ${unconfirmedOrders.size} orders: ${successCount} successful, ${errorCount} errors`
        };
    }
    catch (error) {
        logger.error('❌ Error in batch delivery confirmation process:', error);
        throw error;
    }
};
//# sourceMappingURL=delivery-confirmation.js.map