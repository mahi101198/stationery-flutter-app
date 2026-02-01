import 'package:flutter/material.dart';
import '../../../../data/models/user_model.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/features/personalization/screens/address/address_controller.dart';
import 'package:rps_stationery/features/personalization/screens/address/address_form_page.dart';
import 'package:rps_stationery/data/models/user_model.dart' as user_schema;

const double defaultPadding = 16.0;

class AddressListPage extends StatelessWidget {
  AddressListPage({super.key});

  final AddressController controller = Get.put(AddressController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
            centerTitle: true,
            title: const Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Text(
                "Addresses",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16161E),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Iconsax.arrow_left, color: Color(0xFF16161E)),
              onPressed: () => Get.back(),
            ),
          ),
          SliverToBoxAdapter(child: _buildAddAddressButton(context)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(defaultPadding, defaultPadding / 2, defaultPadding, defaultPadding / 2),
              child: Text(
                "Saved Addresses",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF16161E),
                ),
              ),
            ),
          ),
          _buildAddressList(context),
        ],
      ),
    );
  }

  Widget _buildAddAddressButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(defaultPadding),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Get.to(() => const AddressFormPage()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE8E8E9),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Iconsax.add,
                    color: Color(0xFF5A7C8A),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Add New Address',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF16161E),
                    ),
                  ),
                ),
                const Icon(
                  Iconsax.arrow_right_3,
                  color: Color(0xFF737378),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (controller.addresses.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 50),
            child: Center(
              child: Text(
                'No saved addresses yet.',
                style: TextStyle(
                  fontSize: 15,
                  color: const Color(0xFF737378),
                ),
              ),
            ),
          ),
        );
      }
      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final address = controller.addresses[index];
          return _AddressCard(address: address);
        }, childCount: controller.addresses.length),
      );
    });
  }
}

class _AddressCard extends StatelessWidget {
  final user_schema.UserAddress address;
  const _AddressCard({required this.address});

  IconData _getIconForAddress() {
    return Iconsax.home_2;
  }

  IconData _getIconForAddressType(AddressType? type) {
    switch (type) {
      case AddressType.independentHouse:
        return Iconsax.home_2;
      case AddressType.apartment:
        return Iconsax.building_4;
      case AddressType.office:
        return Iconsax.building;
      default:
        return Iconsax.home_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AddressController>();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              address.isDefault
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                  : Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showAddressActions(context, controller),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconForAddress(),
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              address.label,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (address.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'DEFAULT',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        address.formattedAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address.recepientDetails ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.more_vert,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddressActions(BuildContext context, AddressController controller) {
    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
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
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Address info
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getIconForAddressType(address.addressType),
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                address.addressLabel,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                address.recepientDetails ?? '',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 24),

                  // Action buttons
                  _ActionTile(
                    icon: Iconsax.edit,
                    title: 'Edit Address',
                    onTap: () {
                      Navigator.pop(context);
                      Get.to(() => AddressFormPage(addressToEdit: address));
                    },
                  ),

                  if (!address.isDefault)
                    _ActionTile(
                      icon: Iconsax.star,
                      title: 'Set as Default',
                      onTap: () {
                        Navigator.pop(context);
                        controller.setDefaultAddress(address.id);
                      },
                    ),

                  _ActionTile(
                    icon: Iconsax.trash,
                    title: 'Delete Address',
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(context, controller);
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    AddressController controller,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Address'),
            content: Text(
              'Are you sure you want to delete "${address.addressLabel}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  controller.deleteAddress(address.id);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color =
        isDestructive
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
