import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/repositories/auth/auth_repository.dart';
import 'package:rps_stationery/data/repositories/user/user_repository.dart';
import 'package:rps_stationery/data/models/user_model.dart';
import 'package:rps_stationery/utils/helpers/network_manager.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';
import 'package:rps_stationery/utils/validators/form_validators.dart';
import 'package:rps_stationery/services/referral_service.dart';
import '../google_signin/google_signin_controller.dart';

import '../../../../utils/popups/full_screen_loader.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();

  // Variables
  final hidePassword = true.obs;
  final hideConfirmPassword = true.obs;
  final privacyPolicy = false.obs;
  final email = TextEditingController();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final referralCode = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  Future<void> signup() async {
    try {
      // Start loading
      FullScreenLoader.openLoadingDialog("Signing up...");

      // Check internet connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        FullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(
          title: "No Internet",
          message: "Please check your internet connection and try again.",
        );
        return;
      }

      // Form Validation
      if (!FormValidators.validateForm(signupFormKey)) {
        FullScreenLoader.stopLoading();
        return;
      }

      // Comprehensive field validation
      final firstNameError = FormValidators.validateName(firstName.text, fieldName: 'First name');
      if (firstNameError != null) {
        FullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(title: "Invalid First Name", message: firstNameError);
        return;
      }

      final lastNameError = FormValidators.validateName(lastName.text, fieldName: 'Last name');
      if (lastNameError != null) {
        FullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(title: "Invalid Last Name", message: lastNameError);
        return;
      }

      final emailError = FormValidators.validateEmail(email.text);
      if (emailError != null) {
        FullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(title: "Invalid Email", message: emailError);
        return;
      }

      final passwordError = FormValidators.validatePassword(password.text);
      if (passwordError != null) {
        FullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(title: "Invalid Password", message: passwordError);
        return;
      }

      final confirmPasswordError = FormValidators.validateConfirmPassword(confirmPassword.text, password.text);
      if (confirmPasswordError != null) {
        FullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(title: "Password Mismatch", message: confirmPasswordError);
        return;
      }

      // Privacy Policy check
      if (!privacyPolicy.value) {
        FullScreenLoader.stopLoading();
        TLoaders.warningSnackBar(
          title: "Please accept privacy policy",
          message:
              "In order to create account, you must accept our privacy policy and terms of use.",
        );
        return;
      }

      final userRepository = Get.put(UserRepository());
      final referralService = Get.put(ReferralService());

      // Validate referral code if provided
      String? referredByUserId;
      
      if (referralCode.text.trim().isNotEmpty) {
        print('🔍 Validating referral code: ${referralCode.text}');
        final validation = await referralService.validateReferralCode(referralCode.text.trim());
        
        if (validation.isValid) {
          referredByUserId = validation.referrerId;
          print('✅ Valid referral code from user: $referredByUserId');
        } else {
          FullScreenLoader.stopLoading();
          TLoaders.warningSnackBar(
            title: "Invalid Referral Code",
            message: validation.message ?? "The referral code you entered is invalid",
          );
          return;
        }
      }

      // Generate referral code for new user
      final newUserReferralCode = await referralService.generateReferralCode('temp');

      // Register user
      final fullName = "${firstName.text} ${lastName.text}".trim();
      
      final user = await AuthRepository.instance.registerWithEmailAndPassword(
        fullName,
        email.text,
        password.text,
      );

      final newUserId = user.user!.uid;

      // Save to firestore
      final newUser = UserModel(
        uid: newUserId,
        role: UserRole.customer, // Default role for this app
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        email: email.text.trim(),
        phoneNumber: '', // Empty for email signup, can be updated later
        profilePicture: '',
        referralCode: newUserReferralCode,
        referredBy: referredByUserId,
        walletBalance: 0.0, // Will be updated if referred
        addresses: [], // Empty addresses list
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await userRepository.saveUserRecord(newUser);

      // Create referral record for new user
      await referralService.createReferralRecord(newUserId, newUserReferralCode);

      // Process referral signup bonus if user was referred
      if (referredByUserId != null) {
        try {
          print('🎁 Processing referral signup bonus...');
          // Process referral signup bonus via Cloud Function
          await referralService.processReferralSignupBonus(newUserId, referredByUserId);
          print('✅ Referral signup bonus processed successfully');
        } catch (e) {
          print('❌ Error processing referral signup bonus: $e');
          // Don't fail the signup if referral bonus fails
        }
      }

      FullScreenLoader.stopLoading();

      // Navigate directly without showing success message
      await Future.delayed(Duration(milliseconds: 500));
      AuthRepository.instance.screenRedirect();
    } catch (e) {
      FullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: "Oh snap!", message: e.toString());
    }
  }

  Future<void> googleSignIn() async {
    // Use the Google sign-in controller with referral logic
    // The GoogleSignInController and AuthRepository handle all error cases properly
    // including network errors, existing accounts, and other authentication issues
    final googleController = Get.put(GoogleSignInController());
    await googleController.signInWithGoogle();
  }
}
