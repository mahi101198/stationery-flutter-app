import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rps_stationery/services/razorpay_payment_service.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';
import 'package:rps_stationery/utils/popups/full_screen_loader.dart';
import 'package:rps_stationery/features/order/components/order_ui_helpers.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.warning_2,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading order details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.box_remove,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Order not found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;

          return CustomScrollView(
            slivers: [
              // Minimalistic header
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Iconsax.arrow_left,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => Get.back(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.fromLTRB(60, 0, 20, 16),
                  title: Text(
                    'Order Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Status
                      _buildStatusSection(orderData, context),
                      
                      const SizedBox(height: 20),
                      
                      // Order Info
                      _buildOrderInfoSection(orderData, context),
                      
                      const SizedBox(height: 20),
                      
                      // Items
                      _buildItemsSection(orderData, context),
                      
                      const SizedBox(height: 20),
                      
                      // Pricing Breakdown
                      _buildPricingSection(orderData, context),
                      
                      const SizedBox(height: 20),
                      
                      // Delivery Address
                      _buildAddressSection(orderData, context),
                      
                      const SizedBox(height: 20),
                      
                      // Payment Info
                      _buildPaymentSection(orderData, context),
                      
                      const SizedBox(height: 20),
                      
                      // Action Buttons
                      _buildActionButtons(orderData, context),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusSection(Map<String, dynamic> orderData, BuildContext context) {
    final status = orderData['status'] ?? 'pending';
    final statusInfo = OrderUIHelpers.getStatusInfo(status);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusInfo.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusInfo.color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusInfo.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Iconsax.tick_circle,
              color: statusInfo.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Status',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusInfo.displayText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusInfo.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoSection(Map<String, dynamic> orderData, BuildContext context) {
    final createdAt = orderData['createdAt'] as Timestamp?;
    final dateStr = createdAt != null 
        ? DateFormat('dd MMM yyyy • hh:mm a').format(createdAt.toDate())
        : 'Unknown';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Information',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            'Order ID',
            '#${orderId.substring(0, 12).toUpperCase()}',
            Iconsax.receipt_1,
            copyable: true,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            'Order Date',
            dateStr,
            Iconsax.calendar_1,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(Map<String, dynamic> orderData, BuildContext context) {
    final items = orderData['items'] as List<dynamic>? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items (${items.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) {
            final itemMap = item as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildItemCard(itemMap, context),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, BuildContext context) {
    final name = item['name'] ?? 'Unknown Product';
    final quantity = (item['quantity'] ?? 1).toInt();
    final price = (item['productCurrentPrice'] ?? item['price'] ?? 0).toDouble();
    final image = item['productImage'] ?? item['image'] ?? '';
    
    return Row(
      children: [
        // Product Image
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: image.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Iconsax.gallery_slash,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  )
                : Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Iconsax.gallery_slash,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Qty: $quantity',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          '₹${(price * quantity).toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection(Map<String, dynamic> orderData, BuildContext context) {
    final pricingSummary = orderData['pricingSummary'] as Map<String, dynamic>?;
    final paymentSummary = orderData['paymentSummary'] as Map<String, dynamic>?;
    
    final subTotal = (pricingSummary?['orderSubtotal'] ?? 0).toDouble();
    final productDiscount = (pricingSummary?['productDiscount'] ?? 0).toDouble();
    final couponDiscount = (pricingSummary?['couponDiscount'] ?? 0).toDouble();
    final deliveryFee = (pricingSummary?['deliveryFee'] ?? 0).toDouble();
    final walletUsed = (paymentSummary?['walletPaidAmount'] ?? 0).toDouble();
    final totalAmount = (paymentSummary?['totalOrderValue'] ?? 0).toDouble();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Breakdown',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow(context, 'Subtotal', '₹${subTotal.toStringAsFixed(0)}'),
          if (productDiscount > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              context,
              'Product Discount',
              '-₹${productDiscount.toStringAsFixed(0)}',
              isDiscount: true,
            ),
          ],
          if (couponDiscount > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              context,
              'Coupon Discount',
              '-₹${couponDiscount.toStringAsFixed(0)}',
              isDiscount: true,
            ),
          ],
          const SizedBox(height: 8),
          _buildPriceRow(
            context,
            'Delivery Fee',
            deliveryFee > 0 ? '₹${deliveryFee.toStringAsFixed(0)}' : 'FREE',
            isFree: deliveryFee == 0,
          ),
          if (walletUsed > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow(
              context,
              'Wallet Used',
              '-₹${walletUsed.toStringAsFixed(0)}',
              isDiscount: true,
            ),
          ],
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          _buildPriceRow(
            context,
            'Total Amount',
            '₹${totalAmount.toStringAsFixed(0)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(Map<String, dynamic> orderData, BuildContext context) {
    final address = orderData['deliveryAddress'] as Map<String, dynamic>?;
    
    if (address == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.location,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Delivery Address',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            address['name'] ?? 'Unknown',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            address['street'] ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${address['city'] ?? ''}, ${address['state'] ?? ''} - ${address['postalCode'] ?? ''}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (address['phoneNumber'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Iconsax.call,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  address['phoneNumber'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentSection(Map<String, dynamic> orderData, BuildContext context) {
    final paymentMode = orderData['paymentMode'] ?? 'Unknown';
    
    String paymentMethodName = 'Unknown';
    IconData paymentIcon = Iconsax.card;
    
    switch (paymentMode.toLowerCase()) {
      case 'razorpay':
        paymentMethodName = 'Online Payment';
        paymentIcon = Iconsax.card;
        break;
      case 'cod':
        paymentMethodName = 'Cash on Delivery';
        paymentIcon = Iconsax.money;
        break;
      case 'wallet':
        paymentMethodName = 'Wallet';
        paymentIcon = Iconsax.wallet_3;
        break;
      case 'partial_wallet':
        paymentMethodName = 'Wallet + Online';
        paymentIcon = Iconsax.wallet_3;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            paymentIcon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                paymentMethodName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> orderData, BuildContext context) {
    final status = orderData['status'] as String? ?? '';
    final canCancel = ['pending', 'confirmed', 'processing'].contains(status.toLowerCase());
    
    if (!canCancel) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _showCancelOrderDialog(context, orderData),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Cancel Order',
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool copyable = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (copyable)
          IconButton(
            icon: Icon(
              Iconsax.copy,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    String label,
    String value, {
    bool isDiscount = false,
    bool isFree = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: isTotal
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: isDiscount
                ? Theme.of(context).colorScheme.primary
                : isFree
                    ? Theme.of(context).colorScheme.primary
                    : isTotal
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  void _showCancelOrderDialog(BuildContext context, Map<String, dynamic> orderData) {
    final orderIdToCancel = orderData['id'] ?? orderId;
    
    // Use new schema fields
    final paymentSummary = orderData['paymentSummary'] as Map<String, dynamic>?;
    final totalAmount = (paymentSummary?['totalOrderValue'] ?? 
                        orderData['totalAmount'] ?? 0).toDouble();
    
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to cancel this order?'),
              const SizedBox(height: 12),
              Text(
                'Order ID: #$orderIdToCancel',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total Amount: ₹${totalAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Reason for cancellation:'),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Changed my mind, Wrong address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processOrderCancellation(context, orderIdToCancel, totalAmount, reasonController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  Future<void> _processOrderCancellation(
    BuildContext context,
    String orderId,
    double totalAmount,
    String reason,
  ) async {
    try {
      FullScreenLoader.openLoadingDialog('Cancelling order...');
      
      final razorpayService = RazorpayPaymentService();
      
      final result = await razorpayService.cancelOrder(
        orderId: orderId,
        cancelReason: reason.isEmpty ? 'User requested cancellation' : reason,
        refundAmount: totalAmount,
      );
      
      FullScreenLoader.stopLoading();
      
      if (result != null) {
        Get.offAllNamed(Routes.orderCancelled, arguments: result);
      } else {
        TLoaders.errorSnackBar(
          title: 'Cancellation Failed',
          message: 'Unable to cancel order. Please try again.',
        );
      }
    } catch (e) {
      FullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(
        title: 'Cancellation Failed',
        message: e.toString(),
      );
    }
  }
}
