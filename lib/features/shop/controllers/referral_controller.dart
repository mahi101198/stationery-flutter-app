import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rps_stationery/data/repositories/referral_repository.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';

class ReferralController extends GetxController {
  static ReferralController get instance => Get.find();

  final referralRepository = Get.put(ReferralRepository());
  
  // Observable variables
  RxBool isLoading = false.obs;
  Rx<Map<String, dynamic>?> referralInfo = Rx<Map<String, dynamic>?>(null);
  RxMap<String, dynamic> earningsSummary = <String, dynamic>{}.obs;
  RxList<Map<String, dynamic>> referralHistory = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> withdrawalHistory = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> leaderboard = <Map<String, dynamic>>[].obs;
  RxMap<String, dynamic> referralSettings = <String, dynamic>{}.obs;
  
  // Form controllers
  final referralCodeController = TextEditingController();
  final withdrawalAmountController = TextEditingController();
  RxString referralCodeError = ''.obs;
  RxString withdrawalError = ''.obs;
  RxBool isApplyingCode = false.obs;
  RxBool isRequestingWithdrawal = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize referral system for user
    initializeReferralSystem();
  }

  @override
  void onClose() {
    referralCodeController.dispose();
    withdrawalAmountController.dispose();
    super.onClose();
  }

  /// Initialize referral system for the current user
  Future<void> initializeReferralSystem() async {
    try {
      // Create referral record if it doesn't exist
      await referralRepository.createReferralRecord();
      
      // Load user's referral data
      await Future.wait([
        getUserReferralInfo(),
        getReferralEarningsSummary(),
        getReferralSettings(),
      ]);
    } catch (e) {
      log('Error initializing referral system: $e');
    }
  }

  /// Apply referral code during registration
  Future<void> applyReferralCode() async {
    final code = referralCodeController.text.trim();
    
    if (code.isEmpty) {
      referralCodeError.value = 'Please enter a referral code';
      return;
    }

    if (!referralRepository.isValidReferralCodeFormat(code)) {
      referralCodeError.value = 'Invalid referral code format';
      return;
    }

    try {
      isApplyingCode.value = true;
      referralCodeError.value = '';

      await referralRepository.applyReferralCode(code);

      TLoaders.successSnackBar(
        title: 'Referral Applied!',
        message: 'You\'ll receive your welcome bonus after your first order.',
      );

      referralCodeController.clear();
      
      // Refresh data
      await getUserReferralHistory();

    } catch (e) {
      log('Error applying referral code: $e');
      referralCodeError.value = e.toString();
      
      TLoaders.errorSnackBar(
        title: 'Invalid Code',
        message: e.toString(),
      );
    } finally {
      isApplyingCode.value = false;
    }
  }

  /// Get user's referral information
  Future<void> getUserReferralInfo() async {
    try {
      final info = await referralRepository.getUserReferralInfo();
      referralInfo.value = info;
    } catch (e) {
      log('Error getting referral info: $e');
    }
  }

  /// Get referral earnings summary
  Future<void> getReferralEarningsSummary() async {
    try {
      final summary = await referralRepository.getReferralEarningsSummary();
      earningsSummary.value = summary;
    } catch (e) {
      log('Error getting earnings summary: $e');
    }
  }

  /// Get user's referral history
  Future<void> getUserReferralHistory() async {
    try {
      isLoading.value = true;
      final history = await referralRepository.getUserReferralHistory();
      referralHistory.value = history;
    } catch (e) {
      log('Error getting referral history: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load referral history. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Get withdrawal history
  Future<void> getWithdrawalHistory() async {
    try {
      isLoading.value = true;
      final history = await referralRepository.getWithdrawalHistory();
      withdrawalHistory.value = history;
    } catch (e) {
      log('Error getting withdrawal history: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load withdrawal history. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Request withdrawal
  Future<void> requestWithdrawal() async {
    final amountText = withdrawalAmountController.text.trim();
    
    if (amountText.isEmpty) {
      withdrawalError.value = 'Please enter withdrawal amount';
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      withdrawalError.value = 'Please enter a valid amount';
      return;
    }

    try {
      isRequestingWithdrawal.value = true;
      withdrawalError.value = '';

      await referralRepository.requestWithdrawal(amount);

      TLoaders.successSnackBar(
        title: 'Withdrawal Requested',
        message: 'Your withdrawal request has been submitted and will be processed within 3-5 business days.',
      );

      withdrawalAmountController.clear();
      
      // Refresh data
      await Future.wait([
        getReferralEarningsSummary(),
        getWithdrawalHistory(),
      ]);

      Get.back(); // Close withdrawal dialog

    } catch (e) {
      log('Error requesting withdrawal: $e');
      withdrawalError.value = e.toString();
      
      TLoaders.errorSnackBar(
        title: 'Withdrawal Failed',
        message: e.toString(),
      );
    } finally {
      isRequestingWithdrawal.value = false;
    }
  }

  /// Copy referral code to clipboard
  void copyReferralCode() {
    final code = referralInfo.value?['referralCode'];
    if (code != null) {
      Clipboard.setData(ClipboardData(text: code));
      TLoaders.successSnackBar(
        title: 'Copied!',
        message: 'Referral code copied to clipboard.',
      );
    }
  }

  /// Share referral code
  void shareReferralCode() {
    final code = referralInfo.value?['referralCode'];
    if (code != null) {
      final shareText = 'Join RPS Shopee with my referral code "$code" and get exclusive discounts on your first order! Download the app now.';
      Share.share(shareText);
    }
  }

  /// Get referral leaderboard
  Future<void> getReferralLeaderboard() async {
    try {
      isLoading.value = true;
      final board = await referralRepository.getReferralLeaderboard();
      leaderboard.value = board;
    } catch (e) {
      log('Error getting leaderboard: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load leaderboard. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Get referral settings
  Future<void> getReferralSettings() async {
    try {
      final settings = await referralRepository.getReferralSettings();
      referralSettings.value = settings;
    } catch (e) {
      log('Error getting referral settings: $e');
    }
  }

  /// Show withdrawal dialog
  void showWithdrawalDialog() {
    withdrawalAmountController.clear();
    withdrawalError.value = '';
    
    final pendingEarnings = (earningsSummary['pendingEarnings'] as num?)?.toDouble() ?? 0.0;
    final minWithdrawal = (referralSettings['minWithdrawalAmount'] as num?)?.toDouble() ?? 10.0;
    
    if (pendingEarnings < minWithdrawal) {
      TLoaders.errorSnackBar(
        title: 'Insufficient Balance',
        message: 'Minimum withdrawal amount is \$${minWithdrawal.toStringAsFixed(2)}. Your current balance: \$${pendingEarnings.toStringAsFixed(2)}',
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Withdraw Earnings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available balance: \$${pendingEarnings.toStringAsFixed(2)}'),
            Text('Minimum withdrawal: \$${minWithdrawal.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: withdrawalAmountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Withdrawal Amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                withdrawalError.value = '';
              },
            ),
            Obx(
              () => withdrawalError.value.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        withdrawalError.value,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: isRequestingWithdrawal.value ? null : requestWithdrawal,
              child: isRequestingWithdrawal.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Request Withdrawal'),
            ),
          ),
        ],
      ),
    );
  }

  /// Show referral code input dialog
  void showReferralCodeDialog() {
    referralCodeController.clear();
    referralCodeError.value = '';

    Get.dialog(
      AlertDialog(
        title: const Text('Enter Referral Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Have a referral code? Enter it below to get your welcome bonus!'),
            const SizedBox(height: 16),
            TextField(
              controller: referralCodeController,
              decoration: const InputDecoration(
                labelText: 'Referral Code',
                hintText: 'e.g., JOHN1234',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {
                referralCodeError.value = '';
              },
            ),
            Obx(
              () => referralCodeError.value.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        referralCodeError.value,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(
            () => ElevatedButton(
              onPressed: isApplyingCode.value ? null : applyReferralCode,
              child: isApplyingCode.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Apply Code'),
            ),
          ),
        ],
      ),
    );
  }

  /// Get formatted referral link
  String getReferralLink() {
    final code = referralInfo.value?['referralCode'];
    if (code != null) {
      return 'https://rpsstationery.com/refer/$code';
    }
    return '';
  }

  /// Get referral rewards text based on settings
  String getReferralRewardsText() {
    final referrerRewardType = referralSettings['referrerRewardType'] ?? 'fixed';
    final referrerRewardValue = referralSettings['referrerRewardValue'] ?? 10;
    final refereeRewardType = referralSettings['refereeRewardType'] ?? 'fixed';
    final refereeRewardValue = referralSettings['refereeRewardValue'] ?? 5;

    String referrerText = '';
    String refereeText = '';

    if (referrerRewardType == 'percentage') {
      referrerText = '$referrerRewardValue% of their order';
    } else {
      referrerText = '\$${referrerRewardValue.toStringAsFixed(2)}';
    }

    if (refereeRewardType == 'percentage') {
      refereeText = '$refereeRewardValue% discount';
    } else {
      refereeText = '\$${refereeRewardValue.toStringAsFixed(2)} credit';
    }

    return 'You earn $referrerText for each successful referral. Your friends get $refereeText on their first order!';
  }

  /// Format earnings display
  String formatEarnings(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  /// Get referral status color
  Color getReferralStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get withdrawal status color
  Color getWithdrawalStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Refresh all referral data
  Future<void> refreshReferralData() async {
    await Future.wait([
      getUserReferralInfo(),
      getReferralEarningsSummary(),
      getUserReferralHistory(),
      getWithdrawalHistory(),
    ]);
  }

  /// Check if user has referred anyone
  bool get hasReferrals => ((earningsSummary['totalReferrals'] as int?) ?? 0) > 0;

  /// Check if user has pending earnings
  bool get hasPendingEarnings => ((earningsSummary['pendingEarnings'] as double?) ?? 0.0) > 0;

  /// Check if user can withdraw
  bool get canWithdraw {
    final pendingEarnings = (earningsSummary['pendingEarnings'] as double?) ?? 0.0;
    final minWithdrawal = (referralSettings['minWithdrawalAmount'] as double?) ?? 10.0;
    return pendingEarnings >= minWithdrawal;
  }

  /// Get user's referral code
  String? get userReferralCode => referralInfo.value?['referralCode'];
}
