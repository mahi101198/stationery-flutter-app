/**
 * Check Product Structure in Firestore
 * This script will inspect the actual product data structure
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkProductStructure() {
    console.log('='.repeat(70));
    console.log('CHECKING PRODUCT STRUCTURE IN FIRESTORE');
    console.log('='.repeat(70));
    console.log();

    try {
        // Check what collections exist
        console.log('📦 Checking available collections...\n');

        const collections = await db.listCollections();
        const collectionNames = collections.map(col => col.id);

        console.log('Available collections:');
        collectionNames.forEach(name => {
            console.log(`  - ${name}`);
        });
        console.log();

        // Check for product-related collections
        const productCollections = collectionNames.filter(name =>
            name.toLowerCase().includes('product')
        );

        if (productCollections.length === 0) {
            console.log('❌ No product collections found!');
            return;
        }

        console.log('📦 Product-related collections found:');
        productCollections.forEach(name => console.log(`  - ${name}`));
        console.log();

        // Check each product collection
        for (const collectionName of productCollections) {
            console.log('='.repeat(70));
            console.log(`📋 COLLECTION: ${collectionName}`);
            console.log('='.repeat(70));

            const snapshot = await db.collection(collectionName).limit(3).get();

            console.log(`Total documents: ${snapshot.size}`);
            console.log();

            if (snapshot.empty) {
                console.log('  (Empty collection)');
                continue;
            }

            snapshot.forEach((doc, index) => {
                console.log(`\n📄 Document ${index + 1}: ${doc.id}`);
                console.log('-'.repeat(70));

                const data = doc.data();

                // Show all top-level fields
                console.log('Top-level fields:');
                Object.keys(data).forEach(key => {
                    const value = data[key];
                    const type = Array.isArray(value) ? 'array' : typeof value;
                    const preview = type === 'object' && !Array.isArray(value)
                        ? `{${Object.keys(value).slice(0, 3).join(', ')}...}`
                        : type === 'array'
                            ? `[${value.length} items]`
                            : type === 'string' && value.length > 50
                                ? `"${value.substring(0, 50)}..."`
                                : JSON.stringify(value);

                    console.log(`  ${key}: ${preview} (${type})`);
                });

                // Show full structure for first document
                if (index === 0) {
                    console.log('\nFull structure (first document):');
                    console.log(JSON.stringify(data, null, 2));
                }
            });

            console.log('\n');
        }

        // Check the specific products referenced in home sections
        console.log('='.repeat(70));
        console.log('🔍 CHECKING PRODUCTS REFERENCED IN HOME SECTIONS');
        console.log('='.repeat(70));
        console.log();

        const productIds = [
            'floor-001-500ml-citrus',
            'floor-001-2L-citrus'
        ];

        for (const productId of productIds) {
            console.log(`\nLooking for product: ${productId}`);

            // Check in all product collections
            for (const collectionName of productCollections) {
                const doc = await db.collection(collectionName).doc(productId).get();

                if (doc.exists) {
                    console.log(`  ✅ Found in: ${collectionName}`);
                    console.log(`  Data preview:`, JSON.stringify(doc.data(), null, 2).substring(0, 500));
                } else {
                    console.log(`  ❌ Not found in: ${collectionName}`);
                }
            }
        }

    } catch (error) {
        console.error('\n❌ Error:', error);
    } finally {
        process.exit(0);
    }
}

checkProductStructure();
