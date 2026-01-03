import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A popup widget for confirming delivery of orders
/// Follows the existing UI design patterns and theming
class DeliveryConfirmationPopup extends StatefulWidget {
  final String orderId;
  final String orderNumber;
  final double totalAmount;
  final Map<String, dynamic>? orderData;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  const DeliveryConfirmationPopup({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.totalAmount,
    this.orderData,
    required this.onConfirm,
    required this.onReject,
  });

  @override
  State<DeliveryConfirmationPopup> createState() => _DeliveryConfirmationPopupState();
}

class _DeliveryConfirmationPopupState extends State<DeliveryConfirmationPopup> {
  bool _productChecked = false;
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      backgroundColor: colorScheme.surface,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 450,
          minWidth: 320,
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with delivery icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.truck_fast,
                  size: 36,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              Text(
                'Delivery Confirmation Required',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                'Please confirm that you have received your order',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 20),
              
              // Order details card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order header
                    Row(
                      children: [
                        Icon(
                          Iconsax.receipt_item,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Order Details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Order number and amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          flex: 2,
                          child: Text(
                            'Order #${widget.orderNumber}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.totalAmount > 0)
                          Flexible(
                            flex: 1,
                            child: Text(
                              '₹${widget.totalAmount.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Delivery status
                    Row(
                      children: [
                        Icon(
                          Iconsax.tick_circle,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Marked as delivered',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    // Additional order information
                    if (widget.orderData != null) ...[
                      const SizedBox(height: 16),
                      _buildOrderInfo(theme, colorScheme),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Product verification section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.secondary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Iconsax.verify,
                          size: 20,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Product Verification',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Checkbox for product verification
                    InkWell(
                      onTap: () {
                        setState(() {
                          _productChecked = !_productChecked;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _productChecked 
                              ? colorScheme.primaryContainer.withOpacity(0.5)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _productChecked 
                                ? colorScheme.primary
                                : colorScheme.outline.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _productChecked 
                                    ? colorScheme.primary 
                                    : Colors.transparent,
                                border: Border.all(
                                  color: _productChecked 
                                      ? colorScheme.primary
                                      : colorScheme.outline,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: _productChecked
                                  ? Icon(
                                      Icons.check,
                                      size: 14,
                                      color: colorScheme.onPrimary,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'I have received and checked the product(s)',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: _productChecked 
                                      ? FontWeight.w500 
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  // Not Yet button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isConfirming ? null : widget.onReject,
                      icon: Icon(
                        Iconsax.clock,
                        size: 18,
                      ),
                      label: const Text('Not Yet'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: colorScheme.outline),
                        foregroundColor: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Confirm button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_productChecked && !_isConfirming) 
                          ? () {
                              setState(() {
                                _isConfirming = true;
                              });
                              widget.onConfirm();
                            }
                          : null,
                      icon: _isConfirming
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Icon(
                              Iconsax.tick_circle,
                              size: 18,
                            ),
                      label: Text(_isConfirming ? 'Confirming...' : 'Received'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: _productChecked 
                            ? colorScheme.primary 
                            : colorScheme.surfaceContainerHighest,
                        foregroundColor: _productChecked 
                            ? colorScheme.onPrimary 
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (!_productChecked) ...[
                const SizedBox(height: 12),
                Text(
                  'Please verify that you have received and checked your product(s) before confirming',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderInfo(ThemeData theme, ColorScheme colorScheme) {
    final orderData = widget.orderData!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Delivery address if available
        if (orderData['shippingAddress'] != null) ...[
          _buildInfoRow(
            theme,
            colorScheme,
            Iconsax.location,
            'Delivery Address',
            _formatAddress(orderData['shippingAddress']),
          ),
          const SizedBox(height: 8),
        ],
        
        // Payment method if available
        if (orderData['paymentMethod'] != null) ...[
          _buildInfoRow(
            theme,
            colorScheme,
            Iconsax.card,
            'Payment Method',
            orderData['paymentMethod'].toString().toUpperCase(),
          ),
          const SizedBox(height: 8),
        ],
        
        // Order date if available
        if (orderData['createdAt'] != null) ...[
          _buildInfoRow(
            theme,
            colorScheme,
            Iconsax.calendar,
            'Order Date',
            _formatDate(orderData['createdAt']),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    ColorScheme colorScheme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatAddress(dynamic address) {
    if (address is Map<String, dynamic>) {
      final parts = <String>[];
      if (address['street'] != null) parts.add(address['street'].toString());
      if (address['city'] != null) parts.add(address['city'].toString());
      if (address['state'] != null) parts.add(address['state'].toString());
      if (address['postalCode'] != null) parts.add(address['postalCode'].toString());
      return parts.join(', ');
    }
    return address.toString();
  }

  String _formatDate(dynamic date) {
    try {
      DateTime dateTime;
      
      if (date is DateTime) {
        dateTime = date;
      } else if (date is Timestamp) {
        // Handle Firestore Timestamp objects
        dateTime = date.toDate();
      } else if (date != null) {
        // Try to parse as string
        dateTime = DateTime.parse(date.toString());
      } else {
        return 'N/A';
      }
      
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      // Log the error for debugging
      print('Error formatting date: $e, date type: ${date.runtimeType}, date value: $date');
    }
    return 'N/A';
  }
}

/// A bottom sheet variant of the delivery confirmation popup
/// Can be used as an alternative to the dialog
class DeliveryConfirmationBottomSheet extends StatelessWidget {
  final String orderId;
  final String orderNumber;
  final double totalAmount;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  const DeliveryConfirmationBottomSheet({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.totalAmount,
    required this.onConfirm,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Header with delivery icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.truck_fast,
                size: 28,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Title
            Text(
              'Delivery Confirmation',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Order details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 2,
                        child: Text(
                          'Order #$orderNumber',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (totalAmount > 0)
                        Flexible(
                          flex: 1,
                          child: Text(
                            '₹${totalAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Iconsax.tick_circle,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Marked as delivered',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Main message
            Text(
              'Your order has been marked as delivered. Please confirm if you\'ve received it.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                // Not Received button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Iconsax.close_circle),
                    label: const Text('Not Yet'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: colorScheme.outline,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Confirm button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Iconsax.tick_circle),
                    label: const Text('Received'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Help text
            Text(
              'This helps us improve our delivery service',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Utility class to show delivery confirmation popups
class DeliveryConfirmationHelper {
  /// Show delivery confirmation as a dialog
  static void showAsDialog({
    required String orderId,
    required String orderNumber,
    required double totalAmount,
    required VoidCallback onConfirm,
    required VoidCallback onReject,
  }) {
    Get.dialog(
      DeliveryConfirmationPopup(
        orderId: orderId,
        orderNumber: orderNumber,
        totalAmount: totalAmount,
        onConfirm: onConfirm,
        onReject: onReject,
      ),
      barrierDismissible: false,
      name: 'delivery_confirmation_$orderId',
    );
  }
  
  /// Show delivery confirmation as a bottom sheet
  static void showAsBottomSheet({
    required String orderId,
    required String orderNumber,
    required double totalAmount,
    required VoidCallback onConfirm,
    required VoidCallback onReject,
  }) {
    Get.bottomSheet(
      DeliveryConfirmationBottomSheet(
        orderId: orderId,
        orderNumber: orderNumber,
        totalAmount: totalAmount,
        onConfirm: onConfirm,
        onReject: onReject,
      ),
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
    );
  }
}