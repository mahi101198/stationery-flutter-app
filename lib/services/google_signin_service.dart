import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rps_stationery/config/firebase_config.dart';

class GoogleSignInService {
  static const String _webClientId = FirebaseConfig.webOAuthClientId;
  
  // Singleton pattern
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();
  
  // Google Sign-In instance with proper configuration
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    // This is crucial - ensures ID tokens are generated
    serverClientId: _webClientId,
  );
  
  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null;
      }
      
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Verify tokens are present
      if (googleAuth.idToken == null) {
        throw Exception('ID Token is null - OAuth client configuration issue');
      }
      
      if (googleAuth.accessToken == null) {
        throw Exception('Access Token is null - OAuth client configuration issue');
      }
      
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken!,
        idToken: googleAuth.idToken!,
      );
      
      // Once signed in, return the UserCredential
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      
      return userCredential;
      
    } catch (e) {
      rethrow;
    }
  }
  
  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Check if user is currently signed in with Google
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }
  
  /// Get current Google user
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
  
  /// Get current Firebase user
  User? get currentFirebaseUser => FirebaseAuth.instance.currentUser;
  
  /// Disconnect the Google account (revoke access)
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      rethrow;
    }
  }
}
