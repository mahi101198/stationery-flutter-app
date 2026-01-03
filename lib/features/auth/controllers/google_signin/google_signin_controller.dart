import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rps_stationery/data/repositories/auth/auth_repository.dart';
import 'package:rps_stationery/data/repositories/user/user_repository.dart';
import 'package:rps_stationery/data/models/user_model.dart';
import 'package:rps_stationery/features/auth/widgets/referral_bottom_sheet.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/services/referral_service.dart';
import 'package:rps_stationery/services/notification_service.dart';
import 'package:rps_stationery/utils/popups/loaders.dart';
import 'package:rps_stationery/utils/popups/full_screen_loader.dart';

class GoogleSignInController extends GetxController {
  static GoogleSignInController get instance => Get.find();

  Future<void> signInWithGoogle() async {
    try {
      // Start loading
      FullScreenLoader.openLoadingDialog("Signing in with Google...");

      final userRepository = Get.put(UserRepository());

      // Sign in with Google through AuthRepository
      final userCredential = await AuthRepository.instance.signInWithGoogle();
      final user = userCredential.user;

      if (user == null) {
        FullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(
          title: "Sign-In Error",
          message: "Google Sign-In completed but user information is missing. Please try again.",
        );
        return;
      }

      // Check if user exists in Firestore
      final userExists = await userRepository.userExists(user.uid);

      if (!userExists) {
        // New user - create account with referral code
        await _handleNewGoogleUser(user, userRepository);
      } else {
        // Existing user - direct to home
        FullScreenLoader.stopLoading();
        
        // Show success message
        TLoaders.successSnackBar(
          title: "Welcome Back!",
          message: "Successfully signed in with Google",
        );
        
        Get.offAllNamed(Routes.bottomNav);
      }
    } catch (e) {
      FullScreenLoader.stopLoading();
      
      // Handle specific error messages
      String title = "Google Sign-In Failed";
      String errorMessage;
      
      if (e.toString().contains('cancelled')) {
        title = "Sign-In Cancelled";
        errorMessage = 'Google Sign-In was cancelled';
      } else if (e.toString().contains('network')) {
        title = "Network Error";
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (e.toString().contains('not enabled') || e.toString().contains('not properly configured')) {
        title = "Configuration Error";
        errorMessage = 'Google Sign-In is not properly configured. Please contact support.';
      } else if (e.toString().contains('account already exists') || e.toString().contains('account-exists-with-different-credential')) {
        title = "Account Already Exists";
        errorMessage = 'This email is already registered with a different sign-in method. Please try signing in with email and password instead.';
      } else {
        errorMessage = e.toString();
      }
      
      TLoaders.errorSnackBar(
        title: title, 
        message: errorMessage
      );
    }
  }

  Future<void> _handleNewGoogleUser(user, UserRepository userRepository) async {
    try {
      // Generate unique referral code for new user
      final referralService = Get.put(ReferralService());
      final newUserReferralCode = await referralService.generateReferralCode('temp');

      FullScreenLoader.stopLoading();

      // Show referral bottom sheet
      await showReferralBottomSheet(
        onReferralSubmit: (String? referralCode) async {
          await _createGoogleUserRecord(
            user,
            userRepository,
            newUserReferralCode,
            referralCode,
          );
        },
      );
    } catch (e) {
      FullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: "Error", message: e.toString());
    }
  }

  Future<void> _createGoogleUserRecord(
    user,
    UserRepository userRepository,
    String newUserReferralCode,
    String? referralCode,
  ) async {
    try {
      // Start loading
      FullScreenLoader.openLoadingDialog("Creating account...");

      String? validatedReferralCode;
      String? referrerId;

      // Validate referral code if provided
      if (referralCode != null && referralCode.isNotEmpty) {
        final referralService = Get.put(ReferralService());
        final validation = await referralService.validateReferralCode(referralCode);
        if (!validation.isValid) {
          FullScreenLoader.stopLoading();
          TLoaders.errorSnackBar(
            title: "Invalid Referral Code",
            message: validation.message ?? "The referral code you entered is not valid. Please try again.",
          );

          // Show referral bottom sheet again for retry
          await showReferralBottomSheet(
            onReferralSubmit: (String? retryReferralCode) async {
              await _createGoogleUserRecord(
                user,
                userRepository,
                newUserReferralCode,
                retryReferralCode,
              );
            },
          );
          return;
        } else {
          validatedReferralCode = referralCode;
          referrerId = validation.referrerId; // Get referrer ID from validation result
        }
      }

      // Parse user display name
      final displayName = user.displayName ?? '';
      final nameParts = displayName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : 'User';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Create new user model
      final newUser = UserModel(
        uid: user.uid,
        role: UserRole.customer, // Default role for this app
        firstName: firstName,
        lastName: lastName.isEmpty ? '' : lastName,
        email: user.email ?? '',
        phoneNumber: '', // Empty for Google users, can be updated later
        profilePicture: user.photoURL,
        referralCode: newUserReferralCode,
        referredBy: validatedReferralCode,
        walletBalance: 0.0, // Default wallet balance
        addresses: [], // Empty addresses list
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save user to Firestore
      await userRepository.saveUserRecord(newUser);

      // Update FCM token for the new user immediately
      // This ensures the FCM token is saved right after user creation
      // instead of waiting for the auth state listener delay
      await NotificationService.updateFCMTokenForUser();

      // Create referral record for new user
      final referralService = Get.put(ReferralService());
      await referralService.createReferralRecord(user.uid, newUserReferralCode);

      // Process referral signup bonus if user was referred
      if (validatedReferralCode != null && referrerId != null) {
        try {
          print('🎁 Processing referral signup bonus for Google user...');
          // Process referral signup bonus via Cloud Function
          await referralService.processReferralSignupBonus(user.uid, referrerId);
          print('✅ Referral signup bonus processed successfully for Google user');
        } catch (e) {
          print('❌ Error processing referral signup bonus for Google user: $e');
          // Don't fail the signup if referral bonus fails
        }
      }

      FullScreenLoader.stopLoading();

      // Navigate to home directly without showing success message
      Get.offAllNamed(Routes.bottomNav);
    } catch (e) {
      FullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(
        title: "Error",
        message: "Failed to create account: ${e.toString()}",
      );
    }
  }
}
