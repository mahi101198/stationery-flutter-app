/**
 * Verify Product Schema Migration
 * 
 * Fetches a product from Firestore and displays its structure
 * to verify the migration was successful
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./rps-statationary-jaipur-firebase-adminsdk-fbsvc-b49816e7a3.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function verifyMigration() {
    console.log('🔍 Verifying Product Schema Migration\n');

    try {
        // Fetch the first product (a3-color-sheets)
        const productId = 'a3-color-sheets';
        console.log(`📦 Fetching product: ${productId}\n`);

        const doc = await db.collection('product_details').doc(productId).get();

        if (!doc.exists) {
            console.log('❌ Product not found');
            process.exit(1);
        }

        const product = doc.data();

        console.log('✅ Product fetched successfully!\n');
        console.log('='.repeat(80));
        console.log('PRODUCT STRUCTURE VERIFICATION');
        console.log('='.repeat(80));
        console.log('');

        // Check Core Fields
        console.log('📋 CORE PRODUCT INFO:');
        console.log(`  ✓ product_id: "${product.product_id}"`);
        console.log(`  ✓ title: "${product.title}"`);
        console.log(`  ✓ subtitle: "${product.subtitle || 'N/A'}"`);
        console.log(`  ✓ brand: "${product.brand}"`);
        console.log(`  ✓ category: "${product.category}"`);
        console.log(`  ✓ sub_category: "${product.sub_category}"`);
        console.log('');

        // Check Rating
        console.log('⭐ RATING:');
        if (product.rating) {
            console.log(`  ✓ average: ${product.rating.average}`);
            console.log(`  ✓ count: ${product.rating.count}`);
        } else {
            console.log('  ⚠️  No rating data');
        }
        console.log('');

        // Check Media
        console.log('🖼️  MEDIA:');
        if (product.media) {
            console.log(`  ✓ main_image: ${product.media.main_image?.url ? 'Present' : 'Missing'}`);
            console.log(`  ✓ gallery: ${product.media.gallery?.length || 0} images`);
        } else {
            console.log('  ❌ No media data');
        }
        console.log('');

        // Check NEW FIELDS (from migration)
        console.log('🆕 NEW FIELDS (Added by Migration):');

        // Overall Availability
        if (product.overall_availability) {
            console.log(`  ✅ overall_availability: "${product.overall_availability}"`);
        } else {
            console.log('  ❌ overall_availability: MISSING');
        }

        // Variant Attributes
        if (product.variant_attributes !== undefined) {
            const variantCount = Object.keys(product.variant_attributes).length;
            console.log(`  ✅ variant_attributes: ${variantCount} attributes`);
            if (variantCount > 0) {
                Object.keys(product.variant_attributes).forEach(key => {
                    console.log(`     - ${key}: [${product.variant_attributes[key].join(', ')}]`);
                });
            }
        } else {
            console.log('  ❌ variant_attributes: MISSING');
        }

        // Delivery Info
        if (product.delivery_info) {
            console.log(`  ✅ delivery_info:`);
            console.log(`     - estimated_delivery: "${product.delivery_info.estimated_delivery}"`);
            console.log(`     - return_policy: "${product.delivery_info.return_policy}"`);
            console.log(`     - cod_available: ${product.delivery_info.cod_available}`);
            console.log(`     - free_delivery_threshold: ${product.delivery_info.free_delivery_threshold}`);
        } else {
            console.log('  ❌ delivery_info: MISSING');
        }
        console.log('');

        // Check SKU Structure
        console.log('📦 PRODUCT SKUs (Flattened Structure):');
        if (product.product_skus && product.product_skus.length > 0) {
            product.product_skus.forEach((sku, index) => {
                console.log(`\n  SKU #${index + 1}: ${sku.sku_id}`);
                console.log(`    Attributes:`);
                if (sku.attributes) {
                    Object.entries(sku.attributes).forEach(([key, value]) => {
                        console.log(`      - ${key}: "${value}"`);
                    });
                }

                // Check NEW flat structure
                console.log(`    Pricing (NEW FLAT STRUCTURE):`);
                if (sku.price !== undefined) {
                    console.log(`      ✅ price: ${sku.price}`);
                } else {
                    console.log(`      ❌ price: MISSING`);
                }

                if (sku.mrp !== undefined) {
                    console.log(`      ✅ mrp: ${sku.mrp}`);
                } else {
                    console.log(`      ❌ mrp: MISSING`);
                }

                if (sku.currency) {
                    console.log(`      ✅ currency: "${sku.currency}"`);
                } else {
                    console.log(`      ❌ currency: MISSING`);
                }

                console.log(`    Inventory (NEW FLAT STRUCTURE):`);
                if (sku.availability) {
                    console.log(`      ✅ availability: "${sku.availability}"`);
                } else {
                    console.log(`      ❌ availability: MISSING`);
                }

                if (sku.available_quantity !== undefined) {
                    console.log(`      ✅ available_quantity: ${sku.available_quantity}`);
                } else {
                    console.log(`      ❌ available_quantity: MISSING`);
                }

                // Check OLD nested structure (should be removed)
                if (sku.pricing) {
                    console.log(`      ⚠️  OLD pricing object still present (should be removed)`);
                }
                if (sku.inventory) {
                    console.log(`      ⚠️  OLD inventory object still present (should be removed)`);
                }
            });
        } else {
            console.log('  ❌ No SKUs found');
        }
        console.log('');

        // Check Content Cards
        console.log('📄 CONTENT CARDS:');
        if (product.content_cards && product.content_cards.length > 0) {
            console.log(`  Total cards: ${product.content_cards.length}\n`);
            product.content_cards.forEach((card, index) => {
                console.log(`  Card #${index + 1}:`);
                console.log(`    - card_id: "${card.card_id}"`);
                console.log(`    - title: "${card.title}"`);
                console.log(`    - type: "${card.type}"`);

                // Check NEW order field
                if (card.order !== undefined) {
                    console.log(`    - order: ${card.order} ✅`);
                } else {
                    console.log(`    - order: MISSING ❌`);
                }

                // Show data preview
                if (card.type === 'list' && Array.isArray(card.data)) {
                    console.log(`    - data: [${card.data.length} items]`);
                } else if (card.type === 'key_value' && typeof card.data === 'object') {
                    console.log(`    - data: {${Object.keys(card.data).length} specs}`);
                } else if (card.type === 'text') {
                    const preview = card.data.substring(0, 50);
                    console.log(`    - data: "${preview}..."`);
                }
                console.log('');
            });
        } else {
            console.log('  ⚠️  No content cards');
        }

        // Check Purchase Limits
        console.log('🛒 PURCHASE LIMITS:');
        if (product.purchase_limits) {
            console.log(`  ✓ max_per_order: ${product.purchase_limits.max_per_order}`);
            if (product.purchase_limits.max_per_user_per_day) {
                console.log(`  ✓ max_per_user_per_day: ${product.purchase_limits.max_per_user_per_day}`);
            }
        } else {
            console.log('  ⚠️  No purchase limits');
        }
        console.log('');

        // Final Verification Summary
        console.log('='.repeat(80));
        console.log('MIGRATION VERIFICATION SUMMARY');
        console.log('='.repeat(80));
        console.log('');

        const checks = {
            'Core fields present': !!(product.product_id && product.title && product.category),
            'overall_availability added': !!product.overall_availability,
            'variant_attributes added': product.variant_attributes !== undefined,
            'delivery_info added': !!product.delivery_info,
            'SKU price flattened': product.product_skus?.[0]?.price !== undefined,
            'SKU availability flattened': product.product_skus?.[0]?.availability !== undefined,
            'SKU available_quantity flattened': product.product_skus?.[0]?.available_quantity !== undefined,
            'Content cards have order': product.content_cards?.[0]?.order !== undefined,
            'Rating structure correct': product.rating?.average !== undefined,
        };

        let passedChecks = 0;
        let totalChecks = Object.keys(checks).length;

        Object.entries(checks).forEach(([check, passed]) => {
            const icon = passed ? '✅' : '❌';
            console.log(`${icon} ${check}`);
            if (passed) passedChecks++;
        });

        console.log('');
        console.log(`Score: ${passedChecks}/${totalChecks} checks passed`);
        console.log('');

        if (passedChecks === totalChecks) {
            console.log('🎉 MIGRATION SUCCESSFUL! All checks passed!');
            console.log('✅ Database is ready for the new UI!');
        } else {
            console.log('⚠️  Some checks failed. Review the output above.');
        }

        console.log('');
        console.log('='.repeat(80));

        // Save full product JSON for reference
        const fs = require('fs');
        fs.writeFileSync('verification_output.json', JSON.stringify(product, null, 2));
        console.log('📝 Full product data saved to: verification_output.json');

    } catch (error) {
        console.error('❌ Verification failed:', error);
        process.exit(1);
    }

    process.exit(0);
}

verifyMigration();
