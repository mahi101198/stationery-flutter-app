# 📍 Quick Reference: Data Flow Issue Locations

## 🔴 Where Orders Fail: 5 Key Locations

### Location 1: Item Preparation Fails ❌
**File:** `lib/services/razorpay_payment_service.dart`
**Lines:** 62-215 (Function: `_prepareOrderItems()`)
**Issue:** Products not fetching, returning 0 prices

```dart
// Line 73: Product fetch happens here
final products = await _productService.getProductsByIds(cartProductIds);

// Line 137-140: If product not found, sets 0.0 prices
print('⚠️ Product details NOT found for ${cartItem.productId}');
'productBasePrice': 0.0,  // ❌ PROBLEM: Prices are 0
'productCurrentPrice': 0.0,
```

**Fix Needed:**
- [ ] Verify product cache service working
- [ ] Check product IDs are correct
- [ ] Test product fetch separately

---

### Location 2: Pricing Calculation Error ❌
**File:** `lib/services/razorpay_payment_service.dart`
**Lines:** 252-280 (In `initiatePaymentWithMode()`)
**Issue:** Math doesn't match expected formulas

```dart
// Line 271-280: Pricing calculation
final double orderSubtotal = items.fold<double>(0, (sum, item) => 
  sum + (item['itemSubtotalAtMRP'] as double? ?? 0));

final double productDiscount = items.fold<double>(0, (sum, item) =>
  sum + (item['itemAutoDiscount'] as double? ?? 0));

final double totalDiscount = productDiscount + discount;

final double subtotalAfterDiscount = orderSubtotal - totalDiscount;
// ❌ CHECK: Must equal orderSubtotal - totalDiscount exactly

final double totalBeforePayment = subtotalAfterDiscount + deliveryFee;
// ❌ CHECK: Must equal subtotalAfterDiscount + deliveryFee exactly
```

**Formulas that MUST be correct:**
1. `subtotalAfterDiscount = orderSubtotal - totalDiscount`
2. `totalBeforePayment = subtotalAfterDiscount + deliveryFee`
3. `totalOrderValue = totalBeforePayment`
4. `totalDiscount = productDiscount + couponDiscount`

**Fix Needed:**
- [ ] Verify all formulas are exact matches
- [ ] Check for floating point rounding issues
- [ ] Ensure no missing or extra additions

---

### Location 3: Address Missing Required Fields ❌
**File:** `lib/services/razorpay_payment_service.dart`
**Lines:** 240-248 (In `initiatePaymentWithMode()`)
**Issue:** One or more address fields are null/empty

```dart
// Line 240-248: Address building
final addressData = {
  'id': deliveryAddress.id,                    // ❌ Check: Not null?
  'name': deliveryAddress.name,               // ❌ Check: Not empty?
  'phoneNumber': deliveryAddress.phoneNumber ?? 
                 deliveryAddress.mobileNumber ?? '',  // ❌ Check: Not null?
  'street': '${deliveryAddress.line1}${
    deliveryAddress.line2.isNotEmpty ? ', ${deliveryAddress.line2}' : ''}',
    // ❌ Check: line1 not empty?
  'city': deliveryAddress.city,               // ❌ Check: Not empty?
  'state': deliveryAddress.state,             // ❌ Check: Not empty?
  'postalCode': deliveryAddress.pincode,      // ❌ Check: Not empty?
  'country': deliveryAddress.country,         // ❌ Check: Not empty?
};
```

**Required Fields (ALL 7 MUST have values):**
1. id
2. name
3. phoneNumber
4. street
5. city
6. state
7. postalCode
8. country

**Fix Needed:**
- [ ] Ensure all address fields filled in checkout form
- [ ] Verify no empty string values being passed
- [ ] Check address validation in checkout screen

---

### Location 4: Payment Mode Mismatch ❌
**File:** `lib/features/checkout/controllers/payment_controller.dart`
**Lines:** 60-90 (In `processPayment()`)
**Issue:** Payment mode doesn't match wallet amounts

```dart
// Line 73-90: Payment mode routing
if (_selectedPaymentMethod.value == 'wallet') {
  await _processWalletPayment(...);
  // ❌ MUST HAVE: walletUsed > 0, onlinePaidAmount = 0
  
} else if (_selectedPaymentMethod.value == 'partial_wallet') {
  await _processPartialWalletPayment(...);
  // ❌ MUST HAVE: walletUsed > 0 AND onlinePaidAmount > 0
  
} else if (_selectedPaymentMethod.value == 'razorpay') {
  await _processRazorpayPayment(...);
  // ❌ MUST HAVE: walletUsed = 0, onlinePaidAmount > 0
  
} else if (_selectedPaymentMethod.value == 'cod') {
  await _processCODPayment(...);
  // ❌ MUST HAVE: walletUsed = 0, onlinePaidAmount > 0
}
```

**Rules:**
- `razorpay`: walletPaidAmount = 0, onlinePaidAmount > 0
- `cod`: walletPaidAmount = 0, onlinePaidAmount > 0
- `wallet`: walletPaidAmount > 0, onlinePaidAmount = 0
- `partial_wallet`: walletPaidAmount > 0, onlinePaidAmount > 0

**Fix Needed:**
- [ ] Verify correct payment method selected
- [ ] Check wallet amounts match payment mode
- [ ] Ensure calculations don't send wallet amount for razorpay

---

### Location 5: Firebase Function Validation ❌
**File:** `functions/razorpay.ts`
**Lines:** 57-350 (Function: `createOrder()`)
**Issue:** Firebase rejects payload due to validation failure

```typescript
// Line 100-130: Required field validation
if (!items || !Array.isArray(items) || items.length === 0) {
  throw new Error('Items array is required');  // ❌ Items missing/empty
}

if (!deliveryAddress.name || !deliveryAddress.phoneNumber || ...) {
  throw new Error('Delivery address must include: ...');  // ❌ Address fields missing
}

// Line 160-180: Pricing formula validation
const expectedSubtotalAfterDiscount = orderSubtotal - totalDiscount;
if (Math.abs(subtotalAfterDiscount - expectedSubtotalAfterDiscount) > 0.01) {
  throw new Error(`subtotalAfterDiscount calculation error: ...`);
  // ❌ Pricing math wrong
}

// Line 220-250: Payment mode validation
if (paymentMode === 'razorpay' && walletPaidAmount !== 0) {
  throw new Error('Wallet amount must be 0 for razorpay payment');
  // ❌ Payment mode mismatch
}
```

**Common Validation Failures:**
- ❌ Items array empty
- ❌ Pricing formulas incorrect
- ❌ Address fields missing
- ❌ Payment mode doesn't match wallet amounts
- ❌ Negative amounts

**Fix Needed:**
- [ ] Fix issues in Flutter (Locations 1-4 above)
- [ ] Re-test order creation
- [ ] Check Firebase logs for exact validation failure

---

## 🔍 Debugging Checklist

### Quick Check (1 minute):
- [ ] Open Flutter console
- [ ] Try creating an order
- [ ] Search for: `❌ FIREBASE FUNCTION RETURNED FAILURE`
- [ ] Copy the error message
- [ ] Match error to location above

### Medium Check (5 minutes):
- [ ] Enable full console output
- [ ] Look for: `🔍 Prepared items for Firebase Function`
- [ ] Check if prices show 0.0 → Location 1 issue
- [ ] Check address fields → Location 3 issue
- [ ] Check pricing math → Location 2 issue

### Deep Check (15 minutes):
- [ ] Put breakpoint at line 237 in `razorpay_payment_service.dart`
- [ ] Step through `_prepareOrderItems()` execution
- [ ] Verify products are fetched
- [ ] Verify prices are populated
- [ ] Step to line 301 and inspect all payload fields

---

## 📊 Error Message → Location Mapping

| Error Message | Location | Line Numbers |
|---------------|----------|--------------|
| Items array is required | 1 | 100 (razorpay.ts) |
| Product details NOT found | 1 | 137-140 |
| Order subtotal must be greater than 0 | 1 | 103-105 (razorpay.ts) |
| subtotalAfterDiscount calculation error | 2 | 160-165 (razorpay.ts) |
| totalBeforePayment calculation error | 2 | 167-172 (razorpay.ts) |
| Delivery address must include: ... | 3 | 240-248 |
| Wallet amount must be 0 for razorpay | 4 | 220-226 (razorpay.ts) |
| totalOrderValue does not match ... | 2 | 175-178 (razorpay.ts) |

---

## 🎯 Step-by-Step Fix Process

### Step 1: Identify the error
```
Search console for: ❌ FIREBASE FUNCTION RETURNED FAILURE
Copy the error message
```

### Step 2: Locate the issue
```
Use the "Error Message → Location Mapping" table above
Go to the file and line numbers
```

### Step 3: Add debugging
```dart
// Add before the problematic code:
print('🔍 DEBUG: [variable name] = $variable');

// For example:
print('🔍 DEBUG: productBasePrice = $productBasePrice');
print('🔍 DEBUG: deliveryAddress.city = ${deliveryAddress.city}');
print('🔍 DEBUG: paymentMode = $paymentMode, walletUsed = $walletUsed');
```

### Step 4: Run and check
```
Run app again
Look for your debug print statements
Compare actual values with expected values
```

### Step 5: Fix the issue
```
Make the necessary code changes
Re-run and verify order creation succeeds
```

---

## 💡 Common Fixes by Location

### Location 1 (Item Preparation) Fix:
```dart
// Problem: Products not fetching
// Solution: Check product cache service

// Add logging:
print('🔍 CartItem productId: ${cartItem.productId}');
print('🔍 Fetched products count: ${products.length}');
for (var p in products) {
  print('  - ${p.productId}: ${p.price}');
}
```

### Location 2 (Pricing Calculation) Fix:
```dart
// Problem: Math doesn't match
// Solution: Verify formulas exactly

print('orderSubtotal: $orderSubtotal');
print('totalDiscount: $totalDiscount');
print('subtotalAfterDiscount: $subtotalAfterDiscount');
print('Expected: ${orderSubtotal - totalDiscount}');
```

### Location 3 (Address Missing) Fix:
```dart
// Problem: Address fields null/empty
// Solution: Check address form completely filled

print('🔍 Address validation:');
print('  city: ${deliveryAddress.city}');
print('  state: ${deliveryAddress.state}');
print('  pincode: ${deliveryAddress.pincode}');
// Ensure none are empty
```

### Location 4 (Payment Mode) Fix:
```dart
// Problem: Payment mode mismatched amounts
// Solution: Verify mode matches wallet usage

print('paymentMode: $paymentMode');
print('walletUsed: $walletUsed');
print('finalPayable: $finalPayable');
// For razorpay: walletUsed must be 0
```

---

## 📞 When Asking for Help

Provide this information:

```
Error: [EXACT ERROR MESSAGE]

Location: [FILE NAME]:[LINE NUMBER]

Console Output (from 🔵 to ❌):
[PASTE FULL CONSOLE OUTPUT]

Device: [iOS/Android/Emulator]
Payment Method: [razorpay/cod/wallet/partial_wallet]
```

---

## ✅ Success Indicators

Order creation is working when you see:
```
✅ FIREBASE FUNCTION RESPONSE RECEIVED
✅ success: true
✅ orderId: ORD...
✅ paymentId: PAY...
🚀 Opening Razorpay checkout UI...
```

---

**Last Updated:** [Current Date]
**Status:** Complete root cause analysis
**Next Step:** Identify your specific error and fix using location guide above
