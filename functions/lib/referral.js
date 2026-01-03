import { onCall } from "firebase-functions/v2/https";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
const db = getFirestore();
/**
 * Callable Cloud Function to process referral signup bonus
 * Called directly from the app when a user signs up with a referral code
 */
export const processReferralSignupBonus = onCall(async (request) => {
    const { userId, referrerId } = request.data;
    if (!userId || !referrerId) {
        throw new Error("Missing required parameters: userId and referrerId");
    }
    logger.info(`Processing referral signup bonus for user ${userId} referred by ${referrerId}`);
    try {
        // Prevent self-referral
        if (referrerId === userId) {
            throw new Error("Self-referral is not allowed");
        }
        // Check if referrer exists
        const referrerDoc = await db.collection("users").doc(referrerId).get();
        if (!referrerDoc.exists) {
            throw new Error("Referrer not found");
        }
        // Get app settings for referral configuration
        const settingsDoc = await db.collection('settings').doc('app').get();
        const settings = settingsDoc.data();
        if (!settings || !settings.isReferralActive) {
            throw new Error('Referral system is disabled');
        }
        const refereeReward = settings.refereeRewardValue;
        if (!refereeReward || refereeReward <= 0) {
            throw new Error('Invalid referee reward value in settings');
        }
        // Update referee's wallet with signup bonus
        await db.collection("users").doc(userId).update({
            walletBalance: FieldValue.increment(refereeReward),
            updatedAt: FieldValue.serverTimestamp(),
        });
        // Create a referral record
        await db.collection("referrals").add({
            referrerId: referrerId,
            refereeId: userId,
            refereeRewardAmount: refereeReward,
            refereeRewardStatus: 'completed',
            referrerRewardStatus: 'pending',
            bonusType: "signup",
            createdAt: FieldValue.serverTimestamp(),
            refereeRewardedAt: FieldValue.serverTimestamp()
        });
        logger.info(`✅ Successfully added ₹${refereeReward} signup bonus to referee ${userId}`);
        return { success: true, message: "Referral signup bonus processed successfully", amount: refereeReward };
    }
    catch (error) {
        logger.error(`❌ Error processing referral signup bonus: ${error}`);
        throw new Error(`Failed to process referral signup bonus: ${error}`);
    }
});
/**
 * Internal function to process referral first order bonus
 * This is the core logic that can be called from both callable function and triggers
 */
async function processReferralFirstOrderBonusInternal(userId, orderId, orderAmount) {
    logger.info(`Processing referral first order bonus for user ${userId}, order ${orderId}`);
    try {
        // Check if user was referred
        const userDoc = await db.collection("users").doc(userId).get();
        if (!userDoc.exists) {
            throw new Error("User not found");
        }
        const userData = userDoc.data();
        if (!(userData === null || userData === void 0 ? void 0 : userData.referredBy)) {
            logger.info(`User ${userId} was not referred, skipping first order bonus`);
            return { success: true, message: "User was not referred, no bonus to process" };
        }
        const referralCode = userData.referredBy;
        // Find the referrer by referral code
        const referrerQuery = await db.collection("users")
            .where("referralCode", "==", referralCode)
            .limit(1)
            .get();
        if (referrerQuery.empty) {
            throw new Error(`Referrer not found for referral code: ${referralCode}`);
        }
        const referrerId = referrerQuery.docs[0].id;
        // Check if referrer bonus has already been given
        const existingReferral = await db.collection("referrals")
            .where("refereeId", "==", userId)
            .where("referrerId", "==", referrerId)
            .where("referrerRewardStatus", "==", "completed")
            .get();
        if (!existingReferral.empty) {
            logger.info(`Referrer bonus already given for user ${userId}`);
            return { success: true, message: "Referrer bonus already processed" };
        }
        // Get app settings for referral configuration
        const settingsDoc = await db.collection('settings').doc('app').get();
        const settings = settingsDoc.data();
        if (!settings || !settings.isReferralActive) {
            throw new Error('Referral system is disabled');
        }
        // Validate minimum order amount for referral rewards
        const minOrderAmount = settings.minOrderAmount;
        if (minOrderAmount && orderAmount && orderAmount < minOrderAmount) {
            logger.info(`Order amount ₹${orderAmount} is below minimum ₹${minOrderAmount}, skipping referral reward`);
            return { success: true, message: `Order amount below minimum (₹${minOrderAmount}), no referral reward processed` };
        }
        const referrerReward = settings.referrerRewardValue;
        if (!referrerReward || referrerReward <= 0) {
            throw new Error('Invalid referrer reward value in settings');
        }
        // Update referrer's wallet with first order bonus
        await db.collection("users").doc(referrerId).update({
            walletBalance: FieldValue.increment(referrerReward),
            updatedAt: FieldValue.serverTimestamp(),
        });
        // Update the referral record to mark referrer bonus as completed
        const referralQuery = await db.collection("referrals")
            .where("refereeId", "==", userId)
            .where("referrerId", "==", referrerId)
            .where("referrerRewardStatus", "==", "pending")
            .get();
        if (!referralQuery.empty) {
            const referralDoc = referralQuery.docs[0];
            await referralDoc.ref.update({
                referrerRewardAmount: referrerReward,
                referrerRewardStatus: 'completed',
                referrerRewardedAt: FieldValue.serverTimestamp(),
                firstOrderId: orderId
            });
        }
        logger.info(`✅ Successfully added ₹${referrerReward} first order bonus to referrer ${referrerId}`);
        return { success: true, message: "Referral first order bonus processed successfully", amount: referrerReward };
    }
    catch (error) {
        logger.error(`❌ Error processing referral first order bonus: ${error}`);
        throw new Error(`Failed to process referral first order bonus: ${error}`);
    }
}
/**
 * Callable Cloud Function to process referral first order bonus
 * Called directly from the app when a referred user places their first order
 */
export const processReferralFirstOrderBonus = onCall(async (request) => {
    const { userId, orderId, orderAmount } = request.data;
    if (!userId || !orderId) {
        throw new Error("Missing required parameters: userId and orderId");
    }
    return await processReferralFirstOrderBonusInternal(userId, orderId, orderAmount);
});
/**
 * Firestore trigger to automatically process referral first order bonus
 * when an order status is updated to 'delivered'
 */
export const onOrderDelivered = onDocumentUpdated("orders/{orderId}", async (event) => {
    var _a, _b, _c, _d, _e;
    const beforeData = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const afterData = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!beforeData || !afterData) {
        logger.warn("Missing order data in trigger");
        return;
    }
    // Check if status changed to 'delivered'
    const wasDelivered = beforeData.status === 'delivered';
    const isNowDelivered = afterData.status === 'delivered';
    if (wasDelivered || !isNowDelivered) {
        // Order was already delivered or not delivered now, skip
        return;
    }
    const orderId = (_c = event.params) === null || _c === void 0 ? void 0 : _c.orderId;
    const userId = afterData.userId;
    const orderAmount = ((_d = afterData.amountBreakdown) === null || _d === void 0 ? void 0 : _d.totalOrderAmount) || ((_e = afterData.amountBreakdown) === null || _e === void 0 ? void 0 : _e.finalAmount) || 0;
    logger.info(`Order ${orderId} delivered for user ${userId}, checking for referral bonus`);
    try {
        // Call the internal function directly
        const result = await processReferralFirstOrderBonusInternal(userId, orderId, orderAmount);
        logger.info(`Successfully processed referral first order bonus for order ${orderId}:`, result);
    }
    catch (error) {
        logger.error(`Error processing referral first order bonus for order ${orderId}:`, error);
    }
});
//# sourceMappingURL=referral.js.map