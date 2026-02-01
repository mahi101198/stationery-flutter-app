# ORDER CREATION DATA FLOW ANALYSIS
**Date:** February 1, 2026  
**Status:** Complete Analysis with Recommendations

---

## 📊 EXECUTIVE SUMMARY

The current order creation flow **PARTIALLY captures required data**. While amount breakdown, delivery address, and item details are being saved correctly, **SKU ID and product-specific pricing are NOT being explicitly sent** to the backend for the orders collection.

### ✅ Data Being Saved to Orders Collection
- ✅ Order ID, User ID, Payment ID, Delivery ID
- ✅ Order Status & Payment Status  
- ✅ Items (with productId, name, price, quantity, image)
- ✅ Amount Breakdown (subTotal, discount, deliveryFee, walletUsed, finalAmount)
- ✅ Delivery Address (name, phone, street, city, state, postalCode)
- ✅ Coupon Info
- ✅ Timestamps

### ❌ Data NOT Being Captured
- ❌ **SKU ID** - Only product ID (which is now the SKU ID in the cart)
- ❌ **Selling Price per SKU** - Using generic product price instead
- ❌ **Product-Variant Mapping** - Which variant (color/size) was selected
- ❌ **Actual selling price from SKU** - Not fetching SKU details before order

---

## 🔄 DATA FLOW BREAKDOWN

### 1️⃣ CREATE ORDER FUNCTION (Flutter)
**File:** `lib/services/razorpay_payment_service.dart`

#### What Data is Collected:
```dart
final items = await _prepareOrderItems(cartItems, isBuyNow: isBuyNow, buyNowData: buyNowData);

// Payload sent to Firebase Function:
{
  'items': items,                        // ← Item details
  'amountSummary': {
    'subTotal': subTotal,
    'discount': discount,
    'walletUsed': walletUsed,
    'deliveryFee': deliveryFee,
    'finalPayable': finalPayable,
    'totalOrderAmount': totalAmount,
  },
  'currency': 'INR',
  'paymentMode': paymentMode,
  'deliveryAddress': addressData,
  'couponCode': couponCode,
}
```

#### What Each Item Contains:
```dart
{
  'productId': cartItem.productId,           // ← SKU ID (e.g., "NB-BLUE-P1")
  'quantity': cartItem.quantity,
  'name': product.name,
  'price': product.price,                    // ← Product base price
  'productImage': product.displayImage,
  'discountPrice': product.price,
  'selectedColor': cartItem.selectedColor,   // ← DEPRECATED (for variants)
}
```

**⚠️ ISSUE:** 
- `productId` contains SKU ID but it's not labeled as such
- Price data is basic - doesn't capture SKU-specific pricing
- No separate Product ID for product details reference

---

### 2️⃣ FIREBASE CLOUD FUNCTION (createOrder)
**File:** `functions/razorpay.ts`

#### Data Received:
```typescript
const {
  items,
  amountSummary,
  paymentMode,
  couponCode,
  deliveryAddress,
  paymentDetails,
  currency = 'INR'
} = request.data;
```

#### Data Saved to Firestore Orders Collection:
```typescript
const orderData: any = {
  orderId,
  userId,
  paymentMode,
  paymentId,
  deliveryId,
  status: orderStatus,
  createdAt: now,
  updatedAt: now,

  // ITEMS - What's being saved
  items: items.map((item: any) => ({
    productId: item.productId,              // ← SKU ID
    name: item.name,
    price: item.price,
    quantity: item.quantity,
    subtotal: item.price * item.quantity,
    productImage: item.productImage || null,
    discountPrice: item.discountPrice || item.price,
    totalPrice: (item.discountPrice || item.price) * item.quantity,
    itemMetadata: {
      originalPrice: item.price,
      appliedDiscount: item.discountPrice ? (item.price - item.discountPrice) : 0,
      category: item.category || null,
      brand: item.brand || null
    }
  })),

  // AMOUNTS
  amountBreakdown: {
    subTotal,
    discount: discountAmount,
    deliveryFee,
    walletUsed: walletAmountUsed,
    finalAmount: finalAmount,
    totalOrderAmount: totalOrderAmount,
    // Additional breakdown
    taxAmount: 0,
    serviceCharge: 0,
    totalSavings: discountAmount + walletAmountUsed
  },

  // COUPON
  couponInfo: couponCode ? {
    code: couponCode,
    discountApplied: discountAmount,
    appliedAt: now
  } : null,

  // DELIVERY
  deliveryInfo: {
    address: deliveryAddress,
    estimatedDelivery: null,
    deliveryInstructions: deliveryAddress.instructions || null
  },

  // METADATA
  orderMetadata: {
    source: 'mobile_app',
    userAgent: null,
    ipAddress: null,
    referralCode: null
  }
};
```

**✅ What's Saved:**
- All amount breakdown correctly saved
- Delivery fee captured
- Item details including prices
- Discount and wallet usage

**❌ What's Missing:**
- **Separate Product ID** - No reference to parent product (only SKU ID)
- **SKU-specific attributes** - No variant details (color, size, etc.)
- **Selling price breakdown** - Not capturing if there's MRP vs Selling Price difference

---

### 3️⃣ ORDER DETAILS SCREEN
**File:** `lib/features/order/screens/order_details_screen.dart`

#### What's Being Displayed:
```dart
// Order Info
final orderId = orderData['orderId'];
final paymentId = orderData['paymentId'];
final createdAt = orderData['createdAt'];
final status = orderData['status'];

// Amount Breakdown
final amountBreakdown = orderData['amountBreakdown'];
final subTotal = amountBreakdown['subTotal'];
final discount = amountBreakdown['discount'];
final deliveryFee = amountBreakdown['deliveryFee'];
final walletUsed = amountBreakdown['walletUsed'];
final finalAmount = amountBreakdown['finalAmount'];
final totalSavings = amountBreakdown['totalSavings'];

// Items
final items = orderData['items'];  // Contains productId, name, price, quantity, image

// Coupon Info
final couponInfo = orderData['couponInfo'];

// Delivery Address
final deliveryInfo = orderData['deliveryInfo'];
```

**✅ Can Display:**
- All pricing breakdown (subTotal, discount, delivery fee, wallet used, final amount)
- Item details with images
- Delivery address
- Coupon used

**❌ Cannot Display (Data Not Available):**
- Product details link (no separate product ID)
- SKU variant attributes (color, size)
- Original product price vs selling price
- Inventory reference

---

## 🎯 DATA MAPPING COMPARISON

### Current Implementation:
```
Cart Item (SKU ID)
    ↓
ProductId in Order = SKU ID
    ↓
Order Details Shows Generic Product Info
    ↓
Cannot Link Back to Product Details
```

### Recommended Implementation:
```
Cart Item (SKU ID)
    ↓
├─ productId: Actual Product ID
├─ skuId: SKU ID
├─ variantAttributes: {color: 'Blue', size: 'A4', ...}
├─ sellingPrice: SKU-specific price
└─ originalPrice: Product base price
    ↓
Firebase Function Receives Complete Data
    ↓
Orders Collection Has Full Product + SKU + Pricing Info
    ↓
Order Details Can Link to Product + Show All Details
```

---

## 📋 DETAILED DATA REQUIREMENTS CHECKLIST

### What ORDER DETAILS SCREEN Needs:
- [x] Order ID
- [x] Payment ID
- [x] Delivery ID
- [x] Order Status
- [x] Payment Status
- [x] Created Date
- [x] Item Names
- [x] Item Images
- [x] Item Quantities
- [x] Item Prices
- [x] SubTotal
- [x] Discount Amount
- [x] Delivery Fee
- [x] Wallet Used
- [x] Final Amount
- [x] Coupon Code
- [x] Delivery Address
- [ ] **Product ID** (to link to product details)
- [ ] **SKU ID** (to fetch SKU details)
- [ ] **Variant Attributes** (color, size, etc.)
- [ ] **Selling Price per SKU** (if different from displayed)

---

## 🔧 REQUIRED CHANGES

### Change 1: Enhance Item Data in `_prepareOrderItems()`
**File:** `lib/services/razorpay_payment_service.dart`

Currently sends:
```dart
{
  'productId': cartItem.productId,  // This is SKU ID
  'quantity': cartItem.quantity,
  'name': product.name,
  'price': product.price,
  'productImage': product.displayImage,
  'discountPrice': product.price,
}
```

Should send:
```dart
{
  'productId': product.productId,           // ← Actual Product ID
  'skuId': cartItem.productId,              // ← SKU ID
  'quantity': cartItem.quantity,
  'name': product.name,
  'price': product.price,                   // Base price
  'sellingPrice': sku.sellingPrice,         // SKU selling price
  'productImage': product.displayImage,
  'discountPrice': product.price,
  'variantAttributes': {                    // ← Variant details
    'color': cartItem.selectedColor,
    // Add other variants from SKU
  },
}
```

### Change 2: Update Cloud Function to Save SKU Data
**File:** `functions/razorpay.ts`

Update items mapping to include:
```typescript
items: items.map((item: any) => ({
  productId: item.productId,        // Product ID
  skuId: item.skuId,                // SKU ID
  name: item.name,
  price: item.price,
  sellingPrice: item.sellingPrice,  // ← Add this
  quantity: item.quantity,
  subtotal: item.price * item.quantity,
  productImage: item.productImage || null,
  discountPrice: item.discountPrice || item.price,
  totalPrice: (item.discountPrice || item.price) * item.quantity,
  variantAttributes: item.variantAttributes || null,  // ← Add this
  itemMetadata: {
    originalPrice: item.price,
    sellingPrice: item.sellingPrice,  // ← Add this
    appliedDiscount: item.discountPrice ? (item.price - item.discountPrice) : 0,
    category: item.category || null,
    brand: item.brand || null
  }
})),
```

### Change 3: Update Order Details Screen to Display New Data
**File:** `lib/features/order/screens/order_details_screen.dart`

Add logic to:
- Display SKU variant attributes (if available)
- Show selling price vs original price difference
- Link to product details using productId (in addition to skuId)

---

## 📊 SUMMARY TABLE

| Data | Current | Sent | Saved | Displayed |
|------|---------|------|-------|-----------|
| Order ID | ✅ | ✅ | ✅ | ✅ |
| Product ID | ❌ | ❌ | ❌ | ❌ |
| SKU ID | ✅ (as productId) | ✅ (mixed) | ✅ | ✅ |
| Item Quantity | ✅ | ✅ | ✅ | ✅ |
| Item Price | ✅ | ✅ | ✅ | ✅ |
| Selling Price | ❌ | ❌ | ❌ | ❌ |
| SubTotal | ✅ | ✅ | ✅ | ✅ |
| Discount | ✅ | ✅ | ✅ | ✅ |
| Delivery Fee | ✅ | ✅ | ✅ | ✅ |
| Wallet Used | ✅ | ✅ | ✅ | ✅ |
| Final Amount | ✅ | ✅ | ✅ | ✅ |
| Variant Details | ❌ | ❌ | ❌ | ❌ |
| Delivery Address | ✅ | ✅ | ✅ | ✅ |
| Coupon Code | ✅ | ✅ | ✅ | ✅ |

---

## 🚀 IMPLEMENTATION PRIORITY

**HIGH PRIORITY:**
1. Separate Product ID from SKU ID in items
2. Capture selling price per SKU
3. Store variant attributes in orders

**MEDIUM PRIORITY:**
4. Display variant attributes in order details
5. Add link to product details screen from order

**LOW PRIORITY:**
6. Store MRP vs selling price difference
7. Add price history tracking

---

## ✅ VERIFICATION STEPS

After implementation:

1. **Create test order** with multiple items and variants
2. **Check Firestore orders collection:**
   - Verify each item has `productId` and `skuId`
   - Verify `sellingPrice` is saved
   - Verify `variantAttributes` contains color/size
3. **Check order details screen:**
   - All pricing breakdown displays correctly
   - Variant details show (if applicable)
   - Product link works (if added)
4. **Check different payment modes:**
   - Razorpay: All data saved
   - COD: All data saved
   - Wallet: All data saved
   - Partial Wallet: All data saved

---

**Next Steps:** Implement the recommended changes to ensure complete order data capture.
