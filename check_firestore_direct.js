/**
 * Direct Firestore Data Check Script
 * 
 * This script will:
 * 1. Connect to Firestore using service account
 * 2. Check subcategories collection
 * 3. Check home_sections collection
 * 4. Verify data integrity
 * 
 * Usage: node check_firestore_direct.js
 */

const admin = require('firebase-admin');

// Try to load service account key
let serviceAccount;
try {
    serviceAccount = require('./serviceAccountKey.json');
    console.log('✅ Service account key loaded successfully\n');
} catch (error) {
    console.log('❌ Service account key not found!');
    console.log('📝 Please download it from:');
    console.log('   https://console.firebase.google.com/project/rps-statationary-jaipu/settings/serviceaccounts/adminsdk');
    console.log('   Save as: serviceAccountKey.json in project root\n');
    process.exit(1);
}

// Initialize Firebase Admin
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkFirestoreData() {
    console.log('='.repeat(70));
    console.log('FIRESTORE DATA VERIFICATION');
    console.log('='.repeat(70));
    console.log();

    try {
        // 1. Check Subcategories
        console.log('1️⃣  SUBCATEGORIES COLLECTION');
        console.log('-'.repeat(70));

        const subcategoriesSnapshot = await db.collection('subcategories').get();
        console.log(`Total documents: ${subcategoriesSnapshot.size}`);

        if (subcategoriesSnapshot.empty) {
            console.log('❌ NO SUBCATEGORIES FOUND!\n');
        } else {
            let activeCount = 0;
            let issues = [];

            subcategoriesSnapshot.forEach((doc, index) => {
                const data = doc.data();
                const isActive = data.is_active || data.isActive;

                if (isActive) activeCount++;

                console.log(`\n  ${index + 1}. ${doc.id}`);
                console.log(`     name: ${data.name || 'MISSING ❌'}`);
                console.log(`     category_id: ${data.category_id || data.categoryId || 'MISSING ❌'}`);
                console.log(`     image: ${data.image ? '✓' : 'MISSING ❌'}`);
                console.log(`     is_active: ${isActive !== undefined ? isActive : 'MISSING ❌'}`);
                console.log(`     rank: ${data.rank !== undefined ? data.rank : 'MISSING ❌'}`);

                // Check for issues
                if (!data.name) issues.push(`${doc.id}: missing 'name'`);
                if (!data.category_id && !data.categoryId) issues.push(`${doc.id}: missing 'category_id'`);
                if (!data.image) issues.push(`${doc.id}: missing 'image'`);
                if (isActive === undefined) issues.push(`${doc.id}: missing 'is_active'`);
                if (data.rank === undefined) issues.push(`${doc.id}: missing 'rank'`);
            });

            console.log(`\n  Summary:`);
            console.log(`  - Total: ${subcategoriesSnapshot.size}`);
            console.log(`  - Active: ${activeCount}`);
            console.log(`  - Inactive: ${subcategoriesSnapshot.size - activeCount}`);

            if (issues.length > 0) {
                console.log(`\n  ⚠️  Issues found:`);
                issues.forEach(issue => console.log(`     - ${issue}`));
            } else {
                console.log(`  ✅ All subcategories have required fields`);
            }
        }

        // 2. Check Home Sections
        console.log('\n\n2️⃣  HOME SECTIONS COLLECTION');
        console.log('-'.repeat(70));

        const sectionsSnapshot = await db.collection('home_sections').get();
        console.log(`Total documents: ${sectionsSnapshot.size}`);

        if (sectionsSnapshot.empty) {
            console.log('❌ NO HOME SECTIONS FOUND!\n');
        } else {
            let liveCount = 0;

            for (const [index, sectionDoc] of sectionsSnapshot.docs.entries()) {
                const sectionData = sectionDoc.data();
                const isLive = sectionData.is_live || sectionData.isLive;

                if (isLive) liveCount++;

                console.log(`\n  ${index + 1}. ${sectionDoc.id}`);
                console.log(`     title: ${sectionData.title || 'MISSING ❌'}`);
                console.log(`     is_live: ${isLive !== undefined ? isLive : 'MISSING ❌'}`);
                console.log(`     rank: ${sectionData.rank !== undefined ? sectionData.rank : 'MISSING ❌'}`);

                // Check items in this section
                const itemsSnapshot = await db.collection('home_sections')
                    .doc(sectionDoc.id)
                    .collection('items')
                    .limit(5)
                    .get();

                console.log(`     items: ${itemsSnapshot.size} (showing first 5)`);

                if (!itemsSnapshot.empty) {
                    let itemsWithSubcat = 0;
                    itemsSnapshot.forEach(itemDoc => {
                        const itemData = itemDoc.data();
                        const hasSubcat = itemData.subcategory_id || itemData.subcategoryId;
                        if (hasSubcat) itemsWithSubcat++;

                        console.log(`       - ${itemDoc.id}:`);
                        console.log(`         name: ${itemData.name || 'MISSING'}`);
                        console.log(`         category_id: ${itemData.category_id || itemData.categoryId || 'MISSING ❌'}`);
                        console.log(`         subcategory_id: ${itemData.subcategory_id || itemData.subcategoryId || 'MISSING ❌'}`);
                    });

                    console.log(`     items with subcategory_id: ${itemsWithSubcat}/${itemsSnapshot.size}`);
                }
            }

            console.log(`\n  Summary:`);
            console.log(`  - Total sections: ${sectionsSnapshot.size}`);
            console.log(`  - Live sections: ${liveCount}`);
        }

        // 3. Final Diagnosis
        console.log('\n\n3️⃣  DIAGNOSIS');
        console.log('-'.repeat(70));

        if (subcategoriesSnapshot.empty) {
            console.log('❌ ISSUE: No subcategories in database');
            console.log('   FIX: Add subcategories via Firebase Console');
        } else {
            const activeSubcats = subcategoriesSnapshot.docs.filter(doc => {
                const data = doc.data();
                return data.is_active || data.isActive;
            });

            if (activeSubcats.length === 0) {
                console.log('❌ ISSUE: No active subcategories (all have is_active: false)');
                console.log('   FIX: Set is_active: true for at least one subcategory');
            } else {
                console.log(`✅ Found ${activeSubcats.length} active subcategories`);
            }
        }

        if (sectionsSnapshot.empty) {
            console.log('❌ ISSUE: No home sections in database');
            console.log('   FIX: Add home sections via Firebase Console');
        } else {
            const liveSections = sectionsSnapshot.docs.filter(doc => {
                const data = doc.data();
                return data.is_live || data.isLive;
            });

            if (liveSections.length === 0) {
                console.log('❌ ISSUE: No live sections (all have is_live: false)');
                console.log('   FIX: Set is_live: true for at least one section');
            } else {
                console.log(`✅ Found ${liveSections.length} live sections`);
            }
        }

    } catch (error) {
        console.error('\n❌ Error:', error);
    } finally {
        process.exit(0);
    }
}

checkFirestoreData();
