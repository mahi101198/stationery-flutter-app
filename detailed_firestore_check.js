/**
 * Detailed Firestore Check - Verify exact data structure
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function detailedCheck() {
    console.log('='.repeat(70));
    console.log('DETAILED FIRESTORE CHECK');
    console.log('='.repeat(70));
    console.log();

    try {
        // 1. Check Subcategories with exact field names
        console.log('1️⃣  SUBCATEGORIES - Checking exact field structure');
        console.log('-'.repeat(70));

        const subcatsSnapshot = await db.collection('subcategories').limit(3).get();

        subcatsSnapshot.forEach((doc, index) => {
            const data = doc.data();
            console.log(`\n${index + 1}. Document ID: ${doc.id}`);
            console.log(`   Fields in document:`);
            Object.keys(data).forEach(key => {
                console.log(`   - ${key}: ${JSON.stringify(data[key])}`);
            });
        });

        // 2. Check Home Sections
        console.log('\n\n2️⃣  HOME SECTIONS - Checking status field');
        console.log('-'.repeat(70));

        const sectionsSnapshot = await db.collection('home_sections').get();

        for (const sectionDoc of sectionsSnapshot.docs) {
            const sectionData = sectionDoc.data();
            console.log(`\n📦 Section: ${sectionDoc.id}`);
            console.log(`   title: ${sectionData.title}`);
            console.log(`   status: ${sectionData.status}`);
            console.log(`   type: ${sectionData.type}`);
            console.log(`   rank: ${sectionData.rank}`);

            // Check items
            const itemsSnapshot = await db.collection('home_sections')
                .doc(sectionDoc.id)
                .collection('items')
                .limit(3)
                .get();

            console.log(`   items count: ${itemsSnapshot.size}`);

            if (itemsSnapshot.size > 0) {
                console.log(`   Sample items:`);
                itemsSnapshot.forEach((itemDoc, idx) => {
                    const itemData = itemDoc.data();
                    console.log(`\n   Item ${idx + 1} (${itemDoc.id}):`);
                    console.log(`     Fields in item:`);
                    Object.keys(itemData).forEach(key => {
                        const value = itemData[key];
                        const displayValue = typeof value === 'string' && value.length > 50
                            ? value.substring(0, 50) + '...'
                            : value;
                        console.log(`     - ${key}: ${JSON.stringify(displayValue)}`);
                    });
                });
            } else {
                console.log(`   ⚠️  NO ITEMS in this section!`);
            }
        }

        // 3. Summary
        console.log('\n\n3️⃣  SUMMARY');
        console.log('-'.repeat(70));

        const activeSubcats = subcatsSnapshot.docs.filter(doc => {
            const data = doc.data();
            return data.is_active === true || data.isActive === true;
        });

        const activeSections = sectionsSnapshot.docs.filter(doc => {
            const data = doc.data();
            return data.status === 'active';
        });

        console.log(`Total Subcategories: ${subcatsSnapshot.size} (checked first 3)`);
        console.log(`Active Subcategories: ${activeSubcats.length}`);
        console.log(`\nTotal Sections: ${sectionsSnapshot.size}`);
        console.log(`Active Sections: ${activeSections.length}`);

        if (activeSections.length > 0) {
            console.log(`\nActive sections:`);
            activeSections.forEach(doc => {
                console.log(`  - ${doc.id}: "${doc.data().title}"`);
            });
        }

        // Check if active sections have items
        console.log(`\n4️⃣  CHECKING ITEMS IN ACTIVE SECTIONS`);
        console.log('-'.repeat(70));

        for (const sectionDoc of activeSections) {
            const itemsCount = await db.collection('home_sections')
                .doc(sectionDoc.id)
                .collection('items')
                .count()
                .get();

            console.log(`${sectionDoc.id}: ${itemsCount.data().count} items`);
        }

    } catch (error) {
        console.error('\n❌ Error:', error);
    } finally {
        process.exit(0);
    }
}

detailedCheck();
