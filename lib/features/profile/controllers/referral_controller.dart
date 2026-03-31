import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/repositories/auth/auth_repository.dart';
import 'package:rps_stationery/services/app_settings_service.dart';
import 'package:rps_stationery/services/referral_service.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';
import 'package:share_plus/share_plus.dart';

/// Referral Controller for managing referral system state and operations
class ReferralController extends GetxController {
  static ReferralController get instance => Get.find();

  final ReferralService _referralService = Get.put(ReferralService());
  final AuthRepository _authRepository = Get.find<AuthRepository>();

  // Observable variables
  final RxString referralCode = ''.obs;
  final RxInt totalReferrals = 0.obs;
  final RxDouble totalEarnings = 0.0.obs;
  final RxDouble pendingEarnings = 0.0.obs;
  final RxDouble withdrawnEarnings = 0.0.obs;
  final RxList<Map<String, dynamic>> referredUsers = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadReferralData();
  }

  /// Load referral data for current user
  Future<void> loadReferralData() async {
    try {
      isLoading.value = true;
      final userId = _authRepository.currentUser?.uid;
      
      if (userId == null) {
        print('❌ No user logged in');
        return;
      }

      // Fetch referral stats
      final stats = await _referralService.getReferralStats(userId);
      referralCode.value = stats['referralCode'] ?? '';
      totalReferrals.value = stats['totalReferrals'] ?? 0;
      totalEarnings.value = stats['totalEarnings'] ?? 0.0;
      pendingEarnings.value = stats['pendingEarnings'] ?? 0.0;
      withdrawnEarnings.value = stats['withdrawnEarnings'] ?? 0.0;

      // Fetch referred users
      referredUsers.value = await _referralService.getReferredUsers(userId);

      print('✅ Referral data loaded successfully');
    } catch (e) {
      print('❌ Error loading referral data: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load referral data',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Copy referral code to clipboard
  Future<void> copyReferralCode() async {
    try {
      if (referralCode.value.isEmpty) {
        TLoaders.warningSnackBar(
          title: 'No Code',
          message: 'Referral code not available',
        );
        return;
      }

      await Clipboard.setData(ClipboardData(text: referralCode.value));
      TLoaders.successSnackBar(
        title: 'Copied!',
        message: 'Referral code copied to clipboard',
      );
    } catch (e) {
      print('❌ Error copying referral code: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to copy referral code',
      );
    }
  }

  /// Share referral code
  Future<void> shareReferralCode() async {
    try {
      if (referralCode.value.isEmpty) {
        TLoaders.warningSnackBar(
          title: 'No Code',
          message: 'Referral code not available',
        );
        return;
      }

      // Get app download link from settings
      final appDownloadLink = AppSettingsService.instance.appDownloadLink;
      
      // Build the share message
      final message = '''
🎉 Join RPS Shopee and get ₹${ReferralService.instance.refereeReward} in your wallet!

Use my referral code: ${referralCode.value}

Download the app and start shopping for quality stationery products!${appDownloadLink != null && appDownloadLink.isNotEmpty ? '\n\n$appDownloadLink' : ''}
      ''';

      await Share.share(message);
      print('✅ Referral code shared successfully');
    } catch (e) {
      print('❌ Error sharing referral code: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to share referral code',
      );
    }
  }

  /// Get referral link (if you have a web app or deep linking)
  String getReferralLink() {
    // Update this with your actual app link/deep link
    return 'https://rpsstationery.com/signup?ref=${referralCode.value}';
  }

  /// Format currency
  String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0)}';
  }

  /// Format date
  String formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    DateTime date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'N/A';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

