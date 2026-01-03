import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/repositories/promo_repository.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';

class PromoController extends GetxController {
  static PromoController get instance => Get.find();

  final promoRepository = Get.put(PromoRepository());
  
  // Observable variables
  RxBool isLoading = false.obs;
  RxList<Map<String, dynamic>> activePromos = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> userAvailablePromos = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> userPromoHistory = <Map<String, dynamic>>[].obs;
  
  // Applied promo state
  Rx<Map<String, dynamic>?> appliedPromo = Rx<Map<String, dynamic>?>(null);
  RxDouble discountAmount = 0.0.obs;
  RxBool isPromoApplied = false.obs;
  
  // Form controller
  final promoCodeController = TextEditingController();
  RxString promoCodeError = ''.obs;
  RxBool isValidatingPromo = false.obs;

  @override
  void onClose() {
    promoCodeController.dispose();
    super.onClose();
  }

  /// Validate and apply promo code
  Future<void> validateAndApplyPromo({
    required double orderTotal,
    required List<String> productIds,
    String? categoryId,
  }) async {
    final promoCode = promoCodeController.text.trim();
    
    if (promoCode.isEmpty) {
      promoCodeError.value = 'Please enter a promo code';
      return;
    }

    try {
      isValidatingPromo.value = true;
      promoCodeError.value = '';

      final result = await promoRepository.validateAndApplyPromo(
        promoCode: promoCode,
        orderTotal: orderTotal,
        productIds: productIds,
        categoryId: categoryId,
      );

      // Apply the promo
      appliedPromo.value = result;
      discountAmount.value = result['discountAmount'];
      isPromoApplied.value = true;

      TLoaders.successSnackBar(
        title: 'Promo Applied!',
        message: 'You saved \$${result['discountAmount'].toStringAsFixed(2)}',
      );

      // Clear the text field
      promoCodeController.clear();

    } catch (e) {
      log('Error validating promo: $e');
      promoCodeError.value = e.toString();
      
      TLoaders.errorSnackBar(
        title: 'Invalid Promo Code',
        message: e.toString(),
      );
    } finally {
      isValidatingPromo.value = false;
    }
  }

  /// Remove applied promo
  void removeAppliedPromo() {
    appliedPromo.value = null;
    discountAmount.value = 0.0;
    isPromoApplied.value = false;
    promoCodeError.value = '';
    
    TLoaders.successSnackBar(
      title: 'Promo Removed',
      message: 'Promo code has been removed from your order.',
    );
  }

  /// Check promo eligibility without applying
  Future<bool> checkPromoEligibility({
    required String promoCode,
    required double orderTotal,
    required List<String> productIds,
    String? categoryId,
  }) async {
    try {
      final result = await promoRepository.checkPromoEligibility(
        promoCode: promoCode,
        orderTotal: orderTotal,
        productIds: productIds,
        categoryId: categoryId,
      );
      
      return result['isEligible'] ?? false;
    } catch (e) {
      log('Error checking promo eligibility: $e');
      return false;
    }
  }

  /// Apply promo to order (call this when order is placed)
  Future<void> applyPromoToOrder(String orderId) async {
    if (!isPromoApplied.value || appliedPromo.value == null) return;

    try {
      await promoRepository.applyPromoToOrder(
        promoId: appliedPromo.value!['promoId'],
        orderId: orderId,
        discountAmount: discountAmount.value,
      );
      
      log('Promo applied to order: $orderId');
    } catch (e) {
      log('Error applying promo to order: $e');
      // Note: We don't show error to user here as order is already placed
      // This should be handled by backend/cloud functions as a backup
    }
  }

  /// Get all active promos
  Future<void> getActivePromos() async {
    try {
      isLoading.value = true;
      final promos = await promoRepository.getActivePromos();
      activePromos.value = promos;
    } catch (e) {
      log('Error getting active promos: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load available promos. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Get user's available promos
  Future<void> getUserAvailablePromos() async {
    try {
      isLoading.value = true;
      final promos = await promoRepository.getUserAvailablePromos();
      userAvailablePromos.value = promos;
    } catch (e) {
      log('Error getting user available promos: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load your available promos. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Get user's promo usage history
  Future<void> getUserPromoHistory() async {
    try {
      isLoading.value = true;
      final history = await promoRepository.getUserPromoHistory();
      userPromoHistory.value = history;
    } catch (e) {
      log('Error getting user promo history: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load your promo history. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Select promo from available promos list
  void selectPromo(Map<String, dynamic> promo) {
    promoCodeController.text = promo['code'] ?? '';
    Get.back(); // Close promo selection dialog/sheet
  }

  /// Show available promos bottom sheet
  void showAvailablePromos({
    required double orderTotal,
    required List<String> productIds,
    String? categoryId,
  }) {
    // Refresh available promos first
    getUserAvailablePromos();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Promos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Obx(
                () => isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : userAvailablePromos.isEmpty
                        ? const Center(
                            child: Text(
                              'No promos available at the moment',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: userAvailablePromos.length,
                            itemBuilder: (context, index) {
                              final promo = userAvailablePromos[index];
                              return _buildPromoCard(promo, orderTotal, productIds, categoryId);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildPromoCard(
    Map<String, dynamic> promo,
    double orderTotal,
    List<String> productIds,
    String? categoryId,
  ) {
    final code = promo['code'] ?? '';
    final description = promo['description'] ?? '';
    final discountType = promo['discountType'] ?? '';
    final discountValue = promo['discountValue'] ?? 0;
    final minOrderAmount = promo['minOrderAmount'];
    final maxDiscount = promo['maxDiscount'];
    
    String discountText = '';
    if (discountType == 'percentage') {
      discountText = '${discountValue.toInt()}% OFF';
      if (maxDiscount != null) {
        discountText += ' (up to \$${maxDiscount.toStringAsFixed(2)})';
      }
    } else if (discountType == 'fixed') {
      discountText = '\$${discountValue.toStringAsFixed(2)} OFF';
    }

    String minOrderText = '';
    if (minOrderAmount != null) {
      minOrderText = 'Min. order: \$${minOrderAmount.toStringAsFixed(2)}';
    }

    final validUntil = promo['validUntil'];
    String validityText = '';
    if (validUntil != null) {
      final date = (validUntil as Timestamp).toDate();
      validityText = 'Valid until ${date.day}/${date.month}/${date.year}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          // Check if promo is applicable before selecting
          final isEligible = await checkPromoEligibility(
            promoCode: code,
            orderTotal: orderTotal,
            productIds: productIds,
            categoryId: categoryId,
          );
          
          if (isEligible) {
            selectPromo(promo);
          } else {
            TLoaders.errorSnackBar(
              title: 'Not Applicable',
              message: 'This promo code is not applicable to your current order.',
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      discountText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (minOrderText.isNotEmpty || validityText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          [minOrderText, validityText]
                              .where((text) => text.isNotEmpty)
                              .join(' • '),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Format promo discount text for display
  String formatPromoDiscountText(Map<String, dynamic> promo) {
    final discountType = promo['discountType'] ?? '';
    final discountValue = promo['discountValue'] ?? 0;
    final maxDiscount = promo['maxDiscount'];
    
    if (discountType == 'percentage') {
      String text = '${discountValue.toInt()}% discount';
      if (maxDiscount != null) {
        text += ' (max \$${maxDiscount.toStringAsFixed(2)})';
      }
      return text;
    } else if (discountType == 'fixed') {
      return '\$${discountValue.toStringAsFixed(2)} discount';
    }
    
    return 'Discount applied';
  }

  /// Reset promo state (call when cart is cleared or user logs out)
  void resetPromoState() {
    appliedPromo.value = null;
    discountAmount.value = 0.0;
    isPromoApplied.value = false;
    promoCodeController.clear();
    promoCodeError.value = '';
    isValidatingPromo.value = false;
  }

  /// Auto-apply best available promo (optional feature)
  Future<void> autoApplyBestPromo({
    required double orderTotal,
    required List<String> productIds,
    String? categoryId,
  }) async {
    try {
      await getUserAvailablePromos();
      
      Map<String, dynamic>? bestPromo;
      double bestDiscount = 0.0;
      
      for (final promo in userAvailablePromos) {
        try {
          final result = await promoRepository.validateAndApplyPromo(
            promoCode: promo['code'],
            orderTotal: orderTotal,
            productIds: productIds,
            categoryId: categoryId,
          );
          
          final discount = result['discountAmount'] as double;
          if (discount > bestDiscount) {
            bestDiscount = discount;
            bestPromo = result;
          }
        } catch (e) {
          // Skip invalid promos
          continue;
        }
      }
      
      if (bestPromo != null) {
        appliedPromo.value = bestPromo;
        discountAmount.value = bestDiscount;
        isPromoApplied.value = true;
        
        TLoaders.successSnackBar(
          title: 'Best Promo Applied!',
          message: 'We automatically applied the best available promo for you. Saved \$${bestDiscount.toStringAsFixed(2)}!',
        );
      }
    } catch (e) {
      log('Error auto-applying best promo: $e');
      // Don't show error to user for auto-apply
    }
  }

  /// Validate promo code as user types
  void validatePromoCodeInput(String value) {
    if (value.isEmpty) {
      promoCodeError.value = '';
    } else if (value.length < 3) {
      promoCodeError.value = 'Promo code must be at least 3 characters';
    } else {
      promoCodeError.value = '';
    }
  }

  /// Get applied promo info for display
  Map<String, dynamic>? getAppliedPromoInfo() {
    if (!isPromoApplied.value || appliedPromo.value == null) return null;
    
    return {
      'code': appliedPromo.value!['promoCode'],
      'discountAmount': discountAmount.value,
      'description': appliedPromo.value!['description'],
      'discountText': formatPromoDiscountText(appliedPromo.value!),
    };
  }
}
