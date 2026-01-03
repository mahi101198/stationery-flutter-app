import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Shared UI components and helpers for order screens
/// Prevents code duplication between order list and order details
class OrderUIHelpers {
  OrderUIHelpers._();

  /// Get modern status chip with gradient backgrounds
  static Widget buildModernStatusChip(String status, BuildContext context) {
    final statusInfo = getStatusInfo(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: statusInfo.gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusInfo.color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusInfo.icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            statusInfo.displayText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Get status information
  static StatusInfo getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return StatusInfo(
          displayText: 'Placed',
          color: const Color(0xFF3B82F6),
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
          ),
          icon: Iconsax.clipboard_text,
        );
      case 'paid':
      case 'confirmed':
        return StatusInfo(
          displayText: 'Confirmed',
          color: const Color(0xFF10B981),
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
          ),
          icon: Iconsax.tick_circle5,
        );
      case 'processing':
        return StatusInfo(
          displayText: 'Processing',
          color: const Color(0xFF3B82F6),
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
          ),
          icon: Iconsax.refresh_circle5,
        );
      case 'packed':
        return StatusInfo(
          displayText: 'Packed',
          color: const Color(0xFF8B5CF6),
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
          ),
          icon: Iconsax.box_1,
        );
      case 'shipped':
        return StatusInfo(
          displayText: 'Shipped',
          color: const Color(0xFF8B5CF6),
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          ),
          icon: Iconsax.box_time5,
        );
      case 'out_for_delivery':
        return StatusInfo(
          displayText: 'Out for Delivery',
          color: const Color(0xFFF59E0B),
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
          ),
          icon: Iconsax.truck_fast,
        );
      case 'delivered':
        return StatusInfo(
          displayText: 'Delivered',
          color: const Color(0xFF06B6D4),
          gradient: const LinearGradient(
            colors: [Color(0xFF06B6D4), Color(0xFF10B981)],
          ),
          icon: Iconsax.box_tick5,
        );
      case 'cancelled':
        return StatusInfo(
          displayText: 'Cancelled',
          color: const Color(0xFFEF4444),
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFF43F5E)],
          ),
          icon: Iconsax.close_circle5,
        );
      case 'returned':
        return StatusInfo(
          displayText: 'Returned',
          color: const Color(0xFF6366F1),
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
          ),
          icon: Iconsax.refresh,
        );
      case 'refunded':
        return StatusInfo(
          displayText: 'Refunded',
          color: const Color(0xFF10B981),
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF34D399)],
          ),
          icon: Iconsax.money_change,
        );
      default:
        return StatusInfo(
          displayText: 'Pending',
          color: const Color(0xFFF59E0B),
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
          ),
          icon: Iconsax.clock5,
        );
    }
  }

  /// Get status message
  static String getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return 'Your order has been placed successfully';
      case 'paid':
      case 'confirmed':
        return 'Your order has been confirmed and is being prepared';
      case 'processing':
        return 'We are processing your order';
      case 'packed':
        return 'Your order is packed and ready for shipping';
      case 'shipped':
        return 'Your order has been shipped and is on the way';
      case 'out_for_delivery':
        return 'Your order is out for delivery';
      case 'delivered':
        return 'Your order has been delivered successfully';
      case 'cancelled':
        return 'This order has been cancelled';
      case 'returned':
        return 'This order has been returned';
      case 'refunded':
        return 'The amount has been refunded to your account';
      default:
        return 'Waiting for payment confirmation';
    }
  }

  /// Get payment method icon
  static IconData getPaymentIcon(String? paymentMode) {
    switch (paymentMode?.toLowerCase()) {
      case 'razorpay':
        return Iconsax.card5;
      case 'cod':
        return Iconsax.money_send5;
      case 'wallet':
        return Iconsax.wallet_35;
      case 'upi':
        return Iconsax.mobile5;
      default:
        return Iconsax.card5;
    }
  }

  /// Get payment method display name
  static String getPaymentMethodName(String? paymentMode) {
    switch (paymentMode?.toLowerCase()) {
      case 'razorpay':
        return 'Online Payment';
      case 'cod':
        return 'Cash on Delivery';
      case 'wallet':
        return 'Wallet';
      case 'upi':
        return 'UPI';
      default:
        return 'Online Payment';
    }
  }
}

/// Status information data class
class StatusInfo {
  final String displayText;
  final Color color;
  final LinearGradient gradient;
  final IconData icon;

  StatusInfo({
    required this.displayText,
    required this.color,
    required this.gradient,
    required this.icon,
  });
}

