import 'package:rps_stationery/services/app_settings_service.dart';

/// Unified price calculation logic for the entire checkout flow
/// This ensures consistent calculations across all screens
class PriceCalculator {
  static final AppSettingsService _appSettings = AppSettingsService.instance;

  /// Calculate delivery charge based on order total
  static double calculateDeliveryCharge(double orderTotal) {
    return _appSettings.calculateDeliveryCharge(orderTotal);
  }

  /// Calculate final amount with all discounts applied
  static double calculateFinalAmount({
    required double orderTotal,
    double couponDiscount = 0.0,
    double walletDiscount = 0.0,
  }) {
    final deliveryCharge = calculateDeliveryCharge(orderTotal);
    final subtotal = orderTotal + deliveryCharge;
    final totalDiscount = couponDiscount + walletDiscount;
    return subtotal - totalDiscount;
  }

  /// Calculate subtotal (order + delivery - before discounts)
  static double calculateSubtotal(double orderTotal) {
    final deliveryCharge = calculateDeliveryCharge(orderTotal);
    return orderTotal + deliveryCharge;
  }

  /// Get free delivery threshold info
  static Map<String, dynamic> getFreeDeliveryInfo(double orderTotal) {
    final deliveryCharge = calculateDeliveryCharge(orderTotal);
    final threshold = _appSettings.freeDeliveryThreshold;
    final remainingForFree = threshold - orderTotal;

    return {
      'isFreeDelivery': deliveryCharge == 0.0,
      'deliveryCharge': deliveryCharge,
      'threshold': threshold,
      'remainingForFree': remainingForFree > 0 ? remainingForFree : 0.0,
    };
  }

  /// Get comprehensive price breakdown
  static Map<String, double> getPriceBreakdown({
    required double orderTotal,
    double couponDiscount = 0.0,
    double walletDiscount = 0.0,
  }) {
    final deliveryCharge = calculateDeliveryCharge(orderTotal);
    final subtotal = orderTotal + deliveryCharge;
    final totalDiscount = couponDiscount + walletDiscount;
    final finalAmount = subtotal - totalDiscount;

    return {
      'orderTotal': orderTotal,
      'deliveryCharge': deliveryCharge,
      'subtotal': subtotal,
      'couponDiscount': couponDiscount,
      'walletDiscount': walletDiscount,
      'totalDiscount': totalDiscount,
      'finalAmount': finalAmount,
    };
  }

  /// Check if wallet can pay full amount
  static bool canPayFullyWithWallet({
    required double orderTotal,
    required double walletBalance,
    double couponDiscount = 0.0,
  }) {
    final finalAmount = calculateFinalAmount(
      orderTotal: orderTotal,
      couponDiscount: couponDiscount,
    );
    return walletBalance >= finalAmount;
  }

  /// Calculate partial wallet payment amount
  static double calculatePartialWalletAmount({
    required double orderTotal,
    required double walletBalance,
    double couponDiscount = 0.0,
  }) {
    final finalAmount = calculateFinalAmount(
      orderTotal: orderTotal,
      couponDiscount: couponDiscount,
    );
    return walletBalance >= finalAmount ? finalAmount : walletBalance;
  }

  /// Calculate remaining amount after partial wallet payment
  static double calculateRemainingAmount({
    required double orderTotal,
    required double walletBalance,
    double couponDiscount = 0.0,
  }) {
    final finalAmount = calculateFinalAmount(
      orderTotal: orderTotal,
      couponDiscount: couponDiscount,
    );
    final walletAmount = calculatePartialWalletAmount(
      orderTotal: orderTotal,
      walletBalance: walletBalance,
      couponDiscount: couponDiscount,
    );
    return finalAmount - walletAmount;
  }
}
