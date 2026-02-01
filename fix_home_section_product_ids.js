/**
 * Fix Home Section Items - Update productId to match actual product IDs
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Mapping of SKU IDs to Product IDs
const skuToProductMap = {
    'floor-001-500ml-citrus': 'cleaning-floor-001',
    'floor-001-1L-citrus': 'cleaning-floor-001',
    'floor-001-2L-citrus': 'cleaning-floor-001',
    'toilet-001-500ml-original': 'cleaning-toilet-001',
    'toilet-001-1L-original': 'cleaning-toilet-001',
};

async function fixHomeSectionItems() {
    console.log('='.repeat(70));
    console.log('FIXING HOME SECTION ITEMS');
    console.log('='.repeat(70));
    console.log();

    try {
        // Get all sections
        const sectionsSnapshot = await db.collection('home_sections').get();
        console.log(`Found ${sectionsSnapshot.size} sections\n`);

        let totalItemsFixed = 0;

        for (const sectionDoc of sectionsSnapshot.docs) {
            const sectionData = sectionDoc.data();
            console.log(`\n📦 Section: ${sectionDoc.id} (${sectionData.title})`);

            // Get all items in this section
            const itemsSnapshot = await db
                .collection('home_sections')
                .doc(sectionDoc.id)
                .collection('items')
                .get();

            console.log(`   Total items: ${itemsSnapshot.size}`);

            if (itemsSnapshot.size === 0) {
                console.log('   ⚠️  No items to fix');
                continue;
            }

            let itemsFixed = 0;

            for (const itemDoc of itemsSnapshot.docs) {
                const itemData = itemDoc.data();
                const currentProductId = itemData.product_id;
                const skuId = itemData.sku_id || itemDoc.id;

                // Check if this SKU ID maps to a different product ID
                const correctProductId = skuToProductMap[skuId] || skuToProductMap[currentProductId];

                if (correctProductId && correctProductId !== currentProductId) {
                    console.log(`   🔧 Fixing item: ${itemDoc.id}`);
                    console.log(`      Old productId: ${currentProductId}`);
                    console.log(`      New productId: ${correctProductId}`);
                    console.log(`      SKU ID: ${skuId}`);

                    await itemDoc.ref.update({
                        product_id: correctProductId,
                        sku_id: skuId,
                        updated_at: admin.firestore.FieldValue.serverTimestamp()
                    });

                    itemsFixed++;
                } else {
                    console.log(`   ✅ Item OK: ${itemDoc.id} (productId: ${currentProductId})`);
                }
            }

            console.log(`   Summary: ${itemsFixed} fixed`);
            totalItemsFixed += itemsFixed;
        }

        console.log('\n\n' + '='.repeat(70));
        console.log(`✅ COMPLETE: Fixed ${totalItemsFixed} items total`);
        console.log('='.repeat(70));

        // Verify the fix
        console.log('\n\nVERIFYING FIX...\n');

        for (const sectionDoc of sectionsSnapshot.docs) {
            const itemsSnapshot = await db
                .collection('home_sections')
                .doc(sectionDoc.id)
                .collection('items')
                .get();

            console.log(`${sectionDoc.id}:`);
            itemsSnapshot.forEach(itemDoc => {
                const data = itemDoc.data();
                console.log(`  - ${itemDoc.id}: productId=${data.product_id}, skuId=${data.sku_id || itemDoc.id}`);
            });
        }

    } catch (error) {
        console.error('\n❌ Error:', error);
    } finally {
        process.exit(0);
    }
}

fixHomeSectionItems();
