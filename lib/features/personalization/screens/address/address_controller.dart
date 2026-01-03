import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';
import 'package:rps_stationery/data/models/user_model.dart' as user_schema;
import 'package:rps_stationery/data/services/user_service.dart';

class AddressController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>>? _userDocRef;
  String? _userId;
  final _userService = UserService.instance;

  // Get user ID safely
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  // State variables
  final RxBool isLoading = true.obs;
  final RxList<user_schema.UserAddress> addresses = <user_schema.UserAddress>[].obs;
  final RxList<user_schema.UserAddress> _rawAddresses = <user_schema.UserAddress>[].obs;

  // Stream subscriptions to manage them properly
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }
  
  void _initializeController() {
    _userId = userId;
    if (_userId == null) {
      isLoading.value = false;
      TLoaders.errorSnackBar(
        title: 'Authentication Error',
        message: 'Please sign in to manage addresses',
      );
      return;
    }
    
    // Define references based on the user collection structure
    _userDocRef = _firestore.collection('users').doc(_userId!);

    // Single listener to the user document; addresses are embedded per enterprise schema
    _listenToUserDoc();
  }

  @override
  void onClose() {
    // Always cancel subscriptions to prevent memory leaks
    _userSubscription?.cancel();
    super.onClose();
  }

  void _listenToUserDoc() {
    if (_userDocRef == null) return;

    _userSubscription = _userDocRef!.snapshots().listen(
      (snapshot) {
        try {
          if (!snapshot.exists) {
            _rawAddresses.value = [];
            addresses.value = [];
            isLoading.value = false;
            return;
          }

          // Parse full user schema then use its addresses directly
          final user = user_schema.UserModel.fromFirestore(snapshot);
          final list = user.addresses;

          _rawAddresses.value = List<user_schema.UserAddress>.from(list);
          _combineAndSortAddresses();
          isLoading.value = false;
        } catch (e) {
          isLoading.value = false;
        }
      },
      onError: (error) {
        isLoading.value = false;
        TLoaders.errorSnackBar(
          title: 'Connection Error',
          message: 'Failed to sync default address. Please check your connection.',
        );
      },
    );
  }

  // This method is the core of the new logic. It combines data from two sources.
  void _combineAndSortAddresses() {
    if (_rawAddresses.isEmpty) {
      addresses.value = [];
      return;
    }

    final processedList = List<user_schema.UserAddress>.from(_rawAddresses);
    // Sort to keep default first
    processedList.sort((a, b) {
      if (a.isDefault == b.isDefault) return 0;
      return a.isDefault ? -1 : 1;
    });
    addresses.value = processedList;
  }

  // Add a new address
  Future<void> addAddress(user_schema.UserAddress address, bool shouldBeDefault) async {
    print('AddressController.addAddress called');
    print('User ID: $_userId');
    print('Address: ${address.toFirestore()}');
    print('Should be default: $shouldBeDefault');
    
    if (_userId == null) {
      print('Error: User ID is null');
      TLoaders.errorSnackBar(title: 'Error', message: 'Not signed in');
      return;
    }
    
    try {
      print('Calling UserService.addAddress...');
      await _userService.addAddress(
        userId: _userId!,
        label: address.label,
        line1: address.line1,
        line2: address.line2,
        city: address.city,
        state: address.state,
        pincode: address.pincode,
        country: address.country,
        isDefault: shouldBeDefault || _rawAddresses.isEmpty,
        addressType: address.addressType,
        recepientDetails: address.recepientDetails,
        phoneNumber: address.phoneNumber,
        mobileNumber: address.mobileNumber,        // ✅ Mobile number
        alternateNumber: address.alternateNumber,  // ✅ Alternate number
        landmark: address.landmark,                // ✅ Landmark
      );
      print('UserService.addAddress completed successfully');
      
      // Wait a moment for Firestore listener to update the addresses list
      await Future.delayed(const Duration(milliseconds: 500));
      
      Get.back();
      TLoaders.successSnackBar(title: 'Success!', message: 'Address added successfully!');
    } catch (e) {
      print('Error in AddressController.addAddress: $e');
      TLoaders.errorSnackBar(title: 'Oh Snap!', message: 'Failed to add address: ${e.toString()}');
    }
  }

  // Set a specific address as the default. This is now much simpler.
  Future<void> setDefaultAddress(String addressId) async {
    if (_userId == null) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Not signed in');
      return;
    }
    try {
      await _userService.setDefaultAddress(_userId!, addressId);
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh snap!', message: 'Failed to update default address');
    }
  }

  Future<void> updateAddress(String addressId, user_schema.UserAddress address) async {
    if (_userId == null) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Not signed in');
      return;
    }
    try {
      await _userService.updateAddress(
        userId: _userId!,
        addressId: addressId,
        label: address.label,
        line1: address.line1,
        line2: address.line2,
        city: address.city,
        state: address.state,
        pincode: address.pincode,
        country: address.country,
        addressType: address.addressType,
        recepientDetails: address.recepientDetails,
        phoneNumber: address.phoneNumber,
        mobileNumber: address.mobileNumber,        // ✅ Mobile number
        alternateNumber: address.alternateNumber,  // ✅ Alternate number
        landmark: address.landmark,                // ✅ Landmark
      );
      
      // Wait a moment for Firestore listener to update the addresses list
      await Future.delayed(const Duration(milliseconds: 500));
      
      Get.back();
      TLoaders.successSnackBar(title: 'Success!', message: 'Address updated!');
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh Snap!', message: 'Failed to update address. Please try again.');
    }
  }

  // Delete an address
  Future<void> deleteAddress(String addressId) async {
    if (_userId == null) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Not signed in');
      return;
    }
    try {
      await _userService.deleteAddress(_userId!, addressId);
      TLoaders.successSnackBar(title: 'Success!', message: 'Address deleted successfully!');
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh snap!', message: 'Failed to delete address. Please try again.');
    }
  }
}
