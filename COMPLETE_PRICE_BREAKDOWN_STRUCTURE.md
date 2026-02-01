# 💰 COMPLETE PRICE BREAKDOWN STRUCTURE DESIGN

**Date:** February 1, 2026  
**Purpose:** Define correct fields, naming, and calculations for order summaries

---

## 🎯 REQUIRED FIELDS BREAKDOWN

### 1. PRODUCT LEVEL PRICING

```
productBasePrice (or MRP)
├─ Definition: Original product price set by business
├─ Example: ₹100
├─ Source: Product master data
├─ Used for: Price comparison, discount calculation
└─ Field Name: productBasePrice or mrp

productCurrentPrice (or SKU Selling Price)
├─ Definition: Actual price customer should pay for this SKU
├─ Example: ₹95 (if on offer) or ₹100 (if no offer)
├─ Source: SKU-specific pricing
├─ Used for: Calculate item subtotal
└─ Field Name: productCurrentPrice or skuSellingPrice

itemQuantity
├─ Definition: How many units ordered
├─ Example: 2
├─ Source: Cart or Buy Now
└─ Field Name: quantity
```

### 2. ITEM LEVEL CALCULATIONS

```
itemSubtotal
├─ Formula: productCurrentPrice × quantity
├─ Example: ₹95 × 2 = ₹190
├─ Field Name: itemSubtotal or subtotal

itemDiscount
├─ Definition: Discount applied to this specific item
├─ Formula: (productBasePrice - productCurrentPrice) × quantity
├─ Example: (₹100 - ₹95) × 2 = ₹10
├─ Field Name: itemDiscount or discountAmount
└─ Note: Sum of all items = total product discount
```

### 3. ORDER LEVEL AMOUNTS

```
orderSubtotal
├─ Definition: Sum of all item subtotals at BASE PRICE (MRP) - NOT selling price!
├─ Formula: SUM(itemBasePrice × quantity for all items)
├─ Example: (₹100 × 2) + (₹150 × 1) = ₹350
├─ Field Name: orderSubtotal or subTotal
└─ 🔴 IMPORTANT: Use BASE PRICE (MRP), NOT selling price to avoid double-counting discounts

productDiscount
├─ Definition: Auto discount from price differences (MRP vs Selling Price)
├─ Formula: SUM(itemDiscount for all items) = SUM((basePrice - sellingPrice) × quantity)
├─ Example: ₹20 + ₹0 = ₹20
├─ Field Name: productDiscount or auto_discount
└─ Note: Sum of all items auto-discounts

couponDiscount
├─ Definition: Additional discount from coupon code
├─ Example: ₹50 (SAVE50 coupon)
├─ Field Name: couponDiscount or couponDiscountAmount
└─ Note: Can be 0 if no coupon used

totalDiscount
├─ Definition: Sum of ALL discounts (product + coupon)
├─ Formula: productDiscount + couponDiscount
├─ Example: ₹20 + ₹50 = ₹70
├─ Field Name: totalDiscount or discountTotal
└─ 🔴 THIS IS THE ONLY PLACE WE DEDUCT DISCOUNTS FROM orderSubtotal

deliveryFee
├─ Definition: Shipping cost
├─ Example: ₹80 (or ₹0 if free shipping)
├─ Field Name: deliveryFee or shippingCost

subtotalAfterDiscount
├─ Definition: Order amount after ALL discounts (product + coupon) but before delivery
├─ Formula: orderSubtotal - totalDiscount
├─ Example: ₹350 - ₹70 = ₹280
├─ Field Name: subtotalAfterDiscount or amountAfterDiscount
└─ 🟢 CORRECT: NO double-counting, discounts deducted only once

totalBeforePayment
├─ Definition: Total amount customer owes (before wallet/online split)
├─ Formula: subtotalAfterDiscount + deliveryFee
├─ Example: ₹365 + ₹100 = ₹465
├─ Field Name: totalBeforePayment or amountBeforePaymentMode

walletPaidAmount
├─ Definition: Amount paid using wallet
├─ Example: ₹100
├─ Field Name: walletPaidAmount or walletUsed
└─ Constraint: <= totalBeforePayment

onlinePaidAmount
├─ Definition: Amount paid online (Razorpay/Bank)
├─ Formula: totalBeforePayment - walletPaidAmount
├─ Example: ₹465 - ₹100 = ₹365
├─ Field Name: onlinePaidAmount or razorpayAmount

totalOrderValue
├─ Definition: Grand total including everything
├─ Formula: totalBeforePayment (for tracking, not payment)
├─ Example: ₹465
├─ Field Name: totalOrderValue or grandTotal

codAmount
├─ Definition: Amount to collect if COD
├─ Example: ₹465 (same as totalBeforePayment)
├─ Field Name: codAmount or codValue
└─ Note: Only if paymentMode = 'cod'
```

---

## 📊 COMPLETE EXAMPLE BREAKDOWN

### Order Details:
```
Item 1: Blue Notebook
  - Base Price (MRP): ₹100
  - SKU Selling Price: ₹90
  - Quantity: 2
  - Item Subtotal (at MRP): ₹100 × 2 = ₹200
  - Item Subtotal (at selling price): ₹90 × 2 = ₹180
  - Auto Discount on Item: (₹100 - ₹90) × 2 = ₹20

Item 2: Red Pencil Set
  - Base Price (MRP): ₹150
  - SKU Selling Price: ₹150 (no auto discount)
  - Quantity: 1
  - Item Subtotal (at MRP): ₹150 × 1 = ₹150
  - Item Subtotal (at selling price): ₹150 × 1 = ₹150
  - Auto Discount on Item: (₹150 - ₹150) × 1 = ₹0

Coupon: SAVE50 = ₹50 additional discount
Delivery: ₹80
Wallet: ₹100
```

### Calculation (CORRECT - No Double Counting):
```
┌─────────────────────────────────────┐
│ BREAKDOWN (CORRECTED)               │
├─────────────────────────────────────┤
│ Item 1 (MRP basis):     ₹200        │
│ Item 2 (MRP basis):     ₹150        │
├─────────────────────────────────────┤
│ ORDER SUBTOTAL (MRP):   ₹350        │
├─────────────────────────────────────┤
│ Auto Discount (SKU):    -₹20        │
│ Coupon Discount:        -₹50        │
│ TOTAL DISCOUNT:         -₹70        │
├─────────────────────────────────────┤
│ Subtotal After All      │
│ Discounts:              ₹280        │
├─────────────────────────────────────┤
│ Delivery Fee:           +₹80        │
├─────────────────────────────────────┤
│ TOTAL BEFORE PAYMENT:   ₹360        │
├─────────────────────────────────────┤
│ Paid by Wallet:         -₹100       │
│ Paid Online (Razorpay): -₹260       │
├─────────────────────────────────────┤
│ BALANCE:                ₹0 (Paid)   │
└─────────────────────────────────────┘
```

### Field Names (Correct - No Double Counting):
```json
{
  "orderSummary": {
    "items": [
      {
        "productId": "NOTEBOOK-001",
        "skuId": "NOTEBOOK-BLUE-A4",
        "name": "Blue Notebook",
        "productBasePrice": 100,
        "productCurrentPrice": 90,
        "quantity": 2,
        "itemSubtotalAtMRP": 200,
        "itemSubtotalAtSellingPrice": 180,
        "itemAutoDiscount": 20,
        "variants": {
          "color": "Blue",
          "size": "A4"
        }
      },
      {
        "productId": "PENCIL-001",
        "skuId": "PENCIL-RED-SET",
        "name": "Red Pencil Set",
        "productBasePrice": 150,
        "productCurrentPrice": 150,
        "quantity": 1,
        "itemSubtotalAtMRP": 150,
        "itemSubtotalAtSellingPrice": 150,
        "itemAutoDiscount": 0,
        "variants": {}
      }
    ],
    "pricing": {
      "orderSubtotal": 350,
      "productDiscount": 20,
      "couponCode": "SAVE50",
      "couponDiscount": 50,
      "totalDiscount": 70,
      "subtotalAfterDiscount": 280,
      "deliveryFee": 80,
      "totalBeforePayment": 360
    },
    "payment": {
      "paymentMode": "partial_wallet",
      "walletPaidAmount": 100,
      "onlinePaidAmount": 260,
      "totalOrderValue": 360
    }
  }
}
```

---

## 🔄 PAYMENT MODE VARIATIONS

### Mode 1: RAZORPAY (Online Payment Only)
```
Calculation:
  onlinePaidAmount = totalBeforePayment (full amount)
  walletPaidAmount = 0
  
Example:
  Total Before Payment: ₹340
  Online (Razorpay): ₹340 ✓
  Wallet: ₹0
```

### Mode 2: COD (Cash on Delivery)
```
Calculation:
  onlinePaidAmount = 0
  walletPaidAmount = 0
  codAmount = totalBeforePayment (to collect)
  
Example:
  Total Before Payment: ₹340
  Online: ₹0
  Wallet: ₹0
  COD Amount: ₹340
```

### Mode 3: WALLET (Full Wallet Payment)
```
Calculation:
  onlinePaidAmount = 0
  walletPaidAmount = totalBeforePayment (full amount)
  
Example:
  Total Before Payment: ₹340
  Online: ₹0
  Wallet: ₹340 ✓
```

### Mode 4: PARTIAL_WALLET (Wallet + Online)
```
Calculation:
  walletPaidAmount = min(walletBalance, totalBeforePayment)
  onlinePaidAmount = totalBeforePayment - walletPaidAmount
  
Example:
  Total Before Payment: ₹340
  Wallet Available: ₹100
  Online (Razorpay): ₹240 ✓
  Wallet: ₹100 ✓
```

---

## ✅ FIELD NAMING CONVENTION

### CORRECT NAMES (Use These):
```
✅ productBasePrice          (MRP, original price)
✅ productCurrentPrice       (SKU selling price)
✅ itemSubtotal             (item price × quantity)
✅ itemDiscount             (discount on item)
✅ orderSubtotal            (sum of all items)
✅ productDiscount          (auto discount from price difference)
✅ couponDiscount           (coupon code discount)
✅ totalDiscount            (sum of all discounts)
✅ subtotalAfterDiscount    (order amount after discounts)
✅ deliveryFee              (shipping cost)
✅ totalBeforePayment       (final amount to pay)
✅ walletPaidAmount         (wallet payment)
✅ onlinePaidAmount         (online payment, Razorpay)
✅ totalOrderValue          (grand total)
✅ paymentMode              ('razorpay'|'cod'|'wallet'|'partial_wallet')
```

### AVOID THESE (Don't Use):
```
❌ finalPayable             (Too vague)
❌ finalAmount              (Ambiguous)
❌ amountSummary            (Generic)
❌ walletUsed               (Unclear context)
❌ discountAmount           (Which discount?)
❌ discount                 (Singular, unclear)
❌ subTotal                 (Inconsistent casing)
```

---

## 📋 DATA CAPTURE CHECKLIST

### At Product Level:
- [ ] Product Base Price (MRP)
- [ ] Product Current Price (SKU selling price)
- [ ] Product ID
- [ ] SKU ID
- [ ] Item Name
- [ ] Item Image
- [ ] Category
- [ ] Brand
- [ ] Quantity
- [ ] Variant Attributes

### At Order Level:
- [ ] Order Subtotal
- [ ] Product Discount (auto)
- [ ] Coupon Code (if any)
- [ ] Coupon Discount
- [ ] Total Discount
- [ ] Delivery Fee
- [ ] Subtotal After Discount
- [ ] Total Before Payment

### At Payment Level:
- [ ] Payment Mode
- [ ] Wallet Available Balance
- [ ] Wallet Paid Amount
- [ ] Online Paid Amount
- [ ] Total Order Value
- [ ] COD Amount (if COD)

### At Address Level:
- [ ] Full Name
- [ ] Phone Number
- [ ] Street Address
- [ ] City
- [ ] State
- [ ] Postal Code
- [ ] Country

---

## 🎯 ORDER SUMMARY DISPLAY FORMAT

### For Customer View:
```
┌───────────────────────────────────────┐
│ ORDER SUMMARY                         │
├───────────────────────────────────────┤
│ Items (at selling prices):            │
│  ✓ Blue Notebook (2×) ₹90   = ₹180    │
│  ✓ Red Pencil Set (1×) ₹150 = ₹150    │
│                                       │
│ Price Breakdown:                      │
│  Item Total (at MRP):  ₹350           │
│  Auto Discount:        -₹20           │
│  Coupon (SAVE50):      -₹50           │
│ ───────────────────────────           │
│  Subtotal After       │
│  Discounts:            ₹280           │
│  Delivery Fee:         +₹80           │
├───────────────────────────────────────┤
│ AMOUNT TO PAY:         ₹360           │
├───────────────────────────────────────┤
│ Payment Method:                       │
│ • Paid by Wallet:      ₹100           │
│ • Paid Online:         ₹260           │
├───────────────────────────────────────┤
│ TOTAL:                 ₹360 ✓ Paid    │
└───────────────────────────────────────┘
```

### For Order Details Screen:
```
{
  "items": [...],
  "itemsSummary": {
    "count": 2,
    "subtotal": ₹330
  },
  "pricingSummary": {
    "productDiscount": ₹20,
    "couponDiscount": ₹50,
    "totalDiscount": ₹70,
    "deliveryFee": ₹80,
    "subtotalAfterDiscount": ₹260
  },
  "paymentSummary": {
    "totalBeforePayment": ₹340,
    "walletPaid": ₹100,
    "onlinePaid": ₹240,
    "paymentMode": "partial_wallet"
  }
}
```

---

## 🔴 CRITICAL: HOW TO AVOID DOUBLE-COUNTING DISCOUNTS

### ❌ WRONG APPROACH (Double Counting):
```
Item Subtotal (at selling price):  ₹330  ← Already discounted!
Auto Discount:                     -₹20  ← Deducting again (WRONG!)
Coupon Discount:                   -₹50
────────────────────────────────────────
Result:                            ₹260  (INCORRECT, undercounted)
```

**Problem:** Selling prices already include the auto-discount, so deducting it again is double-counting in reverse.

### ✅ CORRECT APPROACH (No Double Counting):
```
Order Subtotal (at MRP/base price):  ₹350  ← Use BASE price
Auto Discount:                       -₹20  ← Deduct auto-discount
Coupon Discount:                     -₹50  ← Deduct coupon
────────────────────────────────────────
Subtotal After Discount:             ₹280  ✓ CORRECT!
```

**Solution:** Always calculate `orderSubtotal` using **BASE PRICE (MRP)**, not selling price. Then deduct all discounts once.

### Why This Matters:
```
At MRP basis:
  Order Subtotal = ₹100×2 + ₹150×1 = ₹350
  After all discounts (70) = ₹280
  
At Selling Price basis (WRONG):
  Order Subtotal = ₹90×2 + ₹150×1 = ₹330
  If you deduct discount again = ₹330 - ₹20 - ₹50 = ₹260
  But items already cost ₹90 each, not ₹100!
```

### Key Rule:
**Use ONE of these, not both:**
1. ✅ **orderSubtotal = sum of BASE prices, then deduct discounts**
2. ❌ **orderSubtotal = sum of SELLING prices, then DON'T deduct discounts again**

We use approach #1 because it's clearer for showing price breakdown to users.

---

## 🎯 ITEM LEVEL VS ORDER LEVEL CALCULATIONS

### Item Level (for each product):
```
itemSubtotalAtMRP = productBasePrice × quantity
itemSubtotalAtSellingPrice = productCurrentPrice × quantity
itemAutoDiscount = itemSubtotalAtMRP - itemSubtotalAtSellingPrice
                 = (productBasePrice - productCurrentPrice) × quantity
```

### Order Level (sum of all items):
```
orderSubtotal = SUM(itemSubtotalAtMRP)
productDiscount = SUM(itemAutoDiscount)
couponDiscount = <from coupon code>
totalDiscount = productDiscount + couponDiscount

subtotalAfterDiscount = orderSubtotal - totalDiscount
totalBeforePayment = subtotalAfterDiscount + deliveryFee
```

🔴 **NEVER do this:**
```
orderSubtotal = SUM(itemSubtotalAtSellingPrice)  // WRONG!
Then deduct productDiscount  // DOUBLE COUNTING!
```

---

## ✅ FIELD NAMING SUMMARY

| Field | Use BASE or SELLING? | Deduct Discount? |
|-------|---------------------|------------------|
| `itemSubtotalAtMRP` | BASE | No (informational) |
| `itemSubtotalAtSellingPrice` | SELLING | No (informational) |
| `itemAutoDiscount` | N/A (difference) | N/A (informational) |
| `orderSubtotal` | **BASE** | ✅ Yes, then deduct |
| `productDiscount` | N/A | ✅ Deduct once |
| `couponDiscount` | N/A | ✅ Deduct once |
| `subtotalAfterDiscount` | Both applied | No (already applied) |
| `totalBeforePayment` | Both applied | No (already applied) |

---

## ✨ VALIDATION RULES

### Price Validations:
```
✓ orderSubtotal >= 0
✓ productDiscount >= 0
✓ productDiscount <= orderSubtotal
✓ couponDiscount >= 0
✓ totalDiscount = productDiscount + couponDiscount
✓ totalDiscount <= orderSubtotal
✓ subtotalAfterDiscount = orderSubtotal - totalDiscount
✓ subtotalAfterDiscount >= 0
✓ deliveryFee >= 0
✓ totalBeforePayment = subtotalAfterDiscount + deliveryFee
```

### Payment Validations:
```
✓ walletPaidAmount >= 0
✓ onlinePaidAmount >= 0
✓ (walletPaidAmount + onlinePaidAmount) = totalBeforePayment
✓ For razorpay: walletPaidAmount = 0, onlinePaidAmount = totalBeforePayment
✓ For cod: walletPaidAmount = 0, onlinePaidAmount = 0
✓ For wallet: walletPaidAmount = totalBeforePayment, onlinePaidAmount = 0
✓ For partial_wallet: walletPaidAmount > 0, onlinePaidAmount > 0
```

---

## 📍 IMPLEMENTATION PRIORITY

### Phase 1 - Critical (Must Have):
- Product Base Price & Current Price
- Item Subtotal & Discount
- Order Subtotal
- Total Before Payment
- Payment Mode & Amounts

### Phase 2 - Important (Should Have):
- Coupon Code & Discount
- Delivery Fee
- Variant Attributes
- Category & Brand

### Phase 3 - Nice to Have:
- Product Images
- Delivery Instructions
- Special Instructions

---

**Next:** Implement this structure in Flutter app and Firebase function
