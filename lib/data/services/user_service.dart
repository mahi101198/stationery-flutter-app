import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../../services/referral_service.dart';

/// User service following enterprise schema
class UserService extends GetxController {
  static UserService get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Create a new user
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
        role: UserRole.customer,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        profilePicture: profilePicture,
        referralCode: referralCode,
        referredBy: referredBy,
        walletBalance: 0.0,
        addresses: [],
        createdAt: now,
        updatedAt: now,
      );

      await _usersCollection.doc(uid).set(user.toFirestore());
      log('✅ User created successfully: $uid');
    } catch (e) {
      log('❌ Error creating user: $e');
      throw 'Failed to create user account. Please try again.';
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
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

  /// Update user
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
      fields['updatedAt'] = Timestamp.fromDate(DateTime.now());
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
    AddressType? addressType,
    String? recepientDetails,
    String? phoneNumber,
    String? mobileNumber,        // ✅ Mobile number
    String? alternateNumber,     // ✅ Alternate number
    String? landmark,            // ✅ Landmark
  }) async {
    try {
      log('🔍 UserService.addAddress called for user: $userId');
      log('🔍 Address details: label=$label, line1=$line1, city=$city, state=$state, pincode=$pincode');
      
      // Ensure user document exists (auto-provision if missing)
      var user = await getUserById(userId);
      log('🔍 User exists: ${user != null}');
      
      if (user == null) {
        log('🔍 User not found, creating new user...');
        final fbUser = _auth.currentUser;
        if (fbUser == null || fbUser.uid != userId) {
          throw 'User not authenticated';
        }
        final displayName = fbUser.displayName ?? '';
        final parts = displayName.trim().split(' ');
        final firstName = (parts.isNotEmpty && parts.first.isNotEmpty) ? parts.first : 'User';
        final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        await createUser(
          uid: userId,
          firstName: firstName,
          lastName: lastName,
          email: fbUser.email ?? '',
          phoneNumber: fbUser.phoneNumber ?? '',
          profilePicture: fbUser.photoURL,
        );
        user = await getUserById(userId);
        if (user == null) throw 'Failed to create user profile';
        log('🔍 New user created successfully');
      }

      final addressId = const Uuid().v4();
      log('🔍 Generated address ID: $addressId');
      
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
        addressType: addressType,
        recepientDetails: recepientDetails,
        phoneNumber: phoneNumber,
        mobileNumber: mobileNumber,        // ✅ Mobile number
        alternateNumber: alternateNumber,  // ✅ Alternate number
        landmark: landmark,                // ✅ Landmark
      );

      List<UserAddress> updatedAddresses = List.from(user.addresses);
      log('🔍 Current addresses count: ${updatedAddresses.length}');

      // If this is the first address or marked as default, make it default
      if (isDefault || updatedAddresses.isEmpty) {
        log('🔍 Setting as default address');
        updatedAddresses = updatedAddresses
            .map((addr) => addr.copyWith(isDefault: false))
            .toList();
        updatedAddresses.add(newAddress.copyWith(isDefault: true));
      } else {
        log('🔍 Adding as regular address');
        updatedAddresses.add(newAddress);
      }

      log('🔍 Updated addresses count: ${updatedAddresses.length}');
      log('🔍 Calling updateUserFields...');

      await updateUserFields(userId, {
        'addresses': updatedAddresses.map((addr) => addr.toFirestore()).toList(),
      });

      log('✅ Address added successfully for user: $userId');
    } catch (e) {
      log('❌ Error adding address: $e');
      log('❌ Stack trace: ${StackTrace.current}');
      throw 'Failed to add address. Please try again.';
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
    AddressType? addressType,
    String? recepientDetails,
    String? phoneNumber,
    String? mobileNumber,        // ✅ Mobile number
    String? alternateNumber,     // ✅ Alternate number
    String? landmark,            // ✅ Landmark
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
            addressType: addressType ?? addr.addressType,
            recepientDetails: recepientDetails ?? addr.recepientDetails,
            phoneNumber: phoneNumber ?? addr.phoneNumber,
            mobileNumber: mobileNumber ?? addr.mobileNumber,        // ✅ Mobile number
            alternateNumber: alternateNumber ?? addr.alternateNumber, // ✅ Alternate number
            landmark: landmark ?? addr.landmark,                    // ✅ Landmark
          );
        }
        return addr;
      }).toList();

      // If setting as default, remove default from others
      if (isDefault == true) {
        updatedAddresses = updatedAddresses
            .map((addr) => addr.addressId == addressId
                ? addr.copyWith(isDefault: true)
                : addr.copyWith(isDefault: false))
            .toList();
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

      final updatedAddresses =
          user.addresses.where((addr) => addr.addressId != addressId).toList();

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
  Future<void> updateProfilePicture(String userId, String? imageUrl) async {
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
        return UserModel.fromFirestore(query.docs.first);
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

  /// Delete user account (soft delete)
  Future<void> deleteUser(String userId) async {
    try {
      await updateUserFields(userId, {
        'isActive': false,
        'deletedAt': Timestamp.fromDate(DateTime.now()),
      });

      log('✅ User marked as deleted: $userId');
    } catch (e) {
      log('❌ Error deleting user: $e');
      throw 'Failed to delete user account. Please try again.';
    }
  }

  /// Get user stream for real-time updates
  Stream<UserModel?> getUserStream(String userId) {
    try {
      return _usersCollection.doc(userId).snapshots().map((doc) {
        if (doc.exists) {
          return UserModel.fromFirestore(doc);
        }
        return null;
      });
    } catch (e) {
      log('❌ Error creating user stream: $e');
      return Stream.value(null);
    }
  }

  /// Get current user stream
  Stream<UserModel?> getCurrentUserStream() {
    try {
      if (currentUserId == null) return Stream.value(null);
      return getUserStream(currentUserId!);
    } catch (e) {
      log('❌ Error creating current user stream: $e');
      return Stream.value(null);
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
    log('UserService initialized with enterprise schema');
  }
}
