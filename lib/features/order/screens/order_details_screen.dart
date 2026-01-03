import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rps_stationery/utils/constants/sizes.dart';
import 'package:rps_stationery/utils/constants/colors.dart';
import 'package:rps_stationery/services/razorpay_payment_service.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';
import 'package:rps_stationery/utils/popups/full_screen_loader.dart';
import 'package:rps_stationery/features/order/components/order_ui_helpers.dart';
import 'package:intl/intl.dart';
import 'package:rps_stationery/features/order/components/order_review_dialog.dart';
import 'package:rps_stationery/features/product/controllers/review_controller.dart';
import 'package:rps_stationery/data/repositories/review_repo.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    print('📦 OrderDetailsScreen: Loading order details for: $orderId');

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            print('❌ OrderDetailsScreen: Error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Iconsax.warning_2,
                    size: 64,
                    color: TColors.error,
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  const Text('Error loading order details'),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            print('❌ OrderDetailsScreen: Order not found');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Iconsax.box_remove,
                    size: 64,
                    color: TColors.darkGrey,
                  ),
                  const SizedBox(height: TSizes.spaceBtwItems),
                  const Text('Order not found'),
                ],
              ),
            );
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;
          print('✅ OrderDetailsScreen: Order data loaded successfully');

          return CustomScrollView(
            slivers: [
              // Modern header
              SliverAppBar(
                expandedHeight: 100,
                floating: true,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: EdgeInsets.fromLTRB(
                      60,
                      MediaQuery.of(context).padding.top + 16,
                      20,
                      16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                          Theme.of(context).colorScheme.secondary.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Order Details',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
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
                      // Order Status Card
                      _buildModernStatusCard(orderData, context),
                      
                      const SizedBox(height: 16),
                      
                      // Items
                      _buildModernItemsCard(orderData, context),
                      
                      const SizedBox(height: 16),
                      
                      // Order Info
                      _buildModernOrderInfoCard(orderData, context),
                      
                      const SizedBox(height: 16),
                      
                      // Delivery Address
                      _buildModernAddressCard(orderData, context),
                      
                      const SizedBox(height: 16),
                      
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

  Widget _buildModernStatusCard(Map<String, dynamic> orderData, BuildContext context) {
    final status = orderData['status'] ?? 'pending';
    final statusInfo = OrderUIHelpers.getStatusInfo(status);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusInfo.color.withValues(alpha: 0.1),
            statusInfo.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusInfo.color.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusInfo.color.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: statusInfo.gradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: statusInfo.color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      child: Icon(
                        Icons.check_circle, // Using Material icon instead of Iconsax
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Status',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusInfo.displayText,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: statusInfo.color,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              OrderUIHelpers.getStatusMessage(status),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernOrderInfoCard(Map<String, dynamic> orderData, BuildContext context) {
    final createdAt = orderData['createdAt'] as Timestamp?;
    final dateStr = createdAt != null 
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt.toDate())
        : 'Unknown';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Iconsax.receipt_2,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Order Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildModernInfoRowWithCopy(context, 'Order ID', '#$orderId', Iconsax.receipt_1),
            const SizedBox(height: 12),
            _buildModernInfoRow(context, 'Date', dateStr, Iconsax.calendar),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernInfoRowWithCopy(BuildContext context, String label, String value, IconData icon) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label copied to clipboard'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              '$label: ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            Icon(
              Iconsax.copy,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernItemsCard(Map<String, dynamic> orderData, BuildContext context) {
    final items = orderData['items'] as List<dynamic>? ?? [];
    final status = orderData['status'] ?? 'pending';
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Iconsax.shopping_bag,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Items (${items.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((item) {
              final itemMap = item as Map<String, dynamic>;
              final itemImage = itemMap['productImage'] ?? itemMap['image'] ?? itemMap['images']?[0] ?? '';
              final itemName = itemMap['name'] ?? 'Unknown Product';
              final quantity = (itemMap['quantity'] ?? 1).toInt();
              final price = (itemMap['price'] ?? 0).toDouble();
              final totalPrice = (itemMap['totalPrice'] ?? price * quantity).toDouble();
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final productId = itemMap['productId'] ?? itemMap['id'];
                      if (productId != null) {
                        Get.toNamed('/product-detail', arguments: productId);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Product image with modern styling
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: itemImage.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: itemImage,
                                          fit: BoxFit.cover,
                                          fadeInDuration: const Duration(milliseconds: 200),
                                          placeholder: (context, url) => Container(
                                            color: const Color(0xFFF5F5F5),
                                            child: const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBDBDBD)),
                                                ),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: const Color(0xFFF5F5F5),
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              color: Color(0xFFBDBDBD),
                                              size: 24,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: const Color(0xFFF5F5F5),
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            color: Color(0xFFBDBDBD),
                                            size: 24,
                                          ),
                                        ),
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // Product details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      itemName,
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Qty: $quantity',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    // Show discount if applicable
                                    if (itemMap['discountPrice'] != null && 
                                        (itemMap['discountPrice'] as num).toDouble() < price) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              '₹${(price * quantity).toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 4,
                                                vertical: 1,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                'Save ₹${((price - (itemMap['discountPrice'] as num).toDouble()) * quantity).toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // Total price
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${totalPrice.toStringAsFixed(0)}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(context).colorScheme.primary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  if (quantity > 1)
                                    Text(
                                      '₹${price.toStringAsFixed(0)} × $quantity',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          
                          // Review button for delivered products - Full width below product details
                          if (status.toLowerCase() == 'delivered') ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showReviewDialog(context, itemMap),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Iconsax.star1,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Review',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
            const Divider(height: TSizes.spaceBtwItems * 2),
            
            // Payment Method Information
            _buildPaymentMethodInfo(context, orderData),
            
            const SizedBox(height: TSizes.md),
            
            // Refund Information (for cancelled orders only)
            _buildRefundInfoCard(context, orderData),
            
            const SizedBox(height: TSizes.md),
            
            // Detailed Pricing Breakdown
            _buildDetailedPricingBreakdown(context, orderData),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAddressCard(Map<String, dynamic> orderData, BuildContext context) {
    final address = orderData['deliveryAddress'] as Map<String, dynamic>?;
    
    if (address == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Iconsax.location5,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Delivery Address',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address['name'] ?? 'Unknown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.call,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            address['phoneNumber'],
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }





  /// Build refund information card for cancelled orders
  Widget _buildRefundInfoCard(BuildContext context, Map<String, dynamic> orderData) {
    final status = orderData['status'] as String? ?? '';
    final refundDetails = orderData['refundDetails'] as Map<String, dynamic>?;
    
    // Only show refund info for cancelled orders with refund details
    if (status.toLowerCase() != 'cancelled' || refundDetails == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(TSizes.sm),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Iconsax.money_send,
                size: 18,
                color: Colors.orange,
              ),
              const SizedBox(width: TSizes.xs),
              Text(
                'Refund Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: TSizes.xs),
          
          // Refund Type
          _buildRefundInfoRow(
            context,
            'Refund Type',
            _getRefundTypeName(refundDetails['type'] ?? ''),
            Iconsax.category,
          ),
          
          // Refund Amount
          _buildRefundInfoRow(
            context,
            'Refund Amount',
            '₹${(refundDetails['refundAmount'] ?? 0).toStringAsFixed(2)}',
            Iconsax.money_send,
          ),
          
          // Refund Method
          _buildRefundInfoRow(
            context,
            'Refund Method',
            _getRefundMethodName(refundDetails['refundMethod'] ?? ''),
            Iconsax.card,
          ),
          
          // Refund Status
          _buildRefundInfoRow(
            context,
            'Refund Status',
            _getRefundStatusName(refundDetails['refundStatus'] ?? ''),
            Iconsax.tick_circle,
            statusColor: _getRefundStatusColor(refundDetails['refundStatus'] ?? ''),
          ),
          
          // Refund ID
          if (refundDetails['refundId'] != null) ...[
            _buildRefundInfoRow(
              context,
              'Refund ID',
              refundDetails['refundId'],
              Iconsax.receipt_2,
            ),
          ],
          
          // Processed At
          if (refundDetails['processedAt'] != null) ...[
            _buildRefundInfoRow(
              context,
              'Processed At',
              _formatDateTime(refundDetails['processedAt']),
              Iconsax.clock,
            ),
          ],
          
          // Notes
          if (refundDetails['notes'] != null) ...[
            _buildRefundInfoRow(
              context,
              'Notes',
              refundDetails['notes'],
              Iconsax.note,
            ),
          ],
          
          // Breakdown for partial wallet refunds
          if (refundDetails['breakdown'] != null) ...[
            const SizedBox(height: TSizes.xs),
            Container(
              padding: const EdgeInsets.all(TSizes.xs),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Refund Breakdown',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                  _buildBreakdownItem(context, 'Wallet Refund', refundDetails['breakdown']['walletRefund']),
                  _buildBreakdownItem(context, 'Razorpay Refund', refundDetails['breakdown']['razorpayRefund']),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build refund info row
  Widget _buildRefundInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? statusColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: TSizes.xs),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: TSizes.sm),
        Expanded(
          flex: 1,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: statusColor ?? Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Build breakdown item for partial wallet refunds
  Widget _buildBreakdownItem(BuildContext context, String title, Map<String, dynamic>? breakdown) {
    if (breakdown == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.orange,
            ),
          ),
          Text(
            'Amount: ₹${(breakdown['amount'] ?? 0).toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            'Method: ${_getRefundMethodName(breakdown['method'] ?? '')}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            'Status: ${_getRefundStatusName(breakdown['status'] ?? '')}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getRefundStatusColor(breakdown['status'] ?? ''),
            ),
          ),
        ],
      ),
    );
  }

  /// Get refund type name
  String _getRefundTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'cod_cancellation':
        return 'COD Cancellation';
      case 'wallet_refund':
        return 'Wallet Refund';
      case 'razorpay_refund':
        return 'Razorpay Refund';
      case 'partial_wallet_refund':
        return 'Partial Wallet Refund';
      default:
        return type.isNotEmpty ? type.toUpperCase() : 'N/A';
    }
  }

  /// Get refund method name
  String _getRefundMethodName(String method) {
    switch (method.toLowerCase()) {
      case 'none':
        return 'No Refund Required';
      case 'wallet_credit':
        return 'Wallet Credit';
      case 'razorpay_api':
        return 'Razorpay API';
      case 'mixed':
        return 'Mixed (Wallet + Razorpay)';
      default:
        return method.isNotEmpty ? method.toUpperCase() : 'N/A';
    }
  }

  /// Get refund status name
  String _getRefundStatusName(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'not_applicable':
        return 'Not Applicable';
      default:
        return status.isNotEmpty ? status.toUpperCase() : 'N/A';
    }
  }

  /// Get refund status color
  Color _getRefundStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'not_applicable':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// Build payment method information card
  Widget _buildPaymentMethodInfo(BuildContext context, Map<String, dynamic> orderData) {
    final paymentMode = orderData['paymentMode'] ?? '';
    final transactionDetails = orderData['transactionDetails'] as Map<String, dynamic>?;
    // final amountBreakdown = orderData['amountBreakdown'] as Map<String, dynamic>?;
    final walletInfo = orderData['walletInfo'] as Map<String, dynamic>?;
    
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Iconsax.card,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: TSizes.sm),
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Payment Method
          _buildPaymentInfoRow(
            context,
            'Method',
            _getPaymentMethodName(paymentMode),
            _getPaymentIcon(paymentMode),
          ),
          
          // Transaction Details (for Razorpay payments)
          if (transactionDetails != null) ...[
            const SizedBox(height: 8),
            _buildPaymentInfoRow(
              context,
              'Trans ID',
              transactionDetails['razorpayPaymentId'] ?? 'N/A',
              Iconsax.receipt_2,
            ),
            
            if (transactionDetails['method'] != null) ...[
              const SizedBox(height: 6),
              _buildPaymentInfoRow(
                context,
                'Payment',
                _getPaymentTypeName(transactionDetails['method']),
                Iconsax.card,
              ),
            ],
            
            if (transactionDetails['capturedAt'] != null) ...[
              const SizedBox(height: 6),
              _buildPaymentInfoRow(
                context,
                'Paid At',
                _formatCompactDateTime(transactionDetails['capturedAt']),
                Iconsax.clock,
              ),
            ],
          ],
          
          // Wallet Information (for wallet payments)
          if (walletInfo != null) ...[
            const SizedBox(height: 8),
            _buildPaymentInfoRow(
              context,
              'Wallet Used',
              '₹${(walletInfo['amountUsed'] ?? 0).toStringAsFixed(2)}',
              Iconsax.wallet_3,
            ),
            
            if (walletInfo['isPartialPayment'] == true) ...[
              const SizedBox(height: 6),
              _buildPaymentInfoRow(
                context,
                'Remaining Amount',
                '₹${(walletInfo['remainingAmount'] ?? 0).toStringAsFixed(2)}',
                Iconsax.card,
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Build detailed pricing breakdown with comprehensive information
  Widget _buildDetailedPricingBreakdown(BuildContext context, Map<String, dynamic> orderData) {
    final amountBreakdown = orderData['amountBreakdown'] as Map<String, dynamic>?;
    final couponInfo = orderData['couponInfo'] as Map<String, dynamic>?;
    final items = orderData['items'] as List<dynamic>? ?? [];
    
    // Extract amounts from breakdown
    final subTotal = (amountBreakdown?['subTotal'] ?? 0).toDouble();
    final discount = (amountBreakdown?['discount'] ?? 0).toDouble();
    final deliveryFee = (amountBreakdown?['deliveryFee'] ?? 0).toDouble();
    final walletUsed = (amountBreakdown?['walletUsed'] ?? 0).toDouble();
    final finalAmount = (amountBreakdown?['finalAmount'] ?? 0).toDouble();
    // final totalOrderAmount = (amountBreakdown?['totalOrderAmount'] ?? finalAmount).toDouble();
    final totalSavings = (amountBreakdown?['totalSavings'] ?? 0).toDouble();
    
    return Container(
      padding: const EdgeInsets.all(TSizes.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Iconsax.receipt_2,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: TSizes.sm),
              Text(
                'Detailed Price Breakdown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: TSizes.md),
          
          // Items Subtotal
          _buildDetailedPriceRow(
            context,
            'Items Subtotal (${items.length} item${items.length > 1 ? 's' : ''})',
            '₹${subTotal.toStringAsFixed(2)}',
            isSubtotal: true,
          ),
          
          // Coupon Discount
          if (discount > 0) ...[
            const SizedBox(height: TSizes.sm),
            _buildDetailedPriceRow(
              context,
              couponInfo != null ? 'Coupon Discount (${couponInfo['code']})' : 'Discount',
              '-₹${discount.toStringAsFixed(2)}',
              isDiscount: true,
              icon: Iconsax.tag,
            ),
          ],
          
          // Wallet Payment
          if (walletUsed > 0) ...[
            const SizedBox(height: TSizes.sm),
            _buildDetailedPriceRow(
              context,
              'Wallet Payment',
              '-₹${walletUsed.toStringAsFixed(2)}',
              isDiscount: true,
              icon: Iconsax.wallet_3,
            ),
          ],
          
          // Delivery Fee
          const SizedBox(height: TSizes.sm),
          _buildDetailedPriceRow(
            context,
            'Delivery Fee',
            deliveryFee > 0 ? '₹${deliveryFee.toStringAsFixed(2)}' : 'FREE',
            isDelivery: true,
            isFree: deliveryFee == 0,
            icon: Iconsax.truck,
          ),
          
          // Total Savings
          if (totalSavings > 0) ...[
            const SizedBox(height: TSizes.sm),
            Container(
              padding: const EdgeInsets.all(TSizes.sm),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(TSizes.borderRadiusSm),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.discount_shape,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: TSizes.xs),
                  Text(
                    'Total Savings: ₹${totalSavings.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Divider
          const SizedBox(height: TSizes.sm),
          Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            height: 1,
          ),
          const SizedBox(height: TSizes.sm),
          
          // Final Amount
          _buildDetailedPriceRow(
            context,
            'Final Amount',
            '₹${finalAmount.toStringAsFixed(2)}',
            isTotal: true,
            icon: Iconsax.money_send,
          ),
        ],
      ),
    );
  }

  /// Build individual price row for detailed breakdown
  Widget _buildDetailedPriceRow(
    BuildContext context,
    String label,
    String value, {
    bool isSubtotal = false,
    bool isDiscount = false,
    bool isDelivery = false,
    bool isTotal = false,
    bool isFree = false,
    IconData? icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isDiscount 
                      ? Colors.green 
                      : isTotal 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: TSizes.xs),
              ],
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
                    color: isTotal 
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: TSizes.sm),
        Expanded(
          flex: 1,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: isDiscount 
                  ? Colors.green
                  : isFree 
                      ? Colors.green
                      : isTotal 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Build payment info row
  Widget _buildPaymentInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  /// Get payment type name from Razorpay method
  String _getPaymentTypeName(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return 'Credit/Debit Card';
      case 'upi':
        return 'UPI';
      case 'netbanking':
        return 'Net Banking';
      case 'wallet':
        return 'Digital Wallet';
      case 'emi':
        return 'EMI';
      default:
        return method.toUpperCase();
    }
  }

  /// Format date time for display
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

  /// Format date and time in compact format (DD MMM HH:MM)
  String _formatCompactDateTime(dynamic dateTime) {
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
      
      return DateFormat('dd MMM HH:mm').format(date);
    } catch (e) {
      // If all parsing fails, return current date
      return DateFormat('dd MMM HH:mm').format(DateTime.now());
    }
  }

  /// Get payment method icon
  IconData _getPaymentIcon(String? paymentMode) {
    switch (paymentMode?.toLowerCase()) {
      case 'razorpay':
        return Iconsax.card;
      case 'cod':
        return Iconsax.money_send;
      case 'wallet':
        return Iconsax.wallet_3;
      case 'upi':
        return Iconsax.mobile;
      default:
        return Iconsax.card;
    }
  }

  /// Get payment method display name
  String _getPaymentMethodName(String? paymentMode) {
    switch (paymentMode?.toLowerCase()) {
      case 'razorpay':
        return 'Online Payment';
      case 'cod':
        return 'COD';
      case 'wallet':
        return 'Wallet';
      case 'upi':
        return 'UPI';
      default:
        return 'Online Payment';
    }
  }

  /// Build action buttons based on order status
  Widget _buildActionButtons(Map<String, dynamic> orderData, BuildContext context) {
    final status = orderData['status'] as String? ?? '';
    
    // Only show cancel button for orders that can be cancelled
    final canCancel = ['pending', 'confirmed', 'processing', 'processing_payment'].contains(status.toLowerCase());
    
    if (!canCancel) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(TSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TSizes.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showCancelOrderDialog(context, orderData),
                icon: const Icon(Iconsax.close_circle),
                label: const Text('Cancel Order'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show cancel order confirmation dialog
  void _showCancelOrderDialog(BuildContext context, Map<String, dynamic> orderData) {
    final orderIdToCancel = orderData['id'] ?? orderId;
    final totalAmount = (orderData['amountBreakdown']?['totalOrderAmount'] ?? 
                        orderData['amountBreakdown']?['finalAmount'] ?? 
                        orderData['totalAmount'] ?? 0).toDouble();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to cancel this order?'),
              const SizedBox(height: TSizes.sm),
              Text(
                'Order ID: #$orderIdToCancel',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: TSizes.sm),
              Text(
                'Total Amount: ₹${totalAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: TSizes.md),
              const Text('Please provide a reason for cancellation:'),
              const SizedBox(height: TSizes.sm),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'e.g., Changed my mind, Wrong address, etc.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                controller: TextEditingController(),
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
               _processOrderCancellation(context, orderIdToCancel, totalAmount);
             },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  /// Process order cancellation
  Future<void> _processOrderCancellation(BuildContext context, String orderId, double totalAmount) async {
    try {
      // Show loading
      FullScreenLoader.openLoadingDialog('Cancelling order...');
      
      final razorpayService = RazorpayPaymentService();
      
      final result = await razorpayService.cancelOrder(
        orderId: orderId,
        cancelReason: 'User requested cancellation',
        refundAmount: totalAmount,
      );
      
      // Hide loading
      FullScreenLoader.stopLoading();
      
      if (result != null) {
        // Navigate to order cancelled screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed(Routes.orderCancelled, arguments: result);
        });
      } else {
        TLoaders.errorSnackBar(
          title: 'Cancellation Failed',
          message: 'Unable to cancel order. Please try again.',
        );
      }
    } catch (e) {
      // Hide loading
      FullScreenLoader.stopLoading();
      
      TLoaders.errorSnackBar(
        title: 'Cancellation Failed',
        message: e.toString(),
      );
    }
  }

  /// Check if user has already reviewed a product
  Future<bool> _checkIfUserHasReviewed(String? productId) async {
    if (productId == null) return false;
    
    try {
      // Initialize ReviewController if needed
      ReviewController? reviewController;
      try {
        reviewController = Get.find<ReviewController>();
      } catch (e) {
        if (!Get.isRegistered<ReviewRepo>()) {
          Get.put(ReviewRepo(), permanent: true);
        }
        reviewController = Get.put(ReviewController());
      }
      
      // Load reviews for the product
      await reviewController?.loadProductReviews(productId);
      
      // Check if user has a review
      return reviewController?.userReview != null;
    } catch (e) {
      // If there's an error, assume no review exists
      return false;
    }
  }

  /// Show review dialog for a product
  void _showReviewDialog(BuildContext context, Map<String, dynamic> itemData) {
    final productId = itemData['productId'] ?? itemData['id'];
    final productName = itemData['name'] ?? 'Unknown Product';
    final productImage = itemData['productImage'] ?? itemData['image'] ?? itemData['images']?[0];

    if (productId == null) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Product ID not found',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => OrderReviewDialog(
        productId: productId,
        productName: productName,
        productImage: productImage,
      ),
    );
  }
}

