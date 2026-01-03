import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/models/user_model.dart';
import 'package:uuid/uuid.dart';

/// Repository for user data operations following the new schema
class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      final referralCode = _generateReferralCode(firstName);

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

  /// Update address by ID
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

      List<UserAddress> updatedAddresses = List.from(user.addresses);
      final addressIndex = updatedAddresses.indexWhere(
          (addr) => addr.addressId == addressId);

      if (addressIndex == -1) {
        throw 'Address not found';
      }

      // Update the address with new values
      final currentAddress = updatedAddresses[addressIndex];
      final updatedAddress = currentAddress.copyWith(
        label: label ?? currentAddress.label,
        line1: line1 ?? currentAddress.line1,
        line2: line2 ?? currentAddress.line2,
        city: city ?? currentAddress.city,
        state: state ?? currentAddress.state,
        pincode: pincode ?? currentAddress.pincode,
        country: country ?? currentAddress.country,
        isDefault: isDefault ?? currentAddress.isDefault,
      );

      updatedAddresses[addressIndex] = updatedAddress;

      // If setting as default, remove default from others
      if (isDefault == true) {
        updatedAddresses = updatedAddresses.map((addr) => 
            addr.addressId == addressId ? addr : addr.copyWith(isDefault: false)).toList();
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

  /// Delete address by ID
  Future<void> deleteAddress(String userId, String addressId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) throw 'User not found';

      final updatedAddresses = user.addresses.where(
          (addr) => addr.addressId != addressId).toList();

      if (updatedAddresses.length == user.addresses.length) {
        throw 'Address not found';
      }

      // If we deleted the default address and there are remaining addresses,
      // make the first one default
      if (updatedAddresses.isNotEmpty) {
        final deletedAddress = user.addresses.firstWhere(
            (addr) => addr.addressId == addressId);
        
        if (deletedAddress.isDefault && updatedAddresses.isNotEmpty) {
          updatedAddresses[0] = updatedAddresses[0].copyWith(isDefault: true);
        }
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
      final user = await getUserById(userId);
      if (user == null) throw 'User not found';

      final updatedAddresses = user.addresses.map((addr) => 
          addr.copyWith(isDefault: addr.addressId == addressId)).toList();

      if (!updatedAddresses.any((addr) => addr.isDefault)) {
        throw 'Address not found';
      }

      await updateUserFields(userId, {
        'addresses': updatedAddresses.map((addr) => addr.toFirestore()).toList(),
      });

      log('✅ Default address set successfully for user: $userId');
    } catch (e) {
      log('❌ Error setting default address: $e');
      throw 'Failed to set default address. Please try again.';
    }
  }

  /// Add amount to wallet
  Future<void> addToWallet(String userId, double amount) async {
    try {
      final user = await getUserById(userId);
      if (user == null) throw 'User not found';

      if (amount <= 0) {
        throw 'Amount must be greater than 0';
      }

      final newBalance = user.walletBalance + amount;
      
      await updateUserFields(userId, {
        'walletBalance': newBalance,
      });

      log('✅ Amount added to wallet successfully for user: $userId - Amount: $amount');
    } catch (e) {
      log('❌ Error adding to wallet: $e');
      throw 'Failed to add amount to wallet. Please try again.';
    }
  }

  /// Deduct amount from wallet
  Future<void> deductFromWallet(String userId, double amount) async {
    try {
      final user = await getUserById(userId);
      if (user == null) throw 'User not found';

      if (amount <= 0) {
        throw 'Amount must be greater than 0';
      }

      if (user.walletBalance < amount) {
        throw 'Insufficient wallet balance';
      }

      final newBalance = user.walletBalance - amount;
      
      await updateUserFields(userId, {
        'walletBalance': newBalance,
      });

      log('✅ Amount deducted from wallet successfully for user: $userId - Amount: $amount');
    } catch (e) {
      log('❌ Error deducting from wallet: $e');
      throw 'Failed to deduct amount from wallet. Please try again.';
    }
  }

  /// Update profile picture
  Future<void> updateProfilePicture(String userId, String? imageUrl) async {
    try {
      await updateUserFields(userId, {
        'profilePicture': imageUrl,
      });

      log('✅ Profile picture updated successfully for user: $userId');
    } catch (e) {
      log('❌ Error updating profile picture: $e');
      throw 'Failed to update profile picture. Please try again.';
    }
  }

  /// Check if user exists by email
  Future<bool> userExistsByEmail(String email) async {
    try {
      final query = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      log('❌ Error checking user existence by email: $e');
      return false;
    }
  }

  /// Check if user exists by phone number
  Future<bool> userExistsByPhone(String phoneNumber) async {
    try {
      final query = await _usersCollection
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      log('❌ Error checking user existence by phone: $e');
      return false;
    }
  }

  /// Check if referral code exists
  Future<bool> referralCodeExists(String referralCode) async {
    try {
      final query = await _usersCollection
          .where('referralCode', isEqualTo: referralCode)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      log('❌ Error checking referral code existence: $e');
      return false;
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

  /// Soft delete user account (mark as inactive)
  Future<void> softDeleteUser(String userId) async {
    try {
      await updateUserFields(userId, {
        'isActive': false,
        'deletedAt': DateTime.now(),
      });

      log('✅ User soft deleted successfully: $userId');
    } catch (e) {
      log('❌ Error soft deleting user: $e');
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

  /// Generate unique referral code
  String _generateReferralCode(String firstName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final namePrefix = firstName.length >= 3 
        ? firstName.substring(0, 3).toUpperCase()
        : firstName.toUpperCase().padRight(3, 'X');
    final suffix = timestamp.substring(timestamp.length - 4);
    return '$namePrefix$suffix';
  }

  @override
  void onReady() {
    super.onReady();
    log('UserRepository initialized');
  }
}
