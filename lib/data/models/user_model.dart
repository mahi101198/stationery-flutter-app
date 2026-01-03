import 'package:cloud_firestore/cloud_firestore.dart';

/// User role enum following enterprise schema
enum UserRole { customer, admin, delivery_agent }

/// Address type enum
enum AddressType { independentHouse, apartment, office }

/// User address model as per enterprise schema
class UserAddress {
  final String addressId;
  final String label;
  final String line1;
  final String line2;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final bool isDefault;
  final AddressType? addressType;
  final String? recepientDetails;
  final String? phoneNumber;
  final String? email;
  final String? mobileNumber;        // ✅ User's mobile number
  final String? alternateNumber;     // ✅ Optional alternate number
  final String? landmark;            // ✅ Optional landmark

  // Convenience getters for legacy compatibility
  String get id => addressId;
  String get addressLabel => label;
  String get address => formattedAddress; // Alias for formattedAddress
  String get formattedAddress => '$line1, $line2, $city, $state - $pincode';
  String get field1 => line1;
  String get field2 => line2;
  String? get field3 => null; // Not used in current schema
  String get name => recepientDetails ?? '';

  const UserAddress({
    required this.addressId,
    required this.label,
    required this.line1,
    required this.line2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
    required this.isDefault,
    this.addressType,
    this.recepientDetails,
    this.phoneNumber,
    this.email,
    this.mobileNumber,        // ✅ User's mobile number
    this.alternateNumber,     // ✅ Optional alternate number
    this.landmark,            // ✅ Optional landmark
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'addressId': addressId,
      'label': label,
      'line1': line1,
      'line2': line2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
      'isDefault': isDefault,
      'addressType': addressType?.name,
      'recepientDetails': recepientDetails,
      'phoneNumber': phoneNumber,
      'email': email,
      'mobileNumber': mobileNumber,        // ✅ User's mobile number
      'alternateNumber': alternateNumber,  // ✅ Optional alternate number
      'landmark': landmark,                // ✅ Optional landmark
    };
  }

  /// Create from Firestore document
  factory UserAddress.fromFirestore(Map<String, dynamic> data) {
    return UserAddress(
      addressId: data['addressId'] ?? '',
      label: data['label'] ?? '',
      line1: data['line1'] ?? '',
      line2: data['line2'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      pincode: data['pincode'] ?? '',
      country: data['country'] ?? 'India',
      isDefault: data['isDefault'] ?? false,
      addressType: UserAddress._parseAddressType(data['addressType']),
      recepientDetails: data['recepientDetails'],
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      mobileNumber: data['mobileNumber'],        // ✅ User's mobile number
      alternateNumber: data['alternateNumber'],  // ✅ Optional alternate number
      landmark: data['landmark'],                // ✅ Optional landmark
    );
  }

  /// Create copy with optional parameter overrides
  UserAddress copyWith({
    String? addressId,
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
    String? email,
    String? mobileNumber,        // ✅ User's mobile number
    String? alternateNumber,     // ✅ Optional alternate number
    String? landmark,            // ✅ Optional landmark
  }) {
    return UserAddress(
      addressId: addressId ?? this.addressId,
      label: label ?? this.label,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
      addressType: addressType ?? this.addressType,
      recepientDetails: recepientDetails ?? this.recepientDetails,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,        // ✅ User's mobile number
      alternateNumber: alternateNumber ?? this.alternateNumber, // ✅ Optional alternate number
      landmark: landmark ?? this.landmark,                    // ✅ Optional landmark
    );
  }

  /// Helper method to parse address type
  static AddressType? _parseAddressType(dynamic type) {
    if (type == null) return null;
    
    switch (type.toString().toLowerCase()) {
      case 'independenthouse':
        return AddressType.independentHouse;
      case 'apartment':
        return AddressType.apartment;
      case 'office':
        return AddressType.office;
      default:
        return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAddress &&
          runtimeType == other.runtimeType &&
          addressId == other.addressId;

  @override
  int get hashCode => addressId.hashCode;
}

/// Main user model following enterprise schema
class UserModel {
  final String uid;
  final UserRole role;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String? profilePicture;
  final String referralCode;
  final String? referredBy;
  final double walletBalance;
  final List<UserAddress> addresses;
  final String? fcmToken;  // ✅ FCM token for push notifications
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.profilePicture,
    required this.referralCode,
    this.referredBy,
    required this.walletBalance,
    required this.addresses,
    this.fcmToken,  // ✅ FCM token for push notifications
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get full name
  String get fullName => '$firstName $lastName';

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'role': role.name,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profilePicture': profilePicture,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'walletBalance': walletBalance,
      'addresses': addresses.map((addr) => addr.toFirestore()).toList(),
      'fcmToken': fcmToken,  // ✅ FCM token for push notifications
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return UserModel(
      uid: doc.id,
      role: _parseUserRole(data['role']),
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      profilePicture: data['profilePicture'],
      referralCode: data['referralCode'] ?? '',
      referredBy: data['referredBy'],
      walletBalance: (data['walletBalance'] ?? 0.0).toDouble(),
      addresses: _parseAddresses(data['addresses']),
      fcmToken: data['fcmToken'],  // ✅ FCM token for push notifications
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  /// Create copy with optional parameter overrides
  UserModel copyWith({
    String? uid,
    UserRole? role,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? profilePicture,
    String? referralCode,
    String? referredBy,
    double? walletBalance,
    List<UserAddress>? addresses,
    String? fcmToken,  // ✅ FCM token for push notifications
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      walletBalance: walletBalance ?? this.walletBalance,
      addresses: addresses ?? this.addresses,
      fcmToken: fcmToken ?? this.fcmToken,  // ✅ FCM token for push notifications
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper method to parse user role
  static UserRole _parseUserRole(dynamic role) {
    if (role == null) return UserRole.customer;
    
    switch (role.toString().toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'delivery_agent':
        return UserRole.delivery_agent;
      default:
        return UserRole.customer;
    }
  }

  /// Helper method to parse addresses
  static List<UserAddress> _parseAddresses(dynamic addressesData) {
    if (addressesData == null || addressesData is! List) {
      return [];
    }

    return addressesData
        .whereType<Map<String, dynamic>>()
        .map((addr) => UserAddress.fromFirestore(addr))
        .toList();
  }

  /// Helper method to parse timestamp
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    }
    
    return DateTime.now();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
