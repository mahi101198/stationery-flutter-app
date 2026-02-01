import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:confetti/confetti.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/utils/constants/sizes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:rps_stationery/utils/theme/design_system.dart';
import 'package:rps_stationery/utils/theme/component_styles.dart';

class OrderSuccessScreen extends StatefulWidget {
  final String orderId;
  final String? paymentId;
  final double? amount;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    this.paymentId,
    this.amount,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  late ConfettiController _confettiController;
  StreamSubscription<DocumentSnapshot>? _orderSubscription;
  String? _actualOrderId;
  Map<String, dynamic>? _orderData;
  bool _isOrderPaid = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    // Start confetti animation after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _confettiController.play();
    });

    // Get arguments if provided
    final arguments = Get.arguments as Map<String, dynamic>?;
    final razorpayOrderId = arguments?['razorpayOrderId'] ?? widget.orderId;
    final paymentId = arguments?['paymentId'] ?? widget.paymentId;
    final amount = arguments?['amount'] ?? widget.amount;

    print('🔍 OrderSuccessScreen: Arguments received:');
    print('  - razorpayOrderId: $razorpayOrderId');
    print('  - paymentId: $paymentId');
    print('  - amount: $amount');

    // Find the actual order ID and set up real-time listening
    _findOrderAndListen(razorpayOrderId);
  }

  Future<void> _findOrderAndListen(String razorpayOrderId) async {
    try {
      print('🔍 OrderSuccessScreen: Finding order by razorpayOrderId: $razorpayOrderId');

      // Query razorpay_orders collection to find the order
      final razorpayOrderQuery = await FirebaseFirestore.instance
          .collection('razorpay_orders')
          .where('razorpayOrderId', isEqualTo: razorpayOrderId)
          .limit(1)
          .get();

      if (razorpayOrderQuery.docs.isNotEmpty) {
        final razorpayOrderDoc = razorpayOrderQuery.docs.first;
        final razorpayOrderData = razorpayOrderDoc.data();
        final orderId = razorpayOrderData['orderId'];

        print('✅ OrderSuccessScreen: Found orderId: $orderId for razorpayOrderId: $razorpayOrderId');
        
        _actualOrderId = orderId;
        
        // Set up real-time order status listening
        _listenToOrderStatus(orderId);
      } else {
        print('❌ OrderSuccessScreen: No order found for razorpayOrderId: $razorpayOrderId');
        // Use razorpayOrderId as fallback
        _actualOrderId = razorpayOrderId;
      }
    } catch (e) {
      print('❌ OrderSuccessScreen: Error finding order: $e');
      // Continue with success display using available data
    }
  }

  void _listenToOrderStatus(String orderId) {
    print('🔍 OrderSuccessScreen: Setting up real-time listener for order: $orderId');
    
    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        setState(() {
          _orderData = data;
          _isOrderPaid = data['status'] == 'paid' || data['status'] == 'confirmed';
        });
        
        print('📊 OrderSuccessScreen: Order status updated: ${data['status']}');
        
        // If order is paid, show success message
        if (_isOrderPaid) {
          print('✅ OrderSuccessScreen: Order is now paid!');
        }
      }
    }, onError: (error) {
      print('❌ OrderSuccessScreen: Error listening to order: $error');
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _orderSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.03,
              numberOfParticles: 20,
              gravity: 0.1,
              shouldLoop: false,
              colors: [
                Theme.of(context).colorScheme.primary,
                Colors.green,
                Colors.amber,
                Colors.pink,
                Colors.purple,
                Colors.blue,
              ],
            ),
          ),
          
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(DesignSystem.spacing.md),
              child: Column(
                children: [
                  // Success Card
                  _buildSuccessCard(context),
                  
                  SizedBox(height: DesignSystem.spacing.lg),
                  
                  // Order Details Card
                  _buildOrderDetailsCard(context),
                  
                  SizedBox(height: DesignSystem.spacing.lg),
                  
                  // Action Buttons
                  _buildActionButtons(context),
                  
                  SizedBox(height: DesignSystem.spacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(DesignSystem.spacing.xl),
      decoration: BoxDecoration(
        color: _isOrderPaid 
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.orange.withValues(alpha: 0.05),
        borderRadius: DesignSystem.borders.lg,
        border: Border.all(
          color: _isOrderPaid 
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Success Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isOrderPaid ? Colors.green : Colors.orange,
            ),
            child: Icon(
              _isOrderPaid ? Iconsax.tick_circle : Iconsax.timer_1,
              color: Colors.white,
              size: 40,
            ),
          ),
          
          SizedBox(height: DesignSystem.spacing.lg),
          
          // Success Message
          Text(
            _isOrderPaid ? 'Payment Successful!' : 'Order Placed!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: _isOrderPaid ? Colors.green.shade700 : Colors.orange.shade800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: DesignSystem.spacing.sm),
          
          Text(
            _isOrderPaid 
                ? 'Your payment has been received and order is confirmed!'
                : 'Thank you! We\'ll notify you when payment is confirmed.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: DesignSystem.borders.lg,
        boxShadow: DesignSystem.shadows.elevation1,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(DesignSystem.spacing.md),
            child: Row(
              children: [
                Text(
                  'Order Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Details
          Padding(
            padding: EdgeInsets.all(DesignSystem.spacing.md),
            child: Column(
              children: [
                _buildModernDetailRow(
                  context: context,
                  icon: Iconsax.tag,
                  label: 'Order ID',
                  value: _actualOrderId ?? widget.orderId,
                ),
                SizedBox(height: DesignSystem.spacing.md),
                Divider(height: 1, thickness: 1),
                SizedBox(height: DesignSystem.spacing.md),
                _buildModernDetailRow(
                  context: context,
                  icon: Iconsax.money_4,
                  label: 'Amount',
                  value: _getTotalAmount(),
                  isHighlighted: true,
                ),
                SizedBox(height: DesignSystem.spacing.md),
                Divider(height: 1, thickness: 1),
                SizedBox(height: DesignSystem.spacing.md),
                _buildModernDetailRow(
                  context: context,
                  icon: Iconsax.wallet_2,
                  label: 'Payment',
                  value: _getPaymentMethodDisplay(),
                ),
                // Show wallet deduction amount for wallet payments
                if (_isWalletPayment()) ...[
                  SizedBox(height: DesignSystem.spacing.md),
                  Divider(height: 1, thickness: 1),
                  SizedBox(height: DesignSystem.spacing.md),
                  _buildModernDetailRow(
                    context: context,
                    icon: Iconsax.money_4,
                    label: 'Wallet Deduction',
                    value: _getWalletDeductionAmount(),
                    isHighlighted: true,
                  ),
                ],
                SizedBox(height: DesignSystem.spacing.md),
                Divider(height: 1, thickness: 1),
                SizedBox(height: DesignSystem.spacing.md),
                _buildModernDetailRow(
                  context: context,
                  icon: Iconsax.truck,
                  label: 'Delivery',
                  value: '3-5 business days',
                ),
                SizedBox(height: DesignSystem.spacing.lg),
                
                // Info Note
                Container(
                  padding: EdgeInsets.all(DesignSystem.spacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: DesignSystem.borders.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Iconsax.info_circle,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      SizedBox(width: DesignSystem.spacing.sm),
                      Expanded(
                        child: Text(
                          'You\'ll receive order updates via email and push notifications.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDetailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isHighlighted 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: DesignSystem.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: DesignSystem.spacing.xs / 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
                  color: isHighlighted 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Continue Shopping Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Get.offAllNamed(Routes.bottomNav);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: DesignSystem.borders.lg,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.shop, size: 22),
                SizedBox(width: DesignSystem.spacing.sm),
                Text(
                  'Continue Shopping',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: DesignSystem.spacing.md),
        
        // Track Order Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Get.toNamed(Routes.order);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: DesignSystem.borders.lg,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.truck, size: 22),
                SizedBox(width: DesignSystem.spacing.sm),
                Text(
                  'Track Your Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderInfoRow(String label, String value, {IconData? icon, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TSizes.sm),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(TSizes.xs),
              decoration: BoxDecoration(
                color: isTotal 
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) 
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(TSizes.xs),
              ),
              child: Icon(
                icon,
                size: 16,
                color: isTotal 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: TSizes.sm),
          ],
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              fontSize: isTotal ? 16 : 14,
              color: isTotal 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Get total amount from order data (paymentSummary) or fallback to arguments
  /// Always shows totalOrderValue (total order value) for all payment methods
  String _getTotalAmount() {
    // First try to get from order data (new schema: paymentSummary)
    if (_orderData != null) {
      final paymentSummary = _orderData!['paymentSummary'];
      // Check if paymentSummary is actually a Map before casting
      if (paymentSummary is Map<String, dynamic>) {
        // For ALL payment methods, show the total order amount
        try {
          final totalOrderValueRaw = paymentSummary['totalOrderValue'];
          final totalOrderValue = _safeToDouble(totalOrderValueRaw);
          if (totalOrderValue != null && totalOrderValue > 0) {
            print('💰 OrderSuccessScreen: Showing totalOrderValue: ₹$totalOrderValue');
            return '₹${totalOrderValue.toStringAsFixed(2)}';
          }
        } catch (e) {
          print('Error getting totalOrderValue: $e');
        }
      } else if (paymentSummary != null) {
        print('⚠️ OrderSuccessScreen: paymentSummary is not a Map, it is: ${paymentSummary.runtimeType}');
      }
    }
    
    // Fallback to arguments amount
    final arguments = Get.arguments;
    if (arguments is Map<String, dynamic>) {
      final amount = arguments['amount'] ?? widget.amount;
      if (amount != null && amount > 0) {
        print('💰 OrderSuccessScreen: Using fallback amount from arguments: ₹$amount');
        return '₹${amount.toStringAsFixed(2)}';
      }
    }
    
    // Fallback to widget amount
    if (widget.amount != null && widget.amount! > 0) {
      print('💰 OrderSuccessScreen: Using widget amount: ₹${widget.amount}');
      return '₹${widget.amount!.toStringAsFixed(2)}';
    }
    
    // Final fallback
    print('💰 OrderSuccessScreen: Using final fallback amount: ₹0.00');
    return '₹0.00';
  }

  String _getPaymentMethodDisplay() {
    // First try to get from order data
    if (_orderData != null) {
      final paymentMode = _orderData!['paymentMode'] as String?;
      if (paymentMode != null && paymentMode.isNotEmpty) {
        return _formatPaymentMethod(paymentMode);
      }
    }
    
    // Fallback to arguments
    final arguments = Get.arguments as Map<String, dynamic>?;
    final paymentMethod = arguments?['paymentMethod'] as String?;
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      return _formatPaymentMethod(paymentMethod);
    }
    
    // Final fallback
    return 'Online Payment';
  }
  
  String _formatPaymentMethod(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'razorpay':
        return 'Online Payment';
      case 'cod':
        return 'COD';
      case 'wallet':
        return 'Wallet';
      case 'partial_wallet':
        return 'Wallet + Online';
      case 'credit_card':
        return 'Credit/Debit Card';
      case 'upi':
        return 'UPI';
      case 'net_banking':
        return 'Net Banking';
      case 'cash_on_delivery':
        return 'COD';
      case 'digital_wallet':
        return 'Wallet';
      default:
        return 'Online Payment';
    }
  }

  /// Check if this is a wallet payment (full or partial)
  bool _isWalletPayment() {
    // First try to get from order data
    if (_orderData != null) {
      final paymentMode = _orderData!['paymentMode'] as String?;
      if (paymentMode != null) {
        return paymentMode == 'wallet' || paymentMode == 'partial_wallet';
      }
    }
    
    // Fallback to arguments
    final arguments = Get.arguments as Map<String, dynamic>?;
    final paymentMethod = arguments?['paymentMethod'] as String?;
    if (paymentMethod != null) {
      return paymentMethod == 'wallet' || paymentMethod == 'partial_wallet';
    }
    
    return false;
  }

  /// Get wallet deduction amount
  String _getWalletDeductionAmount() {
    // First try to get from order data (new schema: paymentSummary)
    if (_orderData != null) {
      final paymentSummary = _orderData!['paymentSummary'];
      // Check if paymentSummary is actually a Map before accessing
      if (paymentSummary is Map<String, dynamic>) {
        // For full wallet payment, show the total order amount
        final paymentMode = _orderData!['paymentMode'] as String?;
        if (paymentMode == 'wallet') {
          try {
            final totalOrderValueRaw = paymentSummary['totalOrderValue'];
            final totalOrderValue = _safeToDouble(totalOrderValueRaw);
            if (totalOrderValue != null && totalOrderValue > 0) {
              return '₹${totalOrderValue.toStringAsFixed(2)}';
            }
          } catch (e) {
            print('Error getting totalOrderValue for wallet deduction: $e');
          }
        } else if (paymentMode == 'partial_wallet') {
          // For partial wallet payment, show the wallet amount used
          try {
            final walletPaidAmountRaw = paymentSummary['walletPaidAmount'];
            final walletPaidAmount = _safeToDouble(walletPaidAmountRaw);
            if (walletPaidAmount != null && walletPaidAmount > 0) {
              return '₹${walletPaidAmount.toStringAsFixed(2)}';
            }
          } catch (e) {
            print('Error getting walletPaidAmount for partial wallet deduction: $e');
          }
        }
      }
    }
    
    // Fallback to arguments
    final arguments = Get.arguments;
    if (arguments is Map<String, dynamic>) {
      final amountPaid = arguments['amountPaid'] as double?;
      if (amountPaid != null && amountPaid > 0) {
        return '₹${amountPaid.toStringAsFixed(2)}';
      }
    }
    
    // Final fallback
    return '₹0.00';
  }
  
  /// Safe conversion from int/double to double
  double? _safeToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
