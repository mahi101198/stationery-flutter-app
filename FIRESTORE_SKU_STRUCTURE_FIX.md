# CRITICAL: Firestore Product Structure Fix

## Root Cause Found! 🎯

Your system is **storing SKU IDs in orders and cart**, but **Firestore doesn't have documents with those SKU IDs**.

### Evidence from Logs:

```
productId: scale-infinity-small-4pt8in  ← SKU ID stored in order
name: Product scale-infinity-small-4pt8in  ← FALLBACK (product not found)
price: 0  ← FALLBACK
productImage: null  ← FALLBACK
```

The fallback is being used because the product lookup is failing.

---

## The Real Problem

### Current State (BROKEN):

```
Firestore Structure:
product_details/
  ├─ NB              ← Old product format
  ├─ PEN
  └─ PAD

Order Data:
{
  items: [
    { productId: "scale-infinity-small-4pt8in" }  ← SKU ID
  ]
}

Product Lookup:
Try: db.collection('product_details').doc('scale-infinity-small-4pt8in').get()
Result: ❌ Document NOT found
Uses: Fallback → "Product scale-infinity-small-4pt8in"
```

### Solution:

**Firestore needs to have documents with SKU IDs as keys:**

```
Firestore Structure (CORRECT):
product_details/
  ├─ scale-infinity-small-4pt8in
  │  ├─ name: "Scale Infinity Small 4PT8IN"
  │  ├─ price: 199
  │  ├─ displayImage: "https://..."
  │  └─ ... other fields
  │
  ├─ gift-set-painting-kit-complete
  │  ├─ name: "Gift Set Painting Kit Complete"
  │  ├─ price: 599
  │  ├─ displayImage: "https://..."
  │  └─ ... other fields
  │
  ├─ pen-ball-balaji-20pack
  └─ writing-pad-conference-a5
```

---

## What Needs to Change in Firestore

### Step 1: Identify SKU IDs from Orders

Run this query in Firebase Console to see all SKU IDs being used:

```javascript
// In Firebase Console > Firestore > Run Query
db.collection('orders').get()
  .then(snapshot => {
    const skuIds = new Set();
    snapshot.forEach(doc => {
      const items = doc.data().items || [];
      items.forEach(item => {
        skuIds.add(item.productId);
      });
    });
    console.log('SKU IDs found in orders:', Array.from(skuIds));
  });
```

This will show you:
- scale-infinity-small-4pt8in
- gift-set-painting-kit-complete
- pen-ball-balaji-20pack
- writing-pad-conference-a5
- ... and all others

### Step 2: Get Product Details

For each SKU ID, you need to find the product details. Check:

1. **Do documents exist with these SKU IDs?**
   - Open Firebase Console
   - Go to `product_details` collection
   - Search for document "scale-infinity-small-4pt8in"
   - If NOT found → **This is the problem!**

2. **Where are the product details?**
   - Maybe in a different collection like `products_sku` or `skus`?
   - Or maybe they're stored as subcollections?

### Step 3: Create Missing Documents

If products with SKU IDs don't exist, you need to create them:

#### Option A: Using Firebase Console (Manual)

1. Go to Firebase Console > Firestore > product_details
2. Click "Add document"
3. Set document ID to the SKU (e.g., "scale-infinity-small-4pt8in")
4. Add fields:
   ```
   {
     "name": "Scale Infinity Small 4PT8IN",
     "price": 199,
     "displayImage": "https://...",
     "product_id": "scale-infinity-small",
     "sku_id": "scale-infinity-small-4pt8in",
     "category": "Scales",
     "description": "...",
     ... other fields
   }
   ```

#### Option B: Using Script (Recommended)

Create a migration script to update Firestore:

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
            image: item.productImage,
          });
        }
      });
    });

    console.log(`Found ${skuMap.size} unique SKU IDs in orders`);
    console.log('SKUs:', Array.from(skuMap.keys()));

    // Check which ones exist in product_details
    const batch = db.batch();
    let created = 0;

    for (const [skuId, data] of skuMap) {
      const docRef = db.collection('product_details').doc(skuId);
      const doc = await docRef.get();

      if (!doc.exists) {
        console.log(`Creating missing SKU document: ${skuId}`);
        batch.set(docRef, {
          sku_id: skuId,
          name: data.name,
          price: data.price,
          displayImage: data.image,
          description: `${data.name} - SKU: ${skuId}`,
          product_id: skuId.split('-')[0],
          category: 'Uncategorized',
          brand: 'RPS Stationery',
          inStock: true,
          ratings: 0,
          reviews: 0,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        created++;
      }
    }

    if (created > 0) {
      await batch.commit();
      console.log(`✅ Created ${created} product documents for SKU IDs`);
    } else {
      console.log('✅ All SKU products already exist');
    }

  } catch (error) {
    console.error('❌ Migration failed:', error);
  }
}

migrateProductsToSKU();
```

Run it:
```bash
node migrate_sku_products.js
```

---

## Expected Firestore Structure After Fix

```
product_details/
{
  "scale-infinity-small-4pt8in": {
    "sku_id": "scale-infinity-small-4pt8in",
    "name": "Scale Infinity Small 4PT8IN",
    "price": 199,
    "displayImage": "https://firebasecdn.../scale-infinity.jpg",
    "product_id": "scale-infinity-small",
    "category": "Scales & Measurement",
    "description": "High precision scale for measurements",
    "inStock": true,
    "ratings": 4.5,
    "reviews": 12,
    "createdAt": "2026-02-01T...",
    "updatedAt": "2026-02-01T..."
  },
  
  "gift-set-painting-kit-complete": {
    "sku_id": "gift-set-painting-kit-complete",
    "name": "Gift Set Painting Kit Complete",
    "price": 599,
    "displayImage": "https://firebasecdn.../painting-kit.jpg",
    "product_id": "gift-set-painting-kit",
    ... other fields
  },
  
  "pen-ball-balaji-20pack": {
    "sku_id": "pen-ball-balaji-20pack",
    "name": "Pen Ball Balaji 20 Pack",
    "price": 249,
    "displayImage": "https://firebasecdn.../balaji-pens.jpg",
    "product_id": "pen-ball-balaji",
    ... other fields
  },
  
  "writing-pad-conference-a5": {
    "sku_id": "writing-pad-conference-a5",
    "name": "Writing Pad Conference A5",
    "price": 89,
    "displayImage": "https://firebasecdn.../conference-pad.jpg",
    "product_id": "writing-pad-conference",
    ... other fields
  }
}
```

---

## What Changes in Code

**GOOD NEWS:** The code is already set up to use SKU IDs!

No code changes needed. Just need to:

1. ✅ Ensure products exist in Firestore with SKU IDs as document keys
2. ✅ Ensure each document has `name`, `price`, `displayImage` fields
3. ✅ Verify the `displayImage` URLs are valid and accessible

---

## Verification Steps

### Step 1: Check What Products Exist

Go to Firebase Console → Firestore → product_details

Search for document ID: "scale-infinity-small-4pt8in"

**If found:**
- Click it
- Verify fields: `name`, `price`, `displayImage`
- Check if `displayImage` is a valid URL

**If NOT found:**
- This is the problem!
- Need to create the document using migration script

### Step 2: Test Product Fetching

After creating/fixing products in Firestore, test again:

1. Refresh app
2. Place order
3. Check console logs:
   ```
   ✅ Found: Scale Infinity Small 4PT8IN (ID: scale-infinity-small-4pt8in)
   ```

4. Check order details screen:
   - Should show product name
   - Should show image
   - Should show price

### Step 3: Verify Order Details

Open order in Firebase Console:

**Before Fix (WRONG):**
```json
{
  "items": [
    {
      "name": "Product scale-infinity-small-4pt8in",
      "price": 0,
      "productImage": null
    }
  ]
}
```

**After Fix (CORRECT):**
```json
{
  "items": [
    {
      "name": "Scale Infinity Small 4PT8IN",
      "price": 199,
      "productImage": "https://..."
    }
  ]
}
```

---

## Quick Checklist

- [ ] Check Firebase: Do product_details documents exist with SKU IDs?
- [ ] Check each document has: `name`, `price`, `displayImage`
- [ ] Check `displayImage` URLs are valid (not null, not empty)
- [ ] Run migration script to create missing documents
- [ ] Test product lookup: Open Firebase logs and search for SKU
- [ ] Place test order and verify products show correctly
- [ ] Check order details screen: images, names, prices all visible

---

## Android Back Button Warning

The warning in logs:
```
W/OnBackInvokedCallback( 5694): Set 'android:enableOnBackInvokedCallback="true"' in the application manifest.
```

This is separate from the product issue. To fix it, open:

**File:** `android/app/src/main/AndroidManifest.xml`

Add to `<application>` tag:
```xml
<application
    android:enableOnBackInvokedCallback="true"
    ...>
```

---

## Summary

**The Problem:** SKU IDs are stored in orders, but Firestore doesn't have documents with those SKU IDs

**The Solution:** Create/migrate product documents with SKU IDs as document keys in `product_details` collection

**Impact:** Once fixed, order details will show:
- ✅ Product images
- ✅ Product names
- ✅ Product prices
- ✅ All order items correctly

