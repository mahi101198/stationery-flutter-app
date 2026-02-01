# 📊 COMPLETE DATA FLOW DIAGRAM

## End-to-End Order Creation Flow (With Corrected Pricing)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USER ADDS TO CART                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Product 1: Blue Notebook                                                  │
│    MRP (productBasePrice): ₹100                                           │
│    Current Price (productCurrentPrice): ₹90                              │
│    Quantity: 2                                                             │
│                                                                             │
│  Product 2: Red Pencil                                                     │
│    MRP: ₹150                                                              │
│    Current Price: ₹150                                                    │
│    Quantity: 1                                                             │
│                                                                             │
│  Coupon Applied: SAVE50 (₹50 discount)                                   │
│  Delivery Address: Selected ✓                                            │
│  Wallet Balance: ₹100                                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│           STEP 1: _prepareOrderItems() [Flutter Service]                   │
│           ✅ Uses MRP-based pricing, NOT selling price!                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Item 1 (Blue Notebook × 2):                                             │
│    itemSubtotalAtMRP = 100 × 2 = ₹200                 ← MRP-based ✓     │
│    itemSubtotalAtSellingPrice = 90 × 2 = ₹180                           │
│    itemAutoDiscount = 200 - 180 = ₹20                ← Auto discount ✓   │
│                                                                             │
│  Item 2 (Red Pencil × 1):                                               │
│    itemSubtotalAtMRP = 150 × 1 = ₹150                ← MRP-based ✓     │
│    itemSubtotalAtSellingPrice = 150 × 1 = ₹150                         │
│    itemAutoDiscount = 150 - 150 = ₹0                                    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│        STEP 2: Calculate pricingSummary [Flutter Service]                  │
│        ✅ Deducts discounts ONCE, no double-counting!                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  orderSubtotal = SUM(itemSubtotalAtMRP)                                   │
│                = 200 + 150 = ₹350              ← MRP-based sum ✓        │
│                                                                             │
│  productDiscount = SUM(itemAutoDiscount)                                  │
│                  = 20 + 0 = ₹20                ← Auto discount sum ✓     │
│                                                                             │
│  couponDiscount = ₹50                          ← From coupon code ✓      │
│                                                                             │
│  totalDiscount = productDiscount + couponDiscount                        │
│               = 20 + 50 = ₹70                 ← Deducted ONCE ✓         │
│                                                                             │
│  subtotalAfterDiscount = orderSubtotal - totalDiscount                   │
│                       = 350 - 70 = ₹280      ← No double-counting ✓    │
│                                                                             │
│  deliveryFee = ₹80                                                        │
│                                                                             │
│  totalBeforePayment = subtotalAfterDiscount + deliveryFee               │
│                    = 280 + 80 = ₹360         ← Final before payment ✓   │
│                                                                             │
│  pricingSummary = {                                                       │
│    orderSubtotal: 350,                                                    │
│    productDiscount: 20,                                                   │
│    couponDiscount: 50,                                                    │
│    totalDiscount: 70,                                                     │
│    subtotalAfterDiscount: 280,                                           │
│    deliveryFee: 80,                                                       │
│    totalBeforePayment: 360                                               │
│  }                                                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│        STEP 3: Calculate paymentSummary [Flutter Service]                  │
│        ✅ Splits payment by mode (wallet vs online)                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Wallet Available: ₹100                                                    │
│  Total to Pay: ₹360                                                       │
│  Payment Mode: partial_wallet                                              │
│                                                                             │
│  walletPaidAmount = min(walletBalance, totalBeforePayment)               │
│                  = min(100, 360) = ₹100    ← Use available wallet ✓     │
│                                                                             │
│  onlinePaidAmount = totalBeforePayment - walletPaidAmount                │
│                  = 360 - 100 = ₹260        ← Send to Razorpay ✓        │
│                                                                             │
│  totalOrderValue = totalBeforePayment = ₹360                             │
│                                                                             │
│  paymentSummary = {                                                       │
│    paymentMode: 'partial_wallet',                                        │
│    walletPaidAmount: 100,                                                │
│    onlinePaidAmount: 260,                                                │
│    totalOrderValue: 360                                                  │
│  }                                                                         │
│                                                                             │
│  Validation: 100 + 260 = 360 ✓ (Matches totalOrderValue)                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│                 SEND TO FIREBASE CLOUD FUNCTION                            │
│                  createOrder(payload)                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  POST createOrder {                                                        │
│    items: [                                                                │
│      {                                                                     │
│        productId: "PRODUCT-001",                                          │
│        skuId: "SKU-BLUE-001",                                            │
│        name: "Blue Notebook",                                            │
│        quantity: 2,                                                       │
│        productBasePrice: 100,                                             │
│        productCurrentPrice: 90,                                           │
│        itemSubtotalAtMRP: 200,                                           │
│        itemSubtotalAtSellingPrice: 180,                                  │
│        itemAutoDiscount: 20,                                              │
│        variants: { color: "blue" },                                       │
│        productImage: "..."                                                │
│      },                                                                   │
│      { /* Product 2 ... */ }                                             │
│    ],                                                                      │
│    pricingSummary: {                                                     │
│      orderSubtotal: 350,                                                 │
│      productDiscount: 20,                                                │
│      couponDiscount: 50,                                                 │
│      totalDiscount: 70,                                                  │
│      subtotalAfterDiscount: 280,                                         │
│      deliveryFee: 80,                                                    │
│      totalBeforePayment: 360                                             │
│    },                                                                     │
│    paymentSummary: {                                                     │
│      paymentMode: "partial_wallet",                                      │
│      walletPaidAmount: 100,                                              │
│      onlinePaidAmount: 260,                                              │
│      totalOrderValue: 360                                                │
│    },                                                                     │
│    deliveryAddress: { /* ... */ },                                       │
│    couponCode: "SAVE50"                                                  │
│  }                                                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│          STEP 4: Firebase Function Validates [razorpay.ts]                 │
│          ✅ Comprehensive formula validation                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Validation Checks:                                                        │
│                                                                             │
│  ✓ Check 1: subtotalAfterDiscount = orderSubtotal - totalDiscount       │
│    Expected: 350 - 70 = 280                                              │
│    Received: 280 ✓ PASS                                                  │
│                                                                             │
│  ✓ Check 2: totalBeforePayment = subtotalAfterDiscount + deliveryFee    │
│    Expected: 280 + 80 = 360                                              │
│    Received: 360 ✓ PASS                                                  │
│                                                                             │
│  ✓ Check 3: totalDiscount = productDiscount + couponDiscount           │
│    Expected: 20 + 50 = 70                                               │
│    Received: 70 ✓ PASS                                                  │
│                                                                             │
│  ✓ Check 4: walletPaid + onlinePaid = totalOrderValue                   │
│    Expected: 100 + 260 = 360                                             │
│    Received: 100 + 260 = 360 ✓ PASS                                     │
│                                                                             │
│  Logging:                                                                  │
│  ✅ Pricing formula validation passed:                                     │
│     orderSubtotal (MRP) = ₹350                                            │
│     - productDiscount = ₹20                                               │
│     - couponDiscount = ₹50                                                │
│     = subtotalAfterDiscount = ₹280                                       │
│     + deliveryFee = ₹80                                                   │
│     = totalBeforePayment = ₹360                                          │
│     = totalOrderValue = ₹360                                             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│        STEP 5: Create Firestore Documents (Transaction)                    │
│        ✅ All data stored in single transaction                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. Deduct Wallet (if wallet payment):                                     │
│     users/{userId}.walletBalance -= 100                                   │
│                                                                             │
│  2. Create orders document:                                                │
│     orders/{orderId} = {                                                  │
│       orderId: "ORD1707382400123",                                        │
│       userId: "user123",                                                  │
│       paymentMode: "partial_wallet",                                      │
│       status: "processing_payment",                                       │
│       items: [ ← With complete product/SKU/variant data                   │
│         {                                                                  │
│           productId: "PRODUCT-001",     ← Separate from SKU              │
│           skuId: "SKU-BLUE-001",        ← SKU identifier                 │
│           itemSubtotalAtMRP: 200,       ← MRP-based calculation         │
│           itemSubtotalAtSellingPrice: 180,                              │
│           itemAutoDiscount: 20,         ← Per-item discount             │
│           variants: { color: "blue" }   ← All variant attributes        │
│         }                                                                  │
│       ],                                                                  │
│       pricingSummary: { /* 8 fields */ },                                │
│       paymentSummary: { /* 4 fields */ },                                │
│       deliveryInfo: { /* address */ }                                    │
│     }                                                                      │
│                                                                             │
│  3. Create payments document:                                              │
│     payments/{paymentId} = {                                              │
│       paymentId: "PAY1707382400456",                                      │
│       orderId: "ORD1707382400123",                                        │
│       method: "partial_wallet",                                           │
│       status: "created",                                                  │
│       pricingSummary: { /* complete */ },                                │
│       paymentSummary: { /* complete */ },                                │
│       walletInfo: {                                                       │
│         amountUsed: 100,                                                  │
│         isPartialPayment: true,                                           │
│         remainingAmount: 260                                              │
│       },                                                                   │
│       razorpayOrderId: "order_xyz123"                                     │
│     }                                                                      │
│                                                                             │
│  4. Create razorpay_orders document (for Razorpay):                       │
│     razorpay_orders/{razorpayOrderId} = {                                 │
│       razorpayOrderId: "order_xyz123",                                    │
│       amount: 26000,  ← In paise (₹260 × 100)                            │
│       status: "created",                                                  │
│       isPartialWalletPayment: true,                                       │
│       walletAmount: 100,                                                  │
│       totalAmount: 360                                                    │
│     }                                                                      │
│                                                                             │
│  5. Create deliveries document:                                            │
│     deliveries/{deliveryId} = {                                           │
│       deliveryId: "DEL1707382400789",                                     │
│       orderId: "ORD1707382400123",                                        │
│       status: "pending",                                                  │
│       deliveryDetails: { /* address */ }                                  │
│     }                                                                      │
│                                                                             │
│  All documents created atomically ✓                                       │
│  Wallet deducted ✓                                                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│              STEP 6: Return Response to Flutter App                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Response = {                                                             │
│    success: true,                                                         │
│    orderId: "ORD1707382400123",                                          │
│    paymentId: "PAY1707382400456",                                        │
│    deliveryId: "DEL1707382400789",                                       │
│    paymentMode: "partial_wallet",                                        │
│    pricingSummary: { /* echoed back for verification */ },              │
│    paymentSummary: { /* echoed back for verification */ },              │
│    paymentInfo: {                                                         │
│      gateway: "razorpay",                                                 │
│      status: "created",                                                   │
│      razorpayOrderId: "order_xyz123"  ← For Razorpay UI               │
│    },                                                                      │
│    walletInfo: {                                                          │
│      amountUsed: 100,                                                     │
│      isPartialPayment: true,                                              │
│      remainingAmount: 260                                                 │
│    }                                                                       │
│  }                                                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│           STEP 7: Flutter App Opens Razorpay Checkout                      │
│           ✅ For online payment of remaining amount                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Razorpay.open({                                                          │
│    key: "RAZORPAY_KEY",                                                   │
│    order_id: "order_xyz123",  ← From Firebase response                   │
│    amount: 26000,             ← ₹260 × 100 paise ✓                      │
│    currency: "INR",                                                       │
│    description: "Order ORD1707382400123"                                 │
│  })                                                                        │
│                                                                             │
│  User pays ₹260 via Razorpay ✓                                           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│         STEP 8: Order Details Screen Displays Complete Info                │
│         ✅ All data now available for display                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ORDER SUMMARY                                                             │
│  ═══════════════════════════════════════════════════════════════════     │
│                                                                             │
│  Items:                                                                    │
│    Blue Notebook × 2                                                      │
│      MRP: ₹100 × 2 = ₹200                                               │
│      Discount: -₹20 (auto)                                               │
│      Item Total: ₹180                                                     │
│                                                                             │
│    Red Pencil × 1                                                         │
│      MRP: ₹150 × 1 = ₹150                                               │
│      Discount: -₹0                                                        │
│      Item Total: ₹150                                                     │
│                                                                             │
│  ───────────────────────────────────────────────────────────────         │
│                                                                             │
│  Price Breakdown:                                                          │
│    Item Total (at MRP):       ₹350                                        │
│    Auto Discount:             -₹20                                        │
│    Coupon Discount (SAVE50):  -₹50                                        │
│    ─────────────────────────────────                                      │
│    Subtotal After Discount:   ₹280                                        │
│    Delivery Fee:              +₹80                                        │
│    ═════════════════════════════════                                      │
│    Total to Pay:              ₹360                                        │
│                                                                             │
│  ───────────────────────────────────────────────────────────────         │
│                                                                             │
│  Payment Breakdown:                                                        │
│    Paid from Wallet:    ₹100 ✓                                           │
│    Paid via Razorpay:   ₹260 ✓                                           │
│    ═════════════════════════════                                         │
│    Total:               ₹360 ✓                                           │
│                                                                             │
│  ───────────────────────────────────────────────────────────────         │
│                                                                             │
│  Delivery Address:                                                         │
│    [Address details here]                                                 │
│                                                                             │
│  Expected Delivery: [Date range]                                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Key Data Points in Firestore

### orders collection
```typescript
{
  "orderId": "ORD1707382400123",
  "items": [
    {
      "productId": "PRODUCT-001",       // ✅ Product identifier
      "skuId": "SKU-BLUE-001",         // ✅ SKU identifier (separate!)
      "itemSubtotalAtMRP": 200,        // ✅ MRP calculation
      "itemSubtotalAtSellingPrice": 180,
      "itemAutoDiscount": 20           // ✅ Auto discount
    }
  ],
  "pricingSummary": {
    "orderSubtotal": 350,              // ✅ MRP-based, NOT selling price
    "productDiscount": 20,
    "couponDiscount": 50,
    "totalDiscount": 70,               // ✅ Deducted ONCE
    "subtotalAfterDiscount": 280,      // ✅ Correct calculation
    "deliveryFee": 80,
    "totalBeforePayment": 360
  },
  "paymentSummary": {
    "paymentMode": "partial_wallet",
    "walletPaidAmount": 100,           // ✅ Wallet usage tracked
    "onlinePaidAmount": 260,           // ✅ Razorpay amount
    "totalOrderValue": 360             // ✅ Verification sum
  }
}
```

---

## ✅ The Fix in One Image

```
BEFORE (WRONG):                    AFTER (CORRECT):
───────────────────               ──────────────────
MRP: ₹100                          MRP: ₹100
Sell: ₹90                          Sell: ₹90
Qty: 2                             Qty: 2
                                   
orderSubtotal: ₹180 ❌             orderSubtotal: ₹200 ✅
(using selling price)              (using MRP)
                                   
- discount: ₹20                    - discount: ₹20
                                   
Result: ₹160 ❌ WRONG              Result: ₹180 ✅ CORRECT
(double-counting)                  (no double-counting)
```

**Now:** Using MRP for orderSubtotal, deducting discounts only once ✓

---

**Implementation Complete:** February 1, 2026  
**Status:** ✅ READY FOR TESTING
