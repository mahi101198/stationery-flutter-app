import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rps_stationery/utils/constants/colors.dart';
import 'package:rps_stationery/features/order/components/order_ui_helpers.dart';
import 'package:intl/intl.dart';

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
        ),
        body: const Center(
          child: Text('Please login to view your orders'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Modern header
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            automaticallyImplyLeading: true,
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
                      'My Orders',
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
          
          // Orders list
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('userId', isEqualTo: user.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              print('📦 OrderListScreen: Stream state - ${snapshot.connectionState}');
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                print('⏳ OrderListScreen: Loading orders...');
                return const SliverFillRemaining(
                  child: Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                print('❌ OrderListScreen: Error loading orders: ${snapshot.error}');
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: TColors.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Iconsax.warning_2,
                            size: 48,
                            color: TColors.error,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Error loading orders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: TColors.darkGrey),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                print('📭 OrderListScreen: No orders found');
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Iconsax.box,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No orders yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your order history will appear here',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final orders = snapshot.data!.docs;
              print('✅ OrderListScreen: Found ${orders.length} orders');

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final orderDoc = orders[index];
                      final orderData = orderDoc.data() as Map<String, dynamic>;
                      final orderId = orderDoc.id;

                      return Padding(
                        padding: EdgeInsets.only(bottom: index == orders.length - 1 ? 0 : 12),
                        child: _ModernOrderCard(
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

class _ModernOrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const _ModernOrderCard({
    required this.orderId,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    final status = orderData['status'] ?? 'pending';
    final amountBreakdown = orderData['amountBreakdown'] as Map<String, dynamic>?;
    final totalAmount = (amountBreakdown?['totalOrderAmount'] ?? 
                        amountBreakdown?['finalAmount'] ?? 
                        orderData['amount']?['total'] ?? 
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print('📱 Opening order details for: $orderId');
            Get.toNamed('/order-details', arguments: orderId);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with order date and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Iconsax.calendar5,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateStr,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (timeStr.isNotEmpty)
                                      Text(
                                        timeStr,
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
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
                          width: 56,
                          height: 56,
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
                                          width: 16,
                                          height: 16,
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
                                        size: 20,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFFF5F5F5),
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Color(0xFFBDBDBD),
                                      size: 20,
                                    ),
                                  ),
                          ),
                        );
                      }),
                      if (items.length > 3) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '+${items.length - 3}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                ],
                
                // Items count and total section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                        Theme.of(context).colorScheme.secondary.withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Iconsax.shopping_bag,
                            size: 18,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${items.length} ${items.length == 1 ? 'Item' : 'Items'}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${totalAmount.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // View details button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View Details',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Iconsax.arrow_right_3,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
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

