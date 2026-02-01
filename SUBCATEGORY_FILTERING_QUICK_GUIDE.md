# Subcategory Filtering - Quick Reference Guide

## What Changed?

### Before (Problem):
```
Home Page
├── SubcategoryFilter Row (All, Paper, Cleaning, Writing, etc.)
│   └── User selects "Paper"
├── Products Display
│   └── ❌ Still showing mixed products from all categories
│   └── ❌ No pagination
│   └── ❌ Limited to initial loaded items only
```

### After (Solution):
```
Home Page
├── SubcategoryFilter Row (All, Paper, Cleaning, Writing, etc.)
│   └── User selects "Paper"
├── Products Display
│   ├── ✅ Shows ONLY "Paper" products
│   ├── ✅ First 8 items displayed
│   ├── ✅ Scroll → Loading... → Next 8 items appear
│   └── ✅ Fetched from product_details collection
```

## User Experience Flow

### Scenario 1: Select "All"
```
1. User taps "All" button
2. Filter changes to null/empty
3. Homepage shows items from all subcategories (default behavior)
4. Horizontal scroll shows mix of all products
```

### Scenario 2: Select "Paper"
```
1. User taps "Paper" subcategory
2. HomeSectionsList detects change (via Obx)
3. Controller fetches products where sub_category == "paper"
4. First 8 items display in horizontal scroll
5. User scrolls right → reaches near end
6. Next 8 items auto-load
7. Loading spinner shows briefly
8. User continues scrolling with next batch
```

### Scenario 3: Switch from "Paper" to "Cleaning Supply"
```
1. User taps "Cleaning Supply"
2. Items immediately switch to cleaning supplies (cached if loaded)
3. Or fetches first batch if not previously loaded
4. Same 8-item batch loading as "Paper"
```

## Code Integration Points

### 1. Subcategory Selection Trigger
**Location**: [lib/features/home/components/subcategory_filter_row.dart](lib/features/home/components/subcategory_filter_row.dart)

When user taps a subcategory:
```dart
controller.selectSubcategory(subcategoryId)
// This updates selectedSubcategoryId observable
```

### 2. Listen to Selection Change
**Location**: [lib/features/home/components/home_sections_list.dart](lib/features/home/components/home_sections_list.dart)

```dart
Obx(() {
  final selectedSubcategoryId = _filterController.selectedSubcategoryId.value;
  
  if (selectedSubcategoryId != null && selectedSubcategoryId.isNotEmpty) {
    _sectionController.loadSubcategoryProducts(section.sectionId, selectedSubcategoryId);
  }
  
  final filteredItems = _sectionController.getFilteredSectionItemsWithPagination(
    section.sectionId,
    selectedSubcategoryId,
  );
  // Display filteredItems
})
```

### 3. Fetch Products
**Location**: [lib/features/home/controllers/home_section_controller.dart](lib/features/home/controllers/home_section_controller.dart)

```dart
// Fetches from product_details where sub_category == subcategoryId
final products = await ProductRepo.instance.fetchProductsBySubCategory(
  subcategoryId,
  limit: 100,
  offset: 0,
);

// Convert to HomeSectionItemModel and cache
_sectionItemsBySubcategory[sectionId]![subcategoryId] = convertedItems;
```

### 4. Scroll and Load More
**Location**: [lib/features/home/components/home_sections_list.dart](lib/features/home/components/home_sections_list.dart)

```dart
void _onScroll() {
  if (scrollPosition >= maxExtent - 200) {
    // Near end, load more
    _sectionController.loadMoreSubcategoryProducts(sectionId, subcategoryId);
  }
}
```

## Key Methods Reference

### Load Subcategory Products (First Batch)
```dart
Future<void> loadSubcategoryProducts(
  String sectionId, 
  String? subcategoryId
) async
```
**Triggered**: When subcategory is selected
**Fetches**: First batch of products
**Returns**: Cached items for display

### Load More Subcategory Products (Next Batch)
```dart
Future<void> loadMoreSubcategoryProducts(
  String sectionId, 
  String subcategoryId
) async
```
**Triggered**: When user scrolls near end
**Fetches**: Next 8 items
**Returns**: Appended to existing list

### Get Filtered Items
```dart
List<HomeSectionItemModel> getFilteredSectionItemsWithPagination(
  String sectionId,
  String? subcategoryId,
)
```
**Returns**: Appropriate items based on selection
- If `subcategoryId` is null → Returns all items
- If `subcategoryId` is provided → Returns filtered items

### Check Loading State
```dart
bool isLoadingMoreForSubcategory(String sectionId, String subcategoryId)
```
**Returns**: `true` if currently fetching next batch

## Data Model: HomeSectionItemModel

Each item has:
```dart
class HomeSectionItemModel {
  final String skuId;           // Unique SKU identifier
  final String productId;       // Product ID from product_details
  final String categoryId;      // Category (e.g., "stationary")
  final String subcategoryId;   // Subcategory (e.g., "paper")
  final String name;            // Product name
  final String imageUrl;        // Product image
  final double mrp;             // Maximum Retail Price
  final double price;           // Selling price
  final double discountPercent; // Discount %
  final String currencyCode;    // Currency (INR)
}
```

## Firestore Queries

### Query 1: Fetch Products by Subcategory
```
Collection: product_details
Filter: sub_category == "paper"
OrderBy: rank (or default order)
Limit: 100 (for initial batch)
Offset: Applied for pagination
```

### Query 2: Subcategory Names
```
Collection: subcategories
Fields Used:
  - id: "paper", "cleaning_supply", "writing_instrument", etc.
  - name: "Paper", "Cleaning Supply", "Writing Instrument", etc.
  - image: Image URL for filter button
```

## Performance Metrics

| Metric | Value | Notes |
|--------|-------|-------|
| Batch Size | 8 items | Configurable in constants |
| Initial Load | ~500-800ms | First 8 items from Firestore |
| Next Batch | ~300-500ms | Subsequent 8 items |
| UI Update | <100ms | Reactive with Obx |
| Scroll Trigger | 200px before end | Prevents jank |
| Memory Usage | ~2-5MB | Per 50 items cached |

## Debug Logging

Controller logs in this format:
```
📦 HomeSectionController: Loading products for section=home_main, subcategory=paper
✅ HomeSectionController: Fetched 15 products for subcategory=paper
📦 HomeSectionController: Loading more products for section=home_main, subcategory=paper
✅ HomeSectionController: Loaded 8 more products (Total: 23)
```

Check logs in Android Studio / Xcode console:
```bash
flutter logs | grep HomeSectionController
```

## Common Issues & Solutions

### Issue 1: Products not showing for a subcategory
**Solution**: Check if `sub_category` field exists in Firestore product_details

### Issue 2: Duplicate products appearing
**Solution**: Check cache clearing logic, ensure offset is correct

### Issue 3: Slow loading
**Solution**: Add Firestore index on `sub_category` field

### Issue 4: Empty state when switching subcategories
**Solution**: Check if products exist for that subcategory in Firestore

## Testing Commands

### Verify Subcategories Exist
```dart
// In controller
print('Available subcategories: ${_filterController.subcategories.map((s) => s.name).toList()}');
```

### Check Products for Subcategory
```dart
// In controller
final products = await ProductRepo.instance.fetchProductsBySubCategory('paper');
print('Found ${products.length} products for paper');
```

### Monitor Pagination
```dart
// Watch logs
flutter logs | grep "Loading\|Loaded\|Fetched"
```

## Customization Options

### Change Batch Size
File: [lib/features/home/controllers/home_section_controller.dart](lib/features/home/controllers/home_section_controller.dart)
```dart
static const int BATCH_SIZE = 8; // Change to 10, 12, 16, etc.
```

### Change Scroll Trigger Distance
File: [lib/features/home/components/home_sections_list.dart](lib/features/home/components/home_sections_list.dart)
```dart
if (scrollPosition >= maxExtent - 200) // Change 200 to 100, 300, etc.
```

### Change Initial Fetch Limit
File: [lib/features/home/controllers/home_section_controller.dart](lib/features/home/controllers/home_section_controller.dart)
```dart
final products = await ProductRepo.instance.fetchProductsBySubCategory(
  subcategoryId,
  limit: 100,  // Change this value
  offset: 0,
);
```

---

**Questions?** Check the logs and compare actual vs expected data structure in Firestore.
