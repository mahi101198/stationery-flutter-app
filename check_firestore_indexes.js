/**
 * Check and Create Firestore Indexes
 * 
 * This script will:
 * 1. Test the problematic query
 * 2. Show if index is needed
 * 3. Provide instructions to create it
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkIndexes() {
    console.log('='.repeat(70));
    console.log('FIRESTORE INDEX CHECK');
    console.log('='.repeat(70));
    console.log();

    try {
        // Test the exact query used in the app
        console.log('1️⃣  Testing home_sections query...');
        console.log('-'.repeat(70));
        console.log('Query: where("status", "==", "active").orderBy("rank")');
        console.log();

        const startTime = Date.now();

        const querySnapshot = await db
            .collection('home_sections')
            .where('status', '==', 'active')
            .orderBy('rank')
            .get();

        const endTime = Date.now();
        const duration = endTime - startTime;

        console.log(`✅ Query succeeded!`);
        console.log(`   Duration: ${duration}ms`);
        console.log(`   Results: ${querySnapshot.size} documents`);
        console.log();

        if (querySnapshot.size > 0) {
            console.log('📦 Sections found:');
            querySnapshot.forEach((doc, index) => {
                const data = doc.data();
                console.log(`   ${index + 1}. ${doc.id}: "${data.title}" (rank: ${data.rank})`);
            });
        } else {
            console.log('⚠️  No sections found with status="active"');
            console.log();
            console.log('Checking all sections...');

            const allSections = await db.collection('home_sections').get();
            console.log(`Total sections: ${allSections.size}`);

            allSections.forEach(doc => {
                const data = doc.data();
                console.log(`   - ${doc.id}: status="${data.status}"`);
            });
        }

        // Check items in sections
        console.log();
        console.log('2️⃣  Checking section items...');
        console.log('-'.repeat(70));

        for (const sectionDoc of querySnapshot.docs) {
            const itemsQuery = db
                .collection('home_sections')
                .doc(sectionDoc.id)
                .collection('items')
                .where('is_active', '==', true)
                .orderBy('rank');

            try {
                const itemsSnapshot = await itemsQuery.get();
                console.log(`   ${sectionDoc.id}: ${itemsSnapshot.size} active items`);

                if (itemsSnapshot.size === 0) {
                    // Check if items exist without filter
                    const allItems = await db
                        .collection('home_sections')
                        .doc(sectionDoc.id)
                        .collection('items')
                        .get();

                    console.log(`      (${allItems.size} total items, but none with is_active=true)`);
                }
            } catch (error) {
                console.log(`   ${sectionDoc.id}: ❌ Error - ${error.message}`);
            }
        }

        console.log();
        console.log('3️⃣  DIAGNOSIS');
        console.log('-'.repeat(70));

        if (querySnapshot.size === 0) {
            console.log('❌ ISSUE: No sections with status="active" found');
            console.log('   FIX: Update at least one section to have status="active"');
        } else {
            console.log(`✅ Found ${querySnapshot.size} active sections`);

            // Check if any section has items
            let hasItems = false;
            for (const sectionDoc of querySnapshot.docs) {
                const itemsSnapshot = await db
                    .collection('home_sections')
                    .doc(sectionDoc.id)
                    .collection('items')
                    .where('is_active', '==', true)
                    .limit(1)
                    .get();

                if (!itemsSnapshot.empty) {
                    hasItems = true;
                    break;
                }
            }

            if (!hasItems) {
                console.log('❌ ISSUE: Sections exist but have no active items');
                console.log('   FIX: Ensure items have is_active=true');
            } else {
                console.log('✅ Sections have active items');
                console.log();
                console.log('🎯 If app still shows no products, check:');
                console.log('   1. HomeSectionController is initializing');
                console.log('   2. Check app logs for errors');
                console.log('   3. Verify items have category_id and subcategory_id fields');
            }
        }

    } catch (error) {
        console.log();
        console.log('❌ ERROR:', error.message);
        console.log();

        if (error.message.includes('index')) {
            console.log('🔧 INDEX REQUIRED!');
            console.log('-'.repeat(70));
            console.log('The query requires a composite index.');
            console.log();
            console.log('To create it:');
            console.log('1. Go to: https://console.firebase.google.com/project/rps-statationary-jaipur/firestore/indexes');
            console.log('2. Click "Add Index"');
            console.log('3. Set:');
            console.log('   - Collection ID: home_sections');
            console.log('   - Field 1: status (Ascending)');
            console.log('   - Field 2: rank (Ascending)');
            console.log('   - Query scope: Collection');
            console.log('4. Click "Create"');
            console.log('5. Wait for index to build (usually 1-2 minutes)');
            console.log();
            console.log('Or click this link (if provided in error):');
            if (error.message.includes('https://')) {
                const urlMatch = error.message.match(/https:\/\/[^\s]+/);
                if (urlMatch) {
                    console.log(urlMatch[0]);
                }
            }
        } else {
            console.log('Stack trace:', error.stack);
        }
    } finally {
        process.exit(0);
    }
}

checkIndexes();
