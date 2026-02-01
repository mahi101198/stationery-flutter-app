#!/usr/bin/env node

/**
 * Script to check and fix the stapler-kangaro-hd10d product in Firestore
 * This script will:
 * 1. Check if the product exists
 * 2. Check if it has the proper product_skus array
 * 3. Add the SKU if it's missing
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin
const serviceAccountPath = path.join(__dirname, 'functions', 'config', 'rps-stationery-firebase-key.json');
if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert(require(serviceAccountPath)),
      databaseURL: 'https://rps-stationery.firebaseio.com'
    });
  } catch (error) {
    console.log('⚠️  Service account not found. Using default credentials.');
    admin.initializeApp();
  }
}

const db = admin.firestore();

async function checkAndFixProduct() {
  try {
    const productId = 'stapler-kangaro-hd10d';
    const skuId = 'stapler-kangaro-hd10d-standard';

    console.log('🔍 ════════════════════════════════════════════');
    console.log(`Checking product: ${productId}`);
    console.log(`Looking for SKU: ${skuId}`);
    console.log('🔍 ════════════════════════════════════════════\n');

    // 1. Get the product
    const productDoc = await db.collection('product_details').doc(productId).get();

    if (!productDoc.exists) {
      console.log(`❌ Product does NOT exist: ${productId}`);
      console.log('❌ You need to create this product first.');
      return;
    }

    const product = productDoc.data();
    console.log(`✅ Product found: ${product.title || product.product_id}`);
    console.log(`   Price: ${product.price}`);
    console.log(`   Category: ${product.category}`);

    // 2. Check product_skus array
    if (!product.product_skus || !Array.isArray(product.product_skus)) {
      console.log('\n❌ Product does NOT have a product_skus array!');
      console.log('   Creating product_skus array...\n');

      const newSku = {
        sku_id: skuId,
        price: product.price || 0,
        mrp: product.price || 0,
        availability: 'in_stock',
        available_quantity: 100,
        currency: 'INR',
        attributes: {
          type: 'standard'
        }
      };

      await db.collection('product_details').doc(productId).update({
        product_skus: [newSku]
      });

      console.log('✅ Created product_skus array with SKU:');
      console.log(`   ${JSON.stringify(newSku, null, 2)}`);
    } else {
      // Check if SKU exists
      const existingSku = product.product_skus.find(sku => sku.sku_id === skuId);

      if (existingSku) {
        console.log(`\n✅ SKU already exists in product_skus array:`);
        console.log(`   ${JSON.stringify(existingSku, null, 2)}`);
      } else {
        console.log(`\n❌ SKU NOT found in product_skus array`);
        console.log(`   Current SKUs: ${product.product_skus.map(s => s.sku_id).join(', ')}`);
        console.log('\n   Adding SKU...\n');

        const newSku = {
          sku_id: skuId,
          price: product.price || 0,
          mrp: product.price || 0,
          availability: 'in_stock',
          available_quantity: 100,
          currency: 'INR',
          attributes: {
            type: 'standard'
          }
        };

        const updatedSkus = [...product.product_skus, newSku];

        await db.collection('product_details').doc(productId).update({
          product_skus: updatedSkus
        });

        console.log('✅ Added SKU to product_skus array:');
        console.log(`   ${JSON.stringify(newSku, null, 2)}`);
      }
    }

    console.log('\n✅ ════════════════════════════════════════════');
    console.log('Product is now ready for checkout!');
    console.log('════════════════════════════════════════════');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    process.exit(0);
  }
}

checkAndFixProduct();
