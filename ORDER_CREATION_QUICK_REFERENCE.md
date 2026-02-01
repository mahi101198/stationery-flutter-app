# ⚡ ORDER CREATION DATA QUICK REFERENCE

## 📋 Checklist: What Data is Sent Where?

### 1️⃣ CREATE ORDER FUNCTION
**File:** `lib/services/razorpay_payment_service.dart`

| Data | Captured | Sent to Function |
|------|----------|------------------|
| Product ID (SKU) | ✅ | ✅ (as items[].productId) |
| Item Name | ✅ | ✅ |
| Item Quantity | ✅ | ✅ |
| Item Price | ✅ | ✅ |
| Item Image | ✅ | ✅ |
| Selected Color | ✅ | ✅ (in items[].selectedColor) |
| **SubTotal** | ✅ | ✅ (in amountSummary) |
| **Discount** | ✅ | ✅ (in amountSummary) |
| **Delivery Fee** | ✅ | ✅ (in amountSummary) |
| **Wallet Used** | ✅ | ✅ (in amountSummary) |
| **Final Amount** | ✅ | ✅ (in amountSummary) |
| **Total Order Amount** | ✅ | ✅ (in amountSummary) |
| Coupon Code | ✅ | ✅ |
| Delivery Address | ✅ | ✅ |
| Payment Mode | ✅ | ✅ |
| **Product Base ID** | ❌ | ❌ |
| **Selling Price per SKU** | ❌ | ❌ |
| **Variant Attributes** | ⚠️ (Color only) | ⚠️ (deprecated field) |

---

### 2️⃣ FIREBASE CLOUD FUNCTION
**File:** `functions/razorpay.ts`

| Data | Received | Saved to Firestore | Doc |
|------|----------|-------------------|-----|
| Order ID | ✅ | ✅ | orders |
| User ID | ✅ | ✅ | orders |
| Payment ID | ✅ | ✅ | orders |
| Delivery ID | ✅ | ✅ | orders |
| Item productId | ✅ | ✅ | orders.items[] |
| Item Name | ✅ | ✅ | orders.items[] |
| Item Quantity | ✅ | ✅ | orders.items[] |
| Item Price | ✅ | ✅ | orders.items[] |
| Item Image | ✅ | ✅ | orders.items[] |
| **SubTotal** | ✅ | ✅ | orders.amountBreakdown |
| **Discount** | ✅ | ✅ | orders.amountBreakdown |
| **Delivery Fee** | ✅ | ✅ | orders.amountBreakdown |
| **Wallet Used** | ✅ | ✅ | orders.amountBreakdown |
| **Final Amount** | ✅ | ✅ | orders.amountBreakdown |
| **Total Order Amount** | ✅ | ✅ | orders.amountBreakdown |
| Total Savings | ✅ | ✅ | orders.amountBreakdown |
| Coupon Code | ✅ | ✅ | orders.couponInfo |
| Delivery Address | ✅ | ✅ | orders.deliveryInfo |
| Payment Mode | ✅ | ✅ | orders |
| Order Status | ✅ | ✅ | orders |
| **Product Base ID** | ❌ | ❌ | — |
| **SKU Selling Price** | ❌ | ❌ | — |
| **Variant Details** | ⚠️ | ⚠️ | orders.items[] (wrong field) |

---

### 3️⃣ ORDER DETAILS SCREEN
**File:** `lib/features/order/screens/order_details_screen.dart`

| Data | Available | Displayed |
|------|-----------|-----------|
| Order ID | ✅ | ✅ |
| Order Status | ✅ | ✅ |
| Order Date | ✅ | ✅ |
| Item Name | ✅ | ✅ |
| Item Image | ✅ | ✅ |
| Item Quantity | ✅ | ✅ |
| Item Price | ✅ | ✅ |
| **SubTotal** | ✅ | ✅ |
| **Discount** | ✅ | ✅ |
| **Delivery Fee** | ✅ | ✅ |
| **Wallet Used** | ✅ | ✅ |
| **Final Amount** | ✅ | ✅ |
| **Total Savings** | ✅ | ✅ |
| Coupon Code | ✅ | ✅ |
| Delivery Address | ✅ | ✅ |
| **Item Variants** | ✅ (Color) | ❌ (Not shown) |
| **Product Link** | ❌ | — |
| **SKU Details** | ❌ | — |

---

## 🔴 CRITICAL GAPS

### Gap 1: Product ID Missing
```
NEED: productId for each item (to link to product details page)
HAVE: Only SKU ID stored as "productId"
IMPACT: Can't navigate to product from order details
```

### Gap 2: Selling Price Not Captured
```
NEED: sellingPrice for each item (in case SKU has custom pricing)
HAVE: Only base product price
IMPACT: If SKU has different price, order history shows wrong price
```

### Gap 3: Variant Attributes Misplaced
```
NEED: variantAttributes = {color, size, binding, etc}
HAVE: selectedColor in deprecated field (only color, incomplete)
IMPACT: Can't show full variant details in order history
```

---

## 🟢 WHAT'S PERFECT

### Amount Calculation ✅
```
All amounts captured correctly:
✅ SubTotal (sum of item prices)
✅ Discount (coupon amount)
✅ Delivery Fee (shipping cost)
✅ Wallet Used (wallet payment)
✅ Final Amount (payable amount)
✅ Total Savings (discount + wallet)
```

### Delivery Information ✅
```
Complete address captured:
✅ Name
✅ Phone
✅ Street
✅ City
✅ State
✅ Postal Code
✅ Country
```

### Item Basic Info ✅
```
Each item has:
✅ Product Name
✅ Quantity
✅ Price
✅ Image
```

---

## 📍 WHERE TO MAKE CHANGES

### Priority 1 - High (Essential):
| Issue | File | Lines | Effort |
|-------|------|-------|--------|
| Add SKU ID separately | `razorpay_payment_service.dart` | 90-155 | 30min |
| Save SKU ID in function | `functions/razorpay.ts` | 315-350 | 30min |

### Priority 2 - Medium (Important):
| Issue | File | Lines | Effort |
|-------|------|-------|--------|
| Add sellingPrice capture | `razorpay_payment_service.dart` | 90-155 | 1hr |
| Save sellingPrice in DB | `functions/razorpay.ts` | 315-350 | 30min |

### Priority 3 - Low (Nice to have):
| Issue | File | Lines | Effort |
|-------|------|-------|--------|
| Display variants on screen | `order_details_screen.dart` | ~1100 | 1.5hr |
| Add product link | `order_details_screen.dart` | ~1100 | 1hr |

---

## 🧪 TESTING CHECKPOINTS

### Before Implementation:
1. [ ] Current order displays correctly with amounts
2. [ ] Different payment modes work (Razorpay, COD, Wallet)
3. [ ] All price calculations are accurate

### After Implementation:
1. [ ] Orders have SKU ID separate from product ID
2. [ ] Selling price captured and saved correctly
3. [ ] Variant attributes properly stored
4. [ ] Old orders still load without errors
5. [ ] Order details display correctly with new data

---

## 💾 FIRESTORE STRUCTURE COMPARISON

### Current Order Document:
```javascript
{
  orderId: "ORD1707382400123",
  userId: "user123",
  status: "confirmed",
  paymentMode: "razorpay",
  items: [
    {
      productId: "NB-BLUE-P1",      // ← Ambiguous: is this product or SKU?
      name: "Notebook",
      price: 100,
      quantity: 2,
      subtotal: 200,
      productImage: "...",
      discountPrice: 100,
      totalPrice: 200,
      selectedColor: "Blue",        // ← DEPRECATED field
      itemMetadata: {...}
    }
  ],
  amountBreakdown: {
    subTotal: 200,
    discount: 20,
    deliveryFee: 100,
    walletUsed: 50,
    finalAmount: 230,
    totalOrderAmount: 280,
    totalSavings: 70
  },
  couponInfo: {...},
  deliveryInfo: {...},
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### Recommended Order Document:
```javascript
{
  orderId: "ORD1707382400123",
  userId: "user123",
  status: "confirmed",
  paymentMode: "razorpay",
  items: [
    {
      productId: "PROD-NOTEBOOK-001",   // ← Clear: Product ID
      skuId: "NB-BLUE-P1",              // ← Clear: SKU ID
      name: "Notebook",
      price: 100,
      sellingPrice: 150,                // ← SKU-specific price (if different)
      quantity: 2,
      subtotal: 200,
      productImage: "...",
      discountPrice: 150,
      totalPrice: 300,
      variantAttributes: {              // ← Clear structure
        color: "Blue",
        size: "A4",
        binding: "Spiral"
      },
      itemMetadata: {
        originalPrice: 100,
        sellingPrice: 150,
        appliedDiscount: 0,
        variantDetails: {color: "Blue", size: "A4", binding: "Spiral"},
        category: "Stationery",
        brand: "Premium"
      }
    }
  ],
  amountBreakdown: {
    subTotal: 200,
    discount: 20,
    deliveryFee: 100,
    walletUsed: 50,
    finalAmount: 230,
    totalOrderAmount: 280,
    totalSavings: 70
  },
  couponInfo: {...},
  deliveryInfo: {...},
  createdAt: timestamp,
  updatedAt: timestamp
}
```

---

## ⚡ QUICK ANSWERS

**Q: Is selling price being sent to create order?**  
A: No. Only base product price is sent.

**Q: Is product ID stored in orders?**  
A: No. Only SKU ID (stored as productId, which is confusing).

**Q: Are variant attributes being saved?**  
A: Partially. Only selectedColor is saved, and it's in a deprecated field.

**Q: Can you display color in order details?**  
A: The data exists but isn't being displayed on screen.

**Q: Can you link to product from order?**  
A: No. There's no product ID stored to link with.

**Q: Are all payment modes capturing the same data?**  
A: Yes. All payment modes (Razorpay, COD, Wallet, Partial Wallet) use the same flow.

**Q: Is discount being saved?**  
A: Yes, completely. In amountBreakdown.discount.

**Q: Is delivery fee being saved?**  
A: Yes, completely. In amountBreakdown.deliveryFee.

---

**Created:** February 1, 2026  
**Status:** Analysis Complete  
**Next:** Implement recommended changes
