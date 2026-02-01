# Root Cause Analysis: Order Creation Data Flow

## 📊 Complete Data Flow Trace

### Step 1: Cart Items (Client Side)
**Source:** `lib/data/models/cart_model.dart` (CartItem model)

```dart
// CartItem Structure in Flutter
CartItem {
  productId: string;           // Product ID
  quantity: number;
  selectedColor?: string;      // Optional: selected color
  // Other fields like SKU, price from product cache
}
```

---

### Step 2: Razorpay Service Prepares Items
**Source:** `lib/services/razorpay_payment_service.dart` - `_prepareOrderItems()` (Lines 62-215)

#### ✅ What Flutter Sends:
```dart
List<Map<String, dynamic>> items = [
  {
    'productId': string,
    'skuId': string,
    'quantity': number,
    'name': string,
    'category': string,
    'brand': string,
    'productBasePrice': number,           // MRP
    'productCurrentPrice': number,        // Current selling price
    'itemSubtotalAtMRP': number,         // quantity × productBasePrice
    'itemSubtotalAtSellingPrice': number, // quantity × productCurrentPrice
    'itemAutoDiscount': number,          // MRP - selling price difference
    'productImage': string,
    'selectedColor': string?,             // Optional
    'variants': { 'color': string }?      // Optional
  }
]
```

---

### Step 3: Price Summary Calculation
**Source:** `lib/services/razorpay_payment_service.dart` - `initiatePaymentWithMode()` (Lines 252-280)

#### ✅ What Flutter Sends:
```dart
Map<String, dynamic> pricingSummary = {
  'orderSubtotal': double,              // SUM of itemSubtotalAtMRP
  'productDiscount': double,            // SUM of itemAutoDiscount
  'couponCode': string?,                // Applied coupon code
  'couponDiscount': double,             // Coupon discount amount
  'totalDiscount': double,              // productDiscount + couponDiscount
  'subtotalAfterDiscount': double,      // orderSubtotal - totalDiscount
  'deliveryFee': double,
  'totalBeforePayment': double          // subtotalAfterDiscount + deliveryFee
}

Map<String, dynamic> paymentSummary = {
  'paymentMode': 'razorpay'|'cod'|'wallet'|'partial_wallet',
  'walletPaidAmount': double,           // Amount deducted from wallet
  'onlinePaidAmount': double,           // Amount to pay online
  'totalOrderValue': double             // Total = walletPaidAmount + onlinePaidAmount
}
```

---

### Step 4: Delivery Address
**Source:** `lib/services/razorpay_payment_service.dart` - Lines 240-248

#### ✅ What Flutter Sends:
```dart
Map<String, dynamic> addressData = {
  'id': string,
  'name': string,
  'phoneNumber': string,                // From UserAddress
  'street': string,                     // line1 + line2
  'city': string,
  'state': string,
  'postalCode': string,                 // From pincode field
  'country': string
}
```

---

### Step 5: Firebase Function Call
**Source:** `lib/services/razorpay_payment_service.dart` - Lines 301-307

#### ✅ What Flutter Sends to Firebase:
```dart
final callable = _functions.httpsCallable('createOrder');
final result = await callable.call({
  'items': items,                       // Array of prepared items
  'pricingSummary': pricingSummary,    // Pricing breakdown
  'paymentSummary': paymentSummary,    // Payment breakdown
  'currency': 'INR',
  'paymentMode': paymentMode,
  'deliveryAddress': addressData       // Delivery address
});
```

---

### Step 6: Firebase Function Validation
**Source:** `functions/razorpay.ts` - `createOrder()` (Lines 57-190)

#### ✅ What Firebase Expects:
```typescript
{
  items: Array<{
    productId: string,
    skuId: string,
    name: string,
    quantity: number,
    category?: string,
    brand?: string,
    productBasePrice?: number,
    productCurrentPrice?: number,
    itemSubtotalAtMRP?: number,
    itemSubtotalAtSellingPrice?: number,
    itemAutoDiscount?: number,
    productImage?: string,
    variants?: any
  }>,
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
  paymentSummary: {
    paymentMode: string,
    walletPaidAmount: number,
    onlinePaidAmount: number,
    totalOrderValue: number
  },
  paymentMode: 'razorpay' | 'cod' | 'wallet' | 'partial_wallet',
  deliveryAddress: {
    id: string,
    name: string,
    phoneNumber: string,
    street: string,
    city: string,
    state: string,
    postalCode: string,
    country: string
  },
  paymentDetails?: { gateway?: string; transactionId?: string; status?: string },
  currency?: string
}
```

---

## 🎯 Validation Rules in Firebase

### Required Field Validations:
```
❌ !items || !Array.isArray(items) || items.length === 0
   → Error: "Items array is required"

❌ !paymentMode
   → Error: "Payment mode is required"

❌ !deliveryAddress
   → Error: "Delivery address is required"

❌ !pricingSummary
   → Error: "pricingSummary is required"

❌ !paymentSummary
   → Error: "paymentSummary is required"
```

### Delivery Address Validations:
```
❌ Missing: name, phoneNumber, street, city, state, postalCode, country
   → Error: "Delivery address must include: name, phoneNumber, street, city, state, postalCode, country"
```

### Pricing Validations:
```
❌ orderSubtotal <= 0
   → Error: "Order subtotal must be greater than 0"

❌ totalDiscount < 0
   → Error: "Total discount cannot be negative"

❌ deliveryFee < 0
   → Error: "Delivery fee cannot be negative"

❌ totalOrderValue <= 0
   → Error: "Total order value must be greater than 0"
```

### Pricing Formula Validations:
```
✅ subtotalAfterDiscount = orderSubtotal - totalDiscount
❌ If not equal (within 0.01): 
   → Error: "subtotalAfterDiscount calculation error: expected X, got Y"

✅ totalBeforePayment = subtotalAfterDiscount + deliveryFee
❌ If not equal (within 0.01):
   → Error: "totalBeforePayment calculation error: expected X, got Y"

✅ totalOrderValue = totalBeforePayment
❌ If not equal (within 0.01):
   → Error: "totalOrderValue does not match totalBeforePayment: X vs Y"

✅ productDiscount + couponDiscount = totalDiscount
❌ If not equal (within 0.01):
   → Error: "totalDiscount calculation error: productDiscount(X) + couponDiscount(Y) = Z, but got W"
```

### Payment Mode Validations:
```
❌ paymentMode === 'wallet' && walletPaidAmount <= 0
   → Error: "Wallet amount must be positive for wallet payment mode"

❌ paymentMode === 'wallet' && onlinePaidAmount !== 0
   → Error: "Online amount must be 0 for wallet-only payment"

❌ paymentMode === 'cod' && walletPaidAmount !== 0
   → Error: "Wallet amount must be 0 for COD payment"

❌ paymentMode === 'razorpay' && walletPaidAmount !== 0
   → Error: "Wallet amount must be 0 for razorpay payment"

❌ paymentMode === 'partial_wallet' && walletPaidAmount <= 0
   → Error: "Valid wallet amount is required for partial wallet payment"

❌ paymentMode === 'partial_wallet' && onlinePaidAmount <= 0
   → Error: "Valid online amount is required for partial wallet payment"

❌ paymentMode === 'partial_wallet' && (walletPaidAmount + onlinePaidAmount) !== totalOrderValue
   → Error: "Total order value (X) does not match wallet (Y) + online (Z) = W"
```

---

## 🔍 Common Issues & Root Causes

### Issue 1: Missing Items Array
**Symptom:** "Items array is required"
**Root Cause:** Items not being prepared or passed as empty array
**Check:** In `razorpay_payment_service.dart` line 237 - verify `_prepareOrderItems()` returns non-empty list

### Issue 2: Invalid Pricing Calculations
**Symptom:** "subtotalAfterDiscount calculation error"
**Root Cause:** Flutter calculating pricing incorrectly
**Check:** Verify formula at line 271-272:
```dart
final double orderSubtotal = items.fold<double>(0, (sum, item) => 
  sum + (item['itemSubtotalAtMRP'] as double? ?? 0));
```

### Issue 3: Payment Mode Mismatch
**Symptom:** "Wallet amount must be 0 for razorpay payment"
**Root Cause:** walletPaidAmount being sent when it should be 0
**Check:** In `payment_controller.dart` - verify `walletUsed` parameter is 0 for non-wallet modes

### Issue 4: Missing Delivery Address Fields
**Symptom:** "Delivery address must include: name, phoneNumber, street, city, state, postalCode, country"
**Root Cause:** Address object missing required fields
**Check:** Lines 240-248 in `razorpay_payment_service.dart` - ensure all fields are non-null/non-empty

### Issue 5: Negative or Zero Amounts
**Symptom:** "Order subtotal must be greater than 0"
**Root Cause:** Product prices not being fetched correctly, falling back to 0.0
**Check:** Lines 125-140 in `razorpay_payment_service.dart` - product fetch may be failing

---

## 🐛 Debug Checklist

### When User Gets Error:
1. **Check Firebase Console Logs**
   - Go to Cloud Functions → createOrder → Logs tab
   - Look for exact error message

2. **Check Flutter Console Output**
   - Search for "FIREBASE FUNCTION: createOrder"
   - Look for "CALLING FIREBASE FUNCTION" section
   - Check "Prepared items for Firebase Function" section

3. **Verify Each Component:**
   - [ ] Items array is not empty
   - [ ] All items have productId, skuId, quantity, name
   - [ ] All items have positive price values
   - [ ] pricingSummary has all 8 required fields
   - [ ] paymentSummary has all 4 required fields
   - [ ] deliveryAddress has all 7 required fields
   - [ ] Pricing formulas are correct (within 0.01)
   - [ ] Payment mode matches wallet amounts

4. **Common Product Fetch Issue:**
   - If items have productBasePrice: 0.0, productFetch failed
   - Check product cache service
   - Check product IDs are correct

---

## 📋 Data Type Requirements

All values must be proper types:
- **String fields:** name, city, state, etc. must be strings, not null
- **Number fields:** prices, amounts must be number/double, not strings
- **Array fields:** items must be Array<Map>, not string
- **Boolean fields:** isPartialWalletPayment must be boolean, not string

---

## 🚀 Testing the Fix

After identifying issue:

1. **Check Flutter Logs First**
   - Run app with full logs
   - Hit "Place Order" 
   - Watch console output in steps 1-6 above
   - Identify which step produces wrong data

2. **Compare with Firebase Logs**
   - Firebase function logs will show what was received
   - Compare Flutter's "items being sent" with Firebase's "items received"

3. **Add Breakpoints**
   - In `initiatePaymentWithMode()` at line 301
   - Step through and inspect all payload fields before sending

---

## 📝 Summary

The data flow is correct in structure, but validation fails when:
1. Items array is empty
2. Product details not fetched (prices = 0)
3. Pricing calculations don't match formulas
4. Payment mode inconsistent with wallet amounts
5. Delivery address missing required fields

**Next Step:** Share the exact error message you're getting, and we can pinpoint which validation is failing! 🎯
