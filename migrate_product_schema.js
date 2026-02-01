/**
 * Product Schema Migration Script
 * 
 * This script migrates all products in the product_details collection to the new schema:
 * 1. Flattens SKU structure (pricing/inventory → top-level fields)
 * 2. Adds overall_availability field
 * 3. Adds variant_attributes field
 * 4. Adds delivery_info field
 * 5. Adds order field to content_cards
 * 
 * SAFETY FEATURES:
 * - Creates backup before migration
 * - Validates each product before updating
 * - Dry-run mode to preview changes
 * - Rollback capability
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin
const serviceAccount = require('./rps-statationary-jaipur-firebase-adminsdk-fbsvc-b49816e7a3.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Configuration
const CONFIG = {
    COLLECTION: 'product_details',
    BACKUP_DIR: './backups',
    DRY_RUN: process.argv.includes('--dry-run'),
    BATCH_SIZE: 500, // Firestore batch limit
};

// Default delivery info
const DEFAULT_DELIVERY_INFO = {
    estimated_delivery: '3-5 business days',
    return_policy: '7 days return',
    cod_available: true,
    free_delivery_threshold: 499
};

/**
 * Create backup of all products
 */
async function createBackup() {
    console.log('📦 Creating backup...');

    const snapshot = await db.collection(CONFIG.COLLECTION).get();
    const products = [];

    snapshot.forEach(doc => {
        products.push({
            id: doc.id,
            data: doc.data()
        });
    });

    // Create backup directory if it doesn't exist
    if (!fs.existsSync(CONFIG.BACKUP_DIR)) {
        fs.mkdirSync(CONFIG.BACKUP_DIR, { recursive: true });
    }

    // Save backup with timestamp
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupPath = path.join(CONFIG.BACKUP_DIR, `products_backup_${timestamp}.json`);

    fs.writeFileSync(backupPath, JSON.stringify(products, null, 2));

    console.log(`✅ Backup created: ${backupPath}`);
    console.log(`📊 Total products backed up: ${products.length}`);

    return backupPath;
}

/**
 * Transform SKU to new flat structure
 */
function transformSKU(sku) {
    // If already in new format, return as-is
    if (sku.price !== undefined && sku.available_quantity !== undefined) {
        return sku;
    }

    // Extract pricing info
    const pricing = sku.pricing || {};
    const inventory = sku.inventory || {};

    // Determine availability based on stock
    const stockQty = inventory.stock_qty || 0;
    let availability = 'out_of_stock';
    if (stockQty > 10) {
        availability = 'in_stock';
    } else if (stockQty > 0) {
        availability = 'limited';
    }

    return {
        sku_id: sku.sku_id,
        attributes: sku.attributes || {},
        price: pricing.selling_price || 0,
        mrp: pricing.mrp || pricing.selling_price || 0,
        currency: pricing.currency || 'INR',
        availability: availability,
        available_quantity: stockQty
    };
}

/**
 * Calculate overall availability from SKUs
 */
function calculateOverallAvailability(skus) {
    if (!skus || skus.length === 0) {
        return 'out_of_stock';
    }

    const hasInStock = skus.some(sku => {
        const qty = sku.available_quantity || sku.inventory?.stock_qty || 0;
        return qty > 10;
    });

    const hasLimited = skus.some(sku => {
        const qty = sku.available_quantity || sku.inventory?.stock_qty || 0;
        return qty > 0 && qty <= 10;
    });

    if (hasInStock) return 'in_stock';
    if (hasLimited) return 'limited';
    return 'out_of_stock';
}

/**
 * Extract variant attributes from SKUs
 */
function extractVariantAttributes(skus) {
    if (!skus || skus.length <= 1) {
        return {}; // Single SKU products have no variants
    }

    const attributes = {};

    skus.forEach(sku => {
        if (sku.attributes) {
            Object.keys(sku.attributes).forEach(key => {
                if (!attributes[key]) {
                    attributes[key] = [];
                }
                const value = sku.attributes[key];
                if (!attributes[key].includes(value)) {
                    attributes[key].push(value);
                }
            });
        }
    });

    // Remove attributes with only one value (not really variants)
    Object.keys(attributes).forEach(key => {
        if (attributes[key].length <= 1) {
            delete attributes[key];
        }
    });

    return attributes;
}

/**
 * Add order field to content cards
 */
function addOrderToContentCards(cards) {
    if (!cards || !Array.isArray(cards)) {
        return [];
    }

    return cards.map((card, index) => {
        // If order already exists, keep it
        if (card.order !== undefined) {
            return card;
        }

        // Assign order based on card_id priority
        let order = index + 1;

        // Priority ordering
        if (card.card_id === 'highlights') order = 1;
        else if (card.card_id === 'description') order = 2;
        else if (card.card_id === 'specifications') order = 3;
        else if (card.card_id === 'usage' || card.card_id === 'instructions') order = 4;
        else if (card.card_id === 'delivery') order = 5;

        return {
            ...card,
            order
        };
    });
}

/**
 * Transform product to new schema
 */
function transformProduct(productData) {
    const transformed = { ...productData };

    // 1. Transform SKUs
    if (transformed.product_skus && Array.isArray(transformed.product_skus)) {
        transformed.product_skus = transformed.product_skus.map(transformSKU);
    }

    // 2. Add overall_availability if missing
    if (!transformed.overall_availability) {
        transformed.overall_availability = calculateOverallAvailability(transformed.product_skus);
    }

    // 3. Add variant_attributes if missing
    if (!transformed.variant_attributes) {
        transformed.variant_attributes = extractVariantAttributes(transformed.product_skus);
    }

    // 4. Add delivery_info if missing
    if (!transformed.delivery_info) {
        transformed.delivery_info = DEFAULT_DELIVERY_INFO;
    }

    // 5. Add order to content_cards
    if (transformed.content_cards) {
        transformed.content_cards = addOrderToContentCards(transformed.content_cards);
    }

    // 6. Ensure rating structure
    if (transformed.rating && typeof transformed.rating === 'object') {
        // Already in correct format
    } else if (typeof transformed.rating === 'number') {
        // Convert old format
        transformed.rating = {
            average: transformed.rating,
            count: 0
        };
    }

    return transformed;
}

/**
 * Validate transformed product
 */
function validateProduct(product) {
    const errors = [];

    // Required fields
    if (!product.product_id) errors.push('Missing product_id');
    if (!product.title) errors.push('Missing title');
    if (!product.category) errors.push('Missing category');

    // SKU validation
    if (!product.product_skus || product.product_skus.length === 0) {
        errors.push('No SKUs found');
    } else {
        product.product_skus.forEach((sku, index) => {
            if (!sku.sku_id) errors.push(`SKU ${index}: Missing sku_id`);
            if (sku.price === undefined) errors.push(`SKU ${index}: Missing price`);
            if (sku.available_quantity === undefined) errors.push(`SKU ${index}: Missing available_quantity`);
        });
    }

    // New required fields
    if (!product.overall_availability) errors.push('Missing overall_availability');
    if (product.variant_attributes === undefined) errors.push('Missing variant_attributes');
    if (!product.delivery_info) errors.push('Missing delivery_info');

    return {
        isValid: errors.length === 0,
        errors
    };
}

/**
 * Main migration function
 */
async function migrateProducts() {
    console.log('🚀 Starting Product Schema Migration');
    console.log(`📋 Mode: ${CONFIG.DRY_RUN ? 'DRY RUN (no changes will be made)' : 'LIVE MIGRATION'}`);
    console.log('');

    try {
        // Step 1: Create backup
        const backupPath = await createBackup();
        console.log('');

        // Step 2: Fetch all products
        console.log('📥 Fetching products...');
        const snapshot = await db.collection(CONFIG.COLLECTION).get();
        console.log(`✅ Found ${snapshot.size} products`);
        console.log('');

        // Step 3: Transform products
        console.log('🔄 Transforming products...');
        const transformedProducts = [];
        const validationErrors = [];

        snapshot.forEach(doc => {
            const originalData = doc.data();
            const transformedData = transformProduct(originalData);
            const validation = validateProduct(transformedData);

            if (validation.isValid) {
                transformedProducts.push({
                    id: doc.id,
                    original: originalData,
                    transformed: transformedData
                });
            } else {
                validationErrors.push({
                    id: doc.id,
                    errors: validation.errors
                });
            }
        });

        console.log(`✅ Successfully transformed: ${transformedProducts.length}`);
        console.log(`❌ Validation errors: ${validationErrors.length}`);
        console.log('');

        // Show validation errors
        if (validationErrors.length > 0) {
            console.log('⚠️  Validation Errors:');
            validationErrors.forEach(({ id, errors }) => {
                console.log(`  - ${id}:`);
                errors.forEach(err => console.log(`    • ${err}`));
            });
            console.log('');
        }

        // Step 4: Preview changes (first 3 products)
        console.log('👀 Preview of changes (first 3 products):');
        transformedProducts.slice(0, 3).forEach(({ id, original, transformed }) => {
            console.log(`\n📦 Product: ${id}`);
            console.log('  Changes:');

            // Check SKU changes
            if (original.product_skus && original.product_skus[0]) {
                const oldSku = original.product_skus[0];
                const newSku = transformed.product_skus[0];

                if (oldSku.pricing) {
                    console.log(`  ✓ SKU: Flattened pricing (${oldSku.pricing.selling_price} → ${newSku.price})`);
                }
                if (oldSku.inventory) {
                    console.log(`  ✓ SKU: Flattened inventory (${oldSku.inventory.stock_qty} → ${newSku.available_quantity})`);
                }
            }

            if (!original.overall_availability) {
                console.log(`  ✓ Added: overall_availability = "${transformed.overall_availability}"`);
            }

            if (!original.variant_attributes) {
                const variantCount = Object.keys(transformed.variant_attributes).length;
                console.log(`  ✓ Added: variant_attributes (${variantCount} attributes)`);
            }

            if (!original.delivery_info) {
                console.log(`  ✓ Added: delivery_info`);
            }

            if (original.content_cards && !original.content_cards[0]?.order) {
                console.log(`  ✓ Added: order field to ${transformed.content_cards.length} content cards`);
            }
        });
        console.log('');

        // Step 5: Update database (if not dry run)
        if (CONFIG.DRY_RUN) {
            console.log('🔍 DRY RUN MODE - No changes made to database');
            console.log('💡 Run without --dry-run flag to apply changes');
        } else {
            console.log('💾 Updating database...');

            // Update in batches
            let batch = db.batch();
            let batchCount = 0;
            let totalUpdated = 0;

            for (const { id, transformed } of transformedProducts) {
                const docRef = db.collection(CONFIG.COLLECTION).doc(id);
                batch.set(docRef, transformed, { merge: true });
                batchCount++;

                // Commit batch when it reaches limit
                if (batchCount >= CONFIG.BATCH_SIZE) {
                    await batch.commit();
                    totalUpdated += batchCount;
                    console.log(`  ✓ Updated ${totalUpdated} products...`);
                    batch = db.batch();
                    batchCount = 0;
                }
            }

            // Commit remaining batch
            if (batchCount > 0) {
                await batch.commit();
                totalUpdated += batchCount;
            }

            console.log(`✅ Successfully updated ${totalUpdated} products`);
        }

        // Summary
        console.log('');
        console.log('📊 Migration Summary:');
        console.log(`  • Total products: ${snapshot.size}`);
        console.log(`  • Successfully transformed: ${transformedProducts.length}`);
        console.log(`  • Validation errors: ${validationErrors.length}`);
        console.log(`  • Backup location: ${backupPath}`);
        console.log('');
        console.log('✅ Migration completed successfully!');

    } catch (error) {
        console.error('❌ Migration failed:', error);
        console.error('');
        console.error('💡 Your data is safe - restore from backup if needed');
        process.exit(1);
    }
}

/**
 * Rollback function (restore from backup)
 */
async function rollback(backupFile) {
    console.log('🔄 Rolling back from backup...');

    const backupPath = path.join(CONFIG.BACKUP_DIR, backupFile);

    if (!fs.existsSync(backupPath)) {
        console.error(`❌ Backup file not found: ${backupPath}`);
        process.exit(1);
    }

    const backup = JSON.parse(fs.readFileSync(backupPath, 'utf8'));

    console.log(`📦 Restoring ${backup.length} products...`);

    let batch = db.batch();
    let batchCount = 0;
    let totalRestored = 0;

    for (const { id, data } of backup) {
        const docRef = db.collection(CONFIG.COLLECTION).doc(id);
        batch.set(docRef, data);
        batchCount++;

        if (batchCount >= CONFIG.BATCH_SIZE) {
            await batch.commit();
            totalRestored += batchCount;
            console.log(`  ✓ Restored ${totalRestored} products...`);
            batch = db.batch();
            batchCount = 0;
        }
    }

    if (batchCount > 0) {
        await batch.commit();
        totalRestored += batchCount;
    }

    console.log(`✅ Successfully restored ${totalRestored} products`);
}

// Main execution
if (require.main === module) {
    const args = process.argv.slice(2);

    if (args.includes('--rollback')) {
        const backupFile = args[args.indexOf('--rollback') + 1];
        if (!backupFile) {
            console.error('❌ Please specify backup file: --rollback <filename>');
            process.exit(1);
        }
        rollback(backupFile).then(() => process.exit(0));
    } else {
        migrateProducts().then(() => process.exit(0));
    }
}

module.exports = { transformProduct, validateProduct };
