import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rps_stationery/services/google_signin_service.dart';
import 'package:rps_stationery/services/notification_service.dart';
import 'package:rps_stationery/features/auth/screens/login/login.dart';
import 'package:rps_stationery/features/auth/screens/onboarding/onboarding.dart';
import 'package:rps_stationery/features/auth/screens/signup/verify_email.dart';
import 'package:rps_stationery/routes/app_pages.dart';
import 'package:rps_stationery/utils/exceptions/firebase_auth_exceptions.dart';
import 'package:rps_stationery/utils/exceptions/format_exceptions.dart';
import 'package:rps_stationery/utils/exceptions/platform_exceptions.dart';

class AuthRepository extends GetxController {
  static AuthRepository get instance => Get.find();

  // Dependencies
  final deviceStorage = GetStorage();
  final _auth = FirebaseAuth.instance;

  // Auth state management
  StreamSubscription<User?>? _authStateSubscription;
  
  // Track if initial auth state has been determined
  bool _initialAuthStateLoaded = false;

  // Current user state
  Rx<User?> firebaseUser = Rx<User?>(null);

  // Simple getters for other parts of the app
  User? get currentUser => firebaseUser.value;
  bool get isAuthenticated => firebaseUser.value != null;
  String get userId => firebaseUser.value?.uid ?? '';
  bool get isEmailVerified => firebaseUser.value?.emailVerified ?? false;

  // Storage keys
  static const String _isFirstLaunchKey = 'VeryFirstLaunch';

  @override
  void onInit() {
    super.onInit();
    // Initialize with current user
    firebaseUser.value = _auth.currentUser;
    // Setup auth state listener
    _setupAuthStateListener();
  }


  /// Setup auth state listener - simple and clean
  void _setupAuthStateListener() {
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      firebaseUser.value = user;
      
      // Update FCM token when user logs in (asynchronously with delay)
      if (user != null) {
        // Use Future.delayed to avoid triggering during rebuild
        Future.delayed(const Duration(milliseconds: 500), () {
          NotificationService.updateFCMTokenForUser();
        });
      }
      
      // Handle initial auth state load
      if (!_initialAuthStateLoaded) {
        _initialAuthStateLoaded = true;
        // Perform initial redirect after auth state is determined
        screenRedirect();
      } else {
        // Handle subsequent auth state changes (login/logout)
        // Only auto redirect if we're not on the initial route and GetX is ready
        if (Get.currentRoute != '/' && Get.context != null) {
          // Add a small delay to prevent rapid redirects
          Future.delayed(const Duration(milliseconds: 100), () {
            if (Get.context != null) {
              screenRedirect();
            }
          });
        }
      }
    });
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    try {
      await _auth.currentUser?.reload();
      firebaseUser.value = _auth.currentUser;
    } catch (e) {
      // Handle refresh errors completely silently
      // Don't print, don't throw, don't notify
      // This prevents any error notifications during email verification process
      // The silent handling is intentional to avoid odd behavior when user clicks verification link
      // Errors here are expected and normal during the verification flow
    }
  }

  /// Simple screen redirect logic
  void screenRedirect() {
    final user = firebaseUser.value;

    if (user != null && !user.isAnonymous) {

      // Wait for GetX to be ready before navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
        if (Get.context != null) {
          // Check if email is verified (skip verification for social logins)
          if (user.emailVerified || _isSocialLogin(user)) {
            Get.offAllNamed(Routes.bottomNav);
          } else {
            Get.offAll(() => VerifyEmailScreen(email: user.email));
          }
        } else {
          // Retry after a short delay if GetX context is not ready
          Future.delayed(const Duration(milliseconds: 100), screenRedirect);
        }
      });
    } else {
      _handleUnauthenticatedUser();
    }
  }

  /// Check if user signed in with social provider
  bool _isSocialLogin(User user) {
    return user.providerData.any(
      (info) =>
          info.providerId == 'google.com' ||
          info.providerId == 'apple.com' ||
          info.providerId == 'facebook.com',
    );
  }

  /// Handle unauthenticated user navigation
  void _handleUnauthenticatedUser() {
    // Wait for GetX to be fully initialized before navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();

      if (Get.context != null) {
        // Write default only if not set
        deviceStorage.writeIfNull(_isFirstLaunchKey, true);

        final bool isFirstLaunch = deviceStorage.read(_isFirstLaunchKey) ?? true;

        if (isFirstLaunch) {
          Get.offAll(() => const OnboardingScreen());
        } else {
          Get.offAll(() => const LoginScreen());
        }
      } else {
        // Retry until context is ready
        Future.delayed(const Duration(milliseconds: 100), _handleUnauthenticatedUser);
      }
    });
  }

  /// Mark onboarding as completed
  void markOnboardingAsCompleted() {
    deviceStorage.write(_isFirstLaunchKey, false);
  }

  /* ---------------------- Email & Password Sign in ---------------------- */

  // Login
  Future<UserCredential> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        throw 'Email and password cannot be empty';
      }
      
      if (!_isValidEmail(email)) {
        throw 'Please enter a valid email address';
      }
      
      if (password.length < 6) {
        throw 'Password must be at least 6 characters long';
      }
      
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
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

  // Register
  Future<UserCredential> registerWithEmailAndPassword(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      // Validate inputs
      if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
        throw 'All fields are required';
      }
      
      if (!_isValidEmail(email)) {
        throw 'Please enter a valid email address';
      }
      
      if (password.length < 6) {
        throw 'Password must be at least 6 characters long';
      }
      
      if (fullName.trim().length < 2) {
        throw 'Full name must be at least 2 characters long';
      }
      
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Update display name using the user from the credential (more reliable)
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(fullName.trim());
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
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

  // Mail verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'No user is currently signed in';
      }
      
      if (user.emailVerified) {
        throw 'Email is already verified';
      }
      
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
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

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      if (email.isEmpty) {
        throw 'Email address is required';
      }
      
      if (!_isValidEmail(email)) {
        throw 'Please enter a valid email address';
      }
      
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw 'No user found with this email address.';
        case 'invalid-email':
          throw 'Please enter a valid email address.';
        case 'too-many-requests':
          throw 'Too many requests. Please try again later.';
        default:
          throw TFirebaseAuthException(e.code).message;
      }
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

  // Anonymous Sign in
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw TFirebaseAuthException(e.code).message;
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

  /* ---------------------- Google Sign in ---------------------- */
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Use the new GoogleSignInService
      final googleSignInService = GoogleSignInService();
      final userCredential = await googleSignInService.signInWithGoogle();
      
      if (userCredential == null) {
        throw 'Google Sign-In was cancelled';
      }
      
      return userCredential;
      
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw 'An account already exists with the same email but different sign-in credentials. Try signing in with a different method.';
        case 'invalid-credential':
          throw 'The credential is invalid or has expired. Please try again.';
        case 'operation-not-allowed':
          throw 'Google Sign-In is not enabled in Firebase Console. Please contact support.';
        case 'user-disabled':
          throw 'The user account has been disabled.';
        case 'user-not-found':
          throw 'No user found for the given credential.';
        case 'wrong-password':
          throw 'Wrong password provided.';
        case 'too-many-requests':
          throw 'Too many unsuccessful sign-in attempts. Please try again later.';
        case 'app-not-authorized':
          throw 'This app is not authorized for Google Sign-In. Please check Firebase Console configuration.';
        case 'web-storage-unsupported':
          throw 'Web storage is not supported. Please enable cookies and try again.';
        default:
          throw 'Google Sign-In failed: ${e.message ?? "Unknown Firebase error occurred"}';
      }
    } on FirebaseException catch (e) {
      throw 'Firebase error: ${e.message ?? "Unknown Firebase error"}';
    } on PlatformException catch (e) {
      // Handle Google Sign-In specific errors
      switch (e.code) {
        case 'sign_in_failed':
          throw 'Google Sign-In failed. Please check your internet connection and try again.';
        case 'network_error':
          throw 'Network error occurred. Please check your internet connection.';
        case 'sign_in_canceled':
          throw 'Google Sign-In was cancelled';
        case 'sign_in_required':
          throw 'Google Sign-In is required but user is not signed in.';
        default:
          throw 'Platform error: ${e.message ?? "Unknown platform error"}';
      }
    } catch (e) {
      if (e.toString().contains('PlatformException')) {
        throw 'Google Sign-In service is not available. Please try again later.';
      } else if (e.toString().contains('cancelled')) {
        throw 'Google Sign-In was cancelled';
      } else {
        throw 'Google Sign-In failed: ${e.toString()}';
      }
    }
  }

  /* ---------------------- Sign out ---------------------- */

  /// Simple sign out - let auth state listener handle the redirect
  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();

      // Sign out from Google if applicable
      try {
        final googleSignInService = GoogleSignInService();
        await googleSignInService.signOut();
      } catch (e) {
        // Google signout error is non-critical
      }

      // Mark that user is no longer on first launch
      deviceStorage.write(_isFirstLaunchKey, false);

      // Auth state listener will handle the redirect automatically
    } catch (e) {
      // Force manual redirect if signout fails
      _handleUnauthenticatedUser();
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  void onClose() {
    _authStateSubscription?.cancel();
    super.onClose();
  }
}
