# Firestore Product Structure - Verified Data ✅

## Products Found in Firestore

Based on the structure check, these are the products you have with SKU data:

### 1. Scale - Infinity Small

**Firestore Path:** `product_details/scale-infinity-small`

```json
{
  "product_id": "scale-infinity-small",
  "title": "Infinity Small Scale - 4.8 inches",
  "brand": "Infinity",
  "category": "Stationery",
  "sub_category": "Geometry & Scales",
  "subtitle": "Compact size · Portable · Student essential",
  
  "product_skus": [
    {
      "sku_id": "scale-infinity-small-4pt8in",
      "price": 8,
      "mrp": 15,
      "available_quantity": 100,
      "attributes": {
        "color": "Transparent",
        "size": "4.8 inches / 12 cm",
        "type": "Compact ruler",
        "pack": "Single"
      },
      "currency": "INR"
    }
  ],
  
  "media": {
    "main_image": {
      "url": "https://images.unsplash.com/photo-1685038408124-e20ecac92293?...",
      "alt_text": "Infinity Small Scale - 4.8 inches"
    },
    "gallery": [...]
  },
  
  "overall_availability": "in_stock",
  
  "rating": {
    "average": 4.2,
    "count": 756
  }
}
```

**Order Example:**
```json
{
  "productId": "scale-infinity-small-4pt8in",
  "name": "Infinity Small Scale - 4.8 inches",
  "price": 8,
  "mrp": 15,
  "productImage": "https://images.unsplash.com/photo-1685038408124-e20ecac92293?...",
  "quantity": 1
}
```

---

## Products Missing from product_details (Need to Create)

### 2. Register - 172 Pages HB

**Firestore Path:** `product_details/register-172-pages-hb` ← **MISSING!**

**In Orders:** ✅ Yes  
**In product_details:** ❌ No

**Workaround while missing:**
```
Current: "Product register-172-pages-hb" (price: 0)
Solution: Create document in Firestore
```

---

### 3. Scale - Infinity Small (Variant?)

**Firestore Path:** `product_details/stapler-domes-standard` ← **MISSING!**

**In Orders:** ✅ Yes  
**In product_details:** ❌ No

**SKU Details Needed:**
- Product title/name
- Price & MRP
- Image URL
- Category
- Description

---

### 4. Battery - Panasonic AA

**Firestore Path:** `product_details/battery-panasonic-aa-1` ← **MISSING!**

**Status:**
- Order uses SKU: "battery-panasonic-aa-1"
- Base product exists: "battery-panasonic-aa" ✓
- But SKU not in product_skus array

**Solution Needed:**
1. Check if base product "battery-panasonic-aa" has variant with "-1"
2. OR add "-1" variant to product_skus array

---

### 5. Gift Set - Painting Kit Complete

**Firestore Path:** `product_details/gift-set-painting-kit-complete` ← **MISSING!**

**In Orders:** ✅ Yes  
**In product_details:** ❌ No

**Note:** Base product "gift-set-painting-kit" might exist but SKU not found

---

### 6. Pen - Ball Balaji 20 Pack

**Firestore Path:** `product_details/pen-ball-balaji-20pack` ← **MISSING!**

**In Orders:** ✅ Yes  
**In product_details:** ❌ No

**Base Product:** "pen-ball-balaji" might exist, but need to verify SKU

---

### 7. Writing Pad - Conference A5

**Firestore Path:** `product_details/writing-pad-conference-a5` ← **MISSING!**

**In Orders:** ✅ Yes  
**In product_details:** ❌ No

---

## Current Situation

### ✅ What's Working

- **scale-infinity-small-4pt8in** - Full product data in Firestore
- Code can fetch and display correctly
- Console shows: "✅ Found matching SKU"

### ❌ What's Broken

The following SKUs are in orders but **NO product data in Firestore**:

1. register-172-pages-hb
2. stapler-domes-standard
3. battery-panasonic-aa-1
4. gift-set-painting-kit-complete
5. pen-ball-balaji-20pack
6. writing-pad-conference-a5

### 🔄 What Needs Checking

Some base products exist (e.g., "battery-panasonic-aa") but:
- SKU variants might not be in product_skus array
- OR document structure might be different

---

## Two Solutions

### Option A: Add Missing Documents to product_details (Recommended ✅)

Create Firestore documents for each missing SKU:

```bash
Node script: migrate_sku_products.js
Automatically creates missing product documents from order data
```

**Benefits:**
- ✅ Automatic & complete
- ✅ No manual effort
- ✅ All orders immediately show correct data

---

### Option B: Update Order Creation to Use Base Product IDs (Code Change)

Modify cloud function to:
1. Get SKU from cart
2. Look up base product
3. Save order with base product ID instead of SKU
4. Order details screen fetches using base ID

**Drawbacks:**
- ❌ Requires code changes
- ❌ Still need to handle SKU pricing
- ❌ More complex logic

---

## Recommended Action

**Use Option A:**

1. Run migration script:
   ```bash
   node migrate_sku_products.js
   ```

2. Verify in Firebase Console:
   - `product_details/register-172-pages-hb` - should exist
   - `product_details/gift-set-painting-kit-complete` - should exist
   - etc.

3. Test orders - should now show real product data

---

## Migration Script (Copy-Paste Ready)

**File:** `migrate_sku_products.js`

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function migrateProductsToSKU() {
  try {
    console.log('🔄 Analyzing orders for missing SKU products...\n');

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
            mrp: item.mrp || item.price * 1.5,
            image: item.productImage,
          });
        }
      });
    });

    console.log(`Found ${skuMap.size} unique SKU IDs in orders`);
    console.log('SKUs:', Array.from(skuMap.keys()));
    console.log('\n');

    // Check which ones exist in product_details
    const batch = db.batch();
    let created = 0;
    let skipped = 0;

    for (const [skuId, data] of skuMap) {
      const docRef = db.collection('product_details').doc(skuId);
      const doc = await docRef.get();

      if (!doc.exists) {
        console.log(`✅ Creating: ${skuId}`);
        console.log(`   Name: ${data.name}`);
        console.log(`   Price: ${data.price}\n`);

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
          displayImage: data.image,
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
          rating: { average: 0, count: 0 },
          created_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });
        created++;
      } else {
        console.log(`⏭️ Already exists: ${skuId}\n`);
        skipped++;
      }
    }

    if (created > 0) {
      await batch.commit();
      console.log(`\n✅ Successfully created ${created} product documents`);
    } else {
      console.log(`\n✅ All SKU products already exist (${skipped} skipped)`);
    }

  } catch (error) {
    console.error('❌ Migration failed:', error);
  }

  process.exit(0);
}

migrateProductsToSKU();
```

**Run it:**
```bash
cd "d:\backup rps\rps-stationery-main"
node migrate_sku_products.js
```

---

## After Migration

**Expected:**
- ✅ 7 new product documents created in `product_details`
- ✅ Each has SKU ID as document key
- ✅ Each has price, name, image from order data
- ✅ Orders will immediately show real data

**Verify in Firebase Console:**
1. Go to `product_details`
2. Should see new documents:
   - register-172-pages-hb
   - stapler-domes-standard
   - battery-panasonic-aa-1
   - gift-set-painting-kit-complete
   - pen-ball-balaji-20pack
   - writing-pad-conference-a5

3. Click each one - verify fields are populated

---

## Summary

| Product | Status | Action |
|---------|--------|--------|
| scale-infinity-small-4pt8in | ✅ Has full data | No action needed |
| register-172-pages-hb | ❌ Missing | Run migration |
| stapler-domes-standard | ❌ Missing | Run migration |
| battery-panasonic-aa-1 | ⚠️ Check base | Run migration |
| gift-set-painting-kit-complete | ❌ Missing | Run migration |
| pen-ball-balaji-20pack | ❌ Missing | Run migration |
| writing-pad-conference-a5 | ❌ Missing | Run migration |

**Next Step:** Run the migration script to create missing products in Firestore.

