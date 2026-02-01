const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function checkFirestoreStructure() {
  console.log('\n🔍 Checking Firestore Structure...\n');

  try {
    // Step 1: Get all orders and collect SKU IDs
    console.log('📦 Step 1: Checking Orders...');
    const ordersSnapshot = await db.collection('orders').limit(10).get();
    
    const allSkuIds = new Set();
    ordersSnapshot.forEach(doc => {
      const order = doc.data();
      const items = order.items || [];
      console.log(`\n  Order ${doc.id}:`);
      items.forEach((item, idx) => {
        console.log(`    Item ${idx + 1}:`);
        console.log(`      - productId: ${item.productId}`);
        console.log(`      - name: ${item.name}`);
        console.log(`      - price: ${item.price}`);
        console.log(`      - productImage: ${item.productImage || 'null'}`);
        
        if (item.productId) {
          allSkuIds.add(item.productId);
        }
      });
    });

    console.log(`\n✅ Found ${allSkuIds.size} unique SKU IDs in orders:`);
    console.log('   ' + Array.from(allSkuIds).join(', '));

    // Step 2: Check if these SKU IDs exist in product_details
    console.log('\n\n📚 Step 2: Checking product_details collection...');
    
    const productsSnapshot = await db.collection('product_details').get();
    const existingDocIds = new Set();
    
    productsSnapshot.forEach(doc => {
      existingDocIds.add(doc.id);
    });

    console.log(`   Total documents in product_details: ${existingDocIds.size}`);
    console.log(`   Sample document IDs: ${Array.from(existingDocIds).slice(0, 5).join(', ')}`);

    // Step 3: Compare - which SKU IDs are missing
    console.log('\n\n🔄 Step 3: Comparing SKU IDs with product_details...');
    
    let foundCount = 0;
    let missingCount = 0;
    const missingSkus = [];

    for (const sku of allSkuIds) {
      const doc = await db.collection('product_details').doc(sku).get();
      
      if (doc.exists) {
        console.log(`   ✅ FOUND: ${sku}`);
        console.log(`      - Fields: ${Object.keys(doc.data()).join(', ')}`);
        const data = doc.data();
        console.log(`      - name: ${data.name || 'MISSING'}`);
        console.log(`      - price: ${data.price !== undefined ? data.price : 'MISSING'}`);
        console.log(`      - displayImage: ${data.displayImage ? 'YES' : 'MISSING'}`);
        foundCount++;
      } else {
        console.log(`   ❌ MISSING: ${sku}`);
        missingSkus.push(sku);
        missingCount++;
      }
    }

    // Step 4: Summary
    console.log('\n\n📊 Summary:');
    console.log(`   SKU IDs in orders: ${allSkuIds.size}`);
    console.log(`   Found in product_details: ${foundCount}`);
    console.log(`   Missing in product_details: ${missingCount}`);

    if (missingCount > 0) {
      console.log('\n   ❌ PROBLEM IDENTIFIED!');
      console.log(`   These SKU IDs are in orders but NOT in product_details:`);
      missingSkus.forEach(sku => {
        console.log(`      - ${sku}`);
      });
      console.log('\n   SOLUTION: Need to create product documents with these SKU IDs');
      console.log('   See FIRESTORE_SKU_STRUCTURE_FIX.md for migration script');
    } else {
      console.log('\n   ✅ All SKU IDs found in product_details!');
      console.log('   Product fetching should work correctly.');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  }

  process.exit(0);
}

checkFirestoreStructure();
