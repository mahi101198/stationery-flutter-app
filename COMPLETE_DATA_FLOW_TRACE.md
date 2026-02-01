# 🚀 Complete Data Flow Trace: Cart → Order Creation → Firebase

## 📊 Visual Flow Diagram

```
┌─────────────────────┐
│   USER CART         │
│  (CartItem[])       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│ STEP 1: PAYMENT CONTROLLER              │
│ (payment_controller.dart)               │
│ - Determines payment method             │
│ - Routes to appropriate payment handler │
└──────────┬──────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│ STEP 2: RAZORPAY SERVICE                │
│ (razorpay_payment_service.dart)         │
│ - Prepares items with product details   │
│ - Calculates pricing                    │
│ - Constructs delivery address           │
│ - Builds Firebase payload               │
└──────────┬──────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│ STEP 3: FIREBASE FUNCTION CALL          │
│ httpsCallable('createOrder')            │
│ Sends:                                  │
│ - items[]                               │
│ - pricingSummary{}                      │
│ - paymentSummary{}                      │
│ - deliveryAddress{}                     │
│ - paymentMode                           │
│ - currency                              │
└──────────┬──────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│ STEP 4: FIREBASE VALIDATION             │
│ (functions/razorpay.ts)                 │
│ - Validates all required fields         │
│ - Checks pricing formulas               │
│ - Verifies payment mode consistency     │
│ - Validates amounts                     │
└──────────┬──────────────────────────────┘
           │
    ┌──────┴──────┐
    │             │
    ▼             ▼
  ✅ SUCCESS    ❌ ERROR
    │             │
    ▼             ▼
CREATE ORDER   THROW ERROR
    │             │
    ▼             ▼
RESPONSE      RESPONSE
{orderId,     {error:
paymentId}    "message"}
```

---

## 🔍 DETAILED STEP-BY-STEP DATA TRANSFORMATION

### CART ITEMS (Input)
```dart
// lib/data/models/cart_model.dart
CartItem {
  productId: "1zaaOVRcw81Yd1XhKmhb",
  quantity: 2,
  selectedColor: "Red",           // Optional
}
```

---

### STEP 1: Item Preparation (Lines 62-215)
**File:** `lib/services/razorpay_payment_service.dart`
**Function:** `_prepareOrderItems()`

```dart
// INPUT: List<CartItem> cartItems

// FETCH: Get full ProductModel from cache
final products = await _productService.getProductsByIds(cartProductIds);

// TRANSFORM: For each CartItem, get matching ProductModel
final orderItems = cartItems.map((cartItem) {
  final product = products.firstWhereOrNull((p) => p.productId == cartItem.productId);
  
  // Extract prices
  final productBasePrice = product.price;           // MRP
  final productCurrentPrice = product.price;        // Current selling price
  
  // Calculate discounts
  final itemSubtotalAtMRP = productBasePrice * cartItem.quantity;
  final itemSubtotalAtSellingPrice = productCurrentPrice * cartItem.quantity;
  final itemAutoDiscount = itemSubtotalAtMRP - itemSubtotalAtSellingPrice;
  
  return {
    'productId': product.productId,
    'skuId': cartItem.productId,
    'quantity': cartItem.quantity,
    'name': product.name,
    'category': product.category,
    'brand': product.brand,
    'productBasePrice': productBasePrice,
    'productCurrentPrice': productCurrentPrice,
    'itemSubtotalAtMRP': itemSubtotalAtMRP,
    'itemSubtotalAtSellingPrice': itemSubtotalAtSellingPrice,
    'itemAutoDiscount': itemAutoDiscount,
    'productImage': product.displayImage,
    'selectedColor': cartItem.selectedColor,       // If exists
    'variants': {...}
  };
}).toList();

// OUTPUT: List<Map<String, dynamic>> with full product & pricing details
```

**Output Example:**
```json
[
  {
    "productId": "1zaaOVRcw81Yd1XhKmhb",
    "skuId": "1zaaOVRcw81Yd1XhKmhb",
    "quantity": 2,
    "name": "Premium Pen",
    "category": "Writing",
    "brand": "RPS",
    "productBasePrice": 150.0,
    "productCurrentPrice": 146.0,
    "itemSubtotalAtMRP": 300.0,
    "itemSubtotalAtSellingPrice": 292.0,
    "itemAutoDiscount": 8.0,
    "productImage": "https://...",
    "selectedColor": "Red",
    "variants": { "color": "Red" }
  },
  {
    "productId": "xyz789",
    "skuId": "xyz789",
    "quantity": 1,
    "name": "Notebook A4",
    "category": "Stationery",
    "brand": "RPS",
    "productBasePrice": 60.0,
    "productCurrentPrice": 50.0,
    "itemSubtotalAtMRP": 60.0,
    "itemSubtotalAtSellingPrice": 50.0,
    "itemAutoDiscount": 10.0,
    "productImage": "https://...",
    "variants": {}
  }
]
```

---

### STEP 2: Pricing Calculation (Lines 237-280)
**File:** `lib/services/razorpay_payment_service.dart`
**Function:** `initiatePaymentWithMode()`

```dart
// INPUT: items[], prices from UI

// CALCULATE: Sum all MRP-based amounts
final double orderSubtotal = items.fold<double>(0, (sum, item) => 
  sum + (item['itemSubtotalAtMRP'] as double? ?? 0));
  // = 300.0 + 60.0 = 360.0

final double productDiscount = items.fold<double>(0, (sum, item) =>
  sum + (item['itemAutoDiscount'] as double? ?? 0));
  // = 8.0 + 10.0 = 18.0

final double totalDiscount = productDiscount + discount;  // coupon discount
  // = 18.0 + 0.0 = 18.0

final double subtotalAfterDiscount = orderSubtotal - totalDiscount;
  // = 360.0 - 18.0 = 342.0

// OUTPUT: pricingSummary
final pricingSummary = {
  'orderSubtotal': 360.0,
  'productDiscount': 18.0,
  'couponCode': null,
  'couponDiscount': 0.0,
  'totalDiscount': 18.0,
  'subtotalAfterDiscount': 342.0,
  'deliveryFee': 40.0,
  'totalBeforePayment': 382.0,  // 342.0 + 40.0
};

// PAYMENT SUMMARY (based on payment mode)
final double onlinePaidAmount = (subtotalAfterDiscount + deliveryFee) - walletUsed;
  // = 382.0 - 0.0 = 382.0

final double totalOrderValue = subtotalAfterDiscount + deliveryFee;
  // = 382.0

final paymentSummary = {
  'paymentMode': 'razorpay',
  'walletPaidAmount': 0.0,
  'onlinePaidAmount': 382.0,
  'totalOrderValue': 382.0,
};
```

**Output Example:**
```json
{
  "pricingSummary": {
    "orderSubtotal": 360.0,
    "productDiscount": 18.0,
    "couponCode": null,
    "couponDiscount": 0.0,
    "totalDiscount": 18.0,
    "subtotalAfterDiscount": 342.0,
    "deliveryFee": 40.0,
    "totalBeforePayment": 382.0
  },
  "paymentSummary": {
    "paymentMode": "razorpay",
    "walletPaidAmount": 0.0,
    "onlinePaidAmount": 382.0,
    "totalOrderValue": 382.0
  }
}
```

---

### STEP 3: Delivery Address (Lines 240-248)
**File:** `lib/services/razorpay_payment_service.dart`

```dart
// INPUT: UserAddress deliveryAddress

final addressData = {
  'id': deliveryAddress.id,                          // "addr_123"
  'name': deliveryAddress.name,                      // "John Doe"
  'phoneNumber': deliveryAddress.phoneNumber ?? 
                 deliveryAddress.mobileNumber ?? '', // "+919876543210"
  'street': '${deliveryAddress.line1}${
    deliveryAddress.line2.isNotEmpty ? ', ${deliveryAddress.line2}' : ''}',
    // "123 Main Street, Apartment 4B"
  'city': deliveryAddress.city,                      // "Jaipur"
  'state': deliveryAddress.state,                    // "Rajasthan"
  'postalCode': deliveryAddress.pincode,             // "302001"
  'country': deliveryAddress.country,                // "India"
};

// OUTPUT: addressData{}
```

**Output Example:**
```json
{
  "id": "addr_123",
  "name": "John Doe",
  "phoneNumber": "+919876543210",
  "street": "123 Main Street, Apartment 4B",
  "city": "Jaipur",
  "state": "Rajasthan",
  "postalCode": "302001",
  "country": "India"
}
```

---

### STEP 4: Firebase Function Call (Lines 301-307)
**File:** `lib/services/razorpay_payment_service.dart`

```dart
final callable = _functions.httpsCallable('createOrder');
final result = await callable.call({
  'items': items,                    // items[]
  'pricingSummary': pricingSummary, // pricing breakdown
  'paymentSummary': paymentSummary, // payment breakdown
  'currency': 'INR',                // hardcoded
  'paymentMode': paymentMode,       // 'razorpay', 'cod', 'wallet', 'partial_wallet'
  'deliveryAddress': addressData,   // address object
});
```

**Payload Sent to Firebase:**
```json
{
  "items": [
    {
      "productId": "1zaaOVRcw81Yd1XhKmhb",
      "skuId": "1zaaOVRcw81Yd1XhKmhb",
      "quantity": 2,
      "name": "Premium Pen",
      "category": "Writing",
      "brand": "RPS",
      "productBasePrice": 150.0,
      "productCurrentPrice": 146.0,
      "itemSubtotalAtMRP": 300.0,
      "itemSubtotalAtSellingPrice": 292.0,
      "itemAutoDiscount": 8.0,
      "productImage": "https://...",
      "selectedColor": "Red",
      "variants": { "color": "Red" }
    },
    {
      "productId": "xyz789",
      "skuId": "xyz789",
      "quantity": 1,
      "name": "Notebook A4",
      "category": "Stationery",
      "brand": "RPS",
      "productBasePrice": 60.0,
      "productCurrentPrice": 50.0,
      "itemSubtotalAtMRP": 60.0,
      "itemSubtotalAtSellingPrice": 50.0,
      "itemAutoDiscount": 10.0,
      "productImage": "https://...",
      "variants": {}
    }
  ],
  "pricingSummary": {
    "orderSubtotal": 360.0,
    "productDiscount": 18.0,
    "couponCode": null,
    "couponDiscount": 0.0,
    "totalDiscount": 18.0,
    "subtotalAfterDiscount": 342.0,
    "deliveryFee": 40.0,
    "totalBeforePayment": 382.0
  },
  "paymentSummary": {
    "paymentMode": "razorpay",
    "walletPaidAmount": 0.0,
    "onlinePaidAmount": 382.0,
    "totalOrderValue": 382.0
  },
  "currency": "INR",
  "paymentMode": "razorpay",
  "deliveryAddress": {
    "id": "addr_123",
    "name": "John Doe",
    "phoneNumber": "+919876543210",
    "street": "123 Main Street, Apartment 4B",
    "city": "Jaipur",
    "state": "Rajasthan",
    "postalCode": "302001",
    "country": "India"
  }
}
```

---

### STEP 5: Firebase Validation & Processing (Lines 57-350)
**File:** `functions/razorpay.ts`

```typescript
// INPUT: Received payload from Flutter

// EXTRACT: Destructure into variables
const { items, pricingSummary, paymentSummary, paymentMode, deliveryAddress, currency = 'INR' } = request.data;

// VALIDATE: Check all required fields exist and have correct values
// 1. Items validation
if (!items || !Array.isArray(items) || items.length === 0) {
  throw new Error('Items array is required');
}

// 2. Address validation
if (!deliveryAddress.name || !deliveryAddress.phoneNumber || ...) {
  throw new Error('Delivery address must include: name, phoneNumber, street, city, state, postalCode, country');
}

// 3. Pricing formula validation
const expectedSubtotalAfterDiscount = orderSubtotal - totalDiscount;
if (Math.abs(subtotalAfterDiscount - expectedSubtotalAfterDiscount) > 0.01) {
  throw new Error(`subtotalAfterDiscount calculation error: expected ${expectedSubtotalAfterDiscount}, got ${subtotalAfterDiscount}`);
}

const expectedTotalBeforePayment = subtotalAfterDiscount + deliveryFee;
if (Math.abs(totalBeforePayment - expectedTotalBeforePayment) > 0.01) {
  throw new Error(`totalBeforePayment calculation error: expected ${expectedTotalBeforePayment}, got ${totalBeforePayment}`);
}

// 4. Payment mode validation
if (paymentMode === 'razorpay' && walletPaidAmount !== 0) {
  throw new Error('Wallet amount must be 0 for razorpay payment');
}

// PROCESS: If all validations pass, create order documents
const orderId = `ORD${Date.now()}${Math.floor(Math.random() * 1000)}`;
const paymentId = `PAY${Date.now()}${Math.floor(Math.random() * 1000)}`;
const deliveryId = `DEL${Date.now()}${Math.floor(Math.random() * 1000)}`;

// Handle payment based on mode
if (paymentMode === 'razorpay') {
  razorpayOrderId = await handleRazorpayPayment(orderId, userId, paymentId, finalAmount, currency);
}

// Create Firestore documents in transaction
// - razorpay_orders
// - payments
// - orders
// - deliveries

// OUTPUT: Return response with orderId, paymentId, etc.
```

**Response on Success:**
```json
{
  "success": true,
  "orderId": "ORD1735432156789",
  "paymentId": "PAY1735432156234",
  "deliveryId": "DEL1735432156456",
  "paymentMode": "razorpay",
  "currency": "INR",
  "paymentInfo": {
    "gateway": "razorpay",
    "status": "created",
    "razorpayOrderId": "order_QxYZ1234567890"
  },
  "amountBreakdown": {
    "subTotal": 360.0,
    "discount": 18.0,
    "deliveryFee": 40.0,
    "walletUsed": 0.0,
    "finalAmount": 382.0,
    "totalSavings": 18.0
  }
}
```

**Response on Error:**
```json
{
  "success": false,
  "error": "Items array is required"
}
```

---

## 🎯 Key Data Transformation Points

| Step | File | Function | Input | Output | Risk |
|------|------|----------|-------|--------|------|
| 1 | razorpay_payment_service.dart | _prepareOrderItems() | CartItem[] | items[] with productDetails | ❌ Product fetch fails |
| 2 | razorpay_payment_service.dart | initiatePaymentWithMode() | items[], prices | pricingSummary, paymentSummary | ❌ Math error |
| 3 | razorpay_payment_service.dart | initiatePaymentWithMode() | UserAddress | addressData | ❌ Missing fields |
| 4 | razorpay_payment_service.dart | httpsCallable() | All above | Firebase payload | ❌ Type mismatch |
| 5 | razorpay.ts | createOrder() | Firebase payload | Firestore docs | ❌ Validation fails |

---

## ✅ Validation Checklist

Before Firebase receives payload, Flutter should verify:

```
ITEMS:
  ✅ items.length > 0
  ✅ Each item has: productId, skuId, quantity, name
  ✅ Each item has: productBasePrice > 0, productCurrentPrice > 0
  ✅ itemSubtotalAtMRP = productBasePrice × quantity
  ✅ itemAutoDiscount = itemSubtotalAtMRP - itemSubtotalAtSellingPrice

PRICING:
  ✅ orderSubtotal > 0
  ✅ totalDiscount ≥ 0
  ✅ deliveryFee ≥ 0
  ✅ subtotalAfterDiscount = orderSubtotal - totalDiscount
  ✅ totalBeforePayment = subtotalAfterDiscount + deliveryFee
  ✅ totalOrderValue = totalBeforePayment

ADDRESS:
  ✅ name, phoneNumber, street, city, state, postalCode, country all exist
  ✅ No fields are null or empty string

PAYMENT MODE:
  ✅ paymentMode is one of: razorpay, cod, wallet, partial_wallet
  ✅ walletPaidAmount + onlinePaidAmount = totalOrderValue
  ✅ For razorpay: walletPaidAmount = 0
  ✅ For wallet: onlinePaidAmount = 0, walletPaidAmount > 0
  ✅ For partial_wallet: both > 0
  ✅ For cod: walletPaidAmount = 0
```

---

## 🐛 Troubleshooting by Error

| Error Message | Root Cause | Debug Location | Solution |
|---------------|-----------|-----------------|----------|
| Items array is required | Empty items | Step 1 | Check product fetch |
| Order subtotal must be greater than 0 | All prices 0 | Step 1 | Product fetch failed |
| subtotalAfterDiscount calculation error | Math wrong | Step 2 | Check pricing formula |
| Delivery address must include... | Missing field | Step 3 | Fill all address fields |
| Wallet amount must be 0 for razorpay | Mode mismatch | Step 2 | Don't use wallet for razorpay |
| totalOrderValue does not match... | Amount mismatch | Step 2 | Check math formula |

---

## 📝 File References

**Flutter Side (Client):**
- [lib/services/razorpay_payment_service.dart](lib/services/razorpay_payment_service.dart) - Lines 62-307: Main order creation logic
- [lib/features/checkout/controllers/payment_controller.dart](lib/features/checkout/controllers/payment_controller.dart) - Routes payment
- [lib/data/models/cart_model.dart](lib/data/models/cart_model.dart) - CartItem structure

**Firebase Side (Backend):**
- [functions/razorpay.ts](functions/razorpay.ts) - Lines 57-350: Validation and order creation

**Documentation:**
- [DATA_FLOW_ANALYSIS_ROOT_CAUSE.md](DATA_FLOW_ANALYSIS_ROOT_CAUSE.md) - Detailed validation rules
- [FLUTTER_ORDER_DEBUG_GUIDE.md](FLUTTER_ORDER_DEBUG_GUIDE.md) - Console output debugging

---

## 🚀 Next Steps

1. **Get exact error message** from Firebase Console or Flutter logs
2. **Check relevant debugging guide** above for that error
3. **Verify at each step** that data is correct
4. **Share full console output** for deeper analysis if needed

Share the exact error and we can pinpoint the exact line to fix! 🎯
