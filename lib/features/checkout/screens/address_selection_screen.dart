import 'package:flutter/material.dart';
import 'package:rps_stationery/data/models/user_model.dart';
import 'package:rps_stationery/data/models/cart_model.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/features/checkout/controllers/address_selection_controller.dart';
import 'package:rps_stationery/features/personalization/screens/address/address_form_page.dart';
import 'package:rps_stationery/features/cart/controllers/cart_controller.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/utils/constants/sizes.dart';
import 'package:rps_stationery/services/app_settings_service.dart';
import 'package:rps_stationery/utils/theme/component_styles.dart';

class AddressSelectionScreen extends StatelessWidget {
  const AddressSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Get.put with permanent: true to ensure controller persists
    print('🔍 AddressSelectionScreen: build() called, route: ' + Get.currentRoute);
    final args = Get.arguments;
    print('🔍 AddressSelectionScreen: Received arguments: ' + (args?.toString() ?? 'null'));
    final controller = Get.put(AddressSelectionController(), permanent: true);
    print('🔍 AddressSelectionScreen: Controller initialized');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Select Delivery Address',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Choose delivery address',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Add New Address Button
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  print('🔍 AddressSelectionScreen: Add New Address tapped');
                  _addNewAddress(controller);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(TSizes.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(TSizes.sm),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Iconsax.add,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: TSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Address',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Add a new delivery address',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Saved Addresses
            Obx(() {
              print('🔍 AddressSelectionScreen: Obx -> isLoading=' + controller.isLoading.value.toString() + ', addresses=' + controller.addresses.length.toString());
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (controller.addresses.isEmpty) {
                return _buildEmptyState(context);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saved Addresses',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: TSizes.sm),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.addresses.length,
                    itemBuilder: (context, index) {
                      final address = controller.addresses[index];
                      print('🔍 AddressSelectionScreen: Rendering address #'+index.toString()+': '+address.id+' label='+address.addressLabel);
                      return _buildAddressCard(context, controller, address);
                    },
                  ),
                ],
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: Obx(() {
        print('🔍 AddressSelectionScreen: Bottom bar rebuild, selectedAddress=' + (controller.selectedAddress.value?.id ?? 'null'));
        if (controller.selectedAddress.value != null) {
          return Container(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: ElevatedButton(
              onPressed: () {
                print('🔍 AddressSelectionScreen: Proceed to Payment tapped');
                _proceedToPayment(controller);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: TSizes.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Proceed to Payment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }

  Widget _buildAddressCard(BuildContext context, AddressSelectionController controller, UserAddress address) {
    return Obx(() {
      final isSelected = controller.selectedAddress.value?.id == address.id;
      if (isSelected) {
        print('🔍 AddressSelectionScreen: Address selected -> '+address.id+' ('+address.addressLabel+')');
      }
      
      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: TSizes.sm),
        child: InkWell(
          onTap: () {
            print('🔍 AddressSelectionScreen: Address tapped -> '+address.id);
            controller.selectAddress(address);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(TSizes.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                width: 2,
              ),
              color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05) : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address Type Icon
                Container(
                  padding: const EdgeInsets.all(TSizes.sm),
                  decoration: BoxDecoration(
                    color: _getAddressTypeColor(address.addressType ?? AddressType.independentHouse).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getAddressTypeIcon(address.addressType ?? AddressType.independentHouse),
                    color: _getAddressTypeColor(address.addressType ?? AddressType.independentHouse),
                    size: 20,
                  ),
                ),
                const SizedBox(width: TSizes.md),
                
                // Address Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            address.addressLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: TSizes.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SELECTED',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address.recepientDetails ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${address.line1}, ${address.line2}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (address.city.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${address.city}, ${address.state} - ${address.pincode}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (address.phoneNumber?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Phone: ${address.phoneNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Selection Radio
                Radio<String>(
                  value: address.id,
                  groupValue: controller.selectedAddress.value?.id ?? '',
                  onChanged: (value) => controller.selectAddress(address),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(TSizes.lg),
        child: Column(
          children: [
            Icon(
              Iconsax.location,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: TSizes.md),
            const Text(
              'No saved addresses',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TSizes.sm),
            Text(
              'Add your first delivery address to continue',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAddressTypeIcon(AddressType type) {
    switch (type) {
      case AddressType.independentHouse:
        return Iconsax.home_1;
      case AddressType.apartment:
        return Iconsax.home;
      case AddressType.office:
        return Iconsax.building;
    }
  }

  Color _getAddressTypeColor(AddressType type) {
    switch (type) {
      case AddressType.independentHouse:
        return Colors.green;
      case AddressType.apartment:
        return Colors.blue;
      case AddressType.office:
        return Colors.orange;
    }
  }

  void _addNewAddress(AddressSelectionController controller) {
    print('🔍 AddressSelectionScreen: Navigating to AddressFormPage');
    Get.to(() => const AddressFormPage())?.then((result) {
      print('🔍 AddressSelectionScreen: Returned from AddressFormPage with result=' + (result?.toString() ?? 'null'));
      // The address form will handle adding the address through the AddressController
      // We just need to refresh the addresses in our selection controller
      print('🔍 AddressSelectionScreen: Refreshing addresses');
      controller.refreshAddresses();
    });
  }

  void _proceedToPayment(AddressSelectionController controller) {
    if (controller.selectedAddress.value != null) {
      try {
        // Check if this is a Buy Now flow
        final arguments = Get.arguments;
        final isBuyNow = arguments != null && arguments is Map && arguments['isBuyNow'] == true;
        print('🔍 AddressSelectionScreen: Proceed flow -> isBuyNow=' + isBuyNow.toString());
        
        // Simplified flow - no payment processing needed
        print('🔍 AddressSelectionScreen: Proceeding with simplified order flow');
        
        double amount = 0.0;
        
        if (isBuyNow) {
          // For Buy Now flow, calculate subtotal (without delivery) from product data
          final product = arguments['product'];
          final quantity = arguments['quantity'] ?? 1;
          final itemPrice = product.price;
          amount = itemPrice * quantity; // Pass subtotal only, delivery will be calculated in price summary
          print('🔍 AddressSelectionScreen: Calculated buy now subtotal=' + amount.toString());
        } else {
          // For regular cart flow, get cart total (without delivery)
          try {
            final cartController = CartController.instance;
            amount = cartController.total.value; // Use cart total (which is subtotal without delivery) to avoid double delivery charges
            print('🔍 AddressSelectionScreen: Using cart total (subtotal)=' + amount.toString());
          } catch (e) {
            TLoaders.errorSnackBar(
              title: 'Error',
              message: 'Unable to get cart total. Please try again.',
            );
            print('🔍 AddressSelectionScreen: Error getting cart total -> ' + e.toString());
            return;
          }
        }
        
        // Validate amount
        if (amount <= 0) {
          TLoaders.errorSnackBar(
            title: isBuyNow ? 'Invalid Product' : 'Empty Cart',
            message: isBuyNow 
                ? 'Invalid product information. Please try again.'
                : 'Please add items to your cart before proceeding to payment.',
          );
          print('🔍 AddressSelectionScreen: Validation failed, amount <= 0');
          return;
        }
        
        // Prepare cart items for payment
        List<CartItem> cartItems = [];
        
        if (isBuyNow) {
          // For Buy Now flow, create a single item
          final product = arguments['product'];
          final quantity = arguments['quantity'] ?? 1;
          final selectedColor = arguments['selectedColor'] as String?;
          print('🔍 AddressSelectionScreen: Buy Now item - selectedColor=$selectedColor');
          cartItems = [CartItem(
            productId: product.productId,
            quantity: quantity,
            addedAt: DateTime.now(),
            selectedColor: selectedColor,
          )];
        } else {
          // For regular cart flow, get cart items
          try {
            final cartController = CartController.instance;
            cartItems = cartController.cartItems;
          } catch (e) {
            TLoaders.errorSnackBar(
              title: 'Error',
              message: 'Unable to get cart items. Please try again.',
            );
            return;
          }
        }
        
        // Navigate to price summary screen (first step in new flow)
        print('🔍 AddressSelectionScreen: Navigating to price summary');
        final selectedAddress = controller.selectedAddress.value;
        if (selectedAddress != null) {
          Get.toNamed(Routes.priceSummary, arguments: {
            'cartItems': cartItems,
            'deliveryAddress': selectedAddress,
            'totalAmount': amount,
            'promoCode': null,
            'isBuyNow': isBuyNow,
            'buyNowData': isBuyNow ? arguments : null,
          });
        }
        
      } catch (e) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Failed to proceed: ${e.toString()}',
        );
        print('🔍 AddressSelectionScreen: Proceed error -> ' + e.toString());
      }
    }
  }
}
