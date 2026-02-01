# 💰 PRICE CALCULATION FORMULA REFERENCE

**Date:** February 1, 2026  
**Purpose:** Quick reference for correct price calculations (NO double-counting)

---

## 🎯 CORRECT FORMULA FLOW

```
┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: CALCULATE ITEM LEVEL VALUES                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ itemSubtotalAtMRP = productBasePrice × quantity                │
│ itemSubtotalAtSellingPrice = productCurrentPrice × quantity    │
│ itemAutoDiscount = itemSubtotalAtMRP - itemSubtotalAtSellingPrice
│                  = (productBasePrice - productCurrentPrice) × qty
│                                                                  │
│ Example (Blue Notebook):                                        │
│   itemSubtotalAtMRP = 100 × 2 = 200                           │
│   itemSubtotalAtSellingPrice = 90 × 2 = 180                   │
│   itemAutoDiscount = 200 - 180 = 20                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 2: CALCULATE ORDER LEVEL SUBTOTALS                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ orderSubtotal = SUM(itemSubtotalAtMRP for all items)          │
│               = ₹200 + ₹150 = ₹350                            │
│                                                                  │
│ 🔴 IMPORTANT: Use MRP, NOT selling price!                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 3: CALCULATE ALL DISCOUNTS (Deducted ONCE)               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ productDiscount = SUM(itemAutoDiscount for all items)         │
│                = ₹20 + ₹0 = ₹20                              │
│                                                                  │
│ couponDiscount = <from coupon code>                           │
│                = ₹50 (SAVE50 coupon)                         │
│                                                                  │
│ totalDiscount = productDiscount + couponDiscount              │
│               = ₹20 + ₹50 = ₹70                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 4: APPLY DISCOUNTS TO GET SUBTOTAL AFTER DISCOUNT        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ subtotalAfterDiscount = orderSubtotal - totalDiscount         │
│                       = ₹350 - ₹70 = ₹280                   │
│                                                                  │
│ ✓ Discounts deducted ONLY ONCE (no double-counting)          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 5: ADD DELIVERY FEE                                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ totalBeforePayment = subtotalAfterDiscount + deliveryFee      │
│                    = ₹280 + ₹80 = ₹360                       │
│                                                                  │
│ This is the final amount customer needs to pay                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ STEP 6: SPLIT PAYMENT (FINAL STEP)                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ walletPaidAmount = min(walletBalance, totalBeforePayment)    │
│                  = min(100, 360) = 100                       │
│                                                                  │
│ onlinePaidAmount = totalBeforePayment - walletPaidAmount     │
│                  = 360 - 100 = 260                          │
│                                                                  │
│ totalOrderValue = totalBeforePayment (for tracking)           │
│                = 360                                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📋 FIELD DEFINITIONS & FORMULAS

### Item Level Fields:

| Field | Formula | Example | Use Case |
|-------|---------|---------|----------|
| `productBasePrice` | Product master data | ₹100 | Show original price |
| `productCurrentPrice` | SKU pricing | ₹90 | What they pay per unit |
| `quantity` | User input | 2 | How many units |
| `itemSubtotalAtMRP` | productBasePrice × qty | ₹200 | Price breakdown reference |
| `itemSubtotalAtSellingPrice` | productCurrentPrice × qty | ₹180 | Informational |
| `itemAutoDiscount` | itemSubtotalAtMRP - itemSubtotalAtSellingPrice | ₹20 | Inform about discount |

### Order Level Fields:

| Field | Formula | Example | Use For |
|-------|---------|---------|---------|
| `orderSubtotal` | SUM(itemSubtotalAtMRP) | ₹350 | Base for discount calculation |
| `productDiscount` | SUM(itemAutoDiscount) | ₹20 | Show auto-discount |
| `couponDiscount` | From coupon record | ₹50 | Show coupon discount |
| `totalDiscount` | productDiscount + couponDiscount | ₹70 | Total savings |
| `subtotalAfterDiscount` | orderSubtotal - totalDiscount | ₹280 | After all discounts |
| `deliveryFee` | Shipping calculation | ₹80 | Shipping cost |
| `totalBeforePayment` | subtotalAfterDiscount + deliveryFee | ₹360 | **Final amount to pay** |

### Payment Fields:

| Field | Formula | Example | Use For |
|-------|---------|---------|---------|
| `walletPaidAmount` | min(wallet balance, totalBeforePayment) | ₹100 | Wallet deduction |
| `onlinePaidAmount` | totalBeforePayment - walletPaidAmount | ₹260 | Razorpay amount |
| `totalOrderValue` | totalBeforePayment | ₹360 | Order tracking/analytics |
| `paymentMode` | User choice | 'partial_wallet' | Payment method |
| `codAmount` | totalBeforePayment (if COD) | ₹360 | Collection amount |

---

## ✅ CALCULATION CHECKLIST

### For Each Item:
- [ ] Capture productBasePrice (MRP)
- [ ] Capture productCurrentPrice (SKU selling price)
- [ ] Capture quantity
- [ ] Calculate itemSubtotalAtMRP = productBasePrice × quantity
- [ ] Calculate itemSubtotalAtSellingPrice = productCurrentPrice × quantity
- [ ] Calculate itemAutoDiscount = itemSubtotalAtMRP - itemSubtotalAtSellingPrice

### For Order:
- [ ] Calculate orderSubtotal = SUM(itemSubtotalAtMRP)
- [ ] Calculate productDiscount = SUM(itemAutoDiscount)
- [ ] Get couponDiscount from coupon code
- [ ] Calculate totalDiscount = productDiscount + couponDiscount
- [ ] Calculate subtotalAfterDiscount = orderSubtotal - totalDiscount
- [ ] Get deliveryFee from shipping calculation
- [ ] Calculate totalBeforePayment = subtotalAfterDiscount + deliveryFee

### For Payment:
- [ ] Get walletBalance from user record
- [ ] Calculate walletPaidAmount = min(walletBalance, totalBeforePayment)
- [ ] Calculate onlinePaidAmount = totalBeforePayment - walletPaidAmount
- [ ] Set totalOrderValue = totalBeforePayment
- [ ] Validate: walletPaidAmount + onlinePaidAmount = totalBeforePayment

---

## 🔴 COMMON MISTAKES & CORRECTIONS

### Mistake 1: Using Selling Price for orderSubtotal
```
❌ WRONG:
  orderSubtotal = ₹90×2 + ₹150×1 = ₹330 (using selling price!)
  Then deduct productDiscount = ₹330 - ₹20 - ₹50 = ₹260

✅ CORRECT:
  orderSubtotal = ₹100×2 + ₹150×1 = ₹350 (using base price!)
  Then deduct productDiscount = ₹350 - ₹20 - ₹50 = ₹280
```

### Mistake 2: Double-counting Discounts
```
❌ WRONG:
  subtotalAfterDiscount = (selling price subtotal) - discount
  = ₹330 - ₹20 - ₹50 = ₹260
  (Discount already in selling price!)

✅ CORRECT:
  subtotalAfterDiscount = (base price subtotal) - discount
  = ₹350 - ₹20 - ₹50 = ₹280
  (Discount applied only once)
```

### Mistake 3: Wrong Delivery Fee Placement
```
❌ WRONG:
  totalBeforePayment = subtotalAfterDiscount (missing delivery!)
  = ₹280

✅ CORRECT:
  totalBeforePayment = subtotalAfterDiscount + deliveryFee
  = ₹280 + ₹80 = ₹360
```

### Mistake 4: Wallet + Online Not Matching Total
```
❌ WRONG:
  walletPaid = ₹100
  onlinePaid = ₹300
  total = ₹360
  Sum = ₹100 + ₹300 = ₹400 ❌ Doesn't match!

✅ CORRECT:
  total = ₹360
  walletPaid = ₹100
  onlinePaid = ₹360 - ₹100 = ₹260
  Sum = ₹100 + ₹260 = ₹360 ✓ Matches!
```

---

## 🎯 IMPLEMENTATION CHECKLIST FOR CODE

### In _prepareOrderItems():
```dart
✓ For each item:
  - Get productBasePrice
  - Get productCurrentPrice
  - Calculate itemAutoDiscount
  - Include in item object
```

### In createOrder() request payload:
```dart
✓ Send pricingSummary with:
  - orderSubtotal (base price sum!)
  - productDiscount
  - couponDiscount
  - totalDiscount
  - subtotalAfterDiscount
  - deliveryFee
  - totalBeforePayment

✓ Send paymentSummary with:
  - walletPaidAmount
  - onlinePaidAmount
  - totalOrderValue
  - paymentMode
```

### In Firebase createOrder():
```typescript
✓ Receive and validate:
  - pricingSummary fields
  - paymentSummary fields
  - Verify formulas match

✓ Save to orders collection:
  - All item details with base/selling prices
  - Complete pricingSummary
  - Complete paymentSummary
  - All validations passed
```

### In Order Details Screen:
```dart
✓ Display:
  - Items with prices
  - Order Subtotal (base price)
  - Product Discount
  - Coupon Discount
  - Subtotal After Discount
  - Delivery Fee
  - Total to Pay
  - Payment breakdown
```

---

## 📊 EXAMPLE: COMPLETE ORDER DATA

```json
{
  "orderId": "ORD1707382400123",
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
      "itemAutoDiscount": 20
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
      "itemAutoDiscount": 0
    }
  ],
  "pricingSummary": {
    "orderSubtotal": 350,
    "productDiscount": 20,
    "couponCode": "SAVE50",
    "couponDiscount": 50,
    "totalDiscount": 70,
    "subtotalAfterDiscount": 280,
    "deliveryFee": 80,
    "totalBeforePayment": 360
  },
  "paymentSummary": {
    "paymentMode": "partial_wallet",
    "walletPaidAmount": 100,
    "onlinePaidAmount": 260,
    "totalOrderValue": 360
  }
}
```

---

## ✨ KEY TAKEAWAYS

1. **Always use BASE PRICE (MRP) for orderSubtotal**
   - Not selling price (which already includes discount)

2. **Calculate discounts separately, apply once**
   - productDiscount + couponDiscount = totalDiscount
   - Deduct totalDiscount from orderSubtotal only once

3. **Add delivery fee after discounts**
   - Formula: subtotalAfterDiscount + deliveryFee = totalBeforePayment

4. **Payment splits must sum to total**
   - walletPaidAmount + onlinePaidAmount = totalBeforePayment

5. **Store both base and selling prices in orders**
   - Helps with analytics and reporting
   - Shows discount to customers
   - No data loss

---

**Status:** Ready for Implementation  
**Last Updated:** February 1, 2026
