import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

/// Service to handle Firebase initialization and automatic authentication
class FirebaseInitService extends GetxService {
  static FirebaseInitService get instance => Get.find();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize Firebase services without automatic authentication
  Future<void> initialize() async {
    try {
      log('Initializing Firebase services...', name: 'FirebaseInitService');
      
      // Check if user is already authenticated
      final currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        log('User already authenticated: ${currentUser.uid}', name: 'FirebaseInitService');
        return;
      }
      
      // Don't sign in anonymously automatically - let user choose their auth method
      log('No authenticated user found - user will need to sign in manually', name: 'FirebaseInitService');
      
    } catch (e) {
      log('Error initializing Firebase services: $e', name: 'FirebaseInitService');
      // Don't throw error - app should continue to work
    }
  }
  
  /// Check if current user is anonymous
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;
  
  /// Convert anonymous user to permanent user with email/password
  Future<UserCredential?> linkWithEmailAndPassword(String email, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || !user.isAnonymous) {
        throw Exception('No anonymous user to link');
      }
      
      final credential = EmailAuthProvider.credential(email: email, password: password);
      return await user.linkWithCredential(credential);
    } catch (e) {
      log('Error linking anonymous user with email/password: $e', name: 'FirebaseInitService');
      rethrow;
    }
  }
}
