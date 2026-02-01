# 🧪 TESTING CHECKLIST - POST IMPLEMENTATION

**Date:** February 1, 2026  
**Status:** Ready for Testing  
**Environment:** All local + Firebase staging

---

## ✅ UNIT TESTS (Pricing Calculation)

### Test 1: Single Product, No Discount
```
Setup:
  - Product: Notebook (MRP ₹100, Selling ₹100)
  - Quantity: 1
  - Coupon: None

Expected:
  itemSubtotalAtMRP: 100
  itemSubtotalAtSellingPrice: 100
  itemAutoDiscount: 0
  orderSubtotal: 100
  productDiscount: 0
  totalDiscount: 0
  subtotalAfterDiscount: 100

Result: [ ] PASS / [ ] FAIL
```

### Test 2: Single Product, With Auto-Discount
```
Setup:
  - Product: Notebook (MRP ₹100, Selling ₹90)
  - Quantity: 2
  - Coupon: None

Expected:
  itemSubtotalAtMRP: 200
  itemSubtotalAtSellingPrice: 180
  itemAutoDiscount: 20
  orderSubtotal: 200
  productDiscount: 20
  totalDiscount: 20
  subtotalAfterDiscount: 180

Result: [ ] PASS / [ ] FAIL
```

### Test 3: Multiple Products, With Both Discounts
```
Setup:
  - Product 1: Notebook (MRP ₹100, Selling ₹90) × 2
  - Product 2: Pencil Set (MRP ₹150, Selling ₹150) × 1
  - Coupon: SAVE50 (₹50 discount)
  - Delivery Fee: ₹80

Expected:
  orderSubtotal: 350  (200 + 150)
  productDiscount: 20  (20 + 0)
  couponDiscount: 50
  totalDiscount: 70   (20 + 50) ← Deducted ONCE
  subtotalAfterDiscount: 280  (350 - 70)
  deliveryFee: 80
  totalBeforePayment: 360  (280 + 80)

Result: [ ] PASS / [ ] FAIL
```

### Test 4: Partial Wallet Payment
```
Setup:
  - From Test 3
  - Wallet Balance: ₹100
  - Payment Mode: partial_wallet

Expected:
  totalBeforePayment: 360
  walletPaidAmount: 100
  onlinePaidAmount: 260
  totalOrderValue: 360
  walletPaidAmount + onlinePaidAmount = 360 ✓

Result: [ ] PASS / [ ] FAIL
```

### Test 5: Full Wallet Payment
```
Setup:
  - From Test 3
  - Wallet Balance: ₹500
  - Payment Mode: wallet

Expected:
  totalBeforePayment: 360
  walletPaidAmount: 360
  onlinePaidAmount: 0
  totalOrderValue: 360

Result: [ ] PASS / [ ] FAIL
```

---

## 🔄 INTEGRATION TESTS (Data Flow)

### Test 6: Cart to Firebase (Razorpay)
```
Steps:
  1. Add 2 products to cart
  2. Click Checkout
  3. Select Razorpay as payment method
  4. Verify Firebase function is called
  5. Check createOrder response

Verify:
  [ ] _prepareOrderItems() calculates correct values
  [ ] pricingSummary has all 8 fields
  [ ] paymentSummary has all 4 fields
  [ ] Items have productId and skuId separate
  [ ] Items have itemSubtotalAtMRP calculated
  [ ] Items have itemAutoDiscount calculated
  [ ] No compilation errors
  [ ] No validation errors in Firebase

Result: [ ] PASS / [ ] FAIL
```

### Test 7: Cart to Firebase (Partial Wallet)
```
Steps:
  1. Add 2 products to cart
  2. Click Checkout
  3. Select Partial Wallet (wallet balance ₹100)
  4. Verify wallet deduction
  5. Check Razorpay amount calculation

Verify:
  [ ] walletPaidAmount = ₹100
  [ ] onlinePaidAmount = totalBeforePayment - 100
  [ ] Razorpay called with correct amount
  [ ] Wallet balance deducted in user document
  [ ] Firebase documents created correctly

Result: [ ] PASS / [ ] FAIL
```

### Test 8: Cart to Firebase (COD)
```
Steps:
  1. Add 2 products to cart
  2. Click Checkout
  3. Select COD
  4. Verify order is created with COD status

Verify:
  [ ] paymentMode = 'cod'
  [ ] walletPaidAmount = 0
  [ ] onlinePaidAmount = totalBeforePayment
  [ ] Order status = 'confirmed'
  [ ] Payment status = 'pending_collection'
  [ ] No Razorpay order created

Result: [ ] PASS / [ ] FAIL
```

### Test 9: Firestore Document Structure
```
Navigate to Firebase Console > orders collection

Verify Document Has:
  [ ] orderId
  [ ] userId
  [ ] paymentMode
  [ ] items array with:
    [ ] productId
    [ ] skuId (separate from productId)
    [ ] productBasePrice
    [ ] productCurrentPrice
    [ ] itemSubtotalAtMRP
    [ ] itemSubtotalAtSellingPrice
    [ ] itemAutoDiscount
    [ ] variants (with all attributes)
    [ ] itemMetadata
  [ ] pricingSummary with all 8 fields:
    [ ] orderSubtotal
    [ ] productDiscount
    [ ] couponDiscount
    [ ] totalDiscount
    [ ] subtotalAfterDiscount
    [ ] deliveryFee
    [ ] totalBeforePayment
  [ ] paymentSummary with all 4 fields:
    [ ] paymentMode
    [ ] walletPaidAmount
    [ ] onlinePaidAmount
    [ ] totalOrderValue

Result: [ ] PASS / [ ] FAIL
```

---

## 📊 VALIDATION TESTS (Firebase Function)

### Test 10: Pricing Formula Validation
```
Check Firebase Function Logs:

Look for:
  [ ] "✅ Pricing formula validation passed:"
  [ ] All formula checks passed
  [ ] orderSubtotal (MRP) = ₹[amount]
  [ ] All discount components shown
  [ ] subtotalAfterDiscount calculation shown
  [ ] totalBeforePayment calculation shown
  [ ] totalOrderValue matches totalBeforePayment

Result: [ ] PASS / [ ] FAIL
```

### Test 11: Validation Error Handling
```
Setup Invalid Request:
  - Send pricingSummary with incorrect totalDiscount
  - totalDiscount ≠ productDiscount + couponDiscount

Expected:
  [ ] Firebase function rejects request
  [ ] Error message shows formula mismatch
  [ ] Order not created
  [ ] Clear error logging

Result: [ ] PASS / [ ] FAIL
```

### Test 12: Payment Amount Validation
```
Setup Partial Wallet with Mismatch:
  - totalBeforePayment: 360
  - walletPaidAmount: 100
  - onlinePaidAmount: 250 (should be 260)

Expected:
  [ ] Firebase function detects mismatch
  [ ] Error thrown: "Total order value... does not match..."
  [ ] Order not created

Result: [ ] PASS / [ ] FAIL
```

---

## 🎨 UI/UX TESTS

### Test 13: Order Details Screen - Price Breakdown
```
After Successful Order:

Verify Displays:
  [ ] Item Total (at MRP): ₹[orderSubtotal]
  [ ] Product Discount: -₹[productDiscount]
  [ ] Coupon Discount: -₹[couponDiscount]
  [ ] Subtotal After Discount: ₹[subtotalAfterDiscount]
  [ ] Delivery Fee: +₹[deliveryFee]
  [ ] Total to Pay: ₹[totalBeforePayment]
  
  [ ] Item wise:
    - Product name
    - Quantity
    - Base Price (MRP)
    - Selling Price
    - Item Total
    - Discount (if any)

Result: [ ] PASS / [ ] FAIL
```

### Test 14: Order Details Screen - Payment Summary
```
After Successful Order:

Verify Displays:
  [ ] Payment Mode: [razorpay/cod/wallet/partial_wallet]
  
  If Partial Wallet:
    [ ] Wallet Used: ₹[walletPaidAmount]
    [ ] Paid by Razorpay: ₹[onlinePaidAmount]
  
  If Wallet Only:
    [ ] Paid from Wallet: ₹[totalBeforePayment]
  
  If COD:
    [ ] Cash to Collect: ₹[totalBeforePayment]
  
  Total Order Value: ₹[totalOrderValue]

Result: [ ] PASS / [ ] FAIL
```

### Test 15: Order Details Screen - Product Info
```
After Successful Order:

Verify Displays:
  [ ] Product images load correctly
  [ ] Product names display
  [ ] Quantities shown
  [ ] Can view variant details (color, size, etc.)
  [ ] Can navigate to product details (if productId linked)

Result: [ ] PASS / [ ] FAIL
```

---

## 🔐 SECURITY TESTS

### Test 16: Data Integrity
```
Verify:
  [ ] No sensitive data in logs
  [ ] All calculations correct
  [ ] No decimal rounding errors (> ₹0.01)
  [ ] User cannot manipulate orderSubtotal
  [ ] User cannot skip discount deduction
  [ ] Wallet balance properly deducted

Result: [ ] PASS / [ ] FAIL
```

### Test 17: Authorization
```
Verify:
  [ ] Only authenticated users can create orders
  [ ] User can only see their own orders
  [ ] User cannot modify order data after creation
  [ ] Cannot access other user's order data

Result: [ ] PASS / / [ ] FAIL
```

---

## 📱 DEVICE TESTS

### Test 18: Multiple Devices
```
Test on:
  [ ] Android Phone (latest)
  [ ] Android Phone (older)
  [ ] iOS iPhone
  [ ] Tablet
  
Verify:
  [ ] No layout issues
  [ ] Prices calculate correctly
  [ ] All fields display properly
  [ ] No data truncation

Result: [ ] PASS / [ ] FAIL
```

### Test 19: Network Conditions
```
Test with:
  [ ] WiFi (fast)
  [ ] 4G (normal)
  [ ] 3G (slow)
  [ ] Poor signal (intermittent)
  
Verify:
  [ ] Data sent correctly
  [ ] No calculation errors
  [ ] Clear error messages if fails
  [ ] Can retry on network failure

Result: [ ] PASS / [ ] FAIL
```

---

## 📈 PERFORMANCE TESTS

### Test 20: Large Cart
```
Setup:
  - 20+ items in cart
  - Various prices and discounts
  
Verify:
  [ ] Calculations complete in < 2 seconds
  [ ] No memory leaks
  [ ] Firebase function responds in < 5 seconds
  [ ] All formulas calculated correctly

Result: [ ] PASS / [ ] FAIL
```

---

## 📋 SIGN-OFF CHECKLIST

Before going to production:

- [ ] All unit tests passed (Tests 1-5)
- [ ] All integration tests passed (Tests 6-9)
- [ ] All validation tests passed (Tests 10-12)
- [ ] All UI/UX tests passed (Tests 13-15)
- [ ] All security tests passed (Tests 16-17)
- [ ] All device tests passed (Test 18)
- [ ] Network condition tests passed (Test 19)
- [ ] Performance tests passed (Test 20)
- [ ] No console errors or warnings
- [ ] No Firebase function errors
- [ ] Documentation updated
- [ ] Code reviewed
- [ ] Database backups created

---

## 📝 Test Results Summary

**Total Tests:** 20  
**Tests Passed:** [ ] / 20  
**Tests Failed:** [ ] / 20  
**Critical Issues:** [ ] / 20  

**Overall Status:**  
[ ] ✅ READY FOR PRODUCTION  
[ ] ⚠️ NEEDS FIXES  
[ ] ❌ NOT READY  

**Date Tested:** ________________  
**Tester Name:** ________________  
**Signature:** ________________  

---

**Notes/Issues Found:**

```
[Space for documenting any issues]
```

---

**Implementation Status:** Complete ✅  
**Ready for Testing:** Yes ✅
