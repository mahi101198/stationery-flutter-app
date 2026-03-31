import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/models/additional_models.dart';

/// Unified App Settings Service
/// Loads and manages all app configuration from Firestore 'settings' collection
/// This is the SINGLE SOURCE OF TRUTH for all app constants
class AppSettingsService extends GetxService {
  static AppSettingsService get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable settings - updates automatically when Firestore data changes
  final Rx<AppSettingsModel?> settings = Rx<AppSettingsModel?>(null);

  // Loading state
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;

  /// Initialize service and start listening to settings
  Future<AppSettingsService> init() async {
    try {
      log('🔧 Initializing AppSettingsService...', name: 'AppSettings');
      
      // Listen to settings collection in real-time
      _firestore
          .collection('settings')
          .doc('app')
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists) {
                settings.value = AppSettingsModel.fromFirestore(snapshot);
                hasError.value = false;
                log('✅ App settings loaded successfully', name: 'AppSettings');
                log('  - App Name: ${settings.value?.appName}', name: 'AppSettings');
                log('  - App Version: ${settings.value?.appVersion}', name: 'AppSettings');
                log('  - Delivery Fee: ₹${settings.value?.deliveryFee}', name: 'AppSettings');
                log('  - Free Delivery Above: ₹${settings.value?.freeDeliveryAbove}', name: 'AppSettings');
                log('  - Referrer Reward: ₹${settings.value?.referrerRewardValue}', name: 'AppSettings');
                log('  - Referee Reward: ₹${settings.value?.refereeRewardValue}', name: 'AppSettings');
              } else {
                log('❌ Settings document not found in database', name: 'AppSettings');
                hasError.value = true;
              }
              isLoading.value = false;
            },
            onError: (error) {
              log('❌ Error loading settings: $error', name: 'AppSettings');
              hasError.value = true;
              isLoading.value = false;
              // Keep using existing settings or defaults
            },
          );

      return this;
    } catch (e) {
      log('❌ Failed to initialize AppSettingsService: $e', name: 'AppSettings');
      hasError.value = true;
      isLoading.value = false;
      return this;
    }
  }


  // ============================================================================
  // GETTERS - Convenient access to settings values
  // ============================================================================

  /// App Information
  String get appName {
    if (settings.value?.appName == null) {
      throw Exception('App name not configured in database. Please contact support.');
    }
    return settings.value!.appName!;
  }
  
  String get appVersion {
    if (settings.value?.appVersion == null) {
      throw Exception('App version not configured in database. Please contact support.');
    }
    return settings.value!.appVersion!;
  }
  
  String get currency {
    if (settings.value?.currency == null) {
      throw Exception('Currency not configured in database. Please contact support.');
    }
    return settings.value!.currency!;
  }
  
  String get currencySymbol {
    if (settings.value?.currencySymbol == null) {
      throw Exception('Currency symbol not configured in database. Please contact support.');
    }
    return settings.value!.currencySymbol!;
  }

  /// Delivery & Pricing (tax is already included in product prices)
  double get deliveryFee {
    if (settings.value?.deliveryFee == null) {
      throw Exception('Delivery fee not configured in database. Please contact support.');
    }
    return settings.value!.deliveryFee!;
  }
  
  double get freeDeliveryThreshold {
    if (settings.value?.freeDeliveryAbove == null) {
      throw Exception('Free delivery threshold not configured in database. Please contact support.');
    }
    return settings.value!.freeDeliveryAbove!;
  }

  /// Contact Information
  String get supportPhone {
    return settings.value?.supportPhone ?? '+91-9876543210';
  }
  
  String get supportEmail {
    return settings.value?.supportEmail ?? 'support@rpsstationery.com';
  }

  /// Referral System
  double get referrerReward {
    if (settings.value?.referrerRewardValue == null) {
      throw Exception('Referrer reward not configured in database. Please contact support.');
    }
    return settings.value!.referrerRewardValue!;
  }
  
  double get refereeReward {
    if (settings.value?.refereeRewardValue == null) {
      throw Exception('Referee reward not configured in database. Please contact support.');
    }
    return settings.value!.refereeRewardValue!;
  }
  
  double get minOrderAmount {
    if (settings.value?.minOrderAmount == null) {
      throw Exception('Minimum order amount not configured in database. Please contact support.');
    }
    return settings.value!.minOrderAmount!;
  }
  
  double get minWithdrawalAmount {
    if (settings.value?.minWithdrawalAmount == null) {
      throw Exception('Minimum withdrawal amount not configured in database. Please contact support.');
    }
    return settings.value!.minWithdrawalAmount!;
  }
  
  bool get isReferralActive {
    if (settings.value?.isReferralActive == null) {
      throw Exception('Referral system status not configured in database. Please contact support.');
    }
    return settings.value!.isReferralActive!;
  }

  /// Payment Configuration
  String get razorpayKeyId {
    final key = settings.value?.razorpayKeyId;
    if (key == null || key.isEmpty) {
      throw Exception('Razorpay key not configured in database. Please contact support.');
    }
    return key;
  }

  /// App Download Link
  String? get appDownloadLink {
    return settings.value?.appDownloadLink;
  }

  /// Available Pincodes
  List<String> get availablePincodes {
    return settings.value?.availablePincodes ?? [];
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Calculate delivery charge based on cart total
  double calculateDeliveryCharge(double cartTotal) {
    return cartTotal >= freeDeliveryThreshold ? 0.0 : deliveryFee;
  }

  /// Check if free delivery is applicable
  bool isFreeDeliveryApplicable(double cartTotal) {
    return cartTotal >= freeDeliveryThreshold;
  }

  /// Get formatted delivery message
  String getDeliveryMessage(double cartTotal) {
    if (isFreeDeliveryApplicable(cartTotal)) {
      return 'Free Delivery';
    } else {
      final remaining = freeDeliveryThreshold - cartTotal;
      return 'Add $currencySymbol${remaining.toStringAsFixed(0)} for free delivery';
    }
  }

  // ============================================================================
  // ADMIN METHODS (for updating settings)
  // ============================================================================

  /// Update settings (Admin only)
  Future<void> updateSettings(Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection('settings')
          .doc('app')
          .update({
            ...updates,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
      log('✅ Settings updated successfully', name: 'AppSettings');
    } catch (e) {
      log('❌ Failed to update settings: $e', name: 'AppSettings');
      rethrow;
    }
  }

  /// Refresh settings manually
  Future<void> refresh() async {
    try {
      isLoading.value = true;
      final snapshot = await _firestore
          .collection('settings')
          .doc('app')
          .get();

      if (snapshot.exists) {
        settings.value = AppSettingsModel.fromFirestore(snapshot);
        hasError.value = false;
      }
      isLoading.value = false;
    } catch (e) {
      log('❌ Failed to refresh settings: $e', name: 'AppSettings');
      hasError.value = true;
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    // Cleanup if needed
    super.onClose();
  }
}

