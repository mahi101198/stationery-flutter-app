import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/utils/exceptions/firebase_exceptions.dart';
import 'package:rps_stationery/utils/exceptions/format_exceptions.dart';
import 'package:rps_stationery/utils/exceptions/platform_exceptions.dart';

class PromoRepository extends GetxController {
  static PromoRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser!.uid;

  Future<T> safeCall<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      log("PromoRepository unexpected error -> $e", error: e);
      throw 'Something went wrong. Please try again';
    }
  }

  /// Validate and apply promo code
  Future<Map<String, dynamic>> validateAndApplyPromo({
    required String promoCode,
    required double orderTotal,
    required List<String> productIds,
    String? categoryId,
  }) async {
    return safeCall(() async {
      // Get promo code document
      final promoQuery = await _db
          .collection('promos')
          .where('code', isEqualTo: promoCode.toUpperCase())
          .limit(1)
          .get();

      if (promoQuery.docs.isEmpty) {
        throw 'Invalid promo code';
      }

      final promoDoc = promoQuery.docs.first;
      final promoData = promoDoc.data();
      final promoId = promoDoc.id;

      // Check if promo is active
      if (!promoData['isActive']) {
        throw 'This promo code is no longer active';
      }

      // Check validity dates
      final now = DateTime.now();
      final validFrom = (promoData['validFrom'] as Timestamp).toDate();
      final validUntil = (promoData['validUntil'] as Timestamp).toDate();

      if (now.isBefore(validFrom)) {
        throw 'This promo code is not yet valid';
      }

      if (now.isAfter(validUntil)) {
        throw 'This promo code has expired';
      }

      // Check usage limits
      final maxUsage = promoData['maxUsage'] as int?;
      final currentUsage = promoData['currentUsage'] as int;
      
      if (maxUsage != null && currentUsage >= maxUsage) {
        throw 'This promo code has reached its usage limit';
      }

      // Check user usage limit
      final maxUsagePerUser = promoData['maxUsagePerUser'] as int?;
      if (maxUsagePerUser != null) {
        final userUsage = await getUserPromoUsage(promoId);
        if (userUsage >= maxUsagePerUser) {
          throw 'You have already used this promo code the maximum number of times';
        }
      }

      // Check minimum order amount
      final minOrderAmount = (promoData['minOrderAmount'] as num?)?.toDouble();
      if (minOrderAmount != null && orderTotal < minOrderAmount) {
        throw 'Minimum order amount of \$${minOrderAmount.toStringAsFixed(2)} required for this promo code';
      }

      // Check maximum order amount
      final maxOrderAmount = (promoData['maxOrderAmount'] as num?)?.toDouble();
      if (maxOrderAmount != null && orderTotal > maxOrderAmount) {
        throw 'Maximum order amount of \$${maxOrderAmount.toStringAsFixed(2)} exceeded for this promo code';
      }

      // Check applicable products
      final applicableProducts = promoData['applicableProducts'] as List<dynamic>?;
      if (applicableProducts != null && applicableProducts.isNotEmpty) {
        final hasApplicableProduct = productIds.any(
          (productId) => applicableProducts.contains(productId),
        );
        if (!hasApplicableProduct) {
          throw 'This promo code is not applicable to the products in your cart';
        }
      }

      // Check applicable categories
      final applicableCategories = promoData['applicableCategories'] as List<dynamic>?;
      if (applicableCategories != null && applicableCategories.isNotEmpty) {
        if (categoryId == null || !applicableCategories.contains(categoryId)) {
          // Get product categories and check
          bool hasApplicableCategory = false;
          for (String productId in productIds) {
            final productDoc = await _db.collection('product_details').doc(productId).get();
            if (productDoc.exists) {
              final productCategory = productDoc.data()?['categoryId'];
              if (productCategory != null && applicableCategories.contains(productCategory)) {
                hasApplicableCategory = true;
                break;
              }
            }
          }
          
          if (!hasApplicableCategory) {
            throw 'This promo code is not applicable to the categories in your cart';
          }
        }
      }

      // Check if user is eligible (first-time user check)
      final isFirstTimeUserOnly = promoData['isFirstTimeUserOnly'] as bool? ?? false;
      if (isFirstTimeUserOnly) {
        final isFirstTimeUser = await checkIfFirstTimeUser();
        if (!isFirstTimeUser) {
          throw 'This promo code is only for first-time users';
        }
      }

      // Calculate discount
      final discountType = promoData['discountType'] as String; // 'percentage' or 'fixed'
      final discountValue = (promoData['discountValue'] as num).toDouble();
      final maxDiscount = (promoData['maxDiscount'] as num?)?.toDouble();

      double discountAmount = 0.0;
      
      if (discountType == 'percentage') {
        discountAmount = orderTotal * (discountValue / 100);
        if (maxDiscount != null && discountAmount > maxDiscount) {
          discountAmount = maxDiscount;
        }
      } else if (discountType == 'fixed') {
        discountAmount = discountValue;
        // Fixed discount cannot exceed order total
        if (discountAmount > orderTotal) {
          discountAmount = orderTotal;
        }
      }

      return {
        'promoId': promoId,
        'promoCode': promoData['code'],
        'discountType': discountType,
        'discountValue': discountValue,
        'discountAmount': discountAmount,
        'description': promoData['description'],
        'isValid': true,
      };
    });
  }

  /// Apply promo code to order (increment usage count)
  Future<void> applyPromoToOrder({
    required String promoId,
    required String orderId,
    required double discountAmount,
  }) async {
    return safeCall(() async {
      final batch = _db.batch();

      // Update promo usage count
      final promoRef = _db.collection('promos').doc(promoId);
      batch.update(promoRef, {
        'currentUsage': FieldValue.increment(1),
        'lastUsedAt': FieldValue.serverTimestamp(),
      });

      // Add user promo usage record
      final userPromoRef = _db
          .collection('users')
          .doc(userId)
          .collection('promoUsage')
          .doc();
      
      batch.set(userPromoRef, {
        'promoId': promoId,
        'orderId': orderId,
        'discountAmount': discountAmount,
        'usedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    });
  }

  /// Get user's promo usage count for a specific promo
  Future<int> getUserPromoUsage(String promoId) async {
    return safeCall(() async {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('promoUsage')
          .where('promoId', isEqualTo: promoId)
          .get();

      return snapshot.docs.length;
    });
  }

  /// Get all active promos
  Future<List<Map<String, dynamic>>> getActivePromos() async {
    return safeCall(() async {
      final now = Timestamp.now();
      
      final snapshot = await _db
          .collection('promos')
          .where('isActive', isEqualTo: true)
          .where('validFrom', isLessThanOrEqualTo: now)
          .where('validUntil', isGreaterThan: now)
          .orderBy('validUntil')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    });
  }

  /// Get user's available promos (not used up to limit)
  Future<List<Map<String, dynamic>>> getUserAvailablePromos() async {
    return safeCall(() async {
      final allPromos = await getActivePromos();
      final availablePromos = <Map<String, dynamic>>[];

      for (final promo in allPromos) {
        final promoId = promo['id'];
        final maxUsagePerUser = promo['maxUsagePerUser'] as int?;
        
        if (maxUsagePerUser != null) {
          final userUsage = await getUserPromoUsage(promoId);
          if (userUsage < maxUsagePerUser) {
            availablePromos.add(promo);
          }
        } else {
          // No user limit, so it's available
          availablePromos.add(promo);
        }
      }

      return availablePromos;
    });
  }

  /// Get user's promo usage history
  Future<List<Map<String, dynamic>>> getUserPromoHistory() async {
    return safeCall(() async {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('promoUsage')
          .orderBy('usedAt', descending: true)
          .get();

      final promoHistory = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // Get promo details
        final promoDoc = await _db.collection('promos').doc(data['promoId']).get();
        final promoData = promoDoc.exists ? promoDoc.data() : null;

        promoHistory.add({
          'id': doc.id,
          'promoId': data['promoId'],
          'promoCode': promoData?['code'],
          'promoDescription': promoData?['description'],
          'orderId': data['orderId'],
          'discountAmount': data['discountAmount'],
          'usedAt': data['usedAt'],
        });
      }

      return promoHistory;
    });
  }

  /// Check if user is a first-time user
  Future<bool> checkIfFirstTimeUser() async {
    return safeCall(() async {
      final orders = await _db
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('orderStatus', whereIn: ['delivered', 'completed'])
          .limit(1)
          .get();

      return orders.docs.isEmpty;
    });
  }

  /// Get promo by code
  Future<Map<String, dynamic>?> getPromoByCode(String promoCode) async {
    return safeCall(() async {
      final snapshot = await _db
          .collection('promos')
          .where('code', isEqualTo: promoCode.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return {
        'id': doc.id,
        ...doc.data(),
      };
    });
  }

  /// Check promo eligibility without applying
  Future<Map<String, dynamic>> checkPromoEligibility({
    required String promoCode,
    required double orderTotal,
    required List<String> productIds,
    String? categoryId,
  }) async {
    try {
      final result = await validateAndApplyPromo(
        promoCode: promoCode,
        orderTotal: orderTotal,
        productIds: productIds,
        categoryId: categoryId,
      );
      return {
        'isEligible': true,
        'message': 'Promo code is valid and can be applied',
        ...result,
      };
    } catch (e) {
      return {
        'isEligible': false,
        'message': e.toString(),
      };
    }
  }

  // Admin methods

  /// Create new promo (Admin only)
  Future<String> createPromo(Map<String, dynamic> promoData) async {
    return safeCall(() async {
      // Ensure code is uppercase
      promoData['code'] = promoData['code'].toString().toUpperCase();
      promoData['createdAt'] = FieldValue.serverTimestamp();
      promoData['updatedAt'] = FieldValue.serverTimestamp();
      promoData['currentUsage'] = 0;

      final docRef = await _db.collection('promos').add(promoData);
      return docRef.id;
    });
  }

  /// Update promo (Admin only)
  Future<void> updatePromo(String promoId, Map<String, dynamic> updateData) async {
    return safeCall(() async {
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Ensure code is uppercase if being updated
      if (updateData.containsKey('code')) {
        updateData['code'] = updateData['code'].toString().toUpperCase();
      }

      await _db.collection('promos').doc(promoId).update(updateData);
    });
  }

  /// Delete promo (Admin only)
  Future<void> deletePromo(String promoId) async {
    return safeCall(() async {
      await _db.collection('promos').doc(promoId).delete();
    });
  }

  /// Get all promos with statistics (Admin only)
  Future<List<Map<String, dynamic>>> getAllPromosWithStats() async {
    return safeCall(() async {
      final snapshot = await _db
          .collection('promos')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'usagePercentage': data['maxUsage'] != null 
              ? (data['currentUsage'] / data['maxUsage']) * 100 
              : 0.0,
        };
      }).toList();
    });
  }

  /// Get promo usage statistics (Admin only)
  Future<Map<String, dynamic>> getPromoUsageStats(String promoId) async {
    return safeCall(() async {
      // Get total usage from all users
      final usageSnapshot = await _db
          .collectionGroup('promoUsage')
          .where('promoId', isEqualTo: promoId)
          .get();

      final totalUsage = usageSnapshot.docs.length;
      double totalDiscount = 0.0;

      // Calculate total discount given
      for (final doc in usageSnapshot.docs) {
        final discountAmount = (doc.data()['discountAmount'] as num?)?.toDouble() ?? 0.0;
        totalDiscount += discountAmount;
      }

      // Get unique users count
      final uniqueUsers = <String>{};
      for (final doc in usageSnapshot.docs) {
        final userId = doc.reference.parent.parent!.id;
        uniqueUsers.add(userId);
      }

      return {
        'totalUsage': totalUsage,
        'uniqueUsers': uniqueUsers.length,
        'totalDiscountGiven': totalDiscount,
        'averageDiscountPerUse': totalUsage > 0 ? totalDiscount / totalUsage : 0.0,
      };
    });
  }
}
