# Order Data Capture - Implementation Complete ✅

## Summary of Changes

This document summarizes the complete implementation of comprehensive order data capture with proper field naming and calculation.

---

## Phase 1: Flutter App (`lib/services/razorpay_payment_service.dart`) ✅ COMPLETE

### Modified Functions

#### 1. `_prepareOrderItems()` - Enhanced Data Capture
**Lines Changed:** 61-190

**What It Does:**
- Captures complete product information for each item
- Extracts both product base price (MRP) and current selling price
- Calculates item-level subtotals and discounts
- Includes SKU ID separate from product ID
- Structures variant information properly
- Adds category and brand metadata

**Data Captured:**
```dart
{
  'productId': '...',                    // Product identifier
  'skuId': '...',                        // SKU identifier (separate)
  'productBasePrice': 100,               // MRP
  'productCurrentPrice': 90,             // Selling price
  'itemSubtotal': 180,                   // price × quantity
  'itemDiscount': 20,                    // discount calculation
  'variants': {'color': '...'},          // Structured variants
  'category': '...',
  'brand': '...'
}
```

---

#### 2. `initiatePaymentWithMode()` - Pricing & Payment Summary
**Lines Changed:** 190-310

**Pricing Summary (8 Fields):**
```dart
'pricingSummary': {
  'orderSubtotal': 330,                  // Sum of all item subtotals
  'productDiscount': 0,                  // Auto discount from prices
  'couponCode': 'SAVE50',                // Coupon applied
  'couponDiscount': 50,                  // Coupon discount amount
  'totalDiscount': 50,                   // All discounts combined
  'subtotalAfterDiscount': 280,          // After discount amount
  'deliveryFee': 80,                     // Shipping cost
  'totalBeforePayment': 360              // Final amount
}
```

**Payment Summary (4 Fields):**
```dart
'paymentSummary': {
  'paymentMode': 'partial_wallet',       // Payment method
  'walletPaidAmount': 100,               // From wallet
  'onlinePaidAmount': 260,               // Via Razorpay/COD
  'totalOrderValue': 360                 // Grand total
}
```

**Payload Sent to Firebase:**
```dart
{
  'items': items,                        // 10+ fields per item
  'pricingSummary': {...},               // 8 pricing fields
  'paymentSummary': {...},               // 4 payment fields
  'paymentMode': paymentMode,
  'deliveryAddress': addressData,
  'currency': 'INR'
}
```

---

## Phase 2: Firebase Cloud Function (`functions/razorpay.ts`) ✅ COMPLETE

### Updated Function: `createOrder`

#### Request Handler Changes
**Changed Lines:** 49-112
- Updated to accept `pricingSummary` and `paymentSummary`
- Removed old `amountSummary` structure
- Extracts properly named fields from new summaries

#### Validation Logic Changes
**Changed Lines:** 112-200
- Validates pricing structure
- Validates payment structure
- Validates payment mode consistency
- Checks wallet/online split for partial payments
- Clear error messages for each validation

#### Database Document Creation

##### 1. razorpay_orders Document
**Changed Lines:** 278-300
- Uses `onlinePaidAmount` for razorpay amount
- Stores wallet amount for partial wallet payments
- Stores total order value

##### 2. payments Document
**Changed Lines:** 320-366
- Stores `pricingSummary` with all 8 fields
- Stores `paymentSummary` with all 4 fields
- Includes payment details and coupon info
- Tracks wallet information

##### 3. orders Document
**Changed Lines:** 375-440
- Stores complete items with all product fields:
  - `productId`, `skuId` (separate)
  - `productBasePrice`, `productCurrentPrice`
  - `itemSubtotal`, `itemDiscount`
  - `variants`, `category`, `brand`
- Stores `pricingSummary` (8 fields)
- Stores `paymentSummary` (4 fields)
- Includes coupon info and delivery details

##### 4. deliveries Document
**No Changes** (structure already correct)

#### Response Changes
**Changed Lines:** 520-570
- Returns `pricingSummary` with all 8 fields
- Returns `paymentSummary` with all 4 fields
- Includes payment info and wallet information

---

## Field Definitions

### Pricing Summary (8 Fields)

| Field | Definition | Formula | Example |
|-------|-----------|---------|---------|
| `orderSubtotal` | Sum of all product item subtotals | SUM(itemSubtotal) | ₹330 |
| `productDiscount` | Auto discount from price differences | SUM((basePrice - currentPrice) × qty) | ₹0 |
| `couponCode` | Coupon code applied (if any) | User input | "SAVE50" |
| `couponDiscount` | Amount discounted by coupon | User input | ₹50 |
| `totalDiscount` | Sum of all discounts | productDiscount + couponDiscount | ₹50 |
| `subtotalAfterDiscount` | Order amount after discounts | orderSubtotal - totalDiscount | ₹280 |
| `deliveryFee` | Shipping/delivery charge | System/order-based | ₹80 |
| `totalBeforePayment` | Final amount before payment split | subtotalAfterDiscount + deliveryFee | ₹360 |

### Payment Summary (4 Fields)

| Field | Definition | Formula | Payment Modes |
|-------|-----------|---------|----------------|
| `paymentMode` | Payment method selected | User choice | razorpay, cod, wallet, partial_wallet |
| `walletPaidAmount` | Amount paid from wallet | User input | 0-totalBeforePayment |
| `onlinePaidAmount` | Amount via gateway/COD | totalBeforePayment - walletPaidAmount | 0-totalBeforePayment |
| `totalOrderValue` | Grand total | walletPaidAmount + onlinePaidAmount | Same as totalBeforePayment |

---

## Payment Mode Mappings

### Mode: `razorpay` (Full Online)
```
Pricing Summary:
  orderSubtotal: 190 (product costs)
  deliveryFee: 50
  totalDiscount: 40
  totalBeforePayment: 200

Payment Summary:
  paymentMode: "razorpay"
  walletPaidAmount: 0
  onlinePaidAmount: 200 ← Full amount to Razorpay
  totalOrderValue: 200

Firestore razorpay_orders:
  amount: 20000 (200 × 100 paise)
```

### Mode: `cod` (Cash on Delivery)
```
Pricing Summary:
  (same as razorpay)
  totalBeforePayment: 200

Payment Summary:
  paymentMode: "cod"
  walletPaidAmount: 0
  onlinePaidAmount: 200 ← Paid at delivery
  totalOrderValue: 200

Firestore:
  No razorpay_orders document
  payments.status: "pending_collection"
```

### Mode: `wallet` (Full Wallet)
```
Pricing Summary:
  totalBeforePayment: 200

Payment Summary:
  paymentMode: "wallet"
  walletPaidAmount: 200 ← Full amount from wallet
  onlinePaidAmount: 0
  totalOrderValue: 200

Firestore:
  No razorpay_orders document
  User wallet deducted by 200
  payments.status: "paid"
```

### Mode: `partial_wallet` (Split Payment)
```
Pricing Summary:
  totalBeforePayment: 200

Payment Summary:
  paymentMode: "partial_wallet"
  walletPaidAmount: 100 ← From wallet
  onlinePaidAmount: 100 ← Remaining amount
  totalOrderValue: 200

Firestore:
  razorpay_orders with amount: 10000 (100 × 100)
  isPartialWalletPayment: true
  walletAmount: 100
  totalAmount: 200
  User wallet deducted by 100
```

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    FLUTTER APP - USER ACTIONS                   │
├─────────────────────────────────────────────────────────────────┤
│ 1. User selects products & applies coupon                       │
│ 2. Select delivery address & payment method                     │
│ 3. Review order with pricing breakdown                          │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│  _prepareOrderItems() - Capture Complete Product Data           │
├─────────────────────────────────────────────────────────────────┤
│ For each item:                                                  │
│ • productId, skuId                                              │
│ • productBasePrice (MRP), productCurrentPrice (selling)        │
│ • itemSubtotal (price × qty), itemDiscount                     │
│ • variants, category, brand                                     │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│   initiatePaymentWithMode() - Calculate Summaries               │
├─────────────────────────────────────────────────────────────────┤
│ pricingSummary:                                                 │
│ • orderSubtotal, productDiscount, couponDiscount              │
│ • totalDiscount, subtotalAfterDiscount, deliveryFee           │
│ • totalBeforePayment                                            │
│                                                                 │
│ paymentSummary:                                                 │
│ • paymentMode, walletPaidAmount, onlinePaidAmount             │
│ • totalOrderValue                                               │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│    Firebase Cloud Function: createOrder (razorpay.ts)           │
├─────────────────────────────────────────────────────────────────┤
│ 1. Receive items, pricingSummary, paymentSummary              │
│ 2. Validate all amounts and payment mode consistency           │
│ 3. Create Razorpay order (if needed)                           │
│ 4. Handle payment method (razorpay/cod/wallet/partial)        │
│ 5. Deduct wallet amount (if applicable)                        │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│          Firestore Transaction - Create 4 Collections           │
├─────────────────────────────────────────────────────────────────┤
│ 1. razorpay_orders    → Razorpay integration data              │
│ 2. payments           → Complete payment breakdown             │
│ 3. orders             → Complete order with all details        │
│ 4. deliveries         → Delivery tracking info                 │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│           Return Response to App with Order Details             │
├─────────────────────────────────────────────────────────────────┤
│ • orderId, paymentId, deliveryId                                │
│ • pricingSummary, paymentSummary                                │
│ • Payment info and coupon details                               │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│            Display Order Confirmation Screen                    │
├─────────────────────────────────────────────────────────────────┤
│ Show all order details from received response                   │
│ Display pricing breakdown and payment split                     │
│ Show item details with variant information                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Database Schema

### orders Collection
```
orders/{orderId}
├── orderId (string)
├── userId (string)
├── status (string) - processing_payment, confirmed, shipped, delivered
├── createdAt (timestamp)
├── updatedAt (timestamp)
│
├── items (array)
│  └── [0]
│      ├── productId (string)
│      ├── skuId (string)
│      ├── name (string)
│      ├── quantity (number)
│      ├── productBasePrice (number) ← MRP
│      ├── productCurrentPrice (number) ← Selling price
│      ├── itemSubtotal (number)
│      ├── itemDiscount (number)
│      ├── category (string)
│      ├── brand (string)
│      ├── variants (object)
│      └── productImage (string)
│
├── pricingSummary (object)
│  ├── orderSubtotal (number)
│  ├── productDiscount (number)
│  ├── couponCode (string)
│  ├── couponDiscount (number)
│  ├── totalDiscount (number)
│  ├── subtotalAfterDiscount (number)
│  ├── deliveryFee (number)
│  └── totalBeforePayment (number)
│
├── paymentSummary (object)
│  ├── paymentMode (string)
│  ├── walletPaidAmount (number)
│  ├── onlinePaidAmount (number)
│  └── totalOrderValue (number)
│
├── couponInfo (object or null)
│  ├── code (string)
│  ├── discountApplied (number)
│  └── appliedAt (timestamp)
│
└── deliveryInfo (object)
   ├── address (object)
   ├── estimatedDelivery (timestamp)
   └── deliveryInstructions (string)
```

### payments Collection
```
payments/{paymentId}
├── paymentId (string)
├── orderId (string)
├── userId (string)
├── method (string)
├── status (string)
├── gateway (string)
├── createdAt (timestamp)
├── updatedAt (timestamp)
│
├── pricingSummary (object)
│  └── [8 fields - same as orders]
│
├── paymentSummary (object)
│  └── [4 fields - same as orders]
│
├── paymentDetails (object)
│  ├── gateway (string)
│  ├── transactionId (string)
│  └── status (string)
│
├── couponInfo (object or null)
│  └── [coupon details]
│
└── walletInfo (object or null)
   ├── amountUsed (number)
   ├── isPartialPayment (boolean)
   └── remainingAmount (number)
```

---

## Testing Scenarios

### Test 1: Single Item, No Discount, Razorpay
```
Item: A4 Paper ₹100 × 1
Coupon: None
Delivery: ₹50

pricingSummary:
  orderSubtotal: 100
  totalDiscount: 0
  totalBeforePayment: 150

paymentSummary:
  paymentMode: "razorpay"
  onlinePaidAmount: 150
  walletPaidAmount: 0
```

### Test 2: Multiple Items, Coupon, Partial Wallet
```
Item 1: Paper ₹100 × 1 = ₹100
Item 2: Pens ₹50 × 2 = ₹100
Coupon SAVE50: -₹30
Delivery: ₹50
Wallet: ₹80 available

pricingSummary:
  orderSubtotal: 200
  couponDiscount: 30
  totalDiscount: 30
  totalBeforePayment: 220

paymentSummary:
  paymentMode: "partial_wallet"
  walletPaidAmount: 80
  onlinePaidAmount: 140
  totalOrderValue: 220
```

### Test 3: Full Wallet Payment
```
Total: ₹200
Wallet balance: ₹300

paymentSummary:
  paymentMode: "wallet"
  walletPaidAmount: 200
  onlinePaidAmount: 0
  totalOrderValue: 200

Firestore:
  orders.status: "confirmed" (immediate)
  payments.status: "paid"
```

### Test 4: COD Payment
```
Total: ₹200

paymentSummary:
  paymentMode: "cod"
  walletPaidAmount: 0
  onlinePaidAmount: 200
  totalOrderValue: 200

Firestore:
  orders.status: "confirmed"
  payments.status: "pending_collection"
  No razorpay_orders document
```

---

## Implementation Status

### ✅ Completed
1. **Flutter App Modifications**
   - Enhanced `_prepareOrderItems()` with complete product data
   - Updated `initiatePaymentWithMode()` with pricing & payment summaries
   - App sends pricingSummary and paymentSummary

2. **Firebase Cloud Function Updates**
   - Updated request handler to accept new structures
   - Enhanced validation for pricing and payment modes
   - Updated all 4 Firestore collection creation logic
   - Uses properly named fields throughout

3. **Firestore Schema Updates**
   - orders: Stores all items with product data + pricing + payment summaries
   - payments: Stores transaction details with pricing & payment summaries
   - razorpay_orders: Uses onlinePaidAmount for calculations
   - deliveries: Already properly structured

### ⏳ Next Steps

1. **Update Order Details Screen** (`lib/features/order/screens/order_details_screen.dart`)
   - Read pricingSummary and paymentSummary from orders collection
   - Display pricing breakdown with proper field names
   - Show payment split (wallet + online)
   - Display item details with all product information

2. **Testing**
   - Test all 4 payment modes
   - Verify calculations in Firestore
   - Verify order details display
   - Test wallet balance deductions

3. **Order Summary Generation**
   - Create reusable component to display order summary
   - Use from multiple screens (order confirmation, order history, order details)

---

## Key Improvements

### Before Implementation
- Single `amountSummary` was ambiguous
- No separation of productId and skuId
- No product-level pricing (MRP vs selling price)
- Incomplete variant information
- Unclear field naming and purposes
- No item-level discount tracking

### After Implementation
- Clear `pricingSummary` (8 fields) with specific purposes
- Clear `paymentSummary` (4 fields) for payment split tracking
- Separate `productId` and `skuId` capture
- Both MRP (base price) and selling price captured
- Complete variant information as structured object
- Item-level calculations (subtotal and discount per item)
- Professional field naming for clarity
- Complete audit trail for each field

---

## Files Modified

1. ✅ `lib/services/razorpay_payment_service.dart` (Lines 61-310)
   - `_prepareOrderItems()` enhanced
   - `initiatePaymentWithMode()` restructured

2. ✅ `functions/razorpay.ts` (Multiple sections)
   - Request handler updated
   - Validation logic enhanced
   - All 4 Firestore documents updated
   - Response structure changed

---

## Quick Reference: New Fields

### To Use in Order Details Screen

**Read from orders/{orderId}:**
```dart
final order = await _firestore.collection('orders').doc(orderId).get();
final items = order['items'] as List;
final pricingSummary = order['pricingSummary'] as Map;
final paymentSummary = order['paymentSummary'] as Map;
```

**Display Pricing:**
```dart
print('Subtotal: ₹${pricingSummary['orderSubtotal']}');
print('Discount: ₹${pricingSummary['totalDiscount']}');
print('Delivery: ₹${pricingSummary['deliveryFee']}');
print('Total: ₹${pricingSummary['totalBeforePayment']}');
```

**Display Payment:**
```dart
print('Payment Mode: ${paymentSummary['paymentMode']}');
print('Wallet: ₹${paymentSummary['walletPaidAmount']}');
print('Online: ₹${paymentSummary['onlinePaidAmount']}');
```

**Display Items:**
```dart
for (var item in items) {
  print('${item['name']} (${item['skuId']})');
  print('MRP: ₹${item['productBasePrice']}');
  print('Price: ₹${item['productCurrentPrice']}');
  print('Qty: ${item['quantity']}');
  print('Subtotal: ₹${item['itemSubtotal']}');
  print('Discount: ₹${item['itemDiscount']}');
}
```

