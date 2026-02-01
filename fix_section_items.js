/**
 * Fix Home Section Items - Add is_active field to all items
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixSectionItems() {
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
            console.log(`   Status: ${sectionData.status}`);

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
            let itemsAlreadyOk = 0;

            for (const itemDoc of itemsSnapshot.docs) {
                const itemData = itemDoc.data();

                // Check if is_active field exists
                if (itemData.is_active === undefined) {
                    // Add is_active: true
                    await itemDoc.ref.update({
                        is_active: true
                    });
                    itemsFixed++;
                    console.log(`   ✅ Fixed item: ${itemDoc.id} (added is_active: true)`);
                } else {
                    itemsAlreadyOk++;
                }
            }

            console.log(`   Summary: ${itemsFixed} fixed, ${itemsAlreadyOk} already OK`);
            totalItemsFixed += itemsFixed;
        }

        console.log('\n\n' + '='.repeat(70));
        console.log(`✅ COMPLETE: Fixed ${totalItemsFixed} items total`);
        console.log('='.repeat(70));

        // Now verify the fix worked
        console.log('\n\nVERIFYING FIX...\n');

        for (const sectionDoc of sectionsSnapshot.docs) {
            const activeItems = await db
                .collection('home_sections')
                .doc(sectionDoc.id)
                .collection('items')
                .where('is_active', '==', true)
                .get();

            console.log(`${sectionDoc.id}: ${activeItems.size} active items`);
        }

    } catch (error) {
        console.error('\n❌ Error:', error);
    } finally {
        process.exit(0);
    }
}

fixSectionItems();
