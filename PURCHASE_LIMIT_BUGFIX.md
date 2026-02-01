# Purchase Limit Bug Fix - Data Structure Issue

## Problem Identified
Product details page was showing "Maximum 999 units per order" and quantity was unlimited because the `purchase_limits` data wasn't being passed from the product level to the individual SKUs.

### Root Cause
**Data Structure:**
- Firestore stores `purchase_limits` at the **product level**
- Example: `product_details.purchase_limits.max_per_order: 50`
- But the code was looking for it at the **SKU level**
- SKUs didn't have purchase_limits, so it defaulted to 999

## Solution Implemented

Updated the ProductModel parsing to pass parent product's `purchase_limits` to each SKU:

### Changes Made

**File:** `lib/data/models/product_model.dart`

#### 1. Updated `fromFirestore()` method
Changed:
```dart
productSkus: _parseProductSKUs(data['product_skus']),
```

To:
```dart
productSkus: _parseProductSKUs(data['product_skus'], data['purchase_limits']),
```

#### 2. Updated `fromMap()` method
Changed:
```dart
productSkus: _parseProductSKUs(data['product_skus']),
```

To:
```dart
productSkus: _parseProductSKUs(data['product_skus'], data['purchase_limits']),
```

#### 3. Updated `_parseProductSKUs()` method
Changed from:
```dart
static List<ProductSKUModel> _parseProductSKUs(dynamic data) {
  if (data == null || data is! List) return [];
  
  return data
      .whereType<Map<String, dynamic>>()
      .map((skuData) => ProductSKUModel.fromFirestore(skuData))
      .toList();
}
```

To:
```dart
static List<ProductSKUModel> _parseProductSKUs(dynamic data, dynamic purchaseLimitsData) {
  if (data == null || data is! List) return [];
  
  // Parse parent product's purchase limits
  int maxPerOrder = 999;
  if (purchaseLimitsData is Map<String, dynamic>) {
    maxPerOrder = (purchaseLimitsData['max_per_order'] as num?)?.toInt() ?? 999;
  }
  
  return data
      .whereType<Map<String, dynamic>>()
      .map((skuData) {
        // Add purchase_limits to SKU data if not already present
        if (skuData['purchase_limits'] == null) {
          skuData['purchase_limits'] = {'max_per_order': maxPerOrder};
        }
        return ProductSKUModel.fromFirestore(skuData);
      })
      .toList();
}
```

## How It Works Now

1. **Product loaded from Firestore:**
   ```json
   {
     "product_id": "a3-color-sheets",
     "purchase_limits": {
       "max_per_order": 50,
       "max_per_user_per_day": 20
     },
     "product_skus": [
       {
         "sku_id": "a3-color-sheets-default",
         "price": 120,
         "available_quantity": 100
         // NO purchase_limits at SKU level
       }
     ]
   }
   ```

2. **During parsing:**
   - Extract `purchase_limits.max_per_order: 50` from product
   - Add it to each SKU's data before parsing
   - Each SKU now has `purchase_limits.max_per_order: 50`

3. **Result:**
   - ProductSKUModel now has `maxPerOrder = 50` instead of 999
   - Product details page shows "Maximum 50 units per order"
   - Quantity increment respects the 50-unit limit

## Testing

To verify the fix works:

1. Open product details for "A3 Color Sheets"
2. Should now show "Maximum 50 units per order" (was 999)
3. Click + button to increase quantity
4. Stops at 50 with gentle toast message
5. Cannot increase beyond 50

## Impact

✅ **Product Details Page:** Now correctly shows max_per_order from Firestore
✅ **Quantity Limiting:** Works as intended with actual limits, not 999
✅ **Cart Updates:** Will also respect correct limits
✅ **Validation:** All validations now use correct max_per_order values
✅ **Backward Compatible:** Still defaults to 999 if purchase_limits missing

## Files Modified

- `lib/data/models/product_model.dart`
  - ✅ `fromFirestore()` - Passes purchase_limits to _parseProductSKUs()
  - ✅ `fromMap()` - Passes purchase_limits to _parseProductSKUs()
  - ✅ `_parseProductSKUs()` - Now extracts product-level purchase_limits and applies to all SKUs
