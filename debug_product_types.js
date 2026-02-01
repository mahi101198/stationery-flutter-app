/**
 * Debug: Find which field is causing the type mismatch
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function debugProduct() {
    try {
        const doc = await db.collection('product_details').doc('cleaning-floor-001').get();
        const data = doc.data();

        console.log('Checking each field type:\n');

        Object.keys(data).forEach(key => {
            const value = data[key];
            const type = Array.isArray(value) ? 'array' : typeof value;

            console.log(`${key}:`);
            console.log(`  Type: ${type}`);

            if (type === 'object' && !Array.isArray(value)) {
                console.log(`  Keys: ${Object.keys(value).join(', ')}`);
                console.log(`  Value:`, JSON.stringify(value, null, 2));
            } else if (type === 'array') {
                console.log(`  Length: ${value.length}`);
                if (value.length > 0) {
                    console.log(`  First item type: ${typeof value[0]}`);
                    if (typeof value[0] === 'object') {
                        console.log(`  First item:`, JSON.stringify(value[0], null, 2));
                    }
                }
            } else {
                console.log(`  Value: ${value}`);
            }
            console.log();
        });

    } catch (error) {
        console.error('Error:', error);
    } finally {
        process.exit(0);
    }
}

debugProduct();
