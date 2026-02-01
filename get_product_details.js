/**
 * Get detailed product structure to fix the model
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function getProductDetails() {
    console.log('Getting product: cleaning-floor-001\n');

    try {
        const doc = await db.collection('product_details').doc('cleaning-floor-001').get();

        if (!doc.exists) {
            console.log('Product not found!');
            return;
        }

        const data = doc.data();

        console.log('FULL PRODUCT DATA:');
        console.log('='.repeat(70));
        console.log(JSON.stringify(data, null, 2));

    } catch (error) {
        console.error('Error:', error);
    } finally {
        process.exit(0);
    }
}

getProductDetails();
