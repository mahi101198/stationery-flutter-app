import 'dart:developer';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/utils/exceptions/firebase_exceptions.dart';
import 'package:rps_stationery/utils/exceptions/format_exceptions.dart';
import 'package:rps_stationery/utils/exceptions/platform_exceptions.dart';

class ReferralRepository extends GetxController {
  static ReferralRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser!.uid;

  Future<T> safeCall<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      log('Firebase error in ReferralRepository: ${e.code} - ${e.message}');
      // Handle permission denied gracefully
      if (e.code == 'permission-denied') {
        log('Permission denied for referral operation - user may not have proper access');
        // Return null or appropriate default for the operation
        throw 'Access denied. Please check your account permissions.';
      }
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      log("ReferralRepository unexpected error -> $e", error: e);
      throw 'Something went wrong. Please try again';
    }
  }

  /// Generate unique referral code for user
  Future<String> generateReferralCode() async {
    return safeCall(() async {
      // Get user's first name for code generation
      final userDoc = await _db.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final firstName = userData?['firstName'] ?? 'USER';
      
      // Generate unique code
      String code;
      bool isUnique = false;
      int attempts = 0;
      const maxAttempts = 10;

      do {
        // Create code with first name + random numbers
        final random = math.Random();
        final randomNumbers = (1000 + random.nextInt(9000)).toString();
        code = '${firstName.toUpperCase().substring(0, math.min(firstName.length, 3))}$randomNumbers';
        
        // Check if code already exists
        final existingCode = await _db
            .collection('referrals')
            .where('referralCode', isEqualTo: code)
            .limit(1)
            .get();
        
        isUnique = existingCode.docs.isEmpty;
        attempts++;
        
        if (attempts >= maxAttempts && !isUnique) {
          // Fallback to fully random code
          code = 'REF${(10000 + random.nextInt(90000)).toString()}';
          final fallbackCheck = await _db
              .collection('referrals')
              .where('referralCode', isEqualTo: code)
              .limit(1)
              .get();
          isUnique = fallbackCheck.docs.isEmpty;
        }
        
      } while (!isUnique && attempts < maxAttempts);

      if (!isUnique) {
        throw 'Failed to generate unique referral code. Please try again.';
      }

      return code;
    });
  }

  /// Create referral record for user
  Future<void> createReferralRecord() async {
    return safeCall(() async {
      // Check if user already has a referral record
      final existingRecord = await _db.collection('referrals').doc(userId).get();
      
      if (existingRecord.exists) {
        return; // User already has a referral record
      }

      final referralCode = await generateReferralCode();

      await _db.collection('referrals').doc(userId).set({
        'userId': userId,
        'referralCode': referralCode,
        'totalReferrals': 0,
        'totalEarnings': 0.0,
        'pendingEarnings': 0.0,
        'withdrawnEarnings': 0.0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Apply referral code during user registration
  Future<void> applyReferralCode(String referralCode) async {
    return safeCall(() async {
      // Find the referrer
      final referrerQuery = await _db
          .collection('referrals')
          .where('referralCode', isEqualTo: referralCode.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (referrerQuery.docs.isEmpty) {
        throw 'Invalid referral code';
      }

      final referrerDoc = referrerQuery.docs.first;
      final referrerId = referrerDoc.data()['userId'];

      // Check if user is trying to refer themselves
      if (referrerId == userId) {
        throw 'You cannot use your own referral code';
      }

      // Check if user has already been referred
      final existingReferral = await _db
          .collection('users')
          .doc(userId)
          .collection('referralHistory')
          .where('type', isEqualTo: 'referred_by')
          .limit(1)
          .get();

      if (existingReferral.docs.isNotEmpty) {
        throw 'You have already used a referral code';
      }

      final batch = _db.batch();

      // Update user's referral history
      final userReferralRef = _db
          .collection('users')
          .doc(userId)
          .collection('referralHistory')
          .doc();

      batch.set(userReferralRef, {
        'type': 'referred_by',
        'referrerId': referrerId,
        'referralCode': referralCode.toUpperCase(),
        'status': 'pending', // Will be 'completed' after first successful order
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add to referrer's referral history
      final referrerHistoryRef = _db
          .collection('users')
          .doc(referrerId)
          .collection('referralHistory')
          .doc();

      batch.set(referrerHistoryRef, {
        'type': 'referred',
        'referredUserId': userId,
        'referralCode': referralCode.toUpperCase(),
        'status': 'pending',
        'earnings': 0.0, // Will be updated when referred user makes first order
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update referrer's total count
      final referrerRef = _db.collection('referrals').doc(referrerId);
      batch.update(referrerRef, {
        'totalReferrals': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    });
  }



  /// Get user's referral information
  Future<Map<String, dynamic>?> getUserReferralInfo() async {
    return safeCall(() async {
      final doc = await _db.collection('referrals').doc(userId).get();
      
      if (!doc.exists) {
        return null;
      }

      return {
        'id': doc.id,
        ...doc.data()!,
      };
    });
  }

  /// Get user's referral history
  Future<List<Map<String, dynamic>>> getUserReferralHistory() async {
    return safeCall(() async {
      final snapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('referralHistory')
          .orderBy('createdAt', descending: true)
          .get();

      final history = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // Get additional user info if it's a 'referred' type
        if (data['type'] == 'referred' && data['referredUserId'] != null) {
          final referredUserDoc = await _db
              .collection('users')
              .doc(data['referredUserId'])
              .get();
          
          if (referredUserDoc.exists) {
            final referredUserData = referredUserDoc.data()!;
            data['referredUserName'] = 
                '${referredUserData['firstName'] ?? ''} ${referredUserData['lastName'] ?? ''}'.trim();
          }
        } else if (data['type'] == 'referred_by' && data['referrerId'] != null) {
          final referrerDoc = await _db
              .collection('users')
              .doc(data['referrerId'])
              .get();
          
          if (referrerDoc.exists) {
            final referrerData = referrerDoc.data()!;
            data['referrerName'] = 
                '${referrerData['firstName'] ?? ''} ${referrerData['lastName'] ?? ''}'.trim();
          }
        }

        history.add({
          'id': doc.id,
          ...data,
        });
      }

      return history;
    });
  }

  /// Get referral earnings summary
  Future<Map<String, dynamic>> getReferralEarningsSummary() async {
    return safeCall(() async {
      final referralInfo = await getUserReferralInfo();
      
      if (referralInfo == null) {
        return {
          'totalEarnings': 0.0,
          'pendingEarnings': 0.0,
          'withdrawnEarnings': 0.0,
          'totalReferrals': 0,
          'successfulReferrals': 0,
          'pendingReferrals': 0,
        };
      }

      // Get detailed referral statistics
      final referralHistory = await _db
          .collection('users')
          .doc(userId)
          .collection('referralHistory')
          .where('type', isEqualTo: 'referred')
          .get();

      int successfulReferrals = 0;
      int pendingReferrals = 0;

      for (final doc in referralHistory.docs) {
        final data = doc.data();
        if (data['status'] == 'completed') {
          successfulReferrals++;
        } else {
          pendingReferrals++;
        }
      }

      return {
        'totalEarnings': referralInfo['totalEarnings'] ?? 0.0,
        'pendingEarnings': referralInfo['pendingEarnings'] ?? 0.0,
        'withdrawnEarnings': referralInfo['withdrawnEarnings'] ?? 0.0,
        'totalReferrals': referralInfo['totalReferrals'] ?? 0,
        'successfulReferrals': successfulReferrals,
        'pendingReferrals': pendingReferrals,
        'referralCode': referralInfo['referralCode'],
      };
    });
  }

  /// Request withdrawal of referral earnings
  Future<void> requestWithdrawal(double amount) async {
    return safeCall(() async {
      final referralInfo = await getUserReferralInfo();
      
      if (referralInfo == null) {
        throw 'No referral account found';
      }

      final pendingEarnings = (referralInfo['pendingEarnings'] as num?)?.toDouble() ?? 0.0;
      
      if (amount > pendingEarnings) {
        throw 'Insufficient balance. Available: \$${pendingEarnings.toStringAsFixed(2)}';
      }

      // Get minimum withdrawal amount from unified settings
      final settingsDoc = await _db.collection('settings').doc('app').get();
      final settings = settingsDoc.data() ?? {};
      final minWithdrawal = (settings['minWithdrawalAmount'] as num?)?.toDouble() ?? 0.0;

      if (amount < minWithdrawal) {
        throw 'Minimum withdrawal amount is \$${minWithdrawal.toStringAsFixed(2)}';
      }

      final batch = _db.batch();

      // Create withdrawal request
      final withdrawalRef = _db.collection('withdrawalRequests').doc();
      batch.set(withdrawalRef, {
        'userId': userId,
        'amount': amount,
        'type': 'referral_earnings',
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      // Update referral earnings
      final referralRef = _db.collection('referrals').doc(userId);
      batch.update(referralRef, {
        'pendingEarnings': FieldValue.increment(-amount),
        'withdrawnEarnings': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create transaction record
      final transactionRef = _db.collection('transactions').doc();
      batch.set(transactionRef, {
        'userId': userId,
        'type': 'withdrawal_request',
        'amount': -amount, // Negative for withdrawal
        'description': 'Referral earnings withdrawal request',
        'withdrawalRequestId': withdrawalRef.id,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    });
  }

  /// Get withdrawal history
  Future<List<Map<String, dynamic>>> getWithdrawalHistory() async {
    return safeCall(() async {
      final snapshot = await _db
          .collection('withdrawalRequests')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'referral_earnings')
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    });
  }

  /// Validate referral code format
  bool isValidReferralCodeFormat(String code) {
    // Check if code is 6-8 characters, alphanumeric
    final regex = RegExp(r'^[A-Z0-9]{3,8}$');
    return regex.hasMatch(code.toUpperCase());
  }

  /// Get referral leaderboard (top referrers)
  Future<List<Map<String, dynamic>>> getReferralLeaderboard({int limit = 10}) async {
    return safeCall(() async {
      final snapshot = await _db
          .collection('referrals')
          .where('isActive', isEqualTo: true)
          .orderBy('totalReferrals', descending: true)
          .limit(limit)
          .get();

      final leaderboard = <Map<String, dynamic>>[];

      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        
        // Get user info
        final userDoc = await _db.collection('users').doc(data['userId']).get();
        final userData = userDoc.exists ? userDoc.data()! : {};

        leaderboard.add({
          'rank': i + 1,
          'userId': data['userId'],
          'userName': '${userData['firstName'] ?? 'User'} ${userData['lastName'] ?? ''}'.trim(),
          'userAvatar': userData['profilePictureUrl'],
          'totalReferrals': data['totalReferrals'] ?? 0,
          'totalEarnings': data['totalEarnings'] ?? 0.0,
        });
      }

      return leaderboard;
    });
  }

  // Admin methods

  /// Get all referrals with statistics (Admin only)
  Future<List<Map<String, dynamic>>> getAllReferralsWithStats() async {
    return safeCall(() async {
      final snapshot = await _db
          .collection('referrals')
          .orderBy('totalEarnings', descending: true)
          .get();

      final referrals = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // Get user info
        final userDoc = await _db.collection('users').doc(data['userId']).get();
        final userData = userDoc.exists ? userDoc.data()! : {};

        referrals.add({
          'id': doc.id,
          'userName': '${userData['firstName'] ?? 'User'} ${userData['lastName'] ?? ''}'.trim(),
          'userEmail': userData['email'],
          ...data,
        });
      }

      return referrals;
    });
  }

  /// Update referral settings (Admin only)
  /// Updates the unified settings document
  Future<void> updateReferralSettings(Map<String, dynamic> settings) async {
    return safeCall(() async {
      await _db.collection('settings').doc('app').update({
        ...settings,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Get referral settings
  /// Returns referral-related fields from unified settings document
  Future<Map<String, dynamic>> getReferralSettings() async {
    return safeCall(() async {
      final doc = await _db.collection('settings').doc('app').get();
      if (!doc.exists) return {};
      
      final data = doc.data()!;
      return {
        'referrerRewardValue': data['referrerRewardValue'],
        'refereeRewardValue': data['refereeRewardValue'],
        'minOrderAmount': data['minOrderAmount'],
        'minWithdrawalAmount': data['minWithdrawalAmount'],
        'isReferralActive': data['isReferralActive'] ?? true,
      };
    });
  }
}
