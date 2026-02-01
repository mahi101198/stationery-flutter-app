import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rps_stationery/features/order/components/order_ui_helpers.dart';
import 'package:intl/intl.dart';

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text('My Orders'),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.login,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Please login to view your orders',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Minimalistic header
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            automaticallyImplyLeading: true,
            leading: IconButton(
              icon: Icon(
                Iconsax.arrow_left,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () => Get.back(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: EdgeInsets.fromLTRB(
                60,
                0,
                20,
                16,
              ),
              title: Text(
                'My Orders',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          
          // Orders list
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('userId', isEqualTo: user.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
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
                          'Error loading orders',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.box,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No orders yet',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your order history will appear here',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final orders = snapshot.data!.docs;

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final orderDoc = orders[index];
                      final orderData = orderDoc.data() as Map<String, dynamic>;
                      final orderId = orderDoc.id;

                      return Padding(
                        padding: EdgeInsets.only(bottom: index == orders.length - 1 ? 0 : 16),
                        child: _PremiumOrderCard(
                          orderId: orderId,
                          orderData: orderData,
                        ),
                      );
                    },
                    childCount: orders.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PremiumOrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const _PremiumOrderCard({
    required this.orderId,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    final status = orderData['status'] ?? 'pending';
    
    // Use new schema fields (paymentSummary.totalOrderValue)
    final paymentSummary = orderData['paymentSummary'] as Map<String, dynamic>?;
    final pricingSummary = orderData['pricingSummary'] as Map<String, dynamic>?;
    
    final totalAmount = (paymentSummary?['totalOrderValue'] ?? 
                        pricingSummary?['totalBeforePayment'] ?? 
                        orderData['totalAmount'] ?? 0.0).toDouble();
    final createdAt = orderData['createdAt'] as Timestamp?;
    final items = orderData['items'] as List<dynamic>? ?? [];
    
    final dateStr = createdAt != null 
        ? DateFormat('dd MMM yyyy').format(createdAt.toDate())
        : 'Unknown';
    
    final timeStr = createdAt != null
        ? DateFormat('hh:mm a').format(createdAt.toDate())
        : '';

    // Get first 3 items for preview
    final previewItems = items.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed('/order-details', arguments: orderId),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Order ID and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${orderId.substring(0, 8).toUpperCase()}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Iconsax.calendar_1,
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateStr,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (timeStr.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '•',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  timeStr,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    OrderUIHelpers.buildModernStatusChip(status, context),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Product preview images
                if (previewItems.isNotEmpty) ...[ 
                  Row(
                    children: [
                      ...previewItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value as Map<String, dynamic>;
                        final itemImage = item['productImage'] ?? item['image'] ?? item['images']?[0] ?? '';
                        
                        return Container(
                          margin: EdgeInsets.only(right: index < previewItems.length - 1 ? 8 : 0),
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
                            child: itemImage.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: itemImage,
                                    fit: BoxFit.cover,
                                    fadeInDuration: const Duration(milliseconds: 200),
                                    placeholder: (context, url) => Container(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      child: Center(
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
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
                        );
                      }),
                      if (items.length > 3) ...[ 
                        const SizedBox(width: 8),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '+${items.length - 3}',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                ],
                
                // Divider
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
                
                const SizedBox(height: 16),
                
                // Items count and total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Iconsax.box,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${items.length} ${items.length == 1 ? 'Item' : 'Items'}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹${totalAmount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
