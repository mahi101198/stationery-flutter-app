import 'package:flutter/material.dart';

/// Comprehensive form validation utilities
class FormValidators {
  FormValidators._();

  /// Email validation with comprehensive checks
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final email = value.trim();
    
    if (email.length < 5) {
      return 'Email must be at least 5 characters long';
    }

    if (email.length > 254) {
      return 'Email is too long (maximum 254 characters)';
    }

    // Comprehensive email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$'
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    // Check for common typos in domain
    final domain = email.split('@').last.toLowerCase();
    
    // More precise Gmail typo detection
    if (domain == 'gmial.com' || domain == 'gmai.com' || domain == 'gmaill.com' || 
        domain == 'gmail.co' || domain == 'gmail.cm' || domain == 'gmail.coom') {
      return 'Did you mean gmail.com?';
    }
    
    // Check for other common domain typos
    if (domain == 'yahooo.com' || domain == 'yahoo.co' || domain == 'yahoo.cm') {
      return 'Did you mean yahoo.com?';
    }
    
    if (domain == 'hotmial.com' || domain == 'hotmai.com' || domain == 'hotmail.co') {
      return 'Did you mean hotmail.com?';
    }
    
    if (domain == 'outlok.com' || domain == 'outlook.co' || domain == 'outlook.cm') {
      return 'Did you mean outlook.com?';
    }

    return null;
  }

  /// Password validation with strength requirements
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    if (value.length > 128) {
      return 'Password is too long (maximum 128 characters)';
    }

    // Check for common weak passwords
    final weakPasswords = ['password', '123456', 'qwerty', 'abc123', 'password123'];
    if (weakPasswords.contains(value.toLowerCase())) {
      return 'Please choose a stronger password';
    }

    return null;
  }

  /// Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Name validation (first name, last name, full name)
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final name = value.trim();

    if (name.length < 2) {
      return '$fieldName must be at least 2 characters long';
    }

    if (name.length > 50) {
      return '$fieldName is too long (maximum 50 characters)';
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(name)) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }

    // Check for multiple consecutive spaces
    if (name.contains('  ')) {
      return '$fieldName cannot contain multiple consecutive spaces';
    }

    return null;
  }

  /// Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final phone = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (phone.length < 10) {
      return 'Phone number must be at least 10 digits long';
    }

    if (phone.length > 15) {
      return 'Phone number is too long (maximum 15 digits)';
    }

    // Check if it contains only digits and optional + at start
    final phoneRegex = RegExp(r'^\+?[0-9]+$');
    if (!phoneRegex.hasMatch(phone)) {
      return 'Phone number can only contain digits and optional + at the beginning';
    }

    return null;
  }

  /// Address validation
  static String? validateAddress(String? value, {String fieldName = 'Address'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final address = value.trim();

    if (address.length < 5) {
      return '$fieldName must be at least 5 characters long';
    }

    if (address.length > 200) {
      return '$fieldName is too long (maximum 200 characters)';
    }

    return null;
  }

  /// Pincode validation (Indian format)
  static String? validatePincode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Pincode is required';
    }

    final pincode = value.trim();

    if (pincode.length != 6) {
      return 'Pincode must be exactly 6 digits';
    }

    final pincodeRegex = RegExp(r'^[0-9]{6}$');
    if (!pincodeRegex.hasMatch(pincode)) {
      return 'Pincode must contain only digits';
    }

    return null;
  }

  /// City validation
  static String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'City is required';
    }

    final city = value.trim();

    if (city.length < 2) {
      return 'City must be at least 2 characters long';
    }

    if (city.length > 50) {
      return 'City is too long (maximum 50 characters)';
    }

    final cityRegex = RegExp(r'^[a-zA-Z\s\-\.]+$');
    if (!cityRegex.hasMatch(city)) {
      return 'City can only contain letters, spaces, hyphens, and dots';
    }

    return null;
  }

  /// State validation
  static String? validateState(String? value) {
    if (value == null || value.isEmpty) {
      return 'State is required';
    }

    final state = value.trim();

    if (state.length < 2) {
      return 'State must be at least 2 characters long';
    }

    if (state.length > 50) {
      return 'State is too long (maximum 50 characters)';
    }

    final stateRegex = RegExp(r'^[a-zA-Z\s\-\.]+$');
    if (!stateRegex.hasMatch(state)) {
      return 'State can only contain letters, spaces, hyphens, and dots';
    }

    return null;
  }

  /// Quantity validation
  static String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }

    final quantity = int.tryParse(value);
    if (quantity == null) {
      return 'Please enter a valid number';
    }

    if (quantity <= 0) {
      return 'Quantity must be greater than 0';
    }

    if (quantity > 999) {
      return 'Quantity cannot exceed 999';
    }

    return null;
  }

  /// Promo code validation
  static String? validatePromoCode(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Promo code is optional
    }

    final code = value.trim();

    if (code.length < 3) {
      return 'Promo code must be at least 3 characters long';
    }

    if (code.length > 20) {
      return 'Promo code is too long (maximum 20 characters)';
    }

    final codeRegex = RegExp(r'^[A-Z0-9]+$');
    if (!codeRegex.hasMatch(code)) {
      return 'Promo code can only contain uppercase letters and numbers';
    }

    return null;
  }

  /// Search query validation
  static String? validateSearchQuery(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a search term';
    }

    final query = value.trim();

    if (query.length < 2) {
      return 'Search term must be at least 2 characters long';
    }

    if (query.length > 100) {
      return 'Search term is too long (maximum 100 characters)';
    }

    return null;
  }

  /// Generic required field validation
  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.trim().isEmpty) {
      return '$fieldName cannot be empty';
    }

    return null;
  }

  /// Generic text length validation
  static String? validateTextLength(
    String? value, {
    int minLength = 1,
    int maxLength = 100,
    String fieldName = 'Text',
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final text = value.trim();

    if (text.length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }

    if (text.length > maxLength) {
      return '$fieldName is too long (maximum $maxLength characters)';
    }

    return null;
  }

  /// Validate form submission
  static bool validateForm(GlobalKey<FormState> formKey) {
    if (formKey.currentState == null) {
      return false;
    }

    return formKey.currentState!.validate();
  }

  /// Clear form fields
  static void clearForm(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.clear();
    }
  }

  /// Get form data as map
  static Map<String, String> getFormData(List<TextEditingController> controllers, List<String> fieldNames) {
    final Map<String, String> data = {};
    
    for (int i = 0; i < controllers.length && i < fieldNames.length; i++) {
      data[fieldNames[i]] = controllers[i].text.trim();
    }
    
    return data;
  }
}

/// Extension for easy validation
extension FormValidationExtension on String? {
  String? validateEmail() => FormValidators.validateEmail(this);
  String? validatePassword() => FormValidators.validatePassword(this);
  String? validateName({String fieldName = 'Name'}) => FormValidators.validateName(this, fieldName: fieldName);
  String? validatePhoneNumber() => FormValidators.validatePhoneNumber(this);
  String? validateAddress({String fieldName = 'Address'}) => FormValidators.validateAddress(this, fieldName: fieldName);
  String? validatePincode() => FormValidators.validatePincode(this);
  String? validateCity() => FormValidators.validateCity(this);
  String? validateState() => FormValidators.validateState(this);
  String? validateQuantity() => FormValidators.validateQuantity(this);
  String? validatePromoCode() => FormValidators.validatePromoCode(this);
  String? validateSearchQuery() => FormValidators.validateSearchQuery(this);
  String? validateRequired({String fieldName = 'This field'}) => FormValidators.validateRequired(this, fieldName: fieldName);
}
