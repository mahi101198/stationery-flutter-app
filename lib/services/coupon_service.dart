import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/models/coupon_model.dart';
import 'package:rps_stationery/data/models/cart_model.dart';

/// Coupon validation result
class CouponValidationResult {
  final bool isValid;
  final String? message;
  final CouponModel? coupon;
  final double discountAmount;

  const CouponValidationResult({
    required this.isValid,
    this.message,
    this.coupon,
    this.discountAmount = 0.0,
  });
}

/// Coupon Service for validation and management
class CouponService extends GetxService {
  static CouponService get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Validate coupon code
  Future<CouponValidationResult> validateCoupon({
    required String couponCode,
    required double orderTotal,
    required List<CartItem> cartItems,
  }) async {
    try {
      print('🎟️ ════════════════════════════════════════════════════════');
      print('🎟️ VALIDATING COUPON CODE');
      print('🎟️ ════════════════════════════════════════════════════════');
      print('  Code: $couponCode');
      print('  Order Total: ₹$orderTotal');
      print('  Cart Items: ${cartItems.length}');
      print('🎟️ ════════════════════════════════════════════════════════');

      // 1. Find coupon by code (case-insensitive)
      final querySnapshot = await _firestore
          .collection('coupons')
          .where('code', isEqualTo: couponCode.toUpperCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('❌ Coupon not found');
        return const CouponValidationResult(
          isValid: false,
          message: 'Invalid coupon code',
        );
      }

      final coupon = CouponModel.fromFirestore(querySnapshot.docs.first);
      print('✅ Coupon found: ${coupon.title}');
      print('  Type: ${coupon.type}');
      print('  Value: ${coupon.value}');
      print('  Is Active: ${coupon.isActive}');
      print('  Max Usage: ${coupon.maxUsage} (0 = unlimited)');
      print('  Used Count: ${coupon.usedCount}');

      // 2. Check if coupon is active
      if (!coupon.isActive) {
        print('❌ Coupon is not active');
        return const CouponValidationResult(
          isValid: false,
          message: 'This coupon is not active',
        );
      }

      // 3. Check if coupon is valid (not expired, usage limit not reached)
      if (!coupon.isValid()) {
        final now = DateTime.now();
        if (now.isBefore(coupon.validFrom)) {
          print('❌ Coupon not yet valid');
          return CouponValidationResult(
            isValid: false,
            message: 'Coupon valid from ${_formatDate(coupon.validFrom)}',
          );
        }
        if (now.isAfter(coupon.validUntil)) {
          print('❌ Coupon expired');
          return const CouponValidationResult(
            isValid: false,
            message: 'This coupon has expired',
          );
        }
        // maxUsage = 0 means unlimited usage
        if (coupon.maxUsage > 0 && coupon.usedCount >= coupon.maxUsage) {
          print('❌ Coupon usage limit reached: ${coupon.usedCount}/${coupon.maxUsage}');
          return const CouponValidationResult(
            isValid: false,
            message: 'This coupon has reached its usage limit',
          );
        }
      }

      // 4. Check minimum order value
      if (!coupon.meetsMinimumOrder(orderTotal)) {
        print('❌ Minimum order value not met');
        return CouponValidationResult(
          isValid: false,
          message: 'Minimum order value is ₹${coupon.minOrderValue.toInt()}',
        );
      }

      // 5. Check product/category applicability
      if (coupon.applicableProducts.isNotEmpty || coupon.applicableCategories.isNotEmpty) {
        print('🔍 Checking product/category applicability...');
        
        // Get product IDs and category IDs from cart
        final productIds = cartItems.map((item) => item.productId).toList();
        
        // Fetch products to get category IDs
        final categoryIds = await _getCategoryIdsFromProducts(productIds);
        
        print('  Product IDs: $productIds');
        print('  Category IDs: $categoryIds');
        print('  Applicable Products: ${coupon.applicableProducts}');
        print('  Applicable Categories: ${coupon.applicableCategories}');

        final isApplicable = coupon.isApplicableToCart(
          productIds: productIds,
          categoryIds: categoryIds,
        );

        if (!isApplicable) {
          print('❌ Coupon not applicable to cart items');
          return const CouponValidationResult(
            isValid: false,
            message: 'This coupon is not applicable to your cart items',
          );
        }
        
        print('✅ Coupon applicable to cart');
      }

      // 6. Calculate discount
      final discountAmount = coupon.calculateDiscount(orderTotal);
      print('✅ ════════════════════════════════════════════════════════');
      print('✅ COUPON VALID!');
      print('✅ ════════════════════════════════════════════════════════');
      print('  Discount Type: ${coupon.type}');
      print('  Discount Value: ${coupon.value}');
      print('  Discount Amount: ₹$discountAmount');
      print('  Order Total: ₹$orderTotal');
      print('  Final Amount: ₹${orderTotal - discountAmount}');
      print('✅ ════════════════════════════════════════════════════════');

      return CouponValidationResult(
        isValid: true,
        message: 'Coupon applied successfully! You saved ₹${discountAmount.toInt()}',
        coupon: coupon,
        discountAmount: discountAmount,
      );

    } catch (e) {
      print('❌ ════════════════════════════════════════════════════════');
      print('❌ ERROR VALIDATING COUPON');
      print('❌ ════════════════════════════════════════════════════════');
      print('  Error: $e');
      print('  Error type: ${e.runtimeType}');
      print('❌ ════════════════════════════════════════════════════════');
      
      return CouponValidationResult(
        isValid: false,
        message: 'Error validating coupon: ${e.toString()}',
      );
    }
  }

  /// Get category IDs from product IDs
  Future<List<String>> _getCategoryIdsFromProducts(List<String> productIds) async {
    try {
      final categoryIds = <String>{};
      
      for (final productId in productIds) {
        final productDoc = await _firestore
            .collection('product_details')
            .doc(productId)
            .get();
        
        if (productDoc.exists) {
          final data = productDoc.data();
          if (data != null && data.containsKey('categoryId')) {
            categoryIds.add(data['categoryId']);
          }
        }
      }
      
      return categoryIds.toList();
    } catch (e) {
      print('Error fetching category IDs: $e');
      return [];
    }
  }

  /// Get all active coupons (for displaying available coupons)
  Future<List<CouponModel>> getActiveCoupons() async {
    try {
      final querySnapshot = await _firestore
          .collection('coupons')
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CouponModel.fromFirestore(doc))
          .where((coupon) => coupon.isValid())
          .toList();
    } catch (e) {
      print('Error fetching active coupons: $e');
      return [];
    }
  }

  /// Increment coupon usage count
  Future<void> incrementUsageCount(String couponId) async {
    try {
      await _firestore.collection('coupons').doc(couponId).update({
        'usedCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Coupon usage count incremented: $couponId');
    } catch (e) {
      print('Error incrementing coupon usage: $e');
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}


