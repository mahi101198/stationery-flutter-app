# Purchase Limit Feature - Quick Reference

## What Was Implemented

✅ **Purchase Quantity Limits** based on `max_per_order` from Firestore  
✅ **Gentle Warnings** (yellow toast, not red snackbar)  
✅ **Prevented Over-ordering** - Quantity cannot exceed limit  
✅ **Consistent UX** - Same behavior on product details and cart  

---

## Key Implementation Details

### Data Source
```
Firestore: product_details > product_skus[].purchase_limits.max_per_order
Example: 50 units maximum per order
```

### Limit Enforcement Points

1. **Product Details Page**
   - Quantity selector respects max_per_order
   - Increment button shows toast when limit reached
   - Display shows "Maximum 50 units per order"

2. **Cart Page**
   - Plus button shows toast when limit reached
   - Cannot increase beyond max_per_order
   - Visual feedback (disabled state)

3. **Add to Cart Validation**
   - Validates quantity before adding to cart
   - Shows gentle warning if exceeded
   - Item not added with exceeding quantity

---

## Warning Messages (All Gentle - Not Red)

| Location | Message | Type |
|----------|---------|------|
| Product Details - Increment | "Maximum 50 units per order" | Toast |
| Product Details - Warning | "Purchase Limit Reached - Maximum 50 units per order for this product." | Snackbar |
| Cart - Increment | "Maximum 50 units per order" | Toast |
| Add to Cart | "Maximum 50 units per order for this item." | Toast |

---

## Files Changed

### Core Logic Files
- `lib/features/product/controllers/product_detail_controller.dart`
  - Updated `_getMaxAllowedQuantity()` to use `maxPerOrder`
  - Updated `incrementQuantity()` warning message

### UI Components
- `lib/features/product/components/product_quantity.dart`
  - Added gentle toast on plus button when limit reached

- `lib/features/cart/widgets/cart_product.dart`
  - Changed warning from snackbar to toast
  - Added TLoaders import

### Controllers
- `lib/features/cart/controllers/cart_controller.dart`
  - Changed addToCart() warning to gentle toast
  - Changed updateCartItemQuantity() warning to gentle toast

---

## Testing Scenario

```
Product: A3 Color Sheets
max_per_order: 50
brand: "Generic"

1. User opens product details
2. User clicks + button repeatedly
3. Quantity increases: 1, 2, 3, ... 50
4. When quantity = 50 and user clicks +
   → Toast shows: "Maximum 50 units per order"
   → Quantity stays at 50
5. User goes to cart
6. Same behavior when clicking + button
```

---

## Success Criteria Met

✅ Check for `max_per_order` from product_details collection  
✅ Prevent quantity increase beyond max_per_order  
✅ Show gentle warning (yellow toast) not red snackbar  
✅ Prevent user from increasing qty when at limit  
✅ Dynamic display based on max_per_order value  
✅ Same behavior on product details and cart pages  
✅ Include brand info in data (ready for future use)  

---

## How It Works (Technical)

```dart
// Step 1: Get max limit from SKU
int maxLimit = selectedSKU.value.maxPerOrder;  // e.g., 50

// Step 2: Check when incrementing
if (quantity < maxLimit) {
  quantity++;  // Allowed
} else {
  showGentleToast("Maximum $maxLimit units per order");  // Blocked
}

// Step 3: Validate before adding to cart
if (quantity <= sku.maxPerOrder) {
  addToCart(quantity);  // Success
} else {
  showGentleToast("Maximum ${sku.maxPerOrder} units per order");  // Blocked
}
```

---

## Database Structure

```json
{
  "id": "a3-color-sheets",
  "product_skus": [
    {
      "sku_id": "a3-color-sheets-default",
      "available_quantity": 100,
      "purchase_limits": {
        "max_per_order": 50,
        "max_per_user_per_day": 20
      }
    }
  ],
  "brand": "Generic",
  "category": "Stationery"
}
```

---

## User Feedback Style

**Gentle (✅ Implemented):**
- Yellow/neutral toast notification
- Non-blocking message
- Simple text: "Maximum X units per order"
- Appears at top of screen
- Auto-dismisses after 2 seconds

**Harsh (❌ NOT used):**
- Red snackbar
- Blocking dialog
- Error tone: "Purchase Limit Exceeded"
- Takes focus

---

## Future Enhancements

- [ ] Show brand in message: "Generic: Maximum 50 units per order"
- [ ] Track user's daily order count for max_per_user_per_day
- [ ] Analytics: Log when users hit limit
- [ ] Suggestion: "You have X units remaining per order"

---

## Deployment Notes

✅ No breaking changes  
✅ Backward compatible (default limit: 999)  
✅ No database migrations needed  
✅ Works with existing product structure  
✅ Ready for production  

---

## Verification

To verify the feature is working:

1. Open Firebase Console → Collections → product_details
2. Check any product SKU has: `purchase_limits.max_per_order`
3. Open app → Product Details page
4. Try to increase quantity beyond max_per_order
5. Should see gentle toast: "Maximum X units per order"
6. Go to cart and verify same behavior
