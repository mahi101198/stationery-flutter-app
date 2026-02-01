# Product Data Mismatch - Verification & Testing Guide

## Quick Fix Applied ✅

**File:** `lib/data/services/product_cache_service.dart` (Line 549)

**What was fixed:**
- Modified `getProductsByIds()` to extract base product ID from SKU IDs
- Added comprehensive logging to track product fetching
- SKU IDs like "NB-BLUE-P1" are now properly converted to "NB" before Firestore lookup

**File:** `lib/services/razorpay_payment_service.dart` (Line 60)

**What was added:**
- Enhanced logging to show SKU IDs being processed
- Detailed comparison of cart items vs. fetched products
- Warning messages when products aren't found

---

## Testing Steps

### Step 1: Verify Firestore Structure (5 min)

Go to Firebase Console → Firestore and check:

**Collection: `product_details`**

Check what document IDs exist:
```
product_details/
  ├─ NB         ← Product ID (expected)
  ├─ PEN        ← Product ID (expected)
  ├─ PAD        ← Product ID (expected)
  └─ (NOT: NB-BLUE-P1)  ← Should NOT be here
```

**If you see SKU IDs as documents:**
```
product_details/
  ├─ NB-BLUE-P1     ← SKU ID (WRONG - indicates data migration issue)
  ├─ NB-RED-P1      ← SKU ID (WRONG)
  └─ PEN-BLACK-P1   ← SKU ID (WRONG)
```

Then you have **two issues:**
1. Cart is storing SKU IDs
2. Products collection has SKU IDs instead of product IDs

---

### Step 2: Check Cart Structure (5 min)

**Path:** `users/{userId}/cart` document in Firestore

Check what's in the items array:
```json
{
  "items": [
    {
      "productId": "NB-BLUE-P1",  ← Is this a SKU or product ID?
      "quantity": 2
    }
  ]
}
```

**Questions to answer:**
- Is `productId` a full SKU like "NB-BLUE-P1"? → Product ID needs extraction
- Is `productId` just a product ID like "NB"? → Should work directly

---

### Step 3: Test Product Fetching (10 min)

**Add this debugging code temporarily:**

**File:** `lib/features/cart/controllers/cart_controller.dart`

```dart
// Add this method to test
Future<void> testProductFetching() async {
  print('🧪 Testing product fetching...');
  
  // Get first cart item
  if (cartItems.isNotEmpty) {
    final cartItem = cartItems.first;
    print('Testing with cart item: ${cartItem.productId}');
    
    // Try to fetch product
    final product = await _productService.getProductById(cartItem.productId);
    
    if (product != null) {
      print('✅ Product found: ${product.name}');
    } else {
      print('❌ Product NOT found');
      
      // Try with base product ID
      final baseId = cartItem.productId.split('-').first;
      print('Trying with base ID: $baseId');
      
      final baseProduct = await _productService.getProductById(baseId);
      if (baseProduct != null) {
        print('✅ Found with base ID: ${baseProduct.name}');
      }
    }
  }
}

// Call it after loading cart
@override
void onInit() {
  super.onInit();
  loadUserCart();
  Future.delayed(Duration(seconds: 2), () => testProductFetching());
}
```

**Expected console output:**

**If fix is working:**
```
🧪 Testing product fetching...
Testing with cart item: NB-BLUE-P1
✅ Product found: Notebook Pack
```

**If fix is NOT working:**
```
🧪 Testing product fetching...
Testing with cart item: NB-BLUE-P1
❌ Product NOT found
Trying with base ID: NB
✅ Found with base ID: Notebook Pack
```
→ **This means the base ID extraction is needed**

---

### Step 4: Create Test Order (15 min)

**Steps:**
1. Add 1-2 products to cart
2. Open cart and verify products show
3. Proceed to checkout
4. Complete payment
5. **WATCH CONSOLE LOGS**

**Expected Console Output:**

```
🔍 Preparing order items with product details...
🔍 Is Buy Now: false
🔍 Cart items count: 2

🔍 Cart product IDs (may include SKUs): [NB-BLUE-P1, PEN-BLACK-P1]

🔍 Fetching product details for IDs...

🔍 Processing ID: NB-BLUE-P1 → Base product ID: NB
✅ Found product: Notebook Pack (ID: NB)

🔍 Processing ID: PEN-BLACK-P1 → Base product ID: PEN
✅ Found product: Ballpoint Pen (ID: PEN)

🔍 ✅ Fetched 2 products from 2 IDs
   Product 0: Notebook Pack (ID: NB)
   Product 1: Ballpoint Pen (ID: PEN)

✅ Found product details for NB-BLUE-P1: Notebook Pack, Image: https://...
✅ Found product details for PEN-BLACK-P1: Ballpoint Pen, Image: https://...

🔍 Prepared 2 order items
```

**If NOT working, you'll see:**
```
🔍 Cart product IDs (may include SKUs): [NB-BLUE-P1, PEN-BLACK-P1]

🔍 Fetching product details for IDs...

🔍 Processing ID: NB-BLUE-P1 → Base product ID: NB
⚠️ Product not found for: NB-BLUE-P1 (base: NB)

🔍 ✅ Fetched 0 products from 2 IDs

⚠️ Product details NOT found for NB-BLUE-P1, using fallback
   Cart item SKU/ID: NB-BLUE-P1
   Available products: []

⚠️ Product details NOT found for PEN-BLACK-P1, using fallback
```

→ **This means products don't exist in Firestore under those IDs**

---

### Step 5: Verify Order in Firestore (10 min)

After completing order, check Firestore:

**Path:** `orders/{orderId}`

**Expected (CORRECT):**
```json
{
  "items": [
    {
      "productId": "NB-BLUE-P1",
      "name": "Notebook Pack",        ← Product name (NOT "Product NB-BLUE-P1")
      "price": 150.0,                 ← Real price (NOT 0)
      "productImage": "https://...",  ← Real image URL (NOT empty)
      "quantity": 2,
      "totalPrice": 300.0
    }
  ],
  "status": "confirmed"
}
```

**Incorrect (BEFORE FIX):**
```json
{
  "items": [
    {
      "productId": "NB-BLUE-P1",
      "name": "Product NB-BLUE-P1",   ← Fallback name
      "price": 0.0,                   ← Fallback price
      "productImage": "",             ← Fallback image
      "quantity": 2,
      "totalPrice": 0.0               ← Wrong calculation
    }
  ],
  "status": "confirmed"
}
```

---

## Troubleshooting

### Issue 1: Still Seeing "Product NB-BLUE-P1" Names

**Diagnosis:**
- The SKU ID extraction isn't working
- Products not found in Firestore under base IDs

**What to check:**
1. Run console output test (Step 4)
2. Check Firebase: Do documents exist with IDs like "NB", "PEN", etc?
3. If NOT, check if collection has different structure

**Solution options:**
- Check if products are actually stored as "product_details" collection
- Or if using different collection like "products" or "product_sku"
- Update the collection name in getProductById() method

---

### Issue 2: "Product details NOT found for..." Warnings

**Diagnosis:**
- Products can't be found even with base ID extraction
- Likely collection or document ID mismatch

**Steps to fix:**

1. **Verify collection name:**
```dart
// In product_cache_service.dart, line 579
final remoteDoc = await _firestore
    .collection('product_details')  // ← Check if this is correct
    .doc(productId)
    .get();
```

2. **Check what collections actually exist:**
```dart
// Add to any service to debug
final collections = await _firestore.collectionGroup('product_details').limit(1).get();
print('Found collections: ${collections.docs.length}');
```

3. **If collection name is different, update:**
```dart
// Change from:
.collection('product_details')

// To (for example):
.collection('products')
```

---

### Issue 3: Empty Cart

**If cart items are empty:**
- Check: `users/{userId}/cart`
- Verify the path and structure matches CartModel

---

## Home Screen Product Fetching Check

### Verify Home Screen Gets Products Correctly

**File:** `lib/features/home/controllers/product_controller.dart`

Check the logs when app starts:

```
🔄 Starting product fetch (attempt 1/3)...
📦 Using ProductCacheService - combined 20 products
✅ Successfully loaded 20 products
```

**If you see:**
```
⚠️ No products returned from repository!
💡 Check if products exist in Firestore product_details collection
```

→ **Products aren't being fetched from Firestore at all**

### Solutions:

1. **Check product_details collection** exists and has documents
2. **Check popularProducts and flashSaleProducts** are properly configured
3. **Check filter query** for popular/flash sale might be wrong

---

## Complete Verification Checklist

### Before Order:
- [ ] Home screen shows products
- [ ] Products have images
- [ ] Products have prices
- [ ] Can add to cart
- [ ] Cart shows products with correct details

### During Order Creation (Console):
- [ ] See "🔍 Cart product IDs: [...]"
- [ ] See "✅ Found product: ..." for each item
- [ ] See "🔍 Prepared X order items"
- [ ] **NO** "⚠️ Product details NOT found" messages

### After Order:
- [ ] Order visible in Firebase
- [ ] Items have correct names (not "Product NB-BLUE-P1")
- [ ] Items have correct prices (not 0)
- [ ] Items have images (not empty)
- [ ] Order Details screen shows all info

---

## Advanced Debugging

If issues persist, add these debug methods:

### Debug: Check Product Structure
```dart
Future<void> debugProductStructure() async {
  print('🔍 Checking product structure...');
  
  // Try to fetch a known product
  final doc = await FirebaseFirestore.instance
      .collection('product_details')
      .doc('NB')
      .get();
  
  if (doc.exists) {
    print('✅ Document NB exists');
    print('   Keys: ${doc.data()!.keys.toList()}');
    print('   Data: ${doc.data()}');
  } else {
    print('❌ Document NB does NOT exist');
    
    // Try to find any document
    final snapshot = await FirebaseFirestore.instance
        .collection('product_details')
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      print('Found document: ${snapshot.docs.first.id}');
      print('Structure: ${snapshot.docs.first.data()}');
    } else {
      print('❌ Collection is EMPTY');
    }
  }
}
```

### Debug: Check Cart Items
```dart
Future<void> debugCartItems() async {
  final cart = await CartWishlistService.instance.getCurrentUserCart();
  print('🔍 Cart debugging:');
  print('   Items count: ${cart?.items.length ?? 0}');
  
  if (cart != null && cart.items.isNotEmpty) {
    for (int i = 0; i < cart.items.length; i++) {
      final item = cart.items[i];
      print('   Item $i:');
      print('      productId: ${item.productId}');
      print('      quantity: ${item.quantity}');
      print('      selectedColor: ${item.selectedColor}');
    }
  }
}
```

---

## Summary

**The Fix:**
- Modified product fetching to extract base product ID from SKU
- Added extensive logging for debugging
- SKU "NB-BLUE-P1" now resolves to product "NB"

**What to verify:**
1. Firestore has products under base IDs (NB, PEN, etc.)
2. Cart stores SKU IDs but products resolve correctly
3. Orders show correct product details (not defaults)

**Key Files Updated:**
- `lib/data/services/product_cache_service.dart` - Product fetching
- `lib/services/razorpay_payment_service.dart` - Order item preparation

