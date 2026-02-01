# Complete Order Data Capture Implementation

## Overview
This document describes the complete end-to-end implementation for capturing comprehensive order data from product selection through order confirmation, with proper field naming and calculation at each stage.

## Architecture

### 1. Flutter App (`lib/services/razorpay_payment_service.dart`)

#### A. Item Preparation (`_prepareOrderItems()`)
Captures complete product information for each item in the order:

```dart
{
  'productId': 'PRODUCT-001',           // Product identifier
  'skuId': 'SKU-BLUE-A4',               // SKU identifier (different from productId)
  'name': 'A4 Paper Blue Ream',
  'quantity': 2,
  'productImage': 'https://...',
  
  // Pricing Information
  'productBasePrice': 100,              // MRP (base/original price)
  'productCurrentPrice': 90,            // Selling price (can be different from base)
  'itemSubtotal': 180,                  // 90 × 2 (quantity × current price)
  'itemDiscount': 20,                   // (100-90) × 2 (base - current) × qty
  
  // Variant Information
  'variants': {
    'color': 'Blue',
    'size': 'A4'
  },
  
  // Metadata
  'category': 'Paper Products',
  'brand': 'Premium Paper Co.'
}
```

**Key Points:**
- Separates `productId` from `skuId` (different stock keeping units have different prices)
- Captures both base price (MRP) and current selling price for discount calculations
- Pre-calculates `itemSubtotal` and `itemDiscount` at item level
- Includes variant information as structured object (not deprecated field)
- Adds category and brand metadata for reporting

---

#### B. Pricing Summary (`pricingSummary`)
Aggregates all pricing information at order level:

```dart
{
  'orderSubtotal': 330,                 // Sum of all itemSubtotals
  'productDiscount': 0,                 // Auto discount from price differences
  'couponCode': 'SAVE50',               // Coupon applied
  'couponDiscount': 50,                 // Discount from coupon
  'totalDiscount': 50,                  // productDiscount + couponDiscount
  'subtotalAfterDiscount': 280,         // orderSubtotal - totalDiscount
  'deliveryFee': 80,                    // Shipping charge
  'totalBeforePayment': 360             // Final amount before payment split
}
```

**Calculation Flow:**
```
orderSubtotal = SUM(item.itemSubtotal for all items)
totalDiscount = productDiscount + couponDiscount
subtotalAfterDiscount = orderSubtotal - totalDiscount
totalBeforePayment = subtotalAfterDiscount + deliveryFee
```

**Field Purposes:**
- `orderSubtotal`: Total value of all products before any discounts
- `productDiscount`: Auto-calculated from (basePrice - sellingPrice) differences
- `couponDiscount`: Manual discount from coupon application
- `totalDiscount`: Sum of all discounts applied
- `subtotalAfterDiscount`: Order value after all discounts
- `deliveryFee`: Shipping/delivery cost
- `totalBeforePayment`: Final amount before splitting by payment method

---

#### C. Payment Summary (`paymentSummary`)
Splits payment between wallet and online methods:

```dart
{
  'paymentMode': 'partial_wallet',      // Payment method
  'walletPaidAmount': 100,              // Amount from wallet
  'onlinePaidAmount': 260,              // Amount via Razorpay/COD
  'totalOrderValue': 360                // Grand total
}
```

**Payment Mode Variations:**

| Mode | walletPaidAmount | onlinePaidAmount | Usage |
|------|------------------|------------------|-------|
| `razorpay` | 0 | totalBeforePayment | Full online payment |
| `cod` | 0 | totalBeforePayment | Cash on delivery |
| `wallet` | totalBeforePayment | 0 | Full wallet payment |
| `partial_wallet` | Amount used | Remaining | Split payment |

**Validation Rules:**
- `walletPaidAmount + onlinePaidAmount = totalOrderValue`
- For wallet/partial_wallet: ensure user has sufficient balance
- For COD: walletPaidAmount must be 0
- For razorpay: walletPaidAmount must be 0

---

### 2. Firebase Cloud Function (`functions/razorpay.ts`)

#### Request Payload Reception
Function expects three main components:

```typescript
{
  items: [/* with full product details */],
  pricingSummary: {
    orderSubtotal, productDiscount, couponCode, couponDiscount,
    totalDiscount, subtotalAfterDiscount, deliveryFee, totalBeforePayment
  },
  paymentSummary: {
    paymentMode, walletPaidAmount, onlinePaidAmount, totalOrderValue
  },
  paymentMode: 'razorpay' | 'cod' | 'wallet' | 'partial_wallet',
  deliveryAddress: {/* complete address details */},
  currency: 'INR'
}
```

#### Validation Process
1. **Structure Validation**
   - All required arrays and objects present
   - Items array non-empty
   - Delivery address complete

2. **Amount Validation**
   - All amounts ≥ 0
   - Order total > 0
   - Payment splits match payment mode

3. **Payment Mode Validation**
   - `razorpay`: walletPaidAmount = 0
   - `cod`: walletPaidAmount = 0
   - `wallet`: onlinePaidAmount = 0
   - `partial_wallet`: both amounts > 0, sum = total

---

### 3. Firestore Collections

#### A. `orders` Collection
Complete order document with all information:

```typescript
{
  orderId: string,
  userId: string,
  paymentMode: string,
  paymentId: string,
  deliveryId: string,
  status: string,
  createdAt: timestamp,
  updatedAt: timestamp,
  
  // Items with complete product information
  items: [
    {
      productId: string,
      skuId: string,
      name: string,
      quantity: number,
      productBasePrice: number,      // MRP
      productCurrentPrice: number,   // Selling price
      itemSubtotal: number,          // price × quantity
      itemDiscount: number,          // discount per item
      category: string,
      brand: string,
      variants: object,
      productImage: string
    }
  ],
  
  // Pricing breakdown
  pricingSummary: {
    orderSubtotal: number,
    productDiscount: number,
    couponCode: string | null,
    couponDiscount: number,
    totalDiscount: number,
    subtotalAfterDiscount: number,
    deliveryFee: number,
    totalBeforePayment: number
  },
  
  // Payment breakdown
  paymentSummary: {
    paymentMode: string,
    walletPaidAmount: number,
    onlinePaidAmount: number,
    totalOrderValue: number
  },
  
  // Coupon info
  couponInfo: {
    code: string,
    discountApplied: number,
    appliedAt: timestamp
  } | null,
  
  // Delivery info
  deliveryInfo: {
    address: object,
    estimatedDelivery: timestamp | null,
    deliveryInstructions: string | null
  }
}
```

#### B. `payments` Collection
Payment transaction details:

```typescript
{
  paymentId: string,
  orderId: string,
  userId: string,
  method: string,
  currency: string,
  status: string,
  gateway: string,
  createdAt: timestamp,
  updatedAt: timestamp,
  
  // Pricing info from order
  pricingSummary: {
    orderSubtotal, productDiscount, couponCode, couponDiscount,
    totalDiscount, subtotalAfterDiscount, deliveryFee, totalBeforePayment
  },
  
  // Payment info
  paymentSummary: {
    paymentMode, walletPaidAmount, onlinePaidAmount, totalOrderValue
  },
  
  // Payment details
  paymentDetails: {
    gateway: string,
    transactionId: string | null,
    status: string,
    ...additional fields
  },
  
  // Coupon info
  couponInfo: {
    code: string,
    discountApplied: number,
    appliedAt: timestamp
  } | null,
  
  // Wallet info
  walletInfo: {
    amountUsed: number,
    isPartialPayment: boolean,
    remainingAmount: number,
    paymentMethod: string | null
  } | null
}
```

#### C. `razorpay_orders` Collection
Razorpay-specific order data:

```typescript
{
  razorpayOrderId: string,
  userId: string,
  amount: number,                    // Amount in paise
  currency: string,
  status: string,
  createdAt: timestamp,
  orderId: string,
  paymentId: string,
  deliveryId: string,
  isPartialWalletPayment: boolean,
  walletAmount: number | null,       // For partial wallet
  totalAmount: number | null         // For partial wallet
}
```

#### D. `deliveries` Collection
Delivery tracking information:

```typescript
{
  deliveryId: string,
  orderId: string,
  userId: string,
  status: string,
  createdAt: timestamp,
  updatedAt: timestamp,
  
  deliveryDetails: {
    address: object,
    contactInfo: object,
    locationInfo: object,
    deliveryInstructions: string | null,
    preferredDeliveryTime: string | null
  },
  
  trackingInfo: {
    estimatedDelivery: timestamp | null,
    actualDelivery: timestamp | null,
    deliveryPartner: string | null,
    trackingNumber: string | null,
    deliveryAttempts: number
  }
}
```

---

## Example: Complete Order Flow

### Scenario
Customer orders 2 items with coupon, pays with partial wallet:
- Item 1: A4 Paper (₹100 MRP, ₹90 selling) × 1 = ₹90
- Item 2: Pens (₹50 MRP, ₹50 selling) × 2 = ₹100
- Subtotal: ₹190
- Delivery: ₹50
- Coupon SAVE50: -₹30
- Wallet balance: ₹80 (available)
- Pays ₹80 from wallet, ₹100 via Razorpay

### Step 1: Prepare Items (App)
```dart
items = [
  {
    'productId': 'PAPER-A4',
    'skuId': 'SKU-BLUE-100',
    'name': 'A4 Paper Ream',
    'quantity': 1,
    'productBasePrice': 100,
    'productCurrentPrice': 90,
    'itemSubtotal': 90,
    'itemDiscount': 10,
    'variants': {'color': 'Blue'},
    'category': 'Paper',
    'brand': 'Premium'
  },
  {
    'productId': 'PENS-BALL',
    'skuId': 'SKU-PEN-RED',
    'name': 'Ballpoint Pens',
    'quantity': 2,
    'productBasePrice': 50,
    'productCurrentPrice': 50,
    'itemSubtotal': 100,
    'itemDiscount': 0,
    'variants': {'color': 'Red'},
    'category': 'Writing',
    'brand': 'Standard'
  }
]
```

### Step 2: Calculate Pricing Summary (App)
```dart
pricingSummary = {
  'orderSubtotal': 190,              // 90 + 100
  'productDiscount': 10,             // (100-90) × 1 + (50-50) × 2
  'couponCode': 'SAVE50',
  'couponDiscount': 30,              // Coupon discount
  'totalDiscount': 40,               // 10 + 30
  'subtotalAfterDiscount': 150,      // 190 - 40
  'deliveryFee': 50,
  'totalBeforePayment': 200           // 150 + 50
}
```

### Step 3: Calculate Payment Summary (App)
```dart
paymentSummary = {
  'paymentMode': 'partial_wallet',
  'walletPaidAmount': 80,
  'onlinePaidAmount': 120,           // 200 - 80
  'totalOrderValue': 200
}
```

### Step 4: Send to Firebase Function
```dart
createOrder({
  items: [/* as above */],
  pricingSummary: {/* as above */},
  paymentSummary: {/* as above */},
  paymentMode: 'partial_wallet',
  deliveryAddress: {/* complete address */},
  currency: 'INR'
})
```

### Step 5: Firebase Function Processing
1. **Validates** all amounts and payment mode
2. **Deducts** ₹80 from user wallet
3. **Creates** Razorpay order for ₹120 (paise: 12000)
4. **Stores** complete order with all fields in Firestore

### Step 6: Documents Created in Firestore

**orders/{orderId}**
```json
{
  "items": [{...with all product details...}],
  "pricingSummary": {
    "orderSubtotal": 190,
    "productDiscount": 10,
    "couponCode": "SAVE50",
    "couponDiscount": 30,
    "totalDiscount": 40,
    "subtotalAfterDiscount": 150,
    "deliveryFee": 50,
    "totalBeforePayment": 200
  },
  "paymentSummary": {
    "paymentMode": "partial_wallet",
    "walletPaidAmount": 80,
    "onlinePaidAmount": 120,
    "totalOrderValue": 200
  }
}
```

**payments/{paymentId}**
```json
{
  "pricingSummary": {...},
  "paymentSummary": {...},
  "walletInfo": {
    "amountUsed": 80,
    "isPartialPayment": true,
    "remainingAmount": 120
  }
}
```

---

## Key Features of This Implementation

### 1. **Complete Product Data**
- Every item includes base price (MRP) and selling price
- SKU ID captured separately from product ID
- Category, brand, variants included
- Item-level calculations stored

### 2. **Proper Field Naming**
| Field | Meaning | Example |
|-------|---------|---------|
| `productBasePrice` | MRP from product master | ₹100 |
| `productCurrentPrice` | Actual selling price | ₹90 |
| `itemSubtotal` | Price × Quantity | ₹180 |
| `itemDiscount` | Per-item discount | ₹20 |
| `orderSubtotal` | Sum of all items | ₹330 |
| `couponDiscount` | From coupon code | ₹50 |
| `totalDiscount` | All discounts combined | ₹50 |
| `walletPaidAmount` | From wallet | ₹100 |
| `onlinePaidAmount` | Via gateway | ₹260 |
| `totalOrderValue` | Grand total | ₹360 |

### 3. **Calculation Transparency**
Every amount can be traced:
- Item level: quantity × price ± discount
- Order level: sum of items + delivery - discounts
- Payment level: wallet + online = total

### 4. **Payment Mode Support**
- **Razorpay**: 100% online payment
- **COD**: 100% cash on delivery
- **Wallet**: 100% wallet payment
- **Partial Wallet**: Split payment (wallet + online)

### 5. **Data Persistence**
- All data stored in single `orders` document
- `payments` document for transaction details
- `razorpay_orders` for gateway integration
- Complete audit trail available

---

## Display in Order Details Screen

All saved data can be displayed from the orders collection:

### Price Breakdown Section
```
Product Subtotal        ₹330
- Product Discount      ₹0
- Coupon (SAVE50)       ₹50
                        ------
After Discount          ₹280
+ Delivery Fee          ₹80
                        ------
Order Total             ₹360
```

### Payment Section
```
Wallet Payment          ₹100 ✓
Online Payment          ₹260 → Razorpay
                        ------
Total Paid              ₹360
```

### Items Section
Each item shows:
```
A4 Paper Blue Ream
  MRP: ₹100
  Selling Price: ₹90
  Quantity: 2
  Subtotal: ₹180
  Discount: ₹20
  Color: Blue
```

---

## Implementation Checklist

✅ **Completed:**
1. Flutter app captures complete product data (`_prepareOrderItems`)
2. App calculates pricing summary with proper field names
3. App calculates payment summary with wallet/online split
4. Cloud function accepts new payload structure
5. Cloud function validates all amounts and payment modes
6. Firestore stores complete data with proper field names
7. All collections updated with new schema

⏳ **Next Steps:**
1. Update order details display screen to read and display new fields
2. Test complete flow with different payment modes
3. Verify calculations in order history
4. Add order summary generation from stored data

---

## Testing Checklist

### Payment Mode Tests
- [ ] Razorpay: Full online payment
- [ ] COD: Cash on delivery
- [ ] Wallet: Full wallet payment
- [ ] Partial Wallet: Split payment

### Data Validation Tests
- [ ] All items have complete product data
- [ ] Pricing calculations correct
- [ ] Payment amounts match
- [ ] Wallet deduction works
- [ ] Firestore data complete and accurate

### Display Tests
- [ ] Order details show all fields
- [ ] Calculations display correctly
- [ ] Payment breakdown visible
- [ ] Item details complete

