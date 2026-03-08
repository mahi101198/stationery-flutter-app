/**
 * Order lifecycle Cloud Functions
 */

import {setGlobalOptions} from 'firebase-functions';
import * as admin from 'firebase-admin';

// Import all payment functions
import {createOrder, razorpayWebhook, cancelOrder} from './razorpay.ts';

// Import referral functions
import {processRefereeWalletBonus, processReferrerWalletBonus, addRefereeWalletBonus, markOrderAsDelivered} from './referral.ts';

// Re-export all functions
export {createOrder, razorpayWebhook, cancelOrder, processRefereeWalletBonus, processReferrerWalletBonus, addRefereeWalletBonus, markOrderAsDelivered};

setGlobalOptions({maxInstances: 10});

if (!admin.apps.length) {
  admin.initializeApp();
}
