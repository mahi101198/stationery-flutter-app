import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../../data/repositories/auth/auth_repository.dart';
import '../../../../utils/helpers/network_manager.dart';
import '../../../../utils/popups/full_screen_loader.dart';
import '../../../../utils/popups/loaders.dart';
import '../../../../utils/validators/form_validators.dart';
import '../google_signin/google_signin_controller.dart';
import '../../../../data/repositories/user/user_repository.dart';
import '../../screens/password_reset_success/password_reset_success_screen.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();

  // Variables
  final localStorage = GetStorage();
  final hidePassword = true.obs;
  final isLoading = false.obs;
  final rememberMe = false.obs;
  final email = TextEditingController();
  final password = TextEditingController();
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  // Storage keys
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';

  @override
  void onInit() {
    super.onInit();
    loadSavedCredentials();
  }

  /// Load saved credentials if remember me is enabled
  void loadSavedCredentials() {
    final isRemembered = localStorage.read(_rememberMeKey) ?? false;
    rememberMe.value = isRemembered;
    
    if (isRemembered) {
      final savedEmail = localStorage.read(_savedEmailKey) ?? '';
      final savedPassword = localStorage.read(_savedPasswordKey) ?? '';
      
      if (savedEmail.isNotEmpty) {
        email.text = savedEmail;
      }
      if (savedPassword.isNotEmpty) {
        password.text = savedPassword;
      }
    }
  }

  /// Save credentials if remember me is enabled
  void saveCredentials() {
    localStorage.write(_rememberMeKey, rememberMe.value);
    
    if (rememberMe.value) {
      localStorage.write(_savedEmailKey, email.text.trim());
      localStorage.write(_savedPasswordKey, password.text);
    } else {
      localStorage.remove(_savedEmailKey);
      localStorage.remove(_savedPasswordKey);
    }
  }

  /// Toggle remember me checkbox
  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
    if (!rememberMe.value) {
      // Clear saved credentials when unchecked
      localStorage.remove(_savedEmailKey);
      localStorage.remove(_savedPasswordKey);
    }
  }

  /// Forgot Password functionality
  Future<void> forgotPassword(String email) async {
    try {
      // Start loading
      FullScreenLoader.openLoadingDialog("Sending reset email...");

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

      // Validate email using FormValidators for consistency
      final emailError = FormValidators.validateEmail(email);
      if (emailError != null) {
        FullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(title: "Invalid Email", message: emailError);
        return;
      }

      // Send reset email
      await AuthRepository.instance.sendPasswordResetEmail(email.trim());

      // Remove loader
      FullScreenLoader.stopLoading();

      // Navigate to success screen
      Get.to(() => PasswordResetSuccessScreen(email: email.trim()));
    } catch (e) {
      FullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: "Error", message: e.toString());
    }
  }

  Future<void> login() async {
    try {
      // Start loading
      isLoading.value = true;
      FullScreenLoader.openLoadingDialog("Signing in...");

      // Check internet connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        isLoading.value = false;
        FullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(
          title: "No Internet",
          message: "Please check your internet connection and try again.",
        );
        return;
      }

      // Form Validation
      if (!FormValidators.validateForm(loginFormKey)) {
        isLoading.value = false;
        FullScreenLoader.stopLoading();
        return;
      }

      // Additional validation
      final emailError = FormValidators.validateEmail(email.text);
      if (emailError != null) {
        isLoading.value = false;
        FullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(title: "Invalid Email", message: emailError);
        return;
      }

      final passwordError = FormValidators.validatePassword(password.text);
      if (passwordError != null) {
        isLoading.value = false;
        FullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(title: "Invalid Password", message: passwordError);
        return;
      }

      // Save credentials if remember me is checked
      saveCredentials();

      // Login user
      final userCredential = await AuthRepository.instance.loginWithEmailAndPassword(
        email.text.trim(),
        password.text,
      );

      // Ensure user document exists in Firestore
      if (userCredential.user != null) {
        final userRepository = Get.put(UserRepository());
        final userExists = await userRepository.userExists(userCredential.user!.uid);
        
        if (!userExists) {
          // Create user document for email/password users
          final displayName = userCredential.user!.displayName ?? '';
          final nameParts = displayName.split(' ');
          final firstName = nameParts.isNotEmpty ? nameParts.first : 'User';
          final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
          
          await userRepository.createUser(
            uid: userCredential.user!.uid,
            firstName: firstName.isEmpty ? 'User' : firstName,
            lastName: lastName,
            email: userCredential.user!.email ?? email.text,
            phoneNumber: userCredential.user!.phoneNumber ?? '',
          );
        }
      }

      // Remove loader
      isLoading.value = false;
      FullScreenLoader.stopLoading();

      // Redirect
      AuthRepository.instance.screenRedirect();
    } catch (e) {
      isLoading.value = false;
      FullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: "Oh snap!", message: e.toString());
    }
  }

  Future<void> googleSignIn() async {
    try {
      // Check internet connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TLoaders.errorSnackBar(
          title: "No Internet",
          message: "Please check your internet connection and try again.",
        );
        return;
      }

      // Use the Google sign-in controller with referral logic
      final googleController = Get.put(GoogleSignInController());
      await googleController.signInWithGoogle();
    } catch (e) {
      TLoaders.errorSnackBar(title: "Oh snap!", message: e.toString());
    }
  }
}
