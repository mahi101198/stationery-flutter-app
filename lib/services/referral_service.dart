import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/models/referral_model.dart';
import 'package:rps_stationery/services/app_settings_service.dart';

/// Referral validation result
class ReferralValidationResult {
  final bool isValid;
  final String? message;
  final ReferralModel? referral;
  final String? referrerId;

  const ReferralValidationResult({
    required this.isValid,
    this.message,
    this.referral,
    this.referrerId,
  });
}

/// Referral Service for managing referral codes and rewards
class ReferralService extends GetxService {
  static ReferralService get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AppSettingsService _appSettings = AppSettingsService.instance;

  // Reward amounts - now loaded from AppSettingsService
  double get referrerReward => _appSettings.referrerReward;
  double get refereeReward => _appSettings.refereeReward;

  /// Generate unique referral code
  Future<String> generateReferralCode(String userId) async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    
    while (true) {
      // Generate code like "USE2934"
      final code = 'USE${List.generate(4, (_) => chars[random.nextInt(chars.length)]).join()}';
      
      // Check if code already exists
      final exists = await _referralCodeExists(code);
      if (!exists) {
        return code;
      }
    }
  }

  /// Check if referral code exists
  Future<bool> _referralCodeExists(String code) async {
    final snapshot = await _firestore
        .collection('referrals')
        .where('referralCode', isEqualTo: code)
        .limit(1)
        .get();
    
    return snapshot.docs.isNotEmpty;
  }

  /// Create referral record for user
  Future<void> createReferralRecord(String userId, String referralCode) async {
    try {
      print('📝 Creating referral record for user: $userId');
      
      await _firestore.collection('referrals').doc(userId).set({
        'userId': userId,
        'referrerUserId': userId,
        'referredUserId': null,
        'referralCode': referralCode,
        'status': 'pending',
        'rewardStatus': 'pending',
        'rewardAmount': referrerReward,
        'totalEarnings': 0,
        'pendingEarnings': 0,
        'withdrawnEarnings': 0,
        'totalReferrals': 0,
        'orderId': null,
        'isActive': true,
        'completedAt': null,
        'rewardedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Referral record created successfully');
    } catch (e) {
      print('❌ Error creating referral record: $e');
      rethrow;
    }
  }

  /// Validate referral code during signup
  Future<ReferralValidationResult> validateReferralCode(String code) async {
    try {
      print('🔍 ════════════════════════════════════════════════════════');
      print('🔍 VALIDATING REFERRAL CODE');
      print('🔍 ════════════════════════════════════════════════════════');
      print('  Code: $code');
      print('🔍 ════════════════════════════════════════════════════════');

      if (code.isEmpty) {
        return const ReferralValidationResult(
          isValid: false,
          message: 'Please enter a referral code',
        );
      }

      // Find referral by code in users collection
      final querySnapshot = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('❌ Referral code not found');
        return const ReferralValidationResult(
          isValid: false,
          message: 'Invalid referral code',
        );
      }

      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();
      final referrerId = userDoc.id;
      
      print('✅ Referral code valid!');
      print('  Referrer User ID: $referrerId');
      print('  Referrer Name: ${userData['firstName']} ${userData['lastName']}');

      return ReferralValidationResult(
        isValid: true,
        message: 'Valid referral code! You\'ll get ₹$refereeReward on signup',
        referral: null, // We don't need the referral model here
        referrerId: referrerId,
      );

    } catch (e) {
      print('❌ ════════════════════════════════════════════════════════');
      print('❌ ERROR VALIDATING REFERRAL CODE');
      print('❌ ════════════════════════════════════════════════════════');
      print('  Error: $e');
      print('❌ ════════════════════════════════════════════════════════');
      
      return ReferralValidationResult(
        isValid: false,
        message: 'Error validating referral code: ${e.toString()}',
      );
    }
  }



  /// Get referral statistics for a user
  Future<Map<String, dynamic>> getReferralStats(String userId) async {
    try {
      final doc = await _firestore.collection('referrals').doc(userId).get();
      
      if (!doc.exists) {
        return {
          'totalReferrals': 0,
          'totalEarnings': 0.0,
          'pendingEarnings': 0.0,
          'withdrawnEarnings': 0.0,
          'referralCode': '',
        };
      }

      final data = doc.data()!;
      return {
        'totalReferrals': data['totalReferrals'] ?? 0,
        'totalEarnings': (data['totalEarnings'] ?? 0).toDouble(),
        'pendingEarnings': (data['pendingEarnings'] ?? 0).toDouble(),
        'withdrawnEarnings': (data['withdrawnEarnings'] ?? 0).toDouble(),
        'referralCode': data['referralCode'] ?? '',
      };
    } catch (e) {
      print('Error fetching referral stats: $e');
      return {
        'totalReferrals': 0,
        'totalEarnings': 0.0,
        'pendingEarnings': 0.0,
        'withdrawnEarnings': 0.0,
        'referralCode': '',
      };
    }
  }

  /// Get list of referred users
  Future<List<Map<String, dynamic>>> getReferredUsers(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('referrals')
          .where('referrerUserId', isEqualTo: userId)
          .where('referredUserId', isNotEqualTo: null)
          .orderBy('referredUserId')
          .orderBy('completedAt', descending: true)
          .get();

      final referredUsers = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final referredUserId = data['referredUserId'] as String?;
        
        if (referredUserId != null) {
          // Fetch user details
          final userDoc = await _firestore.collection('users').doc(referredUserId).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            referredUsers.add({
              'userId': referredUserId,
              'firstName': userData['firstName'] ?? '',
              'lastName': userData['lastName'] ?? '',
              'email': userData['email'] ?? '',
              'completedAt': data['completedAt'],
              'rewardAmount': (data['rewardAmount'] ?? 0).toDouble(),
              'status': data['status'] ?? 'pending',
            });
          }
        }
      }

      return referredUsers;
    } catch (e) {
      print('Error fetching referred users: $e');
      return [];
    }
  }

  /// Stream referral stats
  Stream<Map<String, dynamic>> streamReferralStats(String userId) {
    return _firestore
        .collection('referrals')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return {
          'totalReferrals': 0,
          'totalEarnings': 0.0,
          'pendingEarnings': 0.0,
          'withdrawnEarnings': 0.0,
          'referralCode': '',
        };
      }

      final data = doc.data()!;
      return {
        'totalReferrals': data['totalReferrals'] ?? 0,
        'totalEarnings': (data['totalEarnings'] ?? 0).toDouble(),
        'pendingEarnings': (data['pendingEarnings'] ?? 0).toDouble(),
        'withdrawnEarnings': (data['withdrawnEarnings'] ?? 0).toDouble(),
        'referralCode': data['referralCode'] ?? '',
      };
    });
  }

  /// Process referral signup bonus via Cloud Function
  Future<void> processReferralSignupBonus(String userId, String referrerId) async {
    try {
      print('🎯 Calling Cloud Function for referral signup bonus...');
      print('  User ID: $userId');
      print('  Referrer ID: $referrerId');

      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('processReferralSignupBonus');
      
      final result = await callable.call({
        'userId': userId,
        'referrerId': referrerId,
      });

      print('✅ Referral signup bonus processed successfully');
      print('  Result: ${result.data}');
    } catch (e) {
      print('❌ Error processing referral signup bonus: $e');
      // Don't rethrow - we don't want signup to fail if bonus processing fails
    }
  }

  /// Process referral first order bonus via Cloud Function
  Future<void> processReferralFirstOrderBonus(String userId, String orderId, double orderAmount) async {
    try {
      print('🎯 Calling Cloud Function for referral first order bonus...');
      print('  User ID: $userId');
      print('  Order ID: $orderId');
      print('  Order Amount: ₹$orderAmount');

      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('processReferralFirstOrderBonus');
      
      final result = await callable.call({
        'userId': userId,
        'orderId': orderId,
        'orderAmount': orderAmount,
      });

      print('✅ Referral first order bonus processed successfully');
      print('  Result: ${result.data}');
    } catch (e) {
      print('❌ Error processing referral first order bonus: $e');
      // This is called from Cloud Function trigger, so we can log the error
    }
  }
}

