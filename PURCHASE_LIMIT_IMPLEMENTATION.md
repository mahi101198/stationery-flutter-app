## Purchase Quantity Limit Implementation - Summary

### Overview
Implemented a purchase quantity limit feature based on the `max_per_order` field from the product's `purchase_limits` in Firestore. This ensures users cannot purchase more than the configured limit per order.

### Changes Made

#### 1. **ProductDetailController** (`lib/features/product/controllers/product_detail_controller.dart`)

**Changes:**
- **`_getMaxAllowedQuantity()` method**: Updated to use `selectedSKU.value!.maxPerOrder` instead of `availableQuantity`
  - Previously: Returned available quantity in stock
  - Now: Returns the max_per_order limit from purchase_limits
  
- **`incrementQuantity()` method**: Updated warning message
  - Previously: "Stock Limited - Only X items available in stock"
  - Now: "Purchase Limit Reached - Maximum X units per order for this product"
  - Still shows gentle warning snackbar (not red)

**Impact:** Product details page now respects the max_per_order limit when user increments quantity.

---

#### 2. **ProductQuantity Component** (`lib/features/product/components/product_quantity.dart`)

**Changes:**
- **Plus button OnTap handler**: Added gentle warning when limit is reached
  - Previously: Button was disabled (onTap: null)
  - Now: Button shows a gentle toast message "Maximum X units per order" when clicked at limit
  
**Feature:**
- Toast message is non-intrusive and gentle (not red)
- Button appears disabled visually but is still clickable to show feedback
- Message: "Maximum X units per order"

**Impact:** Better UX with gentle feedback instead of silent disabled button.

---

#### 3. **CartProduct Widget** (`lib/features/cart/widgets/cart_product.dart`)

**Changes:**
- **Added import**: Added `import 'package:rps_stationery/utils/popups/loaders.dart';`
- **Plus button OnTap handler**: Updated to show gentle toast instead of snackbar
  - Previously: Showed Get.snackbar with "Limit Reached" title
  - Now: Shows customToast with "Maximum X units per order" message
  
**Impact:** Consistent gentle warning behavior across cart and product details pages.

---

#### 4. **CartController** (`lib/features/cart/controllers/cart_controller.dart`)

**Changes in `addToCart()` method:**
- Changed warning from `warningSnackBar` to `customToast`
  - Message: "Maximum X units per order for this item."
  
**Changes in `updateCartItemQuantity()` method:**
- Changed warning from `warningSnackBar` to `customToast`
  - Message: "Maximum X units per order for this item."

**Impact:** Gentle, non-intrusive warnings when users try to add/increase quantity beyond the limit.

---

### Data Structure Reference

The implementation uses the following structure from Firestore `product_details` collection:

```json
{
  "product_skus": [
    {
      "sku_id": "a3-color-sheets-default",
      "attributes": {
        "color": "Assorted Mix",
        "gsm": "80 GSM",
        "size": "A3 (297 x 420 mm)",
        "pack": "20 sheets"
      },
      "price": 55,
      "mrp": 60,
      "available_quantity": 100,
      "availability": "in_stock",
      "purchase_limits": {
        "max_per_order": 50,
        "max_per_user_per_day": 20
      }
    }
  ]
}
```

### Key Features

✅ **Max Per Order Limit**: Enforced at SKU level from `purchase_limits.max_per_order`
✅ **Gentle Warnings**: Uses toast notifications (customToast) instead of harsh snackbars
✅ **Visual Feedback**: Disabled button state when limit is reached
✅ **Non-blocking UX**: User can still interact with the button to see feedback message
✅ **Consistent Behavior**: Same validation across product details and cart screens
✅ **Product Brand Support**: System ready to include brand info in messages if needed

### Testing Scenarios

1. **Product Details Page - Increment Quantity**
   - User adds product to cart
   - User clicks + button to increase quantity
   - When quantity reaches max_per_order, button shows gentle toast
   - Quantity cannot be increased beyond max_per_order

2. **Cart Page - Update Quantity**
   - User in cart tries to increase quantity beyond max_per_order
   - Sees gentle toast message with the limit
   - Quantity is not updated

3. **Add to Cart - Validation**
   - User tries to add quantity beyond max_per_order
   - See gentle toast message
   - Item is not added to cart with exceeding quantity

### Files Modified

1. `lib/features/product/controllers/product_detail_controller.dart`
   - ✅ `_getMaxAllowedQuantity()` 
   - ✅ `incrementQuantity()`

2. `lib/features/product/components/product_quantity.dart`
   - ✅ Plus button handler with gentle toast

3. `lib/features/cart/widgets/cart_product.dart`
   - ✅ Import TLoaders
   - ✅ Plus button handler with gentle toast

4. `lib/features/cart/controllers/cart_controller.dart`
   - ✅ `addToCart()` warning message
   - ✅ `updateCartItemQuantity()` warning message

### Notes

- The `maxQuantity` display on product details screen already uses the dynamic `maxQuantity` getter from controller
- The `MinimalQuantitySelector` component already accepts `maxQuantity` parameter
- All warnings are gentle (using `customToast`) instead of red/harsh (snackbar)
- The brand field from the product is available if needed for future message customization
