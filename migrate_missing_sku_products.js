const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function migrateProductsToSKU() {
  try {
    console.log('\n🔄 Analyzing orders for missing SKU products...\n');

    // Get all orders to find SKU IDs
    const ordersSnapshot = await db.collection('orders').get();
    const skuMap = new Map();

    ordersSnapshot.forEach(doc => {
      const items = doc.data().items || [];
      items.forEach(item => {
        if (!skuMap.has(item.productId)) {
          skuMap.set(item.productId, {
            sku: item.productId,
            name: item.name,
            price: item.price,
            mrp: item.mrp || (item.price ? item.price * 1.5 : 100),
            image: item.productImage,
          });
        }
      });
    });

    console.log(`Found ${skuMap.size} unique SKU IDs in orders:`);
    Array.from(skuMap.keys()).forEach(sku => {
      console.log(`  - ${sku}`);
    });
    console.log('\n');

    // Check which ones exist in product_details
    const batch = db.batch();
    let created = 0;
    let skipped = 0;
    const results = [];

    for (const [skuId, data] of skuMap) {
      const docRef = db.collection('product_details').doc(skuId);
      const doc = await docRef.get();

      if (!doc.exists) {
        console.log(`✅ CREATING: ${skuId}`);
        console.log(`   Name: ${data.name}`);
        console.log(`   Price: ₹${data.price}, MRP: ₹${data.mrp}`);
        console.log(`   Image: ${data.image ? '✓ Yes' : '✗ No'}\n`);

        // Extract category from SKU
        const category = skuId.includes('battery') ? 'Batteries'
          : skuId.includes('pen') ? 'Writing Instruments'
          : skuId.includes('register') ? 'Registers'
          : skuId.includes('stapler') ? 'Office Equipment'
          : skuId.includes('gift') ? 'Gift Sets'
          : skuId.includes('pad') ? 'Notepads'
          : 'Stationery';

        batch.set(docRef, {
          product_id: skuId.replace(/-\d+\w*$/, ''), // extract base ID
          sku_id: skuId,
          title: data.name,
          brand: 'RPS Stationery',
          category: category,
          sub_category: 'General',
          price: data.price,
          mrp: data.mrp,
          displayImage: data.image || '',
          description: `${data.name} - SKU: ${skuId}`,
          is_active: true,
          overall_availability: 'in_stock',
          product_skus: [{
            sku_id: skuId,
            price: data.price,
            mrp: data.mrp,
            available_quantity: 100,
            currency: 'INR',
            availability: 'in_stock'
          }],
          media: {
            main_image: {
              url: data.image || '',
              alt_text: data.name
            },
            gallery: data.image ? [{ url: data.image, alt_text: data.name }] : []
          },
          rating: { average: 0, count: 0 },
          created_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });
        results.push({ sku: skuId, status: 'CREATED' });
        created++;
      } else {
        console.log(`⏭️ EXISTS: ${skuId}\n`);
        results.push({ sku: skuId, status: 'SKIPPED (already exists)' });
        skipped++;
      }
    }

    if (created > 0) {
      console.log(`\n🔄 Committing batch update (${created} documents)...`);
      await batch.commit();
      console.log(`✅ Successfully created ${created} product documents\n`);
    } else {
      console.log(`\n✅ All SKU products already exist (${skipped} skipped)\n`);
    }

    // Summary
    console.log('\n📊 Migration Summary:');
    console.log(`   Total SKU IDs found: ${skuMap.size}`);
    console.log(`   Created: ${created}`);
    console.log(`   Skipped: ${skipped}`);
    
    console.log('\n📋 Details:');
    results.forEach(r => {
      console.log(`   ${r.sku}: ${r.status}`);
    });

    console.log('\n✅ Migration complete! Orders should now show correct product data.\n');

  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }

  process.exit(0);
}

migrateProductsToSKU();
