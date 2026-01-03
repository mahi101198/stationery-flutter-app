import 'dart:developer';
import 'package:firebase_storage/firebase_storage.dart';

/// Helper class for Firebase Storage operations
/// Provides methods to handle Firebase Storage URLs with proper error handling
class FirebaseStorageHelper {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Get download URL for a Firebase Storage file with proper error handling
  /// 
  /// [storagePath] - The path to the file in Firebase Storage (e.g., 'banner/banner2.jpg')
  /// Returns the download URL or null if failed
  static Future<String?> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      final downloadUrl = await ref.getDownloadURL();
      log('Firebase Storage URL obtained for $storagePath: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      log('Firebase Storage error for $storagePath: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      log('Unexpected error getting download URL for $storagePath: $e');
      return null;
    }
  }

  /// Validate if a URL is a Firebase Storage URL
  static bool isFirebaseStorageUrl(String url) {
    return url.contains('firebasestorage.googleapis.com') || 
           url.contains('firebase.google.com');
  }

  /// Extract the storage path from a Firebase Storage URL
  /// 
  /// Example: 
  /// Input: "https://firebasestorage.googleapis.com/v0/b/project.appspot.com/o/banner%2Fbanner2.jpg?alt=media"
  /// Output: "banner/banner2.jpg"
  static String? extractStoragePathFromUrl(String firebaseUrl) {
    try {
      final uri = Uri.parse(firebaseUrl);
      if (!uri.pathSegments.contains('o')) return null;
      
      final oIndex = uri.pathSegments.indexOf('o');
      if (oIndex == -1 || oIndex >= uri.pathSegments.length - 1) return null;
      
      final encodedPath = uri.pathSegments[oIndex + 1];
      return Uri.decodeComponent(encodedPath);
    } catch (e) {
      log('Error extracting storage path from URL: $e');
      return null;
    }
  }

  /// Get a fresh download URL for a Firebase Storage URL that might be expired
  /// This is useful when getting 412 errors which might indicate token issues
  static Future<String?> refreshFirebaseStorageUrl(String originalUrl) async {
    try {
      if (!isFirebaseStorageUrl(originalUrl)) {
        // Not a Firebase Storage URL, return as is
        return originalUrl;
      }

      final storagePath = extractStoragePathFromUrl(originalUrl);
      if (storagePath == null) {
        log('Could not extract storage path from URL: $originalUrl');
        return originalUrl; // Return original URL as fallback
      }

      final freshUrl = await getDownloadUrl(storagePath);
      return freshUrl ?? originalUrl; // Return fresh URL or original as fallback
    } catch (e) {
      log('Error refreshing Firebase Storage URL: $e');
      return originalUrl; // Return original URL as fallback
    }
  }

  /// Configure Firebase Storage settings for better compatibility
  static void configureFirebaseStorage() {
    try {
      // Set longer timeout for downloads
      _storage.setMaxDownloadRetryTime(const Duration(seconds: 30));
      _storage.setMaxUploadRetryTime(const Duration(seconds: 30));
      _storage.setMaxOperationRetryTime(const Duration(seconds: 30));
      
      log('Firebase Storage configured successfully');
    } catch (e) {
      log('Error configuring Firebase Storage: $e');
    }
  }

  /// Check if Firebase Storage is accessible
  static Future<bool> testStorageConnectivity() async {
    try {
      // Try to get the root reference to test connectivity
      final rootRef = _storage.ref();
      
      // Try a simple operation to test if we can connect
      await rootRef.listAll().timeout(const Duration(seconds: 10));
      log('Firebase Storage connectivity test: SUCCESS');
      return true;
    } on FirebaseException catch (e) {
      log('Firebase Storage connectivity test failed: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      log('Firebase Storage connectivity test failed with unexpected error: $e');
      return false;
    }
  }

  /// Get Firebase Storage bucket info for debugging
  static Map<String, String> getStorageInfo() {
    return {
      'bucket': _storage.bucket,
      'app': _storage.app.name,
      'maxDownloadRetryTime': _storage.maxDownloadRetryTime.toString(),
      'maxUploadRetryTime': _storage.maxUploadRetryTime.toString(),
      'maxOperationRetryTime': _storage.maxOperationRetryTime.toString(),
    };
  }
}
