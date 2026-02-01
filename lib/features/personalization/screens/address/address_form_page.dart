import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/user_model.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rps_stationery/features/personalization/screens/address/address_controller.dart';
import 'package:rps_stationery/data/models/user_model.dart' as user_schema;
import 'package:rps_stationery/utils/theme/design_system.dart';
import 'package:rps_stationery/services/app_settings_service.dart';
import 'package:rps_stationery/utils/constants/colors.dart';

class AddressFormPage extends StatefulWidget {
  final user_schema.UserAddress? addressToEdit;
  const AddressFormPage({super.key, this.addressToEdit});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  late final AddressController controller;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _line1Ctrl;
  late TextEditingController _line2Ctrl;
  late TextEditingController _pincodeCtrl;
  late TextEditingController _pincodeSearchCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _landmarkCtrl;
  final _isDefault = false.obs;
  AddressType _selectedType = AddressType.independentHouse;
  
  // Fixed values
  final String _state = 'Rajasthan';
  final String _city = 'Jaipur';
  
  // Pincode search state
  final RxList<String> _filteredPincodes = <String>[].obs;
  final RxBool _showPincodeSuggestions = false.obs;
  late final FocusNode _pincodeFocusNode;

  @override
  void initState() {
    super.initState();
    
    _initializeController();
    
    final a = widget.addressToEdit;
    _line1Ctrl = TextEditingController(text: a?.line1);
    _line2Ctrl = TextEditingController(text: a?.line2);
    _pincodeCtrl = TextEditingController(text: a?.pincode);
    _pincodeSearchCtrl = TextEditingController(text: a?.pincode);
    _nameCtrl = TextEditingController(text: a?.recepientDetails);
    _mobileCtrl = TextEditingController(text: a?.mobileNumber);
    _landmarkCtrl = TextEditingController(text: a?.landmark);
    _isDefault.value = a?.isDefault ?? false;
    _selectedType = a?.addressType ?? AddressType.independentHouse;
    _pincodeFocusNode = FocusNode();
    _pincodeFocusNode.addListener(_onPincodeFocusChange);
    
    _pincodeSearchCtrl.addListener(_onPincodeSearchChanged);
    _filterPincodes('');
  }

  void _initializeController() {
    try {
      if (Get.isRegistered<AddressController>()) {
        controller = Get.find<AddressController>();
      } else {
        controller = Get.put(AddressController(), permanent: true);
      }
    } catch (e) {
      controller = Get.put(AddressController(), permanent: true);
    }
  }

  @override
  void dispose() {
    _line1Ctrl.dispose();
    _line2Ctrl.dispose();
    _pincodeCtrl.dispose();
    _pincodeSearchCtrl.removeListener(_onPincodeSearchChanged);
    _pincodeSearchCtrl.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _landmarkCtrl.dispose();
    _pincodeFocusNode.removeListener(_onPincodeFocusChange);
    _pincodeFocusNode.dispose();
    super.dispose();
  }
  
  void _handlePincodeSelection(String pincode) {
    _showPincodeSuggestions.value = false;
    _pincodeSearchCtrl.removeListener(_onPincodeSearchChanged);
    _pincodeCtrl.text = pincode;
    _pincodeSearchCtrl.text = pincode;
    
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _pincodeSearchCtrl.addListener(_onPincodeSearchChanged);
      }
    });
    
    FocusScope.of(context).unfocus();
  }
  
  void _filterPincodes(String query) {
    try {
      final appSettings = AppSettingsService.instance;
      final availablePincodes = appSettings.availablePincodes;
      
      if (availablePincodes.isEmpty) {
        _filteredPincodes.value = [];
        return;
      }
      
      if (query.isEmpty) {
        _filteredPincodes.value = availablePincodes;
      } else {
        final filtered = availablePincodes
            .where((pincode) => pincode.startsWith(query))
            .toList();
        _filteredPincodes.value = filtered;
      }
    } catch (e) {
      _filteredPincodes.value = [];
    }
  }

  void _onPincodeFocusChange() {
    if (!_pincodeFocusNode.hasFocus) {
      _showPincodeSuggestions.value = false;
    }
  }
  
  void _onPincodeSearchChanged() {
    final query = _pincodeSearchCtrl.text;
    _filterPincodes(query);
    
    if (query.isNotEmpty && _filteredPincodes.isNotEmpty) {
      _showPincodeSuggestions.value = true;
    } else {
      _showPincodeSuggestions.value = false;
    }
    
    if (query.length == 6) {
      _pincodeCtrl.text = query;
    }
    
    if (mounted) {
      setState(() {});
    }
  }
  
  final RxBool _isSaving = false.obs;

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    try {
      _isSaving.value = true;
      
      if (_line1Ctrl.text.trim().isEmpty) {
        Get.snackbar('Error', 'Address is required');
        return;
      }
      
      final appSettings = AppSettingsService.instance;
      final availablePincodes = appSettings.availablePincodes;
      final enteredPincode = _pincodeCtrl.text.trim();
      
      if (enteredPincode.isEmpty) {
        Get.snackbar('Error', 'Pincode is required');
        return;
      }
      
      if (availablePincodes.isNotEmpty && !availablePincodes.contains(enteredPincode)) {
        Get.snackbar('Error', 'This pincode is not available for delivery');
        return;
      }
      
      String label = '';
      switch (_selectedType) {
        case AddressType.independentHouse:
          label = 'Home';
          break;
        case AddressType.apartment:
          label = 'Apartment';
          break;
        case AddressType.office:
          label = 'Office';
          break;
      }
      
      final address = user_schema.UserAddress(
        addressId: widget.addressToEdit?.addressId ?? '',
        label: label,
        line1: _line1Ctrl.text.trim(),
        line2: _line2Ctrl.text.trim(),
        city: _city,
        state: _state,
        pincode: _pincodeCtrl.text.trim(),
        country: 'India',
        isDefault: _isDefault.value,
        addressType: _selectedType,
        recepientDetails: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        mobileNumber: _mobileCtrl.text.trim().isEmpty ? null : _mobileCtrl.text.trim(),
        landmark: _landmarkCtrl.text.trim().isEmpty ? null : _landmarkCtrl.text.trim(),
      );

      if (widget.addressToEdit != null) {
        await controller.updateAddress(widget.addressToEdit!.addressId, address);
        if (_isDefault.value && !widget.addressToEdit!.isDefault) {
          await controller.setDefaultAddress(widget.addressToEdit!.addressId);
        }
      } else {
        await controller.addAddress(address, _isDefault.value);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save address: ${e.toString()}');
    } finally {
      _isSaving.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          widget.addressToEdit == null ? 'Add Address' : 'Edit Address',
          style: DesignSystem.typography.headlineMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(DesignSystem.spacing.md),
          children: [
            // Address Type Selector
            _buildAddressTypeSelector(context, isDark),
            
            SizedBox(height: DesignSystem.spacing.lg),
            
            // Address Details
            _buildTextField(
              context: context,
              controller: _line1Ctrl,
              label: 'House/Flat/Block No.',
              hint: 'e.g., Plot 123, Flat 4B',
              icon: Iconsax.building_4,
              isRequired: true,
            ),
            
            SizedBox(height: DesignSystem.spacing.md),
            
            _buildTextField(
              context: context,
              controller: _line2Ctrl,
              label: 'Area/Street/Sector',
              hint: 'e.g., Sector 21, Main Street',
              icon: Iconsax.location,
              isRequired: false,
            ),
            
            SizedBox(height: DesignSystem.spacing.md),
            
            _buildTextField(
              context: context,
              controller: _landmarkCtrl,
              label: 'Landmark (Optional)',
              hint: 'e.g., Near City Mall',
              icon: Iconsax.signpost,
              isRequired: false,
            ),
            
            SizedBox(height: DesignSystem.spacing.md),
            
            // Pincode with suggestions
            _buildPincodeField(context, isDark),
            
            SizedBox(height: DesignSystem.spacing.md),
            
            // City and State (read-only)
            Row(
              children: [
                Expanded(
                  child: _buildReadOnlyField(
                    context: context,
                    label: 'City',
                    value: _city,
                    icon: Iconsax.building,
                  ),
                ),
                SizedBox(width: DesignSystem.spacing.md),
                Expanded(
                  child: _buildReadOnlyField(
                    context: context,
                    label: 'State',
                    value: _state,
                    icon: Iconsax.map_1,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: DesignSystem.spacing.lg),
            
            // Contact Details
            _buildTextField(
              context: context,
              controller: _nameCtrl,
              label: 'Recipient Name',
              hint: 'Full name',
              icon: Iconsax.user,
              isRequired: true,
            ),
            
            SizedBox(height: DesignSystem.spacing.md),
            
            _buildTextField(
              context: context,
              controller: _mobileCtrl,
              label: 'Mobile Number',
              hint: '10-digit mobile number',
              icon: Iconsax.mobile,
              keyboardType: TextInputType.phone,
              isRequired: true,
            ),
            
            SizedBox(height: DesignSystem.spacing.lg),
            
            // Default Address Toggle
            if (widget.addressToEdit?.isDefault != true)
              _buildDefaultToggle(context),
            
            SizedBox(height: DesignSystem.spacing.xxl),
          ],
        ),
      ),
      bottomNavigationBar: _buildSaveButton(context),
    );
  }

  Widget _buildAddressTypeSelector(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Address Type',
          style: DesignSystem.typography.titleMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignSystem.spacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildTypeChip(
                context,
                AddressType.independentHouse,
                'Home',
                Iconsax.home_2,
              ),
            ),
            SizedBox(width: DesignSystem.spacing.sm),
            Expanded(
              child: _buildTypeChip(
                context,
                AddressType.apartment,
                'Apartment',
                Iconsax.building,
              ),
            ),
            SizedBox(width: DesignSystem.spacing.sm),
            Expanded(
              child: _buildTypeChip(
                context,
                AddressType.office,
                'Office',
                Iconsax.briefcase,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeChip(
    BuildContext context,
    AddressType type,
    String label,
    IconData icon,
  ) {
    final bool isSelected = _selectedType == type;
    final bool enabled = widget.addressToEdit == null;

    return GestureDetector(
      onTap: () {
        if (enabled) {
          HapticFeedback.selectionClick();
          setState(() => _selectedType = type);
        }
      },
      child: AnimatedContainer(
        duration: DesignSystem.animations.fast,
        padding: EdgeInsets.symmetric(
          horizontal: DesignSystem.spacing.sm,
          vertical: DesignSystem.spacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: DesignSystem.borders.md,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : TColors.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
            SizedBox(height: DesignSystem.spacing.xs),
            Text(
              label,
              style: DesignSystem.typography.labelSmall.copyWith(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (isRequired ? ' *' : ''),
          style: DesignSystem.typography.titleMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignSystem.spacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: keyboardType == TextInputType.text 
              ? TextCapitalization.words 
              : TextCapitalization.none,
          style: DesignSystem.typography.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: DesignSystem.typography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            prefixIcon: Icon(icon, size: 20, color: TColors.textSecondary),
            filled: true,
            fillColor: isDark
                ? TColors.surfaceDark
                : TColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: DesignSystem.borders.md,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: DesignSystem.borders.md,
              borderSide: BorderSide(
                color: TColors.borderPrimary,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: DesignSystem.borders.md,
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: DesignSystem.borders.md,
              borderSide: BorderSide(
                color: TColors.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: DesignSystem.borders.md,
              borderSide: BorderSide(
                color: TColors.error,
                width: 1.5,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: DesignSystem.spacing.md,
              vertical: DesignSystem.spacing.md,
            ),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'This field is required';
            }
            
            if (keyboardType == TextInputType.phone && value != null && value.isNotEmpty) {
              if (value.length < 10) {
                return 'Please enter a valid phone number';
              }
            }
            
            return null;
          },
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DesignSystem.typography.titleMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignSystem.spacing.xs),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignSystem.spacing.md,
            vertical: DesignSystem.spacing.md,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? TColors.surfaceDark.withOpacity(0.5)
                : TColors.grey.withOpacity(0.3),
            borderRadius: DesignSystem.borders.md,
            border: Border.all(
              color: TColors.borderPrimary,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: TColors.textSecondary),
              SizedBox(width: DesignSystem.spacing.sm),
              Text(
                value,
                style: DesignSystem.typography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPincodeField(BuildContext context, bool isDark) {
    return Obx(() {
      final bool hasSuggestions =
          _showPincodeSuggestions.value && _filteredPincodes.isNotEmpty;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pincode *',
            style: DesignSystem.typography.titleMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: DesignSystem.spacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _pincodeSearchCtrl,
                focusNode: _pincodeFocusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: DesignSystem.typography.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter 6-digit pincode',
                  hintStyle: DesignSystem.typography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  prefixIcon: Icon(Iconsax.location, size: 20, color: TColors.textSecondary),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _pincodeSearchCtrl,
                    builder: (context, value, child) {
                      return value.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 18, color: TColors.textSecondary),
                              onPressed: () {
                                _pincodeSearchCtrl.clear();
                                _pincodeCtrl.clear();
                                _showPincodeSuggestions.value = false;
                              },
                            )
                          : const SizedBox.shrink();
                    },
                  ),
                  filled: true,
                  fillColor: isDark
                      ? TColors.surfaceDark
                      : TColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: DesignSystem.borders.md,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: DesignSystem.borders.md,
                    borderSide: BorderSide(
                      color: TColors.borderPrimary,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: DesignSystem.borders.md,
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: DesignSystem.borders.md,
                    borderSide: BorderSide(
                      color: TColors.error,
                      width: 1,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: DesignSystem.borders.md,
                    borderSide: BorderSide(
                      color: TColors.error,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: DesignSystem.spacing.md,
                    vertical: DesignSystem.spacing.md,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pincode is required';
                  }
                  if (value.length != 6) {
                    return 'Please enter a valid 6-digit pincode';
                  }
                  final appSettings = AppSettingsService.instance;
                  final availablePincodes = appSettings.availablePincodes;
                  if (availablePincodes.isNotEmpty && !availablePincodes.contains(value)) {
                    return 'This pincode is not available for delivery';
                  }
                  return null;
                },
              ),
              // Dropdown suggestions - appears in normal flow, pushing content below
              if (hasSuggestions) ...[
                SizedBox(height: DesignSystem.spacing.xs),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF1E1E1E) : Color(0xFFFFFFFF),
                    borderRadius: DesignSystem.borders.md,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  constraints: BoxConstraints(maxHeight: 200),
                  child: Material(
                    color: isDark ? Color(0xFF1E1E1E) : Color(0xFFFFFFFF),
                    borderRadius: DesignSystem.borders.md,
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: math.min(5, _filteredPincodes.length),
                      itemBuilder: (context, index) {
                        final pincode = _filteredPincodes[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: isDark ? Color(0xFF1E1E1E) : Color(0xFFFFFFFF),
                          ),
                          child: Column(
                            children: [
                              if (index > 0)
                                Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                              InkWell(
                                onTap: () => _handlePincodeSelection(pincode),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? Color(0xFF1E1E1E) : Color(0xFFFFFFFF),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Iconsax.location,
                                        size: 18,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        pincode,
                                        style: DesignSystem.typography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    });
  }

  Widget _buildDefaultToggle(BuildContext context) {
    return Obx(() => GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _isDefault.value = !_isDefault.value;
      },
      child: Container(
        padding: EdgeInsets.all(DesignSystem.spacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: DesignSystem.borders.md,
          border: Border.all(
            color: _isDefault.value
                ? Theme.of(context).colorScheme.primary
                : TColors.borderPrimary,
            width: _isDefault.value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: DesignSystem.animations.fast,
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: _isDefault.value
                    ? Theme.of(context).colorScheme.primary
                    : TColors.grey,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: DesignSystem.animations.fast,
                alignment: _isDefault.value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: DesignSystem.shadows.elevation2,
                  ),
                ),
              ),
            ),
            SizedBox(width: DesignSystem.spacing.md),
            Expanded(
              child: Text(
                'Set as default address',
                style: DesignSystem.typography.titleMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildSaveButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.spacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: DesignSystem.shadows.elevation2,
      ),
      child: SafeArea(
        child: Obx(() => SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving.value ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: DesignSystem.borders.md,
              ),
            ),
            child: _isSaving.value
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
                        'Saving...',
                        style: DesignSystem.typography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Save Address',
                    style: DesignSystem.typography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        )),
      ),
    );
  }
}
