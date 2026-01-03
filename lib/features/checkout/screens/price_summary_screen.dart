import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/data/models/cart_model.dart';
import 'package:rps_stationery/data/models/coupon_model.dart';
import 'package:rps_stationery/data/models/user_model.dart';
import 'package:rps_stationery/data/services/user_service.dart';
import 'package:rps_stationery/services/coupon_service.dart';
import 'package:rps_stationery/features/checkout/controllers/payment_controller.dart';
import 'package:rps_stationery/services/razorpay_payment_service.dart';
import 'package:rps_stationery/utils/constants/colors.dart';
import 'package:rps_stationery/utils/constants/sizes.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';
import 'package:rps_stationery/utils/price_calculator.dart';
import 'package:rps_stationery/components/checkout/unified_order_summary.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/utils/theme/design_system.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rps_stationery/features/personalization/screens/address/address_form_page.dart';

class PriceSummaryScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final UserAddress deliveryAddress;
  final double totalAmount;
  final String? promoCode;
  final bool isBuyNow;
  final Map<String, dynamic>? buyNowData;

  const PriceSummaryScreen({
    super.key,
    required this.cartItems,
    required this.deliveryAddress,
    required this.totalAmount,
    this.promoCode,
    this.isBuyNow = false,
    this.buyNowData,
  });

  @override
  State<PriceSummaryScreen> createState() => _PriceSummaryScreenState();
}

class _PriceSummaryScreenState extends State<PriceSummaryScreen> with WidgetsBindingObserver {
  final TextEditingController _couponController = TextEditingController();
  final CouponService _couponService = Get.put(CouponService());
  
  CouponModel? _appliedCoupon;
  double _discountAmount = 0.0;
  bool _isValidatingCoupon = false;
  bool _payFromWallet = false;
  double _walletBalance = 0.0;
  bool _isProcessingPayment = false;
  late UserAddress _currentDeliveryAddress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentDeliveryAddress = widget.deliveryAddress;
    // If promoCode is passed from previous screen, apply it
    if (widget.promoCode != null && widget.promoCode!.isNotEmpty) {
      _couponController.text = widget.promoCode!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyCoupon();
      });
    }
    // Load wallet balance
    _loadWalletBalance();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh wallet balance when app becomes active
    if (state == AppLifecycleState.resumed) {
      _loadWalletBalance();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _couponController.dispose();
    super.dispose();
  }

  double get _walletDiscountAmount {
    if (!_payFromWallet || _walletBalance <= 0) return 0.0;
    return PriceCalculator.calculatePartialWalletAmount(
      orderTotal: widget.totalAmount,
      walletBalance: _walletBalance,
      couponDiscount: _discountAmount,
    );
  }

  double get _finalAmount {
    return PriceCalculator.calculateFinalAmount(
      orderTotal: widget.totalAmount,
      couponDiscount: _discountAmount,
      walletDiscount: _walletDiscountAmount,
    );
  }

  bool get _canPayFullyWithWallet {
    return _payFromWallet && PriceCalculator.canPayFullyWithWallet(
      orderTotal: widget.totalAmount,
      walletBalance: _walletBalance,
      couponDiscount: _discountAmount,
    );
  }

  bool get _canPayPartiallyWithWallet {
    return _payFromWallet && _walletBalance > 0 && !_canPayFullyWithWallet;
  }

  double get _deliveryCharge {
    return PriceCalculator.calculateDeliveryCharge(widget.totalAmount);
  }

  Future<void> _applyCoupon() async {
    if (_couponController.text.trim().isEmpty) {
      TLoaders.warningSnackBar(title: 'Invalid Coupon', message: 'Please enter a coupon code');
      return;
    }

    setState(() {
      _isValidatingCoupon = true;
    });

    try {
      final result = await _couponService.validateCoupon(
        cartItems: widget.cartItems,
        couponCode: _couponController.text.trim(),
        orderTotal: widget.totalAmount,
      );
      if (result.isValid && result.coupon != null) {
        setState(() {
          _appliedCoupon = result.coupon;
          _discountAmount = result.discountAmount;
        });
        TLoaders.successSnackBar(title: 'Coupon Applied', message: 'You saved ₹${_discountAmount.toStringAsFixed(2)}');
      } else {
        TLoaders.errorSnackBar(title: 'Invalid Coupon', message: result.message ?? 'This coupon code is not valid');
      }
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: e.toString());
    } finally {
      setState(() {
        _isValidatingCoupon = false;
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _discountAmount = 0.0;
      _couponController.clear();
    });
    TLoaders.customToast(message: 'Coupon removed');
  }

  Future<void> _loadWalletBalance() async {
    try {
      print('💰 Loading wallet balance...');
      final user = await Get.find<UserService>().getCurrentUser();
      if (user != null) {
        print('💰 Current wallet balance: ₹${user.walletBalance}');
        setState(() {
          _walletBalance = user.walletBalance;
        });
      } else {
        print('💰 No user found, wallet balance: ₹0.0');
        setState(() {
          _walletBalance = 0.0;
        });
      }
    } catch (e) {
      print('❌ Error loading wallet balance: $e');
      setState(() {
        _walletBalance = 0.0;
      });
    }
  }

  void _proceedToPayment() {
    if (_canPayFullyWithWallet) {
      // Full wallet payment - process directly
      _processFullWalletPayment();
    } else {
      // Partial wallet or no wallet - go to payment method selection
      Get.toNamed(Routes.paymentMethodSelection, arguments: {
        'cartItems': widget.cartItems,
        'deliveryAddress': widget.deliveryAddress,
        'totalAmount': widget.totalAmount,
        'promoCode': _appliedCoupon?.code,
        'discountAmount': _discountAmount,
        'finalAmount': _finalAmount,
        'deliveryCharge': _deliveryCharge,
        'walletDiscountAmount': _walletDiscountAmount,
        'payFromWallet': _payFromWallet,
        'isBuyNow': widget.isBuyNow,
        'buyNowData': widget.buyNowData,
      });
    }
  }

  Future<void> _processFullWalletPayment() async {
    try {
      // Show loading state
      setState(() {
        _isProcessingPayment = true;
      });
      
      // Ensure RazorpayPaymentService is available
      if (!Get.isRegistered<RazorpayPaymentService>()) {
        Get.put(RazorpayPaymentService(), permanent: true);
      }
      
      final paymentController = Get.put(PaymentController());
      
      // Determine payment mode based on wallet usage
      final bool canPayFullyWithWallet = _canPayFullyWithWallet;
      final bool canPayPartiallyWithWallet = _canPayPartiallyWithWallet;
      
      String paymentMode;
      if (canPayFullyWithWallet) {
        paymentMode = 'wallet';
      } else if (canPayPartiallyWithWallet) {
        paymentMode = 'partial_wallet';
      } else {
        paymentMode = 'razorpay'; // Default to Razorpay
      }
      
      // Set payment method
      paymentController.selectPaymentMethod(paymentMode);
      
      // Calculate amount breakdown for backend
      final double totalOrderAmount = widget.totalAmount + _deliveryCharge;
      final double subTotal = widget.totalAmount;
      final double discount = _discountAmount;
      final double deliveryFee = _deliveryCharge;
      final double walletUsed = _walletDiscountAmount;
      final double finalPayable = _finalAmount;
      
      // Process payment with amount breakdown
      await paymentController.processPayment(
        cartItems: widget.cartItems,
        deliveryAddress: widget.deliveryAddress,
        totalAmount: totalOrderAmount,
        subTotal: subTotal,
        discount: discount,
        deliveryFee: deliveryFee,
        walletUsed: walletUsed,
        finalPayable: finalPayable,
        couponCode: _appliedCoupon?.code,
        isBuyNow: widget.isBuyNow,
        buyNowData: widget.buyNowData,
      );
    } catch (e) {
      // Hide loading state on error
      setState(() {
        _isProcessingPayment = false;
      });
      
      TLoaders.errorSnackBar(
        title: 'Payment Failed',
        message: e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
              icon: Icon(Iconsax.arrow_left, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () {
                HapticFeedback.lightImpact();
                Get.back();
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                    ],
                  ),
                ),
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
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: DesignSystem.borders.md,
                            ),
                            child: Icon(
                              Iconsax.receipt_2,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: DesignSystem.spacing.md),
                          Expanded(
                            child: Text(
                              'Order Summary',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: Theme.of(context).colorScheme.onSurface,
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
                // Order Details
                _buildModernOrderSummary(context),
                
                SizedBox(height: DesignSystem.spacing.md),
                
                // Coupon Section
                _buildModernCouponSection(context),
                
                SizedBox(height: DesignSystem.spacing.md),
                
                // Pay from Wallet Section
                _buildModernWalletSection(context),
                
                SizedBox(height: DesignSystem.spacing.md),

                // Price Breakdown
                _buildModernPriceBreakdown(context),
                
                SizedBox(height: DesignSystem.spacing.xl * 2),
              ]),
            ),
          ),
        ],
      ),
      // Modern Proceed Button
      bottomNavigationBar: _buildModernProceedButton(context),
    );
  }


  Widget _buildModernOrderSummary(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(DesignSystem.spacing.md),
            child: Text(
              '${widget.cartItems.length} ${widget.cartItems.length == 1 ? 'Item' : 'Items'} in Cart',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const Divider(height: 1),
          // Content
          Padding(
            padding: EdgeInsets.all(DesignSystem.spacing.md),
            child: UnifiedOrderSummary(
              cartItems: widget.cartItems,
              deliveryAddress: _currentDeliveryAddress,
              orderTotal: widget.totalAmount,
              couponDiscount: _discountAmount,
              walletDiscount: _walletDiscountAmount,
              showDetailedBreakdown: false,
              onEditAddress: () => _showAddressSelectionBottomSheet(context),
              onEditItems: () => Get.back(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCouponSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: DesignSystem.borders.lg,
        boxShadow: DesignSystem.shadows.elevation1,
        border: Border.all(
          color: _appliedCoupon != null 
              ? TColors.success.withValues(alpha: 0.3) 
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(DesignSystem.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _appliedCoupon != null ? 'Coupon Applied' : 'Apply Coupon',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: _appliedCoupon != null ? TColors.success : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignSystem.spacing.md),
            
            if (_appliedCoupon == null) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'ENTER CODE',
                        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: DesignSystem.borders.md,
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    ),
                  ),
                  SizedBox(width: DesignSystem.spacing.sm),
                  ElevatedButton(
                    onPressed: _isValidatingCoupon ? null : _applyCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignSystem.spacing.lg,
                        vertical: 12, // Match text field height roughly
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: DesignSystem.borders.md,
                      ),
                    ),
                    child: _isValidatingCoupon
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Apply',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: EdgeInsets.all(DesignSystem.spacing.md),
                decoration: BoxDecoration(
                  color: TColors.success.withValues(alpha: 0.05),
                  borderRadius: DesignSystem.borders.md,
                  border: Border.all(
                    color: TColors.success.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.tick_circle,
                      color: TColors.success,
                      size: 20,
                    ),
                    SizedBox(width: DesignSystem.spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _appliedCoupon!.code.toUpperCase(),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: TColors.success,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: DesignSystem.spacing.xs / 2),
                          Text(
                            'You saved ₹${_discountAmount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: TColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _removeCoupon();
                      },
                      icon: Icon(Iconsax.close_circle, color: TColors.success),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernWalletSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: DesignSystem.borders.lg,
        boxShadow: DesignSystem.shadows.elevation1,
        border: Border.all(
          color: _payFromWallet 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3) 
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(DesignSystem.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _walletBalance > 0 ? () {
                HapticFeedback.selectionClick();
                setState(() {
                  _payFromWallet = !_payFromWallet;
                });
                if (_payFromWallet) {
                  _loadWalletBalance();
                }
              } : null,
              borderRadius: DesignSystem.borders.md,
              child: Row(
                children: [
                  Icon(
                    Iconsax.wallet_3,
                    color: _payFromWallet 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  SizedBox(width: DesignSystem.spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pay from Wallet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: DesignSystem.spacing.xs / 2),
                        Row(
                          children: [
                            Text(
                              'Available Balance: ',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '₹${_walletBalance.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _walletBalance > 0 ? TColors.success : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _payFromWallet,
                    onChanged: _walletBalance > 0 ? (value) {
                       setState(() {
                        _payFromWallet = value;
                      });
                      if (_payFromWallet) {
                        _loadWalletBalance();
                      }
                    } : null,
                  ),
                ],
              ),
            ),
            
            if (_payFromWallet) ...[
              SizedBox(height: DesignSystem.spacing.md),
              Container(
                padding: EdgeInsets.all(DesignSystem.spacing.sm),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: DesignSystem.borders.md,
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.info_circle, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    SizedBox(width: DesignSystem.spacing.sm),
                    Expanded(
                      child: Text(
                        _canPayFullyWithWallet
                            ? 'Full amount will be deducted from wallet'
                            : '₹${_walletDiscountAmount.toStringAsFixed(2)} will be deducted from wallet',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernPriceBreakdown(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: DesignSystem.borders.lg,
                boxShadow: DesignSystem.shadows.elevation3,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(DesignSystem.spacing.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: DesignSystem.borders.lg.topLeft,
                        topRight: DesignSystem.borders.lg.topRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Iconsax.calculator, color: Theme.of(context).colorScheme.primary, size: 20),
                        SizedBox(width: DesignSystem.spacing.sm),
                        Text(
                          'Price Breakdown',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Breakdown Items
                  Padding(
                    padding: EdgeInsets.all(DesignSystem.spacing.md),
                    child: Column(
                      children: [
                        _buildPriceRow(context, 'Subtotal', widget.totalAmount, false),
                        SizedBox(height: DesignSystem.spacing.sm),
                        _buildPriceRow(context, 'Delivery Charge', _deliveryCharge, false),
                        if (_discountAmount > 0) ...[
                          SizedBox(height: DesignSystem.spacing.sm),
                          _buildPriceRow(context, 'Coupon Discount', -_discountAmount, false, isDiscount: true),
                        ],
                        if (_walletDiscountAmount > 0) ...[
                          SizedBox(height: DesignSystem.spacing.sm),
                          _buildPriceRow(context, 'Wallet Deduction', -_walletDiscountAmount, false, isWallet: true),
                        ],
                        Divider(height: DesignSystem.spacing.lg * 2, thickness: 1.5),
                        _buildPriceRow(context, 'Total Payable', _finalAmount, true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, double amount, bool isTotal, {bool isDiscount = false, bool isWallet = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: isTotal ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          '${amount < 0 ? '-' : ''}₹${amount.abs().toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            fontSize: isTotal ? 18 : 14,
            color: isTotal 
                ? Theme.of(context).colorScheme.primary 
                : isDiscount 
                    ? TColors.success 
                    : isWallet 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildModernProceedButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.spacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: AnimatedContainer(
          duration: DesignSystem.animations.fast,
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessingPayment ? null : _proceedToPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: DesignSystem.borders.lg,
              ),
              shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
            ),
            child: _isProcessingPayment
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
                        'Processing...',
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
                        _canPayFullyWithWallet ? Iconsax.wallet_check : Iconsax.arrow_right_3,
                        size: 22,
                      ),
                      SizedBox(width: DesignSystem.spacing.sm),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _canPayFullyWithWallet ? 'Pay with Wallet' : 'Continue to Payment',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '₹${_finalAmount.toStringAsFixed(2)}',
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
        ),
      ),
    );
  }

  void _showAddressSelectionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      'Select Delivery Address',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Iconsax.close_circle),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
              // Address list
              Expanded(
                child: FutureBuilder<UserModel?>(
                  future: UserService().getCurrentUser(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final user = snapshot.data;
                    final addresses = user?.addresses ?? [];

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: addresses.length + 1, // +1 for "Add New" button
                      itemBuilder: (context, index) {
                        if (index == addresses.length) {
                          // Add new address button
                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                // Navigate to address form and wait for result
                                await Get.to(() => const AddressFormPage());
                                // Refresh the delivery address section after returning
                                setState(() {});
                              },
                              icon: const Icon(Iconsax.add_circle),
                              label: const Text('Add New Address'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          );
                        }

                        final address = addresses[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            elevation: 2,
                            child: InkWell(
                              onTap: () async {
                                await _selectAddress(address);
                                Navigator.of(context).pop();
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            address.label,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (address.isDefault)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                            ),
                                            child: Text(
                                              'Default',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${address.line1}${address.line2.isNotEmpty ? ', ${address.line2}' : ''}',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${address.city}, ${address.state} - ${address.pincode}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectAddress(UserAddress address) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.snackbar(
          'Error',
          'User not authenticated',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final userService = UserService();
      await userService.setDefaultAddress(user.uid, address.addressId);
      
      // Update the current delivery address
      setState(() {
        _currentDeliveryAddress = address;
      });
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update address: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
