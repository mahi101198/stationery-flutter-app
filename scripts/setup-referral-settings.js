#!/usr/bin/env node

/**
 * Script to set up default referral settings in Firestore
 * Run this script to initialize the referral program with sensible defaults
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

const db = admin.firestore();

async function setupReferralSettings() {
  try {
    console.log('🚀 Setting up referral program settings...');

    const defaultSettings = {
      referrals: {
        enabled: true,
        refereeSignupBonus: 50.0, // ₹50 bonus for new user on signup
        referrerOrderBonus: {
          type: 'fixed', // 'fixed' or 'percentage'
          value: 100.0, // ₹100 bonus for referrer when order is delivered
        },
        minFirstOrderAmount: 200.0, // Minimum order amount to qualify for referrer bonus
        maxReferrerBonus: 500.0, // Maximum referrer bonus (for percentage calculations)
        preventSelfReferral: true,
        maxPerRefereeBonuses: 1, // Each referee can only use one referral code
        unlockOn: 'delivered', // 'delivered' or 'paid'
      },
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Update the app settings document
    await db.collection('settings').doc('app').set(defaultSettings, { merge: true });

    console.log('✅ Referral settings configured successfully!');
    console.log('📋 Default Configuration:');
    console.log('   - Referrals: Enabled');
    console.log('   - Referee Signup Bonus: ₹50');
    console.log('   - Referrer Order Bonus: ₹100 (fixed)');
    console.log('   - Minimum Order Amount: ₹200');
    console.log('   - Max Referrer Bonus: ₹500');
    console.log('   - Self-referral: Prevented');
    console.log('   - Unlock Condition: When order is delivered');
    console.log('');
    console.log('🔧 You can modify these settings in Firestore:');
    console.log('   Collection: settings');
    console.log('   Document: app');
    console.log('   Field: referrals');

  } catch (error) {
    console.error('❌ Error setting up referral settings:', error);
    process.exit(1);
  }
}

// Run the setup
setupReferralSettings()
  .then(() => {
    console.log('🎉 Setup completed successfully!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Setup failed:', error);
    process.exit(1);
  });
