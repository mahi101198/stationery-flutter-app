import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/components/ui/modern_ui.dart';
import 'package:rps_stationery/components/ui/theme_aware_components.dart';
import 'package:rps_stationery/features/cart/controllers/cart_controller.dart';
import 'package:rps_stationery/utils/animations/micro_animations.dart';
import 'package:rps_stationery/features/cart/widgets/cart_product.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/utils/theme/design_system.dart';
import 'package:rps_stationery/services/app_settings_service.dart';
import 'package:rps_stationery/data/models/user_model.dart';
import 'package:rps_stationery/data/services/user_service.dart';
import 'package:rps_stationery/features/personalization/screens/address/address_form_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with WidgetsBindingObserver {

  CartController? _controller;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      _controller?.refreshCartSilently();
    }
  }

  void _initializeController() {
    try {
      _controller = Get.find<CartController>();
    } catch (_) {
      _controller = Get.put(CartController());
    }
    // Refresh cart when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller?.refreshCartSilently();
      _loadCurrentUser();
    });
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await UserService().getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  // Calculate total including delivery charges (tax already included in product prices)
  double _calculateTotal(double orderTotal) {
    final appSettings = AppSettingsService.instance;
    final deliveryCharge = appSettings.calculateDeliveryCharge(orderTotal);
    return orderTotal + deliveryCharge;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;

    return Obx(
      () => Scaffold(
        bottomNavigationBar: controller.isLoading.value
            ? Container(
                padding: EdgeInsets.all(DesignSystem.spacing.lg),
                child: ModernSkeleton(
                  width: double.infinity,
                  height: 52,
                  borderRadius: DesignSystem.borders.lg,
                ),
              )
            : controller.cartItems.isNotEmpty
                ? Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: ThemeAwareCard(
                      elevation: 12,
                      borderRadius: 24,
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Enhanced total summary
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Amount',
                                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${_calculateTotal(controller.total.value).toStringAsFixed(0)}',
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  flex: 1,
                                  child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Iconsax.shopping_bag,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.onPrimary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${controller.cartItems.length} items',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Enhanced checkout button
                          ThemeAwareButton(
                            text: 'Proceed to Payment',
                            icon: Iconsax.card,
                            variant: ButtonVariant.primary,
                            size: ButtonSize.medium,
                            fullWidth: true,
                            onPressed: () => _navigateToAddressSelection(controller),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                )
                : null,
        body: controller.isLoading.value
            ? ListView.builder(
                padding: EdgeInsets.all(DesignSystem.spacing.lg),
                itemCount: 4,
                itemBuilder: (context, index) => const ModernOrderItemSkeleton(),
              )
            : controller.cartItems.isNotEmpty
                ? CustomScrollView(
                    slivers: [
                      // Modern Header
                      SliverAppBar(
                        pinned: false,
                        floating: true,
                        snap: true,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        elevation: 0,
                        automaticallyImplyLeading: false,
                        expandedHeight: 100,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                            padding: EdgeInsets.fromLTRB(
                              20,
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "My Cart",
                                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Iconsax.shopping_bag,
                                                size: 14,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${controller.cartItems.length} ${controller.cartItems.length == 1 ? 'item' : 'items'}',
                                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Delivery Address Section
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: _buildDeliveryAddressSection(context),
                        ),
                      ),

                      // Dynamic spacing based on whether address exists
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: _currentUser?.addresses.isEmpty == true ? 0 : 20,
                        ),
                      ),

                      // Cart items
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final cartItem = controller.cartItems[index];
                              final product = controller.getProductForCartItem(cartItem.productId);
                              final isLast = index == controller.cartItems.length - 1;
                              
                              // Show loading state for items without product details
                              if (product == null) {
                                return MicroAnimations.staggeredListItem(
                                  index: index,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      bottom: isLast ? 0 : 12,
                                    ),
                                    child: const ModernOrderItemSkeleton(),
                                  ),
                                );
                              }
                              
                              return MicroAnimations.staggeredListItem(
                                index: index,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    bottom: isLast ? 0 : 12,
                                  ),
                                  child: CartProduct(
                                    key: ValueKey(product.id),
                                    product: product,
                                    quantity: cartItem.quantity,
                                    isLastInList: isLast,
                                    selectedColor: cartItem.selectedColor,
                                  ),
                                ),
                              );
                            },
                            childCount: controller.cartItems.length,
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                          
                      // Simple Order Summary (without delivery details)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildSimpleOrderSummary(context, controller),
                        ),
                      ),

                      // Add More Items Button
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: () {
                                try {
                                  Get.offAndToNamed(Routes.bottomNav, arguments: 'home');
                                } catch (e) {
                                  Get.back();
                                }
                              },
                              icon: Icon(
                                Iconsax.add_circle,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              label: Text(
                                'Add More Items',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                          
                      // Bottom spacing for floating button
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Enhanced empty state illustration
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Iconsax.shopping_cart,
                              size: 80,
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Your cart is empty',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Looks like you haven\'t added any stationery items yet.\nStart exploring our amazing collection!',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          
                          // Single action button
                          SizedBox(
                            width: double.infinity,
                            child: ThemeAwareButton(
                              text: 'Start Shopping',
                              icon: Iconsax.bag_2,
                              variant: ButtonVariant.primary,
                              size: ButtonSize.large,
                              fullWidth: true,
                              onPressed: () {
                                // Navigate to home tab
                                try {
                                  Get.offAndToNamed(Routes.bottomNav, arguments: 'home');
                                } catch (e) {
                                  // Fallback to simple back navigation
                                  Get.back();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  void _navigateToAddressSelection(CartController controller) {
    if (controller.cartItems.isEmpty) {
      Get.snackbar(
        'Empty Cart',
        'Please add items to your cart before proceeding.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Check if user has a default address selected
    if (_currentUser?.addresses.any((addr) => addr.isDefault) == true) {
      // User already has address selected in cart, go directly to payment summary
      final defaultAddress = _currentUser!.addresses.firstWhere((addr) => addr.isDefault);
      
      // Pass only the subtotal (controller.total.value) - delivery charges will be calculated in price summary
      Get.toNamed(Routes.priceSummary, arguments: {
        'cartItems': controller.cartItems,
        'deliveryAddress': defaultAddress,
        'totalAmount': controller.total.value, // Pass subtotal only, not total with delivery
        'promoCode': null,
        'isBuyNow': false,
        'buyNowData': null,
      });
    } else {
      // No address selected, show address selection screen
      Get.toNamed(Routes.addressSelection);
    }
  }

  Widget _buildSimpleOrderSummary(BuildContext context, CartController controller) {
    final appSettings = AppSettingsService.instance;
    final deliveryCharge = appSettings.calculateDeliveryCharge(controller.total.value);
    final finalTotal = controller.total.value + deliveryCharge;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
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
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Order Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Items count and subtotal
              _buildSummaryRow(
                context,
                'Subtotal (${controller.cartItems.length} ${controller.cartItems.length == 1 ? 'item' : 'items'})',
                '₹${controller.total.value.toStringAsFixed(0)}',
                false,
              ),
              
              const SizedBox(height: 12),
              
              // Delivery Fee with badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Delivery Fee',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (deliveryCharge == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'FREE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    )
                  else
                    Text(
                      '₹${deliveryCharge.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              
              // Final total with gradient background
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${finalTotal.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Iconsax.arrow_right_3,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryAddressSection(BuildContext context) {
    if (_currentUser == null) {
      return Container(
        height: 80,
        margin: const EdgeInsets.only(bottom: 16),
        child: const ModernSkeleton(height: 80, width: double.infinity),
      );
    }

    // Hide address card if user has no saved addresses
    if (_currentUser!.addresses.isEmpty) {
      return const SizedBox.shrink();
    }

    final defaultAddress = _currentUser!.addresses.where((addr) => addr.isDefault).firstOrNull;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Location icon with gradient background
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                          Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Iconsax.location5,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Deliver to text with address
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deliver to',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (defaultAddress != null) ...[
                          Text(
                            '${defaultAddress.label}, ${defaultAddress.pincode}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${defaultAddress.line1}${defaultAddress.line2.isNotEmpty ? ', ${defaultAddress.line2}' : ''}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ] else ...[
                          Text(
                            'No address selected',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Change button with modern design
                  InkWell(
                    onTap: () => _showAddressSelectionBottomSheet(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Change',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
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
                            child: ThemeAwareButton(
                              text: 'Add New Address',
                              icon: Iconsax.add_circle,
                              variant: ButtonVariant.secondary,
                              fullWidth: true,
                              onPressed: () async {
                                Navigator.of(context).pop();
                                // Navigate to address form and wait for result
                                await Get.to(() => const AddressFormPage());
                                // Refresh the delivery address section after returning
                                await _loadCurrentUser();
                              },
                            ),
                          );
                        }

                        final address = addresses[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ThemeAwareCard(
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
      
      // Force UI refresh by reloading user data and calling setState
      await _loadCurrentUser();
      
      // Show success notification
      Get.snackbar(
        'Success',
        'Address updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
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
