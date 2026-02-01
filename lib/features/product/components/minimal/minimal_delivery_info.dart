import 'package:flutter/material.dart';
import 'package:rps_stationery/data/models/delivery_info_model.dart';

/// Minimal Delivery & Trust Info Section
/// Position: After Specifications
/// Background: White
/// Padding: 16px all around + pb-24 for sticky bar clearance
/// Card: border-radius 16px, shadow-sm
class MinimalDeliveryInfo extends StatelessWidget {
  final DeliveryInfoModel deliveryInfo;

  const MinimalDeliveryInfo({
    super.key,
    required this.deliveryInfo,
  });

  bool get _hasAnyInfo {
    return deliveryInfo.deliveryEstimate.isNotEmpty ||
        deliveryInfo.codAvailable ||
        deliveryInfo.returnPolicy.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAnyInfo) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title (h3)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Delivery & Trust Info',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

            // Info Container - space-y: 12px
            Column(
              children: [
                // Delivery Estimate
                if (deliveryInfo.deliveryEstimate.isNotEmpty) ...[
                  _buildInfoItem(
                    context: context,
                    icon: Icons.local_shipping_outlined,
                    title: 'Delivery',
                    value: deliveryInfo.deliveryEstimate,
                  ),
                  const SizedBox(height: 12),
                ],

                // COD Available
                if (deliveryInfo.codAvailable) ...[
                  _buildInfoItem(
                    context: context,
                    icon: Icons.payments_outlined,
                    title: 'Cash on Delivery',
                    value: 'Available',
                  ),
                  const SizedBox(height: 12),
                ],

                // Return Policy
                if (deliveryInfo.returnPolicy.isNotEmpty) ...[
                  _buildInfoItem(
                    context: context,
                    icon: Icons.autorenew,
                    title: 'Easy Returns',
                    value: deliveryInfo.returnPolicy,
                  ),
                  const SizedBox(height: 12),
                ],

                // Secure Payment (always show)
                _buildInfoItem(
                  context: context,
                  icon: Icons.shield_outlined,
                  title: 'Secure Payment',
                  value: '100% secure transactions',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build Info Item
  /// Display: Flex, align-items: center, gap: 12px
  /// Icon: 40x40, rounded-full, bg-gray-50, color #26A69A
  /// Text: flex 1
  /// Title: 12px, color gray-500
  /// Value: 14px, color gray-900, font-weight 500
  Widget _buildInfoItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon Circle (40x40)
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF26A69A),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Text Container (flex: 1)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
