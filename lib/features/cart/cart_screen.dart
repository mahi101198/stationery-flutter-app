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
import 'package:rps_stationery/utils/theme/component_styles.dart';

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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    color: Theme.of(context).scaffoldBackgroundColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignSystem.spacing.lg,
                      vertical: DesignSystem.spacing.md,
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Minimal checkout button - matching reference color
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: Material(
                              color: Color(0xFF6B8FA3), // Muted blue-gray from reference
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: () => _navigateToAddressSelection(controller),
                                borderRadius: BorderRadius.circular(14),
                                child: Center(
                                  child: Text(
                                    'Proceed to checkout',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
                      // Simple Header - White minimal
                      SliverAppBar(
                        pinned: true,
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        elevation: 0,
                        leading: IconButton(
                          icon: Icon(Iconsax.arrow_left, color: Theme.of(context).colorScheme.onSurface),
                          onPressed: () => Get.back(),
                        ),
                        expandedHeight: 140,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                            padding: EdgeInsets.fromLTRB(
                              DesignSystem.spacing.lg,
                              MediaQuery.of(context).padding.top + 40,
                              DesignSystem.spacing.lg,
                              DesignSystem.spacing.md,
                            ),
                            color: Theme.of(context).scaffoldBackgroundColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "My Cart",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${controller.cartItems.length} ${controller.cartItems.length == 1 ? 'item' : 'items'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Delivery Address Section
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            DesignSystem.spacing.lg,
                            DesignSystem.spacing.md,
                            DesignSystem.spacing.lg,
                            0,
                          ),
                          child: _buildDeliveryAddressSection(context),
                        ),
                      ),

                      // Dynamic spacing based on whether address exists
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: _currentUser?.addresses.isEmpty == true ? 0 : DesignSystem.spacing.lg,
                        ),
                      ),

                      // Cart items with minimal design
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: DesignSystem.spacing.lg),
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
                                      bottom: isLast ? 0 : DesignSystem.spacing.md,
                                    ),
                                    child: const ModernOrderItemSkeleton(),
                                  ),
                                );
                              }
                              
                              return MicroAnimations.staggeredListItem(
                                index: index,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    bottom: isLast ? 0 : DesignSystem.spacing.md,
                                  ),
                                  child: CartProduct(
                                    key: ValueKey(cartItem.productId), // Use SKU ID as key
                                    product: product,
                                    skuId: cartItem.productId, // Pass SKU ID
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

                      SliverToBoxAdapter(child: SizedBox(height: DesignSystem.spacing.lg)),
                          
                      // Price summary
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: DesignSystem.spacing.lg),
                          child: _buildSimpleOrderSummary(context, controller),
                        ),
                      ),

                      // Add More Items Button - minimal style
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: DesignSystem.spacing.lg,
                            vertical: DesignSystem.spacing.lg,
                          ),
                          child: Center(
                            child: TextButton(
                              onPressed: () {
                                try {
                                  Get.offAndToNamed(Routes.bottomNav, arguments: 'home');
                                } catch (e) {
                                  Get.back();
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: DesignSystem.spacing.lg,
                                  vertical: DesignSystem.spacing.md,
                                ),
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: Color(0xFFD0D0D2),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Add more items',
                                style: TextStyle(
                                  color: Color(0xFF737378),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                          
                      // Bottom spacing for floating button
                      SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  )
                : Center(
                    child: Padding(
                      padding: EdgeInsets.all(DesignSystem.spacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Empty state icon - minimal
                          Icon(
                            Iconsax.shopping_cart,
                            size: 64,
                            color: Color(0xFFD0D0D2),
                          ),
                          SizedBox(height: DesignSystem.spacing.lg),
                          
                          Text(
                            'Your cart is empty',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF16161E),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: DesignSystem.spacing.md),
                          
                          Text(
                            'Add items to your cart to get started.',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF737378),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: DesignSystem.spacing.xl),
                          
                          // Simple CTA
                          SizedBox(
                            width: 240,
                            height: 56,
                            child: Material(
                              color: Color(0xFF6B8FA3), // Muted blue-gray from reference
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: () {
                                  try {
                                    Get.offAndToNamed(Routes.bottomNav, arguments: 'home');
                                  } catch (e) {
                                    Get.back();
                                  }
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Center(
                                  child: Text(
                                    'Add more items',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(DesignSystem.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Price Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          
          SizedBox(height: DesignSystem.spacing.lg),
          
          // Subtotal
          _buildSummaryRow(
            context,
            'Subtotal (${controller.cartItems.length} ${controller.cartItems.length == 1 ? 'item' : 'items'})',
            '₹${controller.total.value.toStringAsFixed(0)}',
          ),
          
          SizedBox(height: DesignSystem.spacing.md),
          
          // Divider - thin
          Divider(
            color: theme.colorScheme.outline,
            thickness: 1,
            height: 0,
          ),
          
          SizedBox(height: DesignSystem.spacing.md),
          
          // Delivery Fee
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (deliveryCharge == 0)
                Text(
                  'FREE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.primary,
                  ),
                )
              else
                Text(
                  '₹${deliveryCharge.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
            ],
          ),
          
          SizedBox(height: DesignSystem.spacing.md),
          
          // Divider - thin
          Divider(
            color: theme.colorScheme.outline,
            thickness: 1,
            height: 0,
          ),
          
          SizedBox(height: DesignSystem.spacing.md),
          
          // Total - slightly emphasized with gradient price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) =>
                    ComponentStyles.getPriceGradient(isDark).createShader(bounds),
                child: Text(
                  '₹${finalTotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryAddressSection(BuildContext context) {
    if (_currentUser == null) {
      return Container(
        height: 80,
        margin: EdgeInsets.only(bottom: DesignSystem.spacing.md),
        child: const ModernSkeleton(height: 80, width: double.infinity),
      );
    }

    // Hide address card if user has no saved addresses
    if (_currentUser!.addresses.isEmpty) {
      return const SizedBox.shrink();
    }

    final defaultAddress = _currentUser!.addresses.where((addr) => addr.isDefault).firstOrNull;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(DesignSystem.spacing.md),
      child: Row(
        children: [
          // Location icon
          Icon(
            Iconsax.location5,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          SizedBox(width: DesignSystem.spacing.md),
          
          // Address info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Deliver to',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 4),
                if (defaultAddress != null) ...[
                  Text(
                    '${defaultAddress.label}, ${defaultAddress.pincode}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  Text(
                    'No address selected',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          SizedBox(width: DesignSystem.spacing.md),
          
          // Change button
          TextButton(
            onPressed: () => _showAddressSelectionBottomSheet(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: DesignSystem.spacing.md,
                vertical: DesignSystem.spacing.sm,
              ),
            ),
            child: Text(
              'Change',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
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
