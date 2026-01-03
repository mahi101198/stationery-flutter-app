import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/utils/constants/sizes.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:intl/intl.dart';

class OrderCancelledScreen extends StatelessWidget {
  final Map<String, dynamic> cancellationData;

  const OrderCancelledScreen({
    super.key,
    required this.cancellationData,
  });

  /// Safe conversion from Firebase Map to Map<String, dynamic>
  Map<String, dynamic> _safeMapConversion(dynamic data) {
    final Map<String, dynamic> result = {};
    if (data is Map) {
      data.forEach((key, value) {
        if (key is String) {
          result[key] = value;
        }
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final orderId = cancellationData['orderId'] ?? '';
    final refundAmount = (cancellationData['refundAmount'] ?? 0).toDouble();
    
    // Safe conversion from Firebase Map<Object?, Object?> to Map<String, dynamic>
    final refundResultRaw = cancellationData['refundResult'];
    final Map<String, dynamic> refundResult = {};
    if (refundResultRaw is Map) {
      refundResultRaw.forEach((key, value) {
        if (key is String) {
          refundResult[key] = value;
        }
      });
    }
    
    final message = cancellationData['message'] ?? 'Order cancelled successfully';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Cancelled'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Get.offAllNamed(Routes.bottomNav);
              });
            },
            child: const Text('Done'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          children: [
            // Success Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.close_circle,
                size: 60,
                color: Colors.red,
              ),
            ),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Title
            Text(
              'Order Cancelled',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            
            const SizedBox(height: TSizes.sm),
            
            // Message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Order ID Card
            _buildOrderIdCard(context, orderId),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Refund Details Card
            _buildRefundDetailsCard(context, refundAmount, refundResult),
            
            const SizedBox(height: TSizes.spaceBtwSections),
            
            // Action Buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderIdCard(BuildContext context, String orderId) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(TSizes.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(TSizes.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Iconsax.receipt_1,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: TSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ID',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '#$orderId',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundDetailsCard(BuildContext context, double refundAmount, Map<String, dynamic> refundResult) {
    final refundMethod = refundResult['refundMethod'] ?? '';
    final refundStatus = refundResult['refundStatus'] ?? '';
    final processedAt = refundResult['processedAt'];
    final notes = refundResult['notes'] ?? '';
    // Safe conversion for breakdown
    final breakdownRaw = refundResult['breakdown'];
    final Map<String, dynamic> breakdown = {};
    if (breakdownRaw is Map) {
      breakdownRaw.forEach((key, value) {
        if (key is String) {
          breakdown[key] = value;
        }
      });
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(TSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(TSizes.sm),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Iconsax.money_send,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: TSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Refund Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getRefundStatusText(refundStatus),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getRefundStatusColor(refundStatus),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: TSizes.md),
            
            // Refund Amount
            if (refundAmount > 0) ...[
              _buildRefundRow(
                context,
                'Refund Amount',
                '₹${refundAmount.toStringAsFixed(2)}',
                Colors.green,
                true,
              ),
              const SizedBox(height: TSizes.sm),
            ],
            
            // Refund Method
            _buildRefundRow(
              context,
              'Refund Method',
              _getRefundMethodText(refundMethod),
              Theme.of(context).colorScheme.onSurface,
              false,
            ),
            
            const SizedBox(height: TSizes.sm),
            
            // Processed At - Always show, use current date if not available
            _buildRefundRow(
              context,
              'Processed At',
              _formatDateTime(processedAt),
              Theme.of(context).colorScheme.onSurfaceVariant,
              false,
            ),
            const SizedBox(height: TSizes.sm),
            
            // Notes
            if (notes.isNotEmpty) ...[
              _buildRefundRow(
                context,
                'Notes',
                notes,
                Theme.of(context).colorScheme.onSurfaceVariant,
                false,
              ),
              const SizedBox(height: TSizes.sm),
            ],
            
            // Breakdown for partial wallet refunds
            if (breakdown.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: TSizes.sm),
              Text(
                'Refund Breakdown',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: TSizes.sm),
              
              // Wallet Refund
              if (breakdown.containsKey('walletRefund')) ...[
                _buildBreakdownItem(
                  context,
                  'Wallet Refund',
                  _safeMapConversion(breakdown['walletRefund']),
                  Iconsax.wallet_3,
                ),
                const SizedBox(height: TSizes.sm),
              ],
              
              // Razorpay Refund
              if (breakdown.containsKey('razorpayRefund')) ...[
                _buildBreakdownItem(
                  context,
                  'Card/UPI Refund',
                  _safeMapConversion(breakdown['razorpayRefund']),
                  Iconsax.card,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRefundRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
    bool isAmount,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isAmount ? FontWeight.bold : FontWeight.w500,
              color: valueColor,
              fontSize: isAmount ? 16 : 14,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(
    BuildContext context,
    String title,
    Map<String, dynamic> data,
    IconData icon,
  ) {
    final amount = (data['amount'] ?? 0).toDouble();
    final status = data['status'] ?? '';
    final method = data['method'] ?? '';
    final refundId = data['refundId'];

    return Container(
      padding: const EdgeInsets.all(TSizes.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: TSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${amount.toStringAsFixed(2)} • ${_getRefundMethodText(method)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (refundId != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'ID: $refundId',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getRefundStatusColor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _getRefundStatusColor(status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // View Orders Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Get.offAllNamed(Routes.order);
              });
            },
            child: const Text('View My Orders'),
          ),
        ),
        
        const SizedBox(height: TSizes.sm),
        
        // Continue Shopping Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Get.offAllNamed(Routes.bottomNav);
              });
            },
            child: const Text('Continue Shopping'),
          ),
        ),
      ],
    );
  }

  String _getRefundStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Refund Completed';
      case 'processed':
        return 'Refund Processed';
      case 'pending':
        return 'Refund Pending';
      case 'failed':
        return 'Refund Failed';
      case 'not_applicable':
        return 'No Refund Required';
      default:
        return 'Refund Status: $status';
    }
  }

  Color _getRefundStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'processed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'not_applicable':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getRefundMethodText(String method) {
    switch (method.toLowerCase()) {
      case 'wallet_credit':
        return 'Wallet Credit';
      case 'razorpay_api':
        return 'Card/UPI';
      case 'mixed':
        return 'Mixed (Wallet + Card)';
      case 'none':
        return 'No Refund';
      default:
        return method;
    }
  }

  String _formatDateTime(dynamic dateTime) {
    try {
      DateTime date;
      
      if (dateTime is String) {
        date = DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        date = dateTime;
      } else if (dateTime != null) {
        // Handle Firebase Timestamp or other date formats
        final dateString = dateTime.toString();
        if (dateString.contains('Timestamp')) {
          // Extract timestamp from Firebase Timestamp string
          final match = RegExp(r'Timestamp\(seconds=(\d+), nanoseconds=(\d+)\)').firstMatch(dateString);
          if (match != null) {
            final seconds = int.parse(match.group(1)!);
            date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          } else {
            date = DateTime.now(); // Fallback to current date
          }
        } else {
          date = DateTime.parse(dateString);
        }
      } else {
        // If no date provided, use current date
        date = DateTime.now();
      }
      
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      // If all parsing fails, return current date
      return DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now());
    }
  }
}

