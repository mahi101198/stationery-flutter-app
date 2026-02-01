#!/usr/bin/env node

/**
 * Debug script to check if the stapler product exists in Firestore
 * Run from functions directory: node ../check_stapler_product.js
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin
const serviceAccountPath = path.join(__dirname, 'config', 'rps-stationery-firebase-key.json');
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(require(serviceAccountPath)),
    databaseURL: 'https://rps-stationery.firebaseio.com'
  });
}

const db = admin.firestore();

async function checkProducts() {
  try {
    console.log('🔍 Checking Firestore for stapler products...\n');

    // 1. Check if the specific product exists
    console.log('1️⃣ Looking for product: stapler-kangaro-hd10d');
    const staplerDoc = await db.collection('product_details').doc('stapler-kangaro-hd10d').get();
    
    if (staplerDoc.exists) {
      console.log('✅ Found: stapler-kangaro-hd10d');
      const data = staplerDoc.data();
      console.log('   - Name:', data.name);
      console.log('   - Price:', data.price);
      console.log('   - Category:', data.category);
      if (data.productSkus) {
        console.log('   - Product SKUs:');
        data.productSkus.forEach((sku, idx) => {
          console.log(`     [${idx}] ${sku.skuId} - Price: ${sku.price}, MRP: ${sku.mrp}`);
        });
      } else {
        console.log('   - ⚠️  No productSkus array found');
      }
    } else {
      console.log('❌ Product NOT found: stapler-kangaro-hd10d\n');
    }

    // 2. Check for any product with "stapler" in name/id
    console.log('\n2️⃣ Searching for any products with "stapler" in the name...');
    const staplerQuery = await db.collection('product_details')
      .where('name', '>=', 'stapler')
      .where('name', '<=', 'staplerz')
      .get();
    
    if (staplerQuery.empty) {
      console.log('❌ No products found with "stapler" in name');
    } else {
      console.log(`✅ Found ${staplerQuery.size} stapler products:`);
      staplerQuery.forEach(doc => {
        const data = doc.data();
        console.log(`   - ${doc.id}: ${data.name} (Price: ${data.price})`);
        if (data.productSkus) {
          console.log(`     SKUs: ${data.productSkus.map(s => s.skuId).join(', ')}`);
        }
      });
    }

    // 3. Check for the SKU ID directly
    console.log('\n3️⃣ Searching for SKU: stapler-kangaro-hd10d-standard');
    const skuQuery = await db.collection('product_details')
      .get();
    
    let found = false;
    skuQuery.forEach(doc => {
      const data = doc.data();
      if (data.productSkus && data.productSkus.some(sku => sku.skuId === 'stapler-kangaro-hd10d-standard')) {
        console.log(`✅ Found SKU in product: ${doc.id}`);
        const matchingSku = data.productSkus.find(sku => sku.skuId === 'stapler-kangaro-hd10d-standard');
        console.log(`   - Price: ${matchingSku.price}, MRP: ${matchingSku.mrp}`);
        found = true;
      }
    });
    
    if (!found) {
      console.log('❌ SKU NOT found in any product');
    }

    // 4. Show sample of products in database
    console.log('\n4️⃣ First 5 products in database:');
    const allProducts = await db.collection('product_details').limit(5).get();
    
    if (allProducts.empty) {
      console.log('❌ No products found in database!');
    } else {
      allProducts.forEach(doc => {
        const data = doc.data();
        console.log(`   - ${doc.id}: ${data.name} (Price: ${data.price})`);
      });
    }

  } catch (error) {
    console.error('❌ Error checking products:', error);
  } finally {
    process.exit(0);
  }
}

checkProducts();
