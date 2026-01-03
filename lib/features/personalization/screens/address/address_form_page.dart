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

class AddressFormPage extends StatefulWidget {
  final user_schema.UserAddress? addressToEdit;
  const AddressFormPage({super.key, this.addressToEdit});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  late final AddressController controller;
  final _formKey = GlobalKey<FormState>();

  // Form state - simplified and consistent
  late TextEditingController _line1Ctrl;
  late TextEditingController _line2Ctrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _pincodeCtrl;
  late TextEditingController _pincodeSearchCtrl;  // For pincode search
  late TextEditingController _nameCtrl;
  late TextEditingController _mobileCtrl;        // ✅ Mobile number field
  late TextEditingController _landmarkCtrl;      // ✅ Landmark field
  final _isDefault = false.obs;
  AddressType _selectedType = AddressType.independentHouse;
  
  // State and City - fixed values
  final String _state = 'Rajasthan';
  final String _city = 'Jaipur';
  
  // Pincode search state
  final RxList<String> _filteredPincodes = <String>[].obs;
  final RxBool _showPincodeSuggestions = false.obs;
  late final FocusNode _pincodeFocusNode;

  @override
  void initState() {
    super.initState();
    
    // Initialize the AddressController safely
    _initializeController();
    
    final a = widget.addressToEdit;
    _line1Ctrl = TextEditingController(text: a?.line1);
    _line2Ctrl = TextEditingController(text: a?.line2);
    _cityCtrl = TextEditingController(text: _city);  // Always Jaipur
    _stateCtrl = TextEditingController(text: _state);  // Always Rajasthan
    _pincodeCtrl = TextEditingController(text: a?.pincode);
    _pincodeSearchCtrl = TextEditingController(text: a?.pincode);
    _nameCtrl = TextEditingController(text: a?.recepientDetails);
    _mobileCtrl = TextEditingController(text: a?.mobileNumber);        // ✅ Mobile number
    _landmarkCtrl = TextEditingController(text: a?.landmark);          // ✅ Landmark
    _isDefault.value = a?.isDefault ?? false;
    _selectedType = a?.addressType ?? AddressType.independentHouse;
    _pincodeFocusNode = FocusNode();
    _pincodeFocusNode.addListener(_onPincodeFocusChange);
    
    // Initialize pincode search
    _pincodeSearchCtrl.addListener(_onPincodeSearchChanged);
    _filterPincodes('');
  }

  /// Initialize the AddressController safely
  void _initializeController() {
    try {
      // Try to find existing controller first
      if (Get.isRegistered<AddressController>()) {
        controller = Get.find<AddressController>();
      } else {
        // Create new controller if not found
        controller = Get.put(AddressController(), permanent: true);
      }
    } catch (e) {
      // Fallback: create new controller
      controller = Get.put(AddressController(), permanent: true);
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _line1Ctrl.dispose();
    _line2Ctrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _pincodeSearchCtrl.removeListener(_onPincodeSearchChanged);
    _pincodeSearchCtrl.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();        // ✅ Mobile number controller
    _landmarkCtrl.dispose();      // ✅ Landmark controller
    _pincodeFocusNode.removeListener(_onPincodeFocusChange);
    _pincodeFocusNode.dispose();
    super.dispose();
  }
  
  /// Select a pincode from suggestions
  void _handlePincodeSelection(String pincode) {
    print('🎯 ========================================');
    print('🎯 Pincode selected: $pincode');
    
    // Hide suggestions
    _showPincodeSuggestions.value = false;
    
    // Temporarily remove listener
    _pincodeSearchCtrl.removeListener(_onPincodeSearchChanged);
    
    // Set both controllers
    _pincodeCtrl.text = pincode;
    _pincodeSearchCtrl.text = pincode;
    
    print('🎯 ✅ _pincodeCtrl.text = "${_pincodeCtrl.text}"');
    print('🎯 ✅ _pincodeSearchCtrl.text = "${_pincodeSearchCtrl.text}"');
    
    // Re-add listener after a delay
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _pincodeSearchCtrl.addListener(_onPincodeSearchChanged);
      }
    });
    
    // Unfocus
    FocusScope.of(context).unfocus();
    
    print('🎯 ========================================');
  }
  
  /// Filter pincodes based on search query
  void _filterPincodes(String query) {
    try {
      final appSettings = AppSettingsService.instance;
      final availablePincodes = appSettings.availablePincodes;
      print('📍 Available pincodes from settings: ${availablePincodes.length} total');
      
      if (availablePincodes.isEmpty) {
        print('⚠️ No available pincodes configured in app settings!');
        _filteredPincodes.value = [];
        return;
      }
      
      if (query.isEmpty) {
        _filteredPincodes.value = availablePincodes;
        print('📍 Showing all ${availablePincodes.length} pincodes');
      } else {
        // Filter pincodes that start with the query (for progressive typing)
        final filtered = availablePincodes
            .where((pincode) => pincode.startsWith(query))
            .toList();
        _filteredPincodes.value = filtered;
        print('📍 Filtered to ${filtered.length} pincodes starting with "$query"');
        if (filtered.isNotEmpty) {
          print('📍 First few matches: ${filtered.take(3).join(", ")}');
        }
      }
    } catch (e) {
      print('❌ Error filtering pincodes: $e');
      _filteredPincodes.value = [];
    }
  }

  void _onPincodeFocusChange() {
    if (!_pincodeFocusNode.hasFocus) {
      _showPincodeSuggestions.value = false;
    }
  }
  
  /// Handle pincode search input changes
  void _onPincodeSearchChanged() {
    final query = _pincodeSearchCtrl.text;
    print('📍 Pincode search changed: "$query"');
    
    _filterPincodes(query);
    print('📍 Filtered results: ${_filteredPincodes.length} pincodes');
    
    // Only show suggestions if user has typed something AND there are results
    if (query.isNotEmpty && _filteredPincodes.isNotEmpty) {
      _showPincodeSuggestions.value = true;
      print('📍 Showing suggestions');
    } else {
      _showPincodeSuggestions.value = false;
      print('📍 Hiding suggestions');
    }
    
    // Sync with hidden pincode controller
    if (query.length == 6) {
      _pincodeCtrl.text = query;
    }
    
    // Trigger rebuild for suffix icon
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
      
      // Validate required fields
      if (_line1Ctrl.text.trim().isEmpty) {
        print('Line1 is empty');
        Get.snackbar('Error', 'Address line 1 is required');
        return;
      }
      // Validate pincode is from available list
      final appSettings = AppSettingsService.instance;
      final availablePincodes = appSettings.availablePincodes;
      final enteredPincode = _pincodeCtrl.text.trim();
      
      if (enteredPincode.isEmpty) {
        print('Pincode is empty');
        Get.snackbar('Error', 'Pincode is required');
        return;
      }
      
      if (availablePincodes.isNotEmpty && !availablePincodes.contains(enteredPincode)) {
        print('Pincode not available: $enteredPincode');
        Get.snackbar('Error', 'This pincode is not available for delivery. Please select from available pincodes.');
        return;
      }
      
      // Generate label from address type
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
      
      print('Creating address with:');
      print('Label: $label (from address type)');
      print('Line1: ${_line1Ctrl.text.trim()}');
      print('City: ${_cityCtrl.text.trim()}');
      print('State: ${_stateCtrl.text.trim()}');
      print('Pincode: ${_pincodeCtrl.text.trim()}');
      print('AddressType: $_selectedType');
      print('RecipientName: ${_nameCtrl.text.trim()}');
      print('MobileNumber: ${_mobileCtrl.text.trim()}');
      print('Landmark: ${_landmarkCtrl.text.trim()}');
      
      final address = user_schema.UserAddress(
        addressId: widget.addressToEdit?.addressId ?? '',
        label: label, // Use generated label from address type
        line1: _line1Ctrl.text.trim(),
        line2: _line2Ctrl.text.trim(),
        city: _city,  // Always Jaipur
        state: _state,  // Always Rajasthan
        pincode: _pincodeCtrl.text.trim(),
        country: 'India',
        isDefault: _isDefault.value,
        addressType: _selectedType,
        recepientDetails: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        mobileNumber: _mobileCtrl.text.trim().isEmpty ? null : _mobileCtrl.text.trim(),        // ✅ Mobile number
        landmark: _landmarkCtrl.text.trim().isEmpty ? null : _landmarkCtrl.text.trim(),          // ✅ Landmark
      );
      
      print('Address object created successfully');

      if (widget.addressToEdit != null) {
        print('Updating existing address...');
        await controller.updateAddress(widget.addressToEdit!.addressId, address);
        if (_isDefault.value && !widget.addressToEdit!.isDefault) {
          await controller.setDefaultAddress(widget.addressToEdit!.addressId);
        }
      } else {
        print('Adding new address...');
        await controller.addAddress(address, _isDefault.value);
      }
      
      print('Address operation completed successfully');
    } catch (e) {
      print('Error saving address: $e');
      Get.snackbar('Error', 'Failed to save address: ${e.toString()}');
    } finally {
      _isSaving.value = false;
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Gradient
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            leading: IconButton(
              icon: Icon(Iconsax.arrow_left, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
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
                              Iconsax.location,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: DesignSystem.spacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.addressToEdit == null ? 'Add New Address' : 'Edit Address',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                SizedBox(height: DesignSystem.spacing.xs),
                                Text(
                                  widget.addressToEdit == null 
                                      ? 'Complete the form below to add a new delivery address'
                                      : 'Update your delivery address details',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
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

          // Form Content
          SliverPadding(
            padding: EdgeInsets.all(DesignSystem.spacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- SECTION 1: ADDRESS TYPE ---
                      _buildModernSectionCard(
                        context: context,
                        icon: Iconsax.home,
                        title: 'Address Type',
                        subtitle: 'Choose where you want your order delivered',
                        child: _buildAddressTypeSelector(),
                      ),
                      
                      SizedBox(height: DesignSystem.spacing.md),

                      // --- SECTION 2: ADDRESS DETAILS ---
                      _buildModernSectionCard(
                        context: context,
                        icon: Iconsax.map,
                        title: 'Address Details',
                        subtitle: 'Enter your complete delivery address',
                        child: Column(
                          children: [
                            _buildModernTextFormField(
                              context: context,
                              controller: _line1Ctrl,
                              label: 'House/Flat/Block No.*',
                              icon: Iconsax.building_4,
                              hint: 'e.g., Plot 123, Flat 4B',
                            ),
                            SizedBox(height: DesignSystem.spacing.md),
                            _buildModernTextFormField(
                              context: context,
                              controller: _line2Ctrl,
                              label: 'Area/Street/Sector/Locality',
                              icon: Iconsax.location,
                              hint: 'e.g., Sector 21, Main Street',
                              isRequired: false,
                            ),
                            SizedBox(height: DesignSystem.spacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDropdownField(
                                    context: context,
                                    controller: _cityCtrl,
                                    label: 'City*',
                                    icon: Iconsax.building,
                                    value: _city,
                                    options: [_city],
                                  ),
                                ),
                                SizedBox(width: DesignSystem.spacing.md),
                                Expanded(
                                  child: _buildDropdownField(
                                    context: context,
                                    controller: _stateCtrl,
                                    label: 'State*',
                                    icon: Iconsax.map_1,
                                    value: _state,
                                    options: [_state],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: DesignSystem.spacing.md),
                            _buildPincodeSearchField(context),
                            SizedBox(height: DesignSystem.spacing.md),
                            _buildModernTextFormField(
                              context: context,
                              controller: _landmarkCtrl,
                              label: 'Landmark (Optional)',
                              icon: Iconsax.signpost,
                              hint: 'e.g., Near City Mall',
                              isRequired: false,
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: DesignSystem.spacing.md),

                      // --- SECTION 3: CONTACT DETAILS ---
                      _buildModernSectionCard(
                        context: context,
                        icon: Iconsax.call,
                        title: 'Contact Details',
                        subtitle: 'For delivery related communication',
                        child: Column(
                          children: [
                            _buildModernTextFormField(
                              context: context,
                              controller: _nameCtrl,
                              label: 'Recipient\'s Name*',
                              icon: Iconsax.user,
                              hint: 'Full name',
                            ),
                            SizedBox(height: DesignSystem.spacing.md),
                            _buildModernTextFormField(
                              context: context,
                              controller: _mobileCtrl,
                              label: 'Mobile Number*',
                              icon: Iconsax.mobile,
                              hint: '10-digit mobile number',
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: DesignSystem.spacing.md),

                      // --- SECTION 4: DEFAULT ADDRESS ---
                      if (widget.addressToEdit?.isDefault != true)
                        _buildModernDefaultToggle(context),
                      
                      SizedBox(height: DesignSystem.spacing.xl * 2),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      // Modern Floating Save Button
      bottomNavigationBar: _buildModernSaveButton(context),
    );
  }

  Widget _buildModernSectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
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
          // Section Header
          Padding(
            padding: EdgeInsets.all(DesignSystem.spacing.md),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
                SizedBox(width: DesignSystem.spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: DesignSystem.spacing.xs / 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Section Content
          Padding(
            padding: EdgeInsets.all(DesignSystem.spacing.md),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String value,
    required List<String> options,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.grey[850]?.withOpacity(0.3)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark 
                  ? Colors.grey[700]!.withOpacity(0.3)
                  : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              isDense: true,
            ),
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: null, // Disabled - fixed value
            isExpanded: true,
            icon: Icon(
              Iconsax.arrow_down_1,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPincodeSearchField(BuildContext context) {
    return Obx(() {
      final bool hasSuggestions =
          _showPincodeSuggestions.value && _filteredPincodes.isNotEmpty;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      const double fieldHeight = 56.0;
      final double suggestionHeight = hasSuggestions
          ? math.min(220, _filteredPincodes.length * 48).toDouble()
          : 0.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Pincode*',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: fieldHeight + suggestionHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: fieldHeight,
                  child: TextFormField(
              controller: _pincodeSearchCtrl,
              focusNode: _pincodeFocusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.normal,
              ),
              decoration: InputDecoration(
                hintText: 'Search or enter pincode',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                ),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _pincodeSearchCtrl,
                  builder: (context, value, child) {
                    return value.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
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
                    ? Colors.grey[850]?.withOpacity(0.3)
                    : Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark 
                        ? Colors.grey[700]!.withOpacity(0.3)
                        : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
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
              onChanged: (value) {
                // This is called by the listener
                print('📍 Pincode changed: $value');
              },
            ),
                ),
                if (hasSuggestions)
                  Positioned(
                    top: fieldHeight - 4,
                    left: 0,
                    right: 0,
                    height: suggestionHeight,
                    child: Material(
                      elevation: 8,
                      borderRadius: DesignSystem.borders.md,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: DesignSystem.borders.md,
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: DesignSystem.borders.md,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _filteredPincodes.length > 10
                                ? 10
                                : _filteredPincodes.length,
                            itemBuilder: (context, index) {
                              final pincode = _filteredPincodes[index];
                              return Column(
                                children: [
                                  if (index > 0)
                                    Divider(height: 1, thickness: 0.5),
                                  ListTile(
                                    dense: true,
                                    leading: Icon(
                                      Iconsax.location,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    title: Text(
                                      pincode,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    onTap: () {
                                      print('🎯 Pincode tapped: $pincode');
                                      _handlePincodeSelection(pincode);
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildModernTextFormField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: TextCapitalization.words,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.normal,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            filled: true,
            fillColor: isDark 
                ? Colors.grey[850]?.withOpacity(0.3)
                : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark 
                    ? Colors.grey[700]!.withOpacity(0.3)
                    : Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'This field is required';
            }
            
            // Special validation for phone number
            if (keyboardType == TextInputType.phone && value != null && value.isNotEmpty) {
              if (value.length < 10) {
                return 'Please enter a valid phone number';
              }
            }
            
            // Special validation for pincode
            if (label.toLowerCase().contains('pincode') && value != null && value.isNotEmpty) {
              if (value.length != 6) {
                return 'Please enter a valid 6-digit pincode';
              }
            }
            
            return null;
          },
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
      ],
    );
  }

  Widget _buildModernDefaultToggle(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Obx(() => GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _isDefault.value = !_isDefault.value;
              },
              child: Container(
                padding: EdgeInsets.all(DesignSystem.spacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: DesignSystem.borders.lg,
                  boxShadow: DesignSystem.shadows.elevation2,
                  border: Border.all(
                    color: _isDefault.value
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    width: _isDefault.value ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: DesignSystem.animations.fast,
                      curve: Curves.easeInOut,
                      width: 48,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _isDefault.value
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: AnimatedAlign(
                        duration: DesignSystem.animations.fast,
                        curve: Curves.easeInOut,
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
                          child: _isDefault.value
                              ? Icon(
                                  Iconsax.tick_circle,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(width: DesignSystem.spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set as default address',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: DesignSystem.spacing.xs / 2),
                          Text(
                            'Use this address for future orders',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ),
        );
      },
    );
  }

  Widget _buildModernSaveButton(BuildContext context) {
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
        child: Obx(() => AnimatedContainer(
          duration: DesignSystem.animations.fast,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSaving.value ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: DesignSystem.borders.lg,
              ),
              shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
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
                        'Saving Address...',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Save Address',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        )),
      ),
    );
  }

  Widget _buildAddressTypeSelector() {
    bool enabled = widget.addressToEdit == null;

    return Row(
      children: [
        Expanded(
          child: _buildTypeChip(
            AddressType.independentHouse,
            'House',
            Iconsax.home_2,
            enabled,
          ),
        ),
        SizedBox(width: DesignSystem.spacing.md),
        Expanded(
          child: _buildTypeChip(
            AddressType.apartment,
            'Apartment',
            Iconsax.building,
            enabled,
          ),
        ),
        SizedBox(width: DesignSystem.spacing.md),
        Expanded(
          child: _buildTypeChip(
            AddressType.office,
            'Office',
            Iconsax.briefcase,
            enabled,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(
    AddressType type,
    String label,
    IconData icon,
    bool enabled,
  ) {
    final bool isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        if (enabled) {
          HapticFeedback.selectionClick();
          setState(() => _selectedType = type);
        }
      },
      child: AnimatedContainer(
        duration: DesignSystem.animations.fast,
        curve: Curves.easeInOut,
        constraints: BoxConstraints(minHeight: 80),
        padding: EdgeInsets.symmetric(
          horizontal: DesignSystem.spacing.sm,
          vertical: DesignSystem.spacing.md,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                )
              : null,
          color: isSelected 
              ? null 
              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: DesignSystem.borders.lg,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? DesignSystem.shadows.primaryShadow(0.3) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: DesignSystem.animations.fast,
              padding: EdgeInsets.all(DesignSystem.spacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: DesignSystem.borders.md,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            SizedBox(height: DesignSystem.spacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
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
}
