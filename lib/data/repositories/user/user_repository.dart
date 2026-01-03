import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rps_stationery/data/models/user_model.dart';
import 'package:rps_stationery/services/referral_service.dart';
import 'package:uuid/uuid.dart';

import '../../../utils/exceptions/firebase_auth_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';

/// Repository for user data operations following the new schema
class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Collection reference for users
  CollectionReference get _usersCollection => _db.collection('users');

  /// Current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Create a new user in Firestore
  Future<void> createUser({
    required String uid,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    String? referredBy,
    String? profilePicture,
  }) async {
    try {
      final now = DateTime.now();
      // Generate referral code using ReferralService for consistency
      final referralService = Get.put(ReferralService());
      final referralCode = await referralService.generateReferralCode(uid);

      final user = UserModel(
        uid: uid,
        role: UserRole.customer, // Always customer for this app
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        profilePicture: profilePicture,
        referralCode: referralCode,
        referredBy: referredBy,
        walletBalance: 0.0,
        addresses: [], // Empty initially
        createdAt: now,
        updatedAt: now,
      );

      await _usersCollection.doc(uid).set(user.toFirestore());
      
      log('✅ User created successfully in Firestore: $uid');
    } catch (e) {
      log('❌ Error creating user: $e');
      throw 'Failed to create user account. Please try again.';
    }
  }

  // Save user data (legacy method for compatibility)
  Future<void> saveUserRecord(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toFirestore());
      // Save the user referral code to Get Storage
      GetStorage().write('userReferCode', user.referralCode);
      log('✅ User record saved successfully: ${user.uid}');
    } on FirebaseException catch (e) {
      throw TFirebaseAuthException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      
      if (doc.exists) {
        return UserModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
      }
      
      return null;
    } catch (e) {
      log('❌ Error fetching user: $e');
      throw 'Failed to fetch user data. Please try again.';
    }
  }

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      if (currentUserId == null) return null;
      return await getUserById(currentUserId!);
    } catch (e) {
      log('❌ Error fetching current user: $e');
      return null;
    }
  }

  // Get user data (legacy method for compatibility)
  Future<UserModel?> getUserData() async {
    return await getCurrentUser();
  }

  /// Update user data
  Future<void> updateUser(UserModel user) async {
    try {
      final updatedUser = user.copyWith(updatedAt: DateTime.now());
      await _usersCollection.doc(user.uid).update(updatedUser.toFirestore());
      
      log('✅ User updated successfully: ${user.uid}');
    } catch (e) {
      log('❌ Error updating user: $e');
      throw 'Failed to update user data. Please try again.';
    }
  }

  /// Update specific user fields
  Future<void> updateUserFields(String userId, Map<String, dynamic> fields) async {
    try {
      fields['updatedAt'] = DateTime.now();
      await _usersCollection.doc(userId).update(fields);
      
      log('✅ User fields updated successfully: $userId');
    } catch (e) {
      log('❌ Error updating user fields: $e');
      throw 'Failed to update user information. Please try again.';
    }
  }

  /// Add address to user
  Future<void> addAddress({
    required String userId,
    required String label,
    required String line1,
    required String line2,
    required String city,
    required String state,
    required String pincode,
    String country = 'India',
    bool isDefault = false,
  }) async {
    try {
      final user = await getUserById(userId);
      if (user == null) throw 'User not found';

      // Generate unique address ID
      final addressId = const Uuid().v4();

      final newAddress = UserAddress(
        addressId: addressId,
        label: label,
        line1: line1,
        line2: line2,
        city: city,
        state: state,
        pincode: pincode,
        country: country,
        isDefault: isDefault,
      );

      List<UserAddress> updatedAddresses = List.from(user.addresses);

      // If this is the first address or marked as default, make it default
      if (isDefault || updatedAddresses.isEmpty) {
        // Remove default from other addresses
        updatedAddresses = updatedAddresses.map((addr) => 
            addr.copyWith(isDefault: false)).toList();
        updatedAddresses.add(newAddress.copyWith(isDefault: true));
      } else {
        updatedAddresses.add(newAddress);
      }

      await updateUserFields(userId, {
        'addresses': updatedAddresses.map((addr) => addr.toFirestore()).toList(),
      });

      log('✅ Address added successfully for user: $userId');
    } catch (e) {
      log('❌ Error adding address: $e');
      throw 'Failed to add address. Please try again.';
    }
  }

  /// Get user stream for real-time updates
  Stream<UserModel?> getUserStream(String userId) {
    try {
      return _usersCollection.doc(userId).snapshots().map((doc) {
        if (doc.exists) {
          return UserModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
        }
        return null;
      });
    } catch (e) {
      log('❌ Error creating user stream: $e');
      return Stream.value(null);
    }
  }

  /// Update address
  Future<void> updateAddress({
    required String userId,
    required String addressId,
    String? label,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? pincode,
    String? country,
    bool? isDefault,
  }) async {
    try {
      final user = await getUserById(userId);
      if (user == null) throw 'User not found';

      List<UserAddress> updatedAddresses = user.addresses.map((addr) {
        if (addr.addressId == addressId) {
          return addr.copyWith(
            label: label ?? addr.label,
            line1: line1 ?? addr.line1,
            line2: line2 ?? addr.line2,
            city: city ?? addr.city,
            state: state ?? addr.state,
            pincode: pincode ?? addr.pincode,
            country: country ?? addr.country,
            isDefault: isDefault ?? addr.isDefault,
          );
        }
        return addr;
      }).toList();

      // If setting as default, remove default from others
      if (isDefault == true) {
        updatedAddresses = updatedAddresses.map((addr) => 
            addr.addressId == addressId 
                ? addr.copyWith(isDefault: true)
                : addr.copyWith(isDefault: false)).toList();
      }

      await updateUserFields(userId, {
        'addresses': updatedAddresses.map((addr) => addr.toFirestore()).toList(),
      });

      log('✅ Address updated successfully for user: $userId');
    } catch (e) {
      log('❌ Error updating address: $e');
      throw 'Failed to update address. Please try again.';
    }
  }

  /// Delete address
  Future<void> deleteAddress(String userId, String addressId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) throw 'User not found';

      final updatedAddresses = user.addresses
          .where((addr) => addr.addressId != addressId)
          .toList();

      // If deleted address was default and there are other addresses,
      // make the first one default
      if (updatedAddresses.isNotEmpty && 
          !updatedAddresses.any((addr) => addr.isDefault)) {
        updatedAddresses[0] = updatedAddresses[0].copyWith(isDefault: true);
      }

      await updateUserFields(userId, {
        'addresses': updatedAddresses.map((addr) => addr.toFirestore()).toList(),
      });

      log('✅ Address deleted successfully for user: $userId');
    } catch (e) {
      log('❌ Error deleting address: $e');
      throw 'Failed to delete address. Please try again.';
    }
  }

  /// Set address as default
  Future<void> setDefaultAddress(String userId, String addressId) async {
    try {
      await updateAddress(
        userId: userId,
        addressId: addressId,
        isDefault: true,
      );
    } catch (e) {
      log('❌ Error setting default address: $e');
      throw 'Failed to set default address. Please try again.';
    }
  }

  /// Add to wallet balance
  Future<void> addToWallet(String userId, double amount) async {
    try {
      final user = await getUserById(userId);
      if (user == null) throw 'User not found';

      final newBalance = user.walletBalance + amount;
      
      await updateUserFields(userId, {
        'walletBalance': newBalance,
      });

      log('✅ Amount added to wallet for user: $userId, Amount: $amount');
    } catch (e) {
      log('❌ Error adding to wallet: $e');
      throw 'Failed to add money to wallet. Please try again.';
    }
  }

  /// Deduct from wallet balance
  Future<bool> deductFromWallet(String userId, double amount) async {
    try {
      final user = await getUserById(userId);
      if (user == null) throw 'User not found';

      if (user.walletBalance < amount) {
        return false; // Insufficient balance
      }

      final newBalance = user.walletBalance - amount;
      
      await updateUserFields(userId, {
        'walletBalance': newBalance,
      });

      log('✅ Amount deducted from wallet for user: $userId, Amount: $amount');
      return true;
    } catch (e) {
      log('❌ Error deducting from wallet: $e');
      throw 'Failed to deduct money from wallet. Please try again.';
    }
  }

  /// Update profile picture
  Future<void> updateProfilePicture(String userId, String imageUrl) async {
    try {
      await updateUserFields(userId, {
        'profilePicture': imageUrl,
      });

      log('✅ Profile picture updated for user: $userId');
    } catch (e) {
      log('❌ Error updating profile picture: $e');
      throw 'Failed to update profile picture. Please try again.';
    }
  }

  /// Get user by referral code
  Future<UserModel?> getUserByReferralCode(String referralCode) async {
    try {
      final query = await _usersCollection
          .where('referralCode', isEqualTo: referralCode)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return UserModel.fromFirestore(
            query.docs.first as DocumentSnapshot<Map<String, dynamic>>);
      }

      return null;
    } catch (e) {
      log('❌ Error fetching user by referral code: $e');
      return null;
    }
  }

  /// Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      final query = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      log('❌ Error checking email exists: $e');
      return false;
    }
  }

  /// Check if phone number exists
  Future<bool> phoneExists(String phoneNumber) async {
    try {
      final query = await _usersCollection
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      log('❌ Error checking phone exists: $e');
      return false;
    }
  }

  /// Check if user exists in Firestore (legacy method for compatibility)
  Future<bool> userExists(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Check if referral code exists and is valid
  Future<bool> isValidReferralCode(String referralCode) async {
    try {
      log('Validating referral code: $referralCode');

      final HttpsCallable callable = _functions.httpsCallable(
        'validateReferralCode',
      );

      final result = await callable.call({
        'referralCode': referralCode.trim().toUpperCase(),
      });

      final data = result.data as Map<String, dynamic>;
      final isValid = data['isValid'] as bool;
      final message = data['message'] as String?;

      log(
        'Referral code validation result: isValid=$isValid, message=$message',
      );

      return isValid;
    } on FirebaseFunctionsException catch (e) {
      log('Firebase Functions Error: ${e.code} - ${e.message}');

      // Handle specific error codes
      switch (e.code) {
        case 'invalid-argument':
          log('Invalid referral code format');
          return false;
        case 'internal':
          log('Internal server error during validation');
          return false;
        default:
          log('Unknown Firebase Functions error: ${e.code}');
          return false;
      }
    } catch (e) {
      log('Error checking referral code: $e');
      return false;
    }
  }

  // Check if referral code is unique (for generating new codes)
  Future<bool> isReferralCodeUnique(String referralCode) async {
    try {
      log('Checking unique referral code: $referralCode');

      final HttpsCallable callable = _functions.httpsCallable(
        'validateReferralCode',
      );

      final result = await callable.call({
        'referralCode': referralCode.trim().toUpperCase(),
      });

      final data = result.data as Map<String, dynamic>;
      final isValid = data['isValid'] as bool;
      final message = data['message'] as String?;

      log('Referral code unique result: isValid=$isValid, message=$message');

      return !isValid; // Unique if not valid
    } on FirebaseFunctionsException catch (e) {
      log('Firebase Functions Error: ${e.code} - ${e.message}');

      // Handle specific error codes
      switch (e.code) {
        case 'invalid-argument':
          log('Invalid referral code format');
          return false;
        case 'internal':
          log('Internal server error during validation');
          return false;
        default:
          log('Unknown Firebase Functions error: ${e.code}');
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Delete user account (soft delete - just mark inactive)
  Future<void> deleteUser(String userId) async {
    try {
      await updateUserFields(userId, {
        'isActive': false,
        'deletedAt': DateTime.now(),
      });

      log('✅ User marked as deleted: $userId');
    } catch (e) {
      log('❌ Error deleting user: $e');
      throw 'Failed to delete user account. Please try again.';
    }
  }


  /// Get user's default address
  UserAddress? getDefaultAddress(UserModel user) {
    try {
      return user.addresses.firstWhere(
        (address) => address.isDefault,
      );
    } catch (e) {
      // Return first address if no default is set
      return user.addresses.isNotEmpty ? user.addresses.first : null;
    }
  }

  // Note: Referral code generation is now handled by ReferralService for consistency

  @override
  void onReady() {
    super.onReady();
    log('UserRepository initialized');
  }
}
