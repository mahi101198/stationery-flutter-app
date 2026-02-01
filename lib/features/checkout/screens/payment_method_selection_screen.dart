import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/features/checkout/controllers/payment_controller.dart';
import 'package:rps_stationery/data/models/cart_model.dart';
import 'package:rps_stationery/data/models/user_model.dart';
import 'package:rps_stationery/services/razorpay_payment_service.dart';
import 'package:rps_stationery/utils/constants/colors.dart';
import 'package:rps_stationery/utils/constants/sizes.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/utils/theme/design_system.dart';

class PaymentMethodSelectionScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final UserAddress deliveryAddress;
  final double totalAmount;
  final String? promoCode;
  final double discountAmount;
  final double finalAmount;
  final double deliveryCharge;
  final double walletDiscountAmount;
  final bool payFromWallet;
  final String? orderId; // For remaining payment scenarios
  final double? remainingAmount; // For remaining payment scenarios
  final bool isBuyNow;
  final Map<String, dynamic>? buyNowData;

  const PaymentMethodSelectionScreen({
    super.key,
    required this.cartItems,
    required this.deliveryAddress,
    required this.totalAmount,
    this.promoCode,
    required this.discountAmount,
    required this.finalAmount,
    required this.deliveryCharge,
    this.walletDiscountAmount = 0.0,
    this.payFromWallet = false,
    this.orderId,
    this.remainingAmount,
    this.isBuyNow = false,
    this.buyNowData,
  });

  @override
  State<PaymentMethodSelectionScreen> createState() => _PaymentMethodSelectionScreenState();
}

class _PaymentMethodSelectionScreenState extends State<PaymentMethodSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentController());
    
    // If partial wallet payment, disable COD and select Razorpay by default
    if (widget.walletDiscountAmount > 0 && controller.selectedPaymentMethod == 'cod') {
      controller.selectPaymentMethod('razorpay');
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Minimal App Bar - White background
          SliverAppBar(
            expandedHeight: 110,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            leading: IconButton(
              icon: Icon(Iconsax.arrow_left, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () {
                HapticFeedback.lightImpact();
                Get.back();
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    DesignSystem.spacing.md,
                    MediaQuery.of(context).padding.top + DesignSystem.spacing.xl,
                    DesignSystem.spacing.md,
                    DesignSystem.spacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(DesignSystem.spacing.sm),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F3F4),
                              borderRadius: DesignSystem.borders.md,
                            ),
                            child: const Icon(
                              Iconsax.card,
                              color: Color(0xFF5A7C8A),
                              size: 20,
                            ),
                          ),
                          SizedBox(width: DesignSystem.spacing.md),
                          const Expanded(
                            child: Text(
                              'Payment Method',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF16161E),
                                letterSpacing: -0.5,
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
          ),

          // Content
          SliverPadding(
            padding: EdgeInsets.all(DesignSystem.spacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Amount to Pay Card
                _buildAmountCard(context),
                
                SizedBox(height: DesignSystem.spacing.md),
                
                // Payment Methods
                _buildModernPaymentMethods(context, controller),
                
                SizedBox(height: DesignSystem.spacing.md),
                
                // Terms and Conditions
                _buildModernTermsCard(context),
                
                SizedBox(height: DesignSystem.spacing.xl * 2),
              ]),
            ),
          ),
        ],
      ),
      // Modern Payment Button
      bottomNavigationBar: _buildModernPaymentButton(context, controller),
    );
  }


  Widget _buildAmountCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.spacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: DesignSystem.borders.lg,
        boxShadow: DesignSystem.shadows.primaryShadow(0.2),
      ),
      child: Column(
        children: [
          Text(
            'Total Amount',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: DesignSystem.spacing.xs),
          Text(
            '₹${widget.finalAmount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 36,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPaymentMethods(BuildContext context, PaymentController controller) {
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
                  'Choose Payment Method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Payment Method Cards
          Padding(
            padding: EdgeInsets.all(DesignSystem.spacing.md),
            child: Obx(() => Column(
              children: [
                // Razorpay
                _buildModernPaymentMethodCard(
                  context: context,
                  controller: controller,
                  methodId: 'razorpay',
                  title: 'Online Payment',
                  subtitle: 'UPI, Card, Net Banking & More',
                  icon: Iconsax.card,
                  isSelected: controller.selectedPaymentMethod == 'razorpay',
                ),
                
                SizedBox(height: DesignSystem.spacing.md),
                
                // COD - Disabled for partial wallet payments
                // _buildModernPaymentMethodCard(
                //   context: context,
                //   controller: controller,
                //   methodId: 'cod',
                //   title: 'Cash on Delivery',
                //   subtitle: widget.walletDiscountAmount > 0 
                //       ? 'Not available with wallet payment'
                //       : 'Pay when your order arrives',
                //   icon: Iconsax.money_send,
                //   isSelected: controller.selectedPaymentMethod == 'cod',
                //   isDisabled: widget.walletDiscountAmount > 0,
                // ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPaymentMethodCard({
    required BuildContext context,
    required PaymentController controller,
    required String methodId,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : () {
        HapticFeedback.selectionClick();
        controller.selectPaymentMethod(methodId);
      },
      child: Container(
        padding: EdgeInsets.all(DesignSystem.spacing.md),
        decoration: BoxDecoration(
          color: isDisabled 
              ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05) : Theme.of(context).cardColor,
          borderRadius: DesignSystem.borders.md,
          border: Border.all(
            color: isDisabled
                ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)
                : isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected && !isDisabled ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDisabled 
                  ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                  : isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 24,
            ),
            SizedBox(width: DesignSystem.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDisabled
                          ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                          : isSelected 
                              ? Theme.of(context).colorScheme.primary 
                              : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: DesignSystem.spacing.xs / 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDisabled
                          ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected && !isDisabled)
              Icon(
                Iconsax.tick_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTermsCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.spacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: DesignSystem.borders.md,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Iconsax.security_safe,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          SizedBox(width: DesignSystem.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Payment',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: DesignSystem.spacing.xs / 2),
                Text(
                  'Your payment information is encrypted and secure. By proceeding, you agree to our terms and conditions.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPaymentButton(BuildContext context, PaymentController controller) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.spacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        child: Obx(() => SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: controller.isProcessingPayment ? null : () => _processPayment(controller),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: DesignSystem.borders.lg,
              ),
            ),
            child: controller.isProcessingPayment
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: DesignSystem.spacing.md),
                      Text(
                        'Processing Payment...',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        controller.selectedPaymentMethod == 'razorpay' 
                            ? Iconsax.card_tick 
                            : Iconsax.money_send,
                        size: 22,
                      ),
                      SizedBox(width: DesignSystem.spacing.sm),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.selectedPaymentMethod == 'razorpay'
                                ? 'Pay Now'
                                : 'Place Order',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '₹${widget.finalAmount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        )),
      ),
    );
  }

  Future<void> _processPayment(PaymentController controller) async {
    print('🔍 PaymentMethodSelectionScreen._processPayment called');
    print('  - cartItems count: ${widget.cartItems.length}');
    print('  - Original totalAmount: ${widget.totalAmount}');
    print('  - Final amount: ${widget.finalAmount}');
    print('  - Discount amount: ${widget.discountAmount}');
    print('  - Wallet discount amount: ${widget.walletDiscountAmount}');
    print('  - Pay from wallet: ${widget.payFromWallet}');
    print('  - Delivery charge: ${widget.deliveryCharge}');
    print('  - Selected payment method: ${controller.selectedPaymentMethod}');
    
    for (int i = 0; i < widget.cartItems.length; i++) {
      print('  CartItem $i: productId=${widget.cartItems[i].productId}, quantity=${widget.cartItems[i].quantity}');
    }

    try {
      print('🚀 Starting payment processing...');
      
      // Check if this is a remaining payment scenario
      if (widget.orderId != null && widget.remainingAmount != null) {
        // This is completing remaining payment for a partial wallet order
        print('💰 Processing remaining payment for order: ${widget.orderId}');
        print('💰 Remaining amount: ₹${widget.remainingAmount}');
        
        final razorpayService = Get.find<RazorpayPaymentService>();
        final response = await razorpayService.completeRemainingPayment(
          orderId: widget.orderId!,
          remainingAmount: widget.remainingAmount!,
          paymentMethod: controller.selectedPaymentMethod,
        );
        
        if (response['success'] == true) {
          // Navigate to order success
          Get.offAllNamed(Routes.orderSuccess, arguments: {
            'orderId': widget.orderId,
            'paymentMethod': 'partial_wallet', // This is for remaining payment after wallet deduction
            'amount': widget.totalAmount, // Pass total order amount
          });
          TLoaders.successSnackBar(
            title: 'Payment Successful',
            message: 'Remaining payment processed!',
          );
        } else {
          throw Exception(response['error'] ?? 'Failed to complete remaining payment');
        }
      } else {
        // This is a regular payment flow
        if (widget.payFromWallet && widget.walletDiscountAmount > 0) {
          // Partial wallet payment - set partial_wallet payment method
          controller.selectPaymentMethod('partial_wallet');
        }
        
        // Calculate amount breakdown for backend
        final double totalOrderAmount = widget.totalAmount + widget.deliveryCharge;
        final double subTotal = widget.totalAmount;
        final double discount = widget.discountAmount;
        final double deliveryFee = widget.deliveryCharge;
        final double walletUsed = widget.walletDiscountAmount;
        final double finalPayable = widget.finalAmount;
        
        await controller.processPayment(
          cartItems: widget.cartItems,
          deliveryAddress: widget.deliveryAddress,
          totalAmount: totalOrderAmount,
          subTotal: subTotal,
          discount: discount,
          deliveryFee: deliveryFee,
          walletUsed: walletUsed,
          finalPayable: finalPayable,
          couponCode: widget.promoCode,
          isBuyNow: widget.isBuyNow,
          buyNowData: widget.buyNowData,
        );
      }

      print('✅ Payment processing completed successfully');
    } catch (e) {
      print('❌ Payment processing failed: $e');
    }
  }
}
