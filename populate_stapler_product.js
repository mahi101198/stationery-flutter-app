#!/usr/bin/env node

/**
 * Script to populate the stapler-kangaro-hd10d product in Firestore
 * with the correct product_skus structure
 * 
 * Run from functions directory:
 * node ../populate_stapler_product.js
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Try to load service account from functions/config directory
const possiblePaths = [
  path.join(__dirname, 'functions', 'config', 'rps-stationery-firebase-key.json'),
  path.join(__dirname, 'config', 'rps-stationery-firebase-key.json'),
  path.join(process.cwd(), 'functions', 'config', 'rps-stationery-firebase-key.json'),
];

let serviceAccountPath = null;
for (const p of possiblePaths) {
  if (fs.existsSync(p)) {
    serviceAccountPath = p;
    break;
  }
}

if (!admin.apps.length) {
  if (serviceAccountPath) {
    admin.initializeApp({
      credential: admin.credential.cert(require(serviceAccountPath)),
    });
  } else {
    // Use default credentials (gcloud SDK)
    admin.initializeApp();
  }
}

const db = admin.firestore();

async function populateStaplerProduct() {
  try {
    const productId = 'stapler-kangaro-hd10d';
    const skuId = 'stapler-kangaro-hd10d-standard';

    console.log('🔍 ════════════════════════════════════════════');
    console.log(`Populating product: ${productId}`);
    console.log('🔍 ════════════════════════════════════════════\n');

    // Get the product
    const productDoc = await db.collection('product_details').doc(productId).get();

    if (!productDoc.exists) {
      console.log(`❌ Product does NOT exist: ${productId}`);
      console.log('Creating new product with complete structure...\n');

      // Create a new product following the a3-color-sheets template
      const newProduct = {
        id: productId,
        product_id: productId,
        title: 'Kangaro HD10D Heavy Duty Stapler',
        subtitle: 'Heavy duty stapler for continuous use',
        price: 275,
        brand: 'Kangaro',
        category: 'Office Supplies',
        sub_category: 'Staplers',
        is_active: true,
        
        // Media
        media: {
          main_image: {
            url: 'https://images.unsplash.com/photo-1599122762127-a8d72e4db0bc?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxvZmZpY2UlMjBzdGFwbGVyJTIwbWV0YWx8ZW58MXx8fHwxNzY5ODM5MjE5fDA&ixlib=rb-4.1.0&q=80&w=1080',
            alt_text: 'Kangaro HD10D Heavy Duty Stapler'
          },
          gallery: []
        },

        // Product SKUs - THIS IS THE KEY PART
        product_skus: [
          {
            sku_id: skuId,
            price: 275,
            mrp: 275,
            availability: 'in_stock',
            available_quantity: 100,
            currency: 'INR',
            attributes: {
              type: 'standard',
              capacity: '50 pages'
            }
          }
        ],

        // Delivery info
        delivery_info: {
          cod_available: true,
          estimated_delivery: '2-3 business days',
          free_delivery_threshold: 499,
          return_policy: '7 days return'
        },

        // Content cards
        content_cards: [
          {
            card_id: 'highlights',
            type: 'list',
            title: 'Highlights',
            order: 1,
            data: [
              'Heavy duty stapler',
              'Capacity: 50 pages',
              'Metal body construction',
              'Built to last',
              'Easy to refill',
              'Perfect for office use'
            ]
          },
          {
            card_id: 'specifications',
            type: 'key_value',
            title: 'Specifications',
            order: 3,
            data: {
              'Capacity': '50 pages',
              'Material': 'Metal',
              'Color': 'Black',
              'Weight': '500g',
              'Staple Size': 'No. 10',
              'Brand': 'Kangaro'
            }
          },
          {
            card_id: 'description',
            type: 'text',
            title: 'Product Description',
            order: 2,
            data: 'Kangaro HD10D is a heavy-duty stapler designed for continuous office use. With a sturdy metal body and large capacity, it can staple up to 50 pages at once. Perfect for busy offices and high-volume stapling needs.'
          }
        ],

        // Ratings and other metadata
        rating: {
          average: 4.5,
          count: 128
        },
        purchase_limits: {
          max_per_order: 50,
          max_per_user_per_day: 20
        },
        overall_availability: 'in_stock',
        created_at: new Date().toISOString(),
        uploaded_at: new Date().toISOString(),
        last_updated: new Date().toISOString(),
        last_sync: new Date().toISOString(),
        updated_at: Math.floor(Date.now() / 1000)
      };

      // Save the product
      await db.collection('product_details').doc(productId).set(newProduct);

      console.log(`✅ Product created successfully: ${productId}`);
      console.log(`✅ Added SKU: ${skuId}`);
      console.log(`✅ Price: ₹275\n`);

    } else {
      console.log(`✅ Product exists: ${productId}`);
      const product = productDoc.data();

      // Check if product_skus exists
      if (!product.product_skus || !Array.isArray(product.product_skus)) {
        console.log('⚠️  product_skus array is missing. Adding it...\n');

        const newSku = {
          sku_id: skuId,
          price: product.price || 275,
          mrp: product.price || 275,
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
        console.log(`   ${JSON.stringify(newSku, null, 2)}\n`);

      } else {
        // Check if SKU exists
        const existingSku = product.product_skus.find(sku => sku.sku_id === skuId);

        if (existingSku) {
          console.log(`✅ SKU already exists in product_skus array:`);
          console.log(`   ${JSON.stringify(existingSku, null, 2)}\n`);
        } else {
          console.log(`⚠️  SKU not found. Adding to product_skus array...\n`);

          const newSku = {
            sku_id: skuId,
            price: product.price || 275,
            mrp: product.price || 275,
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
          console.log(`   ${JSON.stringify(newSku, null, 2)}\n`);
        }
      }
    }

    console.log('✅ ════════════════════════════════════════════');
    console.log('✅ Product is now ready for checkout!');
    console.log('✅ Try creating an order with this product.');
    console.log('════════════════════════════════════════════\n');

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error);
  } finally {
    process.exit(0);
  }
}

populateStaplerProduct();
