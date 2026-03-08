/**
 * Order lifecycle Cloud Functions
 */

import { setGlobalOptions } from 'firebase-functions';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as logger from 'firebase-functions/logger';
import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore, Timestamp, FieldValue } from 'firebase-admin/firestore';

// Import all payment functions
import { createOrder, razorpayWebhook, cancelOrder } from './razorpay.js';

// Import referral functions
import { processReferralSignupBonus, processReferralFirstOrderBonus, onOrderDelivered } from './referral.js';

// Import delivery confirmation functions
import { onOrderStatusUpdated, sendManualDeliveryConfirmation, sendBatchDeliveryConfirmations } from './delivery-confirmation.js';

// Re-export the functions
export { createOrder, razorpayWebhook, cancelOrder, processReferralSignupBonus, processReferralFirstOrderBonus, onOrderDelivered, onOrderStatusUpdated, sendManualDeliveryConfirmation, sendBatchDeliveryConfirmations };

setGlobalOptions({ maxInstances: 10 });

// Initialize Firebase Admin if not already initialized
if (getApps().length === 0) {
  initializeApp();
}

const db = getFirestore();

// Auto-cancel abandoned Razorpay orders (REDUCED FREQUENCY for cost efficiency)
export const autoCancelAbandonedRazorpayOrders = onSchedule({
  schedule: "every 2 hours", // Reduced from every 10 minutes to every 2 hours
}, async () => {
  const cutoff = Timestamp.fromDate(new Date(Date.now() - 2 * 60 * 60 * 1000)); // 2 hours instead of 30 minutes
  const snapshot = await db
    .collection("orders")
    .where("paymentMode", "==", "razorpay")
    .where("status", "==", "processing_payment")
    .where("createdAt", "<=", cutoff)
    .get();

  if (snapshot.empty) {
    logger.info("No abandoned Razorpay orders to cancel.");
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    const orderData = doc.data();
    batch.update(doc.ref, {
      status: "cancelled",
      paymentStatus: "failed",
      updatedAt: FieldValue.serverTimestamp(),
      cancelledAt: FieldValue.serverTimestamp(),
      cancelReason: "Payment not completed within 2 hours",
    });

    // Also update related documents
    if (orderData.paymentId) {
      const paymentRef = db.collection("payments").doc(orderData.paymentId);
      batch.update(paymentRef, {
        status: "cancelled",
        cancelledAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    if (orderData.deliveryId) {
      const deliveryRef = db.collection("deliveries").doc(orderData.deliveryId);
      batch.update(deliveryRef, {
        status: "cancelled",
        cancelledAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  });

  await batch.commit();
  logger.info(`Auto-cancelled ${snapshot.size} abandoned Razorpay orders.`);
});
