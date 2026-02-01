const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkFirestoreData() {
    console.log('🔍 Checking Firestore Data Structure...\n');

    try {
        // 1. Check Subcategories Collection
        console.log('📂 SUBCATEGORIES COLLECTION:');
        console.log('='.repeat(60));

        const subcategoriesSnapshot = await db.collection('subcategories').limit(5).get();

        if (subcategoriesSnapshot.empty) {
            console.log('❌ No subcategories found in database!');
        } else {
            console.log(`✅ Found ${subcategoriesSnapshot.size} subcategories (showing first 5)`);
            subcategoriesSnapshot.forEach((doc, index) => {
                const data = doc.data();
                console.log(`\n${index + 1}. Subcategory ID: ${doc.id}`);
                console.log(`   - name: ${data.name || 'N/A'}`);
                console.log(`   - categoryId: ${data.categoryId || data.category_id || 'N/A'}`);
                console.log(`   - image: ${data.image ? 'Yes' : 'No'}`);
                console.log(`   - isActive: ${data.isActive !== undefined ? data.isActive : data.is_active}`);
                console.log(`   - rank: ${data.rank || 'N/A'}`);
            });
        }

        // 2. Check Home Sections Collection
        console.log('\n\n📂 HOME SECTIONS COLLECTION:');
        console.log('='.repeat(60));

        const sectionsSnapshot = await db.collection('home_sections').limit(3).get();

        if (sectionsSnapshot.empty) {
            console.log('❌ No home sections found in database!');
        } else {
            console.log(`✅ Found ${sectionsSnapshot.size} home sections (showing first 3)`);

            for (const sectionDoc of sectionsSnapshot.docs) {
                const sectionData = sectionDoc.data();
                console.log(`\n📦 Section ID: ${sectionDoc.id}`);
                console.log(`   - title: ${sectionData.title || 'N/A'}`);
                console.log(`   - isLive: ${sectionData.isLive !== undefined ? sectionData.isLive : sectionData.is_live}`);
                console.log(`   - rank: ${sectionData.rank || 'N/A'}`);

                // Check section items
                const itemsSnapshot = await db.collection('home_sections')
                    .doc(sectionDoc.id)
                    .collection('items')
                    .limit(2)
                    .get();

                if (itemsSnapshot.empty) {
                    console.log('   ⚠️  No items in this section');
                } else {
                    console.log(`   ✅ Has ${itemsSnapshot.size} items (showing first 2):`);
                    itemsSnapshot.forEach((itemDoc, index) => {
                        const itemData = itemDoc.data();
                        console.log(`\n   ${index + 1}. Item ID: ${itemDoc.id}`);
                        console.log(`      - name: ${itemData.name || 'N/A'}`);
                        console.log(`      - productId: ${itemData.productId || itemData.product_id || 'N/A'}`);
                        console.log(`      - skuId: ${itemData.skuId || itemData.sku_id || 'N/A'}`);
                        console.log(`      - categoryId: ${itemData.categoryId || itemData.category_id || 'MISSING ❌'}`);
                        console.log(`      - subcategoryId: ${itemData.subcategoryId || itemData.subcategory_id || 'MISSING ❌'}`);
                        console.log(`      - price: ${itemData.price || 'N/A'}`);
                        console.log(`      - imageUrl: ${itemData.imageUrl || itemData.image_url ? 'Yes' : 'No'}`);
                    });
                }
            }
        }

        // 3. Summary
        console.log('\n\n📊 SUMMARY:');
        console.log('='.repeat(60));

        const totalSubcategories = await db.collection('subcategories').count().get();
        const totalSections = await db.collection('home_sections').count().get();

        console.log(`Total Subcategories: ${totalSubcategories.data().count}`);
        console.log(`Total Home Sections: ${totalSections.data().count}`);

        // Check if subcategories have required fields
        const activeSubcategories = await db.collection('subcategories')
            .where('isActive', '==', true)
            .get();

        console.log(`Active Subcategories: ${activeSubcategories.size}`);

        // Check schema compliance
        console.log('\n🔍 SCHEMA VALIDATION:');
        let schemaIssues = [];

        // Check if home section items have category and subcategory IDs
        for (const sectionDoc of sectionsSnapshot.docs) {
            const itemsSnapshot = await db.collection('home_sections')
                .doc(sectionDoc.id)
                .collection('items')
                .limit(10)
                .get();

            itemsSnapshot.forEach(itemDoc => {
                const data = itemDoc.data();
                if (!data.categoryId && !data.category_id) {
                    schemaIssues.push(`Item ${itemDoc.id} in section ${sectionDoc.id} missing categoryId`);
                }
                if (!data.subcategoryId && !data.subcategory_id) {
                    schemaIssues.push(`Item ${itemDoc.id} in section ${sectionDoc.id} missing subcategoryId`);
                }
            });
        }

        if (schemaIssues.length > 0) {
            console.log('❌ Schema Issues Found:');
            schemaIssues.forEach(issue => console.log(`   - ${issue}`));
        } else {
            console.log('✅ All checked items have required fields (categoryId, subcategoryId)');
        }

    } catch (error) {
        console.error('❌ Error checking Firestore data:', error);
    } finally {
        process.exit(0);
    }
}

checkFirestoreData();
