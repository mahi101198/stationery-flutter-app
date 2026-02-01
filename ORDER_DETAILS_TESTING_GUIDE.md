# Order Details Screen - Testing & Verification Guide

## Test Case 1: Verify Order Status Displays Correctly

### Steps:
1. Create an order via Razorpay payment
2. Note the order ID
3. Open "My Orders" screen
4. Click on the order
5. Wait for Order Details to load

### Expected Results:
```
Console Logs:
📦 OrderDetailsScreen: Loading order details for: ORD1735...
✅ OrderDetailsScreen: Order data loaded successfully
📊 Order Data Keys: [orderId, userId, status, items, amountBreakdown, ...]
📊 Order Status: confirmed  (or other valid status)
📊 Items Count: 2

UI Display:
- Status card shows with correct color
- Status message is appropriate
- Status icon is visible
```

### Failure Indicators:
- ❌ `⚠️ WARNING: Status is empty, using pending as default`
- ❌ Status card doesn't appear
- ❌ Wrong color for status
- ❌ Console shows: `📊 Order Status: null`

---

## Test Case 2: Verify Items Render with All Details

### Steps:
1. Open order details (from Test Case 1)
2. Scroll to "Items" section
3. Verify each item shows:
   - Product image
   - Product name
   - Quantity
   - Price
   - Total price

### Expected Results:
```
Console Logs (for 2 items):
🔍 Item 0: [productId, name, price, quantity, totalPrice, productImage, ...]
   - productId: prod123
   - name: Notebook Pack
   - price: 150
   - quantity: 2
   - totalPrice: 300
   - productImage: https://firebase...

🔍 Item 1: [productId, name, price, quantity, totalPrice, productImage, ...]
   - productId: prod456
   - name: Pen Set
   - price: 200
   - quantity: 1
   - totalPrice: 200
   - productImage: https://firebase...

UI Display:
✓ 2 items showing in card
✓ Each item has image, name, qty, price
✓ No blank items
✓ Images load properly
```

### Failure Indicators:
- ❌ `⚠️ WARNING: No items found in order`
- ❌ `⚠️ WARNING: Item 0 has no image URL`
- ❌ Blank product names
- ❌ Missing or broken images
- ❌ Console shows: `📊 Items Count: 0`

---

## Test Case 3: Verify Pricing Breakdown

### Steps:
1. Open order details
2. Scroll to "Detailed Price Breakdown" section
3. Verify all amounts match:
   - Items Subtotal
   - Discount (if applied)
   - Delivery Fee
   - Final Amount

### Expected Results:
```
Console Logs:
🔍 _buildDetailedPricingBreakdown: amountBreakdown keys: 
  [subTotal, discount, deliveryFee, walletUsed, finalAmount, totalSavings]

📊 Price Breakdown:
   - subTotal: ₹500
   - discount: ₹50
   - deliveryFee: ₹100
   - walletUsed: ₹0
   - finalAmount: ₹550
   - totalSavings: ₹50

UI Display:
✓ Items Subtotal: ₹500
✓ Discount: ₹50
✓ Delivery Fee: ₹100
✓ Final Amount: ₹550
✓ Calculation correct: 500 - 50 + 100 = 550
```

### Failure Indicators:
- ❌ `⚠️ WARNING: amountBreakdown is null`
- ❌ Some amounts showing as ₹0 when they shouldn't
- ❌ Console shows: `amountBreakdown keys: []`
- ❌ Missing price breakdown section
- ❌ Calculation mismatch

---

## Test Case 4: Verify Delivery Address

### Steps:
1. Open order details
2. Scroll to "Delivery Address" section
3. Verify all address details:
   - Recipient name
   - Street address
   - City/State
   - Pin code
   - Phone number

### Expected Results:
```
UI Display:
✓ Full address visible
✓ Name matches user
✓ All fields populated
✓ Phone number valid format
✓ Pin code 6 digits
```

### Failure Indicators:
- ❌ Missing delivery address section
- ❌ Partial address (empty fields)
- ❌ Address card crashes
- ❌ Shows "null" or "undefined"

---

## Test Case 5: Test Different Order Statuses

### Steps:
1. Create orders with different payment methods:
   - Razorpay → Status: `processing_payment` → `confirmed`
   - COD → Status: `confirmed` immediately
   - Wallet → Status: `confirmed` immediately

2. Check order details for each

### Expected Results:

**Razorpay Order:**
```
- Initial status: processing_payment
- After payment: confirmed
- Status color: Blue
- Status message: "Your order has been confirmed and is being prepared"
```

**COD Order:**
```
- Initial status: confirmed
- Status color: Green
- Status message: "Your order has been confirmed and is being prepared"
```

**Wallet Order:**
```
- Initial status: confirmed
- Status color: Green
- Status message: "Your order has been confirmed and is being prepared"
```

### Failure Indicators:
- ❌ Status doesn't update after payment
- ❌ Wrong status color
- ❌ Wrong status message
- ❌ All orders show "pending" status

---

## Test Case 6: Test with Empty/Missing Fields

### Steps (Simulated):
1. Manually edit Firestore document to test edge cases
2. Remove `productImage` from an item
3. Remove `items` array
4. Remove `amountBreakdown`
5. Set `status` to null

### Expected Results:

**Missing Image:**
```
Console:
⚠️ WARNING: Item 0 has no image URL: Notebook Pack

UI:
✓ Product still shows
✓ Fallback image placeholder appears
✓ No crash
```

**Empty Items:**
```
Console:
⚠️ WARNING: No items found in order

UI:
✓ Shows "No items in this order" message
✓ Card displays properly
✓ No crash
```

**Null Status:**
```
Console:
⚠️ WARNING: Status is empty, using pending as default
📊 Order Status: pending

UI:
✓ Shows "Pending" status
✓ Uses correct color for pending
✓ No crash
```

**Missing amountBreakdown:**
```
Console:
⚠️ WARNING: amountBreakdown is null

UI:
✓ Shows all amounts as ₹0
✓ Breakdown section still displays
✓ No crash
```

---

## Test Case 7: Performance Test

### Steps:
1. Create order with 20+ items
2. Open order details
3. Scroll through the screen
4. Monitor:
   - Load time
   - Scroll smoothness
   - Memory usage

### Expected Results:
```
✓ Initial load: < 2 seconds
✓ Scroll: Smooth (60 FPS)
✓ No jank or stuttering
✓ Images load progressively
✓ No memory leaks
```

### Failure Indicators:
- ❌ Load time > 5 seconds
- ❌ Scroll stutters
- ❌ Memory usage increases rapidly
- ❌ Images don't load
- ❌ App becomes unresponsive

---

## Quick Verification Checklist

### Before Deploying:

- [ ] ✅ Order status displays correctly
- [ ] ✅ All items show with images and details
- [ ] ✅ Pricing breakdown calculates correctly
- [ ] ✅ Delivery address complete
- [ ] ✅ No crashes on missing fields
- [ ] ✅ Console has all debug logs
- [ ] ✅ Works with different payment methods
- [ ] ✅ Performance acceptable
- [ ] ✅ No memory leaks

### If Any ❌ Fails:

1. Check console logs for warnings
2. Check Firestore document structure
3. Verify all required fields are present
4. Check for null/empty values
5. Review relevant section in this guide

---

## Log Output Examples

### Successful Order Load:

```
📦 OrderDetailsScreen: Loading order details for: ORD1735605234123
✅ OrderDetailsScreen: Order data loaded successfully
📊 Order Data Keys: [orderId, userId, paymentMode, paymentId, deliveryId, status, createdAt, updatedAt, items, amountBreakdown, couponInfo, deliveryInfo, orderMetadata]
📊 Order Status: confirmed
📊 Items Count: 2
📊 First Item: {productId: prod123, name: Notebook Pack, price: 150, quantity: 2, subtotal: 300, productImage: https://..., discountPrice: 150, totalPrice: 300, ...}

🔍 _buildModernStatusCard: Raw status: "confirmed"
🔍 _buildModernStatusCard: Processed status: "confirmed"

🔍 _buildModernItemsCard: Items count: 2
🔍 _buildModernItemsCard: Status: confirmed

🔍 Item 0: [productId, name, price, quantity, subtotal, productImage, discountPrice, totalPrice, itemMetadata]
   - productId: prod123
   - name: Notebook Pack
   - price: 150
   - quantity: 2
   - totalPrice: 300
   - productImage: https://firebasecdn.../notebook.jpg

🔍 Item 1: [productId, name, price, quantity, subtotal, productImage, discountPrice, totalPrice, itemMetadata]
   - productId: prod456
   - name: Pen Set
   - price: 200
   - quantity: 1
   - totalPrice: 200
   - productImage: https://firebasecdn.../pens.jpg

🔍 _buildDetailedPricingBreakdown: amountBreakdown keys: [subTotal, discount, deliveryFee, walletUsed, finalAmount, totalOrderAmount, taxAmount, serviceCharge, totalSavings]
🔍 _buildDetailedPricingBreakdown: couponInfo: null
🔍 _buildDetailedPricingBreakdown: items count: 2

📊 Price Breakdown:
   - subTotal: ₹350.0
   - discount: ₹0.0
   - deliveryFee: ₹100.0
   - walletUsed: ₹0.0
   - finalAmount: ₹450.0
   - totalSavings: ₹0.0
```

### Cloud Function Success:

```
🔍 Firebase Function: createOrder called
🔍 Firebase Function: Request data: {
  "items": [...],
  "amountSummary": {...},
  "paymentMode": "razorpay",
  "deliveryAddress": {...}
}
✅ Created orders document

📊 Order Document Structure: {
  "orderId": "ORD1735605234123",
  "status": "processing_payment",
  "itemsCount": 2,
  "firstItem": {...},
  "amountBreakdown": {...},
  "createdAt": "2025-02-01T..."
}
```

---

## Troubleshooting Guide

| Issue | Check | Solution |
|-------|-------|----------|
| Status null | Console `📊 Order Status:` line | Verify status field in Firestore |
| No items | Console `📊 Items Count:` line | Check items array in Firestore |
| No images | Console `⚠️ WARNING: Item X has no image URL` | Verify product displayImage is saved |
| Wrong amounts | Console `📊 Price Breakdown:` line | Check amountBreakdown in Firestore |
| App crashes | Look for exceptions in console | Check for null dereferences |
| Slow load | Measure console timestamps | Optimize product fetch |

