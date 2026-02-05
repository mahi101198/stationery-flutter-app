import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/features/checkout/controllers/payment_controller.dart';
import 'package:rps_stationery/features/checkout/components/payment_banner_carousel.dart';
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
          // Minimal App Bar
          SliverAppBar(
            expandedHeight: 80,
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
                    MediaQuery.of(context).padding.top + DesignSystem.spacing.md,
                    DesignSystem.spacing.md,
                    DesignSystem.spacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                          Expanded(
                            child: Text(
                              'Payment',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
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

          // Main content with banner carousel and payment info
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: DesignSystem.spacing.xs, vertical: DesignSystem.spacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Premium Banner Carousel
                const PaymentBannerCarousel(),
                
                SizedBox(height: DesignSystem.spacing.lg),
                
                // Payment Method - Single Option: Online
                _buildOnlinePaymentCard(context, controller),
                
                SizedBox(height: DesignSystem.spacing.xl * 2),
              ]),
            ),
          ),
        ],
      ),
      // Modern Price Card at Bottom
      bottomNavigationBar: _buildPriceCardBottom(context, controller),
    );
  }

  /// Build online payment card - Modern design
  Widget _buildOnlinePaymentCard(BuildContext context, PaymentController controller) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        controller.selectPaymentMethod('razorpay');
      },
      child: Container(
        padding: EdgeInsets.all(DesignSystem.spacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: DesignSystem.borders.lg,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Payment icon
            Container(
              padding: EdgeInsets.all(DesignSystem.spacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: DesignSystem.borders.md,
              ),
              child: Icon(
                Iconsax.card_tick,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            SizedBox(width: DesignSystem.spacing.lg),
            // Payment method details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Online Payment',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: DesignSystem.spacing.xs),
                  Text(
                    'UPI, Card, Net Banking & More',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Check mark
            Icon(
              Iconsax.tick_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }


  /// Build price card at bottom - Premium design
  Widget _buildPriceCardBottom(BuildContext context, PaymentController controller) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.spacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: SafeArea(
        child: Obx(() => Row(
          children: [
            // Total amount display on left
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: DesignSystem.spacing.xs),
                  Text(
                    '₹${widget.finalAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: DesignSystem.spacing.lg),
            // Pay button on right
            Expanded(
              child: ElevatedButton(
                onPressed: controller.isProcessingPayment ? null : () => _processPayment(controller),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: DesignSystem.borders.lg,
                  ),
                  disabledBackgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  padding: EdgeInsets.symmetric(vertical: DesignSystem.spacing.md),
                ),
                child: controller.isProcessingPayment
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.card_tick,
                            size: 20,
                          ),
                          SizedBox(width: DesignSystem.spacing.sm),
                          Text(
                            'Pay',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
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
