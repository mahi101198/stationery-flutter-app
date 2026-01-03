import 'package:rps_stationery/data/models/order_model.dart' as enterprise;
import 'package:rps_stationery/data/models/user_model.dart' as user_schema;

/// Adapter class to convert between legacy AddressModel and enterprise DeliveryAddress
class AddressAdapter {
  
  /// Convert legacy AddressModel to enterprise DeliveryAddress
  static enterprise.DeliveryAddress toEnterprise(user_schema.UserAddress addressModel) {
    return enterprise.DeliveryAddress(
      addressId: addressModel.id,
      label: addressModel.addressLabel,
      line1: addressModel.field1, // House No / Flat No / Building No
      line2: addressModel.field2, // Colony / Building Name / Area  
      city: addressModel.city,
      state: addressModel.state,
      pincode: addressModel.pincode,
      country: 'India', // Default country
      mobileNumber: addressModel.mobileNumber ?? '',  // ✅ User's mobile number
      alternateNumber: addressModel.alternateNumber,  // ✅ Optional alternate number
      landmark: addressModel.landmark,                // ✅ Optional landmark
      recipientName: addressModel.recepientDetails,  // ✅ Recipient's name for delivery
    );
  }
  
  /// Convert enterprise DeliveryAddress to legacy AddressModel
  static user_schema.UserAddress toLegacy(enterprise.DeliveryAddress deliveryAddress) {
    return user_schema.UserAddress(
      addressId: deliveryAddress.addressId,
      label: deliveryAddress.label,
      line1: deliveryAddress.line1,
      line2: deliveryAddress.line2,
      city: deliveryAddress.city,
      state: deliveryAddress.state,
      pincode: deliveryAddress.pincode,
      country: deliveryAddress.country,
      isDefault: false,
    );
  }
  
  /// Create enterprise DeliveryAddress with minimal required fields
  static enterprise.DeliveryAddress createMinimal({
    required String addressId,
    required String label,
    required String line1,
    required String line2,
    required String city,
    required String state,
    required String pincode,
    String country = 'India',
    String mobileNumber = '',  // ✅ Default empty mobile number
    String? alternateNumber,    // ✅ Optional alternate number
    String? landmark,           // ✅ Optional landmark
    String? recipientName,      // ✅ Optional recipient name
  }) {
    return enterprise.DeliveryAddress(
      addressId: addressId,
      label: label,
      line1: line1,
      line2: line2,
      city: city,
      state: state,
      pincode: pincode,
      country: country,
      mobileNumber: mobileNumber,        // ✅ User's mobile number
      alternateNumber: alternateNumber,  // ✅ Optional alternate number
      landmark: landmark,                // ✅ Optional landmark
      recipientName: recipientName,      // ✅ Optional recipient name
    );
  }
  
  /// Batch convert list of AddressModel to DeliveryAddress
  static List<enterprise.DeliveryAddress> batchToEnterprise(
    List<user_schema.UserAddress> addresses,
  ) {
    return addresses.map((address) => toEnterprise(address)).toList();
  }
  
  /// Batch convert list of DeliveryAddress to AddressModel
  static List<user_schema.UserAddress> batchToLegacy(
    List<enterprise.DeliveryAddress> addresses,
  ) {
    return addresses.map((address) => toLegacy(address)).toList();
  }
}
