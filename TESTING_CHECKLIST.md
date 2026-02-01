# Subcategory Filtering - Testing Checklist

## Pre-Testing Setup

- [ ] Build the app: `flutter pub get && flutter run`
- [ ] Clear app data to reset state
- [ ] Ensure Firebase connection is working
- [ ] Check that product_details collection has products with `sub_category` field
- [ ] Enable logging: Check logs in Android Studio / Xcode

## Basic Functionality Tests

### Test 1: Default "All" Selection
**Expected**: Shows mix of products from all subcategories
```
Steps:
1. Open Home Page
2. Observe "All" button is selected in subcategory filter
3. View products displayed in horizontal scroll

Expected Results:
✅ Multiple different product types visible
✅ No filtering applied
✅ Products load smoothly
✅ Logs show: "Using default items for All"
```

### Test 2: Select Individual Subcategory - "Paper"
**Expected**: Only paper products shown
```
Steps:
1. On Home Page, tap "Paper" in subcategory filter
2. Observe the products displayed

Expected Results:
✅ Product list refreshes
✅ Only items with sub_category == "paper" shown
✅ First 8 items display
✅ Loading spinner shows briefly
✅ Logs show: "Loading products for section=..., subcategory=paper"
✅ Logs show: "Fetched X products for subcategory=paper"
```

### Test 3: Select "Cleaning Supply"
**Expected**: Only cleaning supply products shown
```
Steps:
1. Tap "Cleaning Supply" in subcategory filter
2. Observe product switch

Expected Results:
✅ Products immediately switch to cleaning supplies
✅ First 8 items display
✅ Different products than "Paper" selection
✅ Logs show correct subcategory loading
```

### Test 4: Select "Writing Instrument"
**Expected**: Only writing instrument products shown
```
Steps:
1. Tap "Writing Instrument" in subcategory filter
2. Verify product change

Expected Results:
✅ Products switch to writing instruments
✅ All items have "writing instrument" subcategory
✅ Smooth transition with loading indicator
```

## Pagination & Lazy Loading Tests

### Test 5: Scroll and Load More - Horizontal Scroll
**Expected**: More items load when scrolling to the end
```
Steps:
1. Select a subcategory (e.g., "Paper")
2. Wait for first 8 items to load
3. Scroll horizontally to the right
4. Approach the end of the visible items

Expected Results:
✅ When ~2 items from end remain, loading starts
✅ Spinner shows in the last position
✅ Next 8 items appear after loading
✅ Total items now: 16 items
✅ Can continue scrolling for more
✅ Logs show: "Loading more products" and "Loaded X more products"
```

### Test 6: Continuous Scrolling
**Expected**: Can scroll indefinitely with pagination
```
Steps:
1. Select "Paper" subcategory
2. Scroll right repeatedly
3. Let each batch load
4. Continue scrolling

Expected Results:
✅ 1st batch: Items 1-8 load
✅ 2nd batch: Items 9-16 load
✅ 3rd batch: Items 17-24 load
✅ No duplicates appear
✅ No performance degradation
✅ Smooth scrolling experience
```

### Test 7: Fast Switching Between Subcategories
**Expected**: Products switch without errors
```
Steps:
1. Tap "Paper"
2. Quickly scroll a few items
3. Tap "Cleaning Supply"
4. Quickly scroll a few items
5. Tap "Writing Instrument"
6. Scroll a few items

Expected Results:
✅ Products switch correctly each time
✅ No mixing of products from different categories
✅ Previous pagination state cleared
✅ New subcategory starts from first batch
✅ No errors in logs
```

## Edge Case Tests

### Test 8: Empty Subcategory
**Expected**: Shows empty state gracefully
```
Steps:
1. If any subcategory has no products:
   - Tap that subcategory
   - Observe UI

Expected Results:
✅ Shows empty state message
✅ No crash
✅ Can switch to other subcategories
✅ Logs show: "No products found" or similar
```

### Test 9: Network Error During Loading
**Expected**: Error handling works
```
Steps:
1. Select a subcategory
2. During loading, disconnect internet
3. Re-connect
4. Tap to retry

Expected Results:
✅ Error message appears
✅ Can retry after reconnecting
✅ No app crash
✅ Error logged appropriately
```

### Test 10: Return to "All" After Selection
**Expected**: Goes back to original state
```
Steps:
1. Select "Paper" and scroll a few batches
2. Tap "All"
3. Observe

Expected Results:
✅ Shows all products mix
✅ Products from different categories visible
✅ First 8 items from "all" shown
✅ Previous pagination state cleared
✅ Smooth transition
```

## UI/UX Tests

### Test 11: Loading Indicator Visibility
**Expected**: Spinner shows during loading
```
Steps:
1. Select a subcategory
2. Watch for loading indicator
3. Scroll to trigger next batch

Expected Results:
✅ Spinner appears while loading first batch
✅ Spinner positioned correctly
✅ Spinner disappears when items loaded
✅ No flashing or unnecessary redraws
```

### Test 12: Button States in Filter Row
**Expected**: Selected button highlighted
```
Steps:
1. Observe subcategory filter row
2. Tap different subcategories
3. Watch button highlighting

Expected Results:
✅ Selected button shows blue background
✅ Unselected buttons show white background
✅ Color changes immediately on tap
✅ "All" button highlights correctly
```

### Test 13: Product Card Display
**Expected**: Cards show correct information
```
Steps:
1. Select any subcategory
2. Examine product cards displayed

Expected Results:
✅ Product images load
✅ Product names visible
✅ Prices displayed
✅ Discount labels shown (if applicable)
✅ Cards are clickable
```

## Performance Tests

### Test 14: No Jank During Scroll
**Expected**: Smooth 60fps scrolling
```
Steps:
1. Select a subcategory
2. Scroll smoothly
3. Continue scrolling multiple batches
4. Monitor frame rate (use DevTools)

Expected Results:
✅ Smooth scrolling without stuttering
✅ Frame rate stays ~60fps
✅ No lag when loading more items
✅ Memory usage stable
```

### Test 15: Memory Efficiency
**Expected**: Memory doesn't leak
```
Steps:
1. Select and scroll 10+ batches (80+ items)
2. Switch subcategories 5+ times
3. Check memory usage

Expected Results:
✅ Memory increases but stabilizes
✅ No continuous memory growth
✅ No memory leaks after switching
```

## Integration Tests

### Test 16: Tap Product → Product Details
**Expected**: Navigation works from filtered items
```
Steps:
1. Select any subcategory
2. Tap on a product card
3. Verify navigation

Expected Results:
✅ Product details page opens
✅ Correct product displayed
✅ Can go back to home
✅ Filter state preserved after returning
```

### Test 17: Cart Addition from Filtered Items
**Expected**: Can add products to cart
```
Steps:
1. Select "Paper"
2. Find a product
3. Tap product → Details page
4. Add to cart
5. Go back to home

Expected Results:
✅ Product added successfully
✅ Cart count updated
✅ Can complete purchase flow
✅ Filtered view still active
```

## Data Integrity Tests

### Test 18: No Duplicate Products
**Expected**: Same product not shown twice
```
Steps:
1. Select any subcategory
2. Scroll through all batches
3. Check for duplicates

Expected Results:
✅ Each product appears only once
✅ No SKU IDs repeated
✅ No product IDs repeated
```

### Test 19: Correct Subcategory Filtering
**Expected**: All shown products match selected subcategory
```
Steps:
1. Select "Writing Instrument"
2. Check each product in Firestore
3. Verify all have sub_category == "writing_instrument"

Expected Results:
✅ All products match selected subcategory
✅ No cross-category products shown
✅ Filter accuracy 100%
```

### Test 20: Product Details Accuracy
**Expected**: Displayed info matches Firestore
```
Steps:
1. Select any subcategory
2. Compare product card info with Firestore:
   - Name
   - Price
   - Image
   - Discount

Expected Results:
✅ All info matches Firestore
✅ Prices accurate
✅ Images load from correct URL
✅ No stale data
```

## Logging Tests

### Test 21: Comprehensive Logging
**Expected**: All actions logged
```
Steps:
1. Enable flutter logs
2. Perform various operations
3. Review logs

Expected Results:
✅ All loading actions logged
✅ Timestamps present
✅ Error messages descriptive
✅ No sensitive data logged
```

## Regression Tests

### Test 22: Original "All" Functionality Unaffected
**Expected**: "All" selection works as before
```
Steps:
1. Tap "All"
2. Use normally

Expected Results:
✅ All sections load
✅ All products visible
✅ Scrolling works
✅ No new issues introduced
```

### Test 23: Non-Filtered Items Still Load
**Expected**: Home sections without filters work
```
Steps:
1. Look at other home sections
2. Verify normal operation

Expected Results:
✅ Flash sale items load
✅ Popular items load
✅ Banner carousel works
✅ All original features intact
```

## Test Results Template

```
Test Date: ____________
Tester Name: ____________
Build Version: ____________
Device: ____________

| Test # | Test Name | Status | Notes |
|--------|-----------|--------|-------|
| 1 | Default "All" Selection | ☐ PASS ☐ FAIL | |
| 2 | Select "Paper" | ☐ PASS ☐ FAIL | |
| 3 | Select "Cleaning Supply" | ☐ PASS ☐ FAIL | |
| 4 | Select "Writing Instrument" | ☐ PASS ☐ FAIL | |
| 5 | Scroll and Load More | ☐ PASS ☐ FAIL | |
| 6 | Continuous Scrolling | ☐ PASS ☐ FAIL | |
| 7 | Fast Switching | ☐ PASS ☐ FAIL | |
| 8 | Empty Subcategory | ☐ PASS ☐ FAIL | |
| 9 | Network Error Handling | ☐ PASS ☐ FAIL | |
| 10 | Return to "All" | ☐ PASS ☐ FAIL | |
| 11 | Loading Indicator | ☐ PASS ☐ FAIL | |
| 12 | Button States | ☐ PASS ☐ FAIL | |
| 13 | Product Card Display | ☐ PASS ☐ FAIL | |
| 14 | Scroll Performance | ☐ PASS ☐ FAIL | |
| 15 | Memory Efficiency | ☐ PASS ☐ FAIL | |
| 16 | Product Navigation | ☐ PASS ☐ FAIL | |
| 17 | Cart Addition | ☐ PASS ☐ FAIL | |
| 18 | No Duplicates | ☐ PASS ☐ FAIL | |
| 19 | Correct Filtering | ☐ PASS ☐ FAIL | |
| 20 | Data Accuracy | ☐ PASS ☐ FAIL | |
| 21 | Logging | ☐ PASS ☐ FAIL | |
| 22 | Original "All" | ☐ PASS ☐ FAIL | |
| 23 | Non-Filtered Items | ☐ PASS ☐ FAIL | |

**Total Tests**: 23
**Passed**: ___
**Failed**: ___
**Success Rate**: ___ %

Issues Found:
1. ___________
2. ___________
3. ___________

Overall Status: ☐ APPROVED ☐ NEEDS FIXES

Tester Signature: ______________ Date: ____________
```

## Debug Commands

### View Logs
```bash
flutter logs | grep "HomeSectionController"
```

### Check Product Count for Subcategory
In Firebase Console:
```
Collection: product_details
Filter: sub_category == "paper"
Count documents
```

### Monitor Memory
In Android Studio:
```
View → Tool Windows → Profiler
Monitor Memory tab
```

### View Network Requests
In Android Studio DevTools:
```
Timeline tab
Network requests
```

---

**Note**: Ensure all 23 tests pass before considering implementation complete.
