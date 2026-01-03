import 'package:get/get.dart';
import 'package:rps_stationery/features/personalization/screens/address/address_controller.dart';
import 'package:rps_stationery/data/models/user_model.dart' as user_schema;

class AddressSelectionController extends GetxController {
  static AddressSelectionController get instance => Get.find();

  // Observable variables
  final isLoading = true.obs;
  final selectedAddress = Rxn<user_schema.UserAddress>();
  final addresses = <user_schema.UserAddress>[].obs;

  // Dependencies
  late AddressController _addressController;

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  /// Initialize the controller and load addresses
  void _initializeController() {
    try {
      isLoading.value = true;
      
      // Get or create the address controller instance
      if (Get.isRegistered<AddressController>()) {
        _addressController = Get.find<AddressController>();
      } else {
        _addressController = Get.put(AddressController());
      }

      // Listen to address changes from the AddressController
      _listenToAddressChanges();
      
      // Load initial addresses
      _loadInitialAddresses();
    } catch (e) {
      // Use TLoaders for consistent error handling
      isLoading.value = false;
      // Only show error if context is available and error is significant
      if (Get.context != null) {
        // Log error but don't show snackbar for initialization errors
        // as they might not be critical
      }
    }
  }

  /// Listen to address changes from AddressController
  void _listenToAddressChanges() {
    // Listen to changes in the address controller's addresses
    ever(_addressController.addresses, (List<user_schema.UserAddress> newAddresses) {
      print('🔍 AddressSelectionController: AddressController addresses changed, count=${newAddresses.length}');
      addresses.assignAll(newAddresses);
      _selectDefaultOrFirstAddress();
      if (addresses.isNotEmpty || !_addressController.isLoading.value) {
        isLoading.value = false;
      }
    });
    
    // Also listen to loading state changes
    ever(_addressController.isLoading, (bool loading) {
      print('🔍 AddressSelectionController: AddressController loading state changed, loading=$loading');
      if (!loading) {
        addresses.assignAll(_addressController.addresses);
        _selectDefaultOrFirstAddress();
        isLoading.value = false;
      }
    });
  }

  /// Load initial addresses
  void _loadInitialAddresses() {
    // Get current addresses from the address controller
    addresses.assignAll(_addressController.addresses);
    
    // If addresses are already loaded, update selection and stop loading
    if (addresses.isNotEmpty) {
      _selectDefaultOrFirstAddress();
      isLoading.value = false;
    } else if (!_addressController.isLoading.value) {
      // If no addresses and not loading, we're done
      isLoading.value = false;
    }
    // If still loading, the listener will handle the update
  }

  /// Select default address or first available address
  void _selectDefaultOrFirstAddress() {
    if (addresses.isEmpty) return;
    
    // Auto-select the first default address if available
    final primaryAddress = addresses.firstWhereOrNull(
      (address) => address.isDefault,
    );
    
    if (primaryAddress != null) {
      selectAddress(primaryAddress);
    } else {
      // If no primary address, select the first one
      selectAddress(addresses.first);
    }
  }

  /// Load all user addresses
  Future<void> loadAddresses() async {
    try {
      isLoading.value = true;
      
      // Wait a moment to ensure Firestore listener has updated the address controller
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Update local addresses list from the address controller
      addresses.assignAll(_addressController.addresses);
      
      print('🔍 AddressSelectionController: Loaded ${addresses.length} addresses from AddressController');
      
      // Auto-select the first default address if available
      final primaryAddress = addresses.firstWhereOrNull(
        (address) => address.isDefault,
      );
      
      if (primaryAddress != null) {
        selectAddress(primaryAddress);
        print('🔍 AddressSelectionController: Auto-selected default address: ${primaryAddress.id}');
      } else if (addresses.isNotEmpty) {
        // If no primary address, select the first one
        selectAddress(addresses.first);
        print('🔍 AddressSelectionController: Auto-selected first address: ${addresses.first.id}');
      }
    } catch (e) {
      // Use TLoaders for consistent error handling  
      print('🔍 AddressSelectionController: Error loading addresses: $e');
      if (Get.context != null) {
        // Log error but don't show snackbar unless it's a critical error
        // Most address loading errors are handled by the underlying address controller
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Select an address
  void selectAddress(user_schema.UserAddress address) {
    selectedAddress.value = address;
  }

  /// Add a new address to the list
  void addAddress(user_schema.UserAddress address) {
    addresses.add(address);
    
    // If this is the first address, auto-select it
    if (addresses.length == 1) {
      selectAddress(address);
    }
  }

  /// Remove an address from the list
  void removeAddress(String addressId) {
    addresses.removeWhere((address) => address.id == addressId);
    
    // If the removed address was selected, clear selection
    if (selectedAddress.value?.id == addressId) {
      selectedAddress.value = null;
      
      // Auto-select first available address if any
      if (addresses.isNotEmpty) {
        selectAddress(addresses.first);
      }
    }
  }

  /// Update an existing address
  void updateAddress(user_schema.UserAddress updatedAddress) {
    final index = addresses.indexWhere((address) => address.id == updatedAddress.id);
    if (index != -1) {
      addresses[index] = updatedAddress;
      
      // Update selection if this was the selected address
      if (selectedAddress.value?.id == updatedAddress.id) {
        selectedAddress.value = updatedAddress;
      }
    }
  }

  /// Refresh addresses from the server
  Future<void> refreshAddresses() async {
    await loadAddresses();
  }

  /// Check if an address is selected
  bool isAddressSelected(user_schema.UserAddress address) {
    return selectedAddress.value?.id == address.id;
  }

  /// Get the selected address
  user_schema.UserAddress? get getSelectedAddress => selectedAddress.value;

  /// Check if any address is selected
  bool get hasSelectedAddress => selectedAddress.value != null;

  /// Get the number of addresses
  int get addressCount => addresses.length;

  /// Check if addresses are empty
  bool get isAddressesEmpty => addresses.isEmpty;

  @override
  void onClose() {
    // Clean up if needed
    super.onClose();
  }
}
