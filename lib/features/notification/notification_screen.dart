import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/models/notification_model.dart';
import 'package:rps_stationery/features/notification/enable_notification.dart';
import 'package:rps_stationery/features/notification/notification_controller.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/services/notification_storage_service.dart';
import 'package:rps_stationery/utils/theme/design_system.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationController());
    final storageService = Get.put(NotificationStorageService());

    return Obx(() {
      if (!controller.hasNotificationPermission.value) {
        return EnableNotification(
          onEnableClick: () async => controller.requestNotificationPermission(),
        );
      }

      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(DesignSystem.spacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Notifications",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (storageService.unreadCount.value > 0)
                      TextButton(
                        onPressed: () => storageService.markAllAsRead(),
                        child: Text(
                          'Mark all read',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Notifications List
              Expanded(
                child: Obx(() {
                  if (storageService.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (storageService.notifications.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return RefreshIndicator(
                    onRefresh: () => storageService.refreshNotifications(),
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignSystem.spacing.lg,
                      ),
                      itemCount: storageService.notifications.length,
                      itemBuilder: (context, index) {
                        final notification = storageService.notifications[index];
                        return NotificationTile(
                          notification: notification,
                          onTap: () => _handleNotificationTap(context, notification),
                          onMarkAsRead: () => storageService.markAsRead(notification.id),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: DesignSystem.spacing.lg),
          Text(
            'No notifications yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: DesignSystem.spacing.sm),
          Text(
            'You\'ll receive notifications about your orders and updates here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, NotificationModel notification) {
    // Mark as read if not already
    if (!notification.isRead) {
      Get.find<NotificationStorageService>().markAsRead(notification.id);
    }

    // Navigate based on notification type
    switch (notification.type) {
      case 'payment_success':
      case 'cod_order_placed':
      case 'wallet_order_placed':
      case 'order_confirmed':
      case 'order_shipped':
      case 'order_cancelled':
      case 'order_update':
        if (notification.orderId != null) {
          Get.toNamed(Routes.orderDetails, arguments: {'orderId': notification.orderId});
        } else {
          Get.toNamed(Routes.order);
        }
        break;
      case 'product':
        if (notification.productId != null) {
          Get.toNamed(Routes.productDetail, arguments: notification.productId);
        } else {
          _showNotificationDetails(context, notification);
        }
        break;
      case 'category':
        if (notification.categoryId != null) {
          Get.toNamed(Routes.category, arguments: {'categoryId': notification.categoryId});
        } else {
          _showNotificationDetails(context, notification);
        }
        break;
      case 'promotion':
        Get.toNamed(Routes.promotions);
        break;
      case 'referral':
        Get.toNamed(Routes.profileReferrals);
        break;
      default:
        // Show full details
        _showNotificationDetails(context, notification);
        break;
    }
  }

  void _showNotificationDetails(BuildContext context, NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: DesignSystem.borders.md,
        ),
        child: Padding(
          padding: EdgeInsets.all(DesignSystem.spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: DesignSystem.spacing.md),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    notification.body,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              SizedBox(height: DesignSystem.spacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: DesignSystem.borders.md,
      child: Container(
        margin: EdgeInsets.only(bottom: DesignSystem.spacing.sm),
        padding: EdgeInsets.all(DesignSystem.spacing.md),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
          borderRadius: DesignSystem.borders.md,
          border: Border.all(
            color: notification.isRead
                ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  notification.icon,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),

            SizedBox(width: DesignSystem.spacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: DesignSystem.spacing.xs),

                  Text(
                    notification.body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: DesignSystem.spacing.sm),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.timeAgo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      if (!notification.isRead && onMarkAsRead != null)
                        TextButton(
                          onPressed: onMarkAsRead,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: DesignSystem.spacing.sm,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Mark read',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
