# Product Schema Migration Guide

## Overview

This migration script updates all products in your Firestore `product_details` collection to align with the new UI-ready schema.

---

## What It Does

✅ **Flattens SKU structure**: `pricing.selling_price` → `price`, `inventory.stock_qty` → `available_quantity`  
✅ **Adds `overall_availability`**: Calculated from SKU stock levels  
✅ **Adds `variant_attributes`**: Extracted from SKUs (empty for single-SKU products)  
✅ **Adds `delivery_info`**: Default delivery information  
✅ **Adds `order` to content cards**: Priority-based ordering  

---

## Safety Features

🔒 **Automatic Backup**: Creates timestamped backup before migration  
🔍 **Dry Run Mode**: Preview changes without modifying database  
✅ **Validation**: Checks each product before updating  
🔄 **Rollback**: Restore from backup if needed  

---

## Prerequisites

1. **Node.js** installed (v14 or higher)
2. **Firebase Admin SDK** service account key in the same directory
3. **npm packages** installed

---

## Installation

```bash
# Install required packages
npm install firebase-admin
```

---

## Usage

### Step 1: Dry Run (Preview Changes)

**ALWAYS run this first** to see what will change:

```bash
node migrate_product_schema.js --dry-run
```

**Output**:
- Shows how many products will be updated
- Displays validation errors (if any)
- Previews changes for first 3 products
- **Does NOT modify database**

### Step 2: Run Migration

If dry run looks good, run the actual migration:

```bash
node migrate_product_schema.js
```

**Output**:
- Creates backup in `./backups/` directory
- Updates all products in batches
- Shows progress and summary

### Step 3: Verify Results

Check Firestore console to verify products are updated correctly.

---

## Rollback (If Needed)

If something goes wrong, restore from backup:

```bash
node migrate_product_schema.js --rollback products_backup_2026-01-31T15-00-00-000Z.json
```

Replace the filename with your actual backup file from `./backups/` directory.

---

## Example Output

### Dry Run Mode

```
🚀 Starting Product Schema Migration
📋 Mode: DRY RUN (no changes will be made)

📦 Creating backup...
✅ Backup created: ./backups/products_backup_2026-01-31T15-00-00-000Z.json
📊 Total products backed up: 45

📥 Fetching products...
✅ Found 45 products

🔄 Transforming products...
✅ Successfully transformed: 45
❌ Validation errors: 0

👀 Preview of changes (first 3 products):

📦 Product: a3-color-sheets
  Changes:
  ✓ SKU: Flattened pricing (120 → 120)
  ✓ SKU: Flattened inventory (100 → 100)
  ✓ Added: overall_availability = "in_stock"
  ✓ Added: variant_attributes (0 attributes)
  ✓ Added: delivery_info
  ✓ Added: order field to 3 content cards

📦 Product: a4-notebook
  Changes:
  ✓ SKU: Flattened pricing (80 → 80)
  ✓ SKU: Flattened inventory (250 → 250)
  ✓ Added: overall_availability = "in_stock"
  ✓ Added: variant_attributes (0 attributes)
  ✓ Added: delivery_info
  ✓ Added: order field to 4 content cards

...

📊 Migration Summary:
  • Total products: 45
  • Successfully transformed: 45
  • Validation errors: 0
  • Backup location: ./backups/products_backup_2026-01-31T15-00-00-000Z.json

🔍 DRY RUN MODE - No changes made to database
💡 Run without --dry-run flag to apply changes
```

### Live Migration

```
🚀 Starting Product Schema Migration
📋 Mode: LIVE MIGRATION

📦 Creating backup...
✅ Backup created: ./backups/products_backup_2026-01-31T15-05-00-000Z.json
📊 Total products backed up: 45

📥 Fetching products...
✅ Found 45 products

🔄 Transforming products...
✅ Successfully transformed: 45
❌ Validation errors: 0

💾 Updating database...
✅ Successfully updated 45 products

📊 Migration Summary:
  • Total products: 45
  • Successfully transformed: 45
  • Validation errors: 0
  • Backup location: ./backups/products_backup_2026-01-31T15-05-00-000Z.json

✅ Migration completed successfully!
```

---

## What Gets Changed

### Before (Your Current Schema)

```json
{
  "product_skus": [
    {
      "sku_id": "a3-color-sheets-default",
      "attributes": {...},
      "inventory": {
        "stock_qty": 100
      },
      "pricing": {
        "currency": "INR",
        "mrp": 180,
        "selling_price": 120
      }
    }
  ]
}
```

### After (New Schema)

```json
{
  "product_skus": [
    {
      "sku_id": "a3-color-sheets-default",
      "attributes": {...},
      "price": 120,
      "mrp": 180,
      "currency": "INR",
      "availability": "in_stock",
      "available_quantity": 100
    }
  ],
  "overall_availability": "in_stock",
  "variant_attributes": {},
  "delivery_info": {
    "estimated_delivery": "3-5 business days",
    "return_policy": "7 days return",
    "cod_available": true,
    "free_delivery_threshold": 499
  }
}
```

---

## Customization

### Change Default Delivery Info

Edit the `DEFAULT_DELIVERY_INFO` constant in the script:

```javascript
const DEFAULT_DELIVERY_INFO = {
  estimated_delivery: '2-4 business days',  // ← Change this
  return_policy: '14 days return',          // ← Change this
  cod_available: true,
  free_delivery_threshold: 299              // ← Change this
};
```

### Change Batch Size

Edit the `CONFIG.BATCH_SIZE` if you have many products:

```javascript
const CONFIG = {
  BATCH_SIZE: 500, // ← Firestore limit is 500
};
```

---

## Troubleshooting

### Error: "Missing product_id"

**Cause**: Some products don't have `product_id` field  
**Solution**: Add `product_id` manually or use document ID as fallback

### Error: "No SKUs found"

**Cause**: Product has empty `product_skus` array  
**Solution**: Add at least one SKU to the product

### Error: "Permission denied"

**Cause**: Service account doesn't have write permissions  
**Solution**: Check Firebase IAM permissions for the service account

---

## FAQ

**Q: Will this delete any data?**  
A: No, it only adds new fields and restructures existing ones. Original data is preserved in backup.

**Q: Can I run this multiple times?**  
A: Yes, the script is idempotent. It checks if fields already exist before adding them.

**Q: What if I have custom SKU fields?**  
A: Custom fields are preserved. The script only transforms known fields.

**Q: How long does migration take?**  
A: ~1 second per product. 100 products = ~2 minutes.

---

## Next Steps

After migration:

1. ✅ Verify products in Firestore console
2. ✅ Test product details page in your app
3. ✅ Check that all UI elements render correctly
4. ✅ Delete old backups after confirming everything works

---

## Support

If you encounter issues:

1. Check the backup file in `./backups/`
2. Review validation errors in the output
3. Run with `--dry-run` to debug
4. Rollback if needed

**Backup files are safe to delete after 30 days** (once you've confirmed migration success).
