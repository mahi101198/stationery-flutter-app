import 'package:cloud_firestore/cloud_firestore.dart';

/// Referral model for tracking referrals and rewards
class ReferralModel {
  final String referralId;
  final String userId;
  final String referrerUserId;
  final String? referredUserId;
  final String referralCode;
  final String status; // 'pending', 'completed', 'expired'
  final String rewardStatus; // 'pending', 'credited', 'failed'
  final double rewardAmount;
  final double totalEarnings;
  final double pendingEarnings;
  final double withdrawnEarnings;
  final int totalReferrals;
  final String? orderId;
  final bool isActive;
  final DateTime? completedAt;
  final DateTime? rewardedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReferralModel({
    required this.referralId,
    required this.userId,
    required this.referrerUserId,
    this.referredUserId,
    required this.referralCode,
    required this.status,
    required this.rewardStatus,
    required this.rewardAmount,
    required this.totalEarnings,
    required this.pendingEarnings,
    required this.withdrawnEarnings,
    required this.totalReferrals,
    this.orderId,
    required this.isActive,
    this.completedAt,
    this.rewardedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory ReferralModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ReferralModel(
      referralId: doc.id,
      userId: data['userId'] ?? '',
      referrerUserId: data['referrerUserId'] ?? '',
      referredUserId: data['referredUserId'],
      referralCode: data['referralCode'] ?? '',
      status: data['status'] ?? 'pending',
      rewardStatus: data['rewardStatus'] ?? 'pending',
      rewardAmount: (data['rewardAmount'] ?? 0).toDouble(),
      totalEarnings: (data['totalEarnings'] ?? 0).toDouble(),
      pendingEarnings: (data['pendingEarnings'] ?? 0).toDouble(),
      withdrawnEarnings: (data['withdrawnEarnings'] ?? 0).toDouble(),
      totalReferrals: (data['totalReferrals'] ?? 0).toInt(),
      orderId: data['orderId'],
      isActive: data['isActive'] ?? true,
      completedAt: _parseTimestamp(data['completedAt']),
      rewardedAt: _parseTimestamp(data['rewardedAt']),
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseTimestamp(data['updatedAt']) ?? DateTime.now(),
    );
  }

  /// Parse timestamp from Firestore
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return null;
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'referrerUserId': referrerUserId,
      'referredUserId': referredUserId,
      'referralCode': referralCode,
      'status': status,
      'rewardStatus': rewardStatus,
      'rewardAmount': rewardAmount,
      'totalEarnings': totalEarnings,
      'pendingEarnings': pendingEarnings,
      'withdrawnEarnings': withdrawnEarnings,
      'totalReferrals': totalReferrals,
      'orderId': orderId,
      'isActive': isActive,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'rewardedAt': rewardedAt != null ? Timestamp.fromDate(rewardedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Copy with method
  ReferralModel copyWith({
    String? referralId,
    String? userId,
    String? referrerUserId,
    String? referredUserId,
    String? referralCode,
    String? status,
    String? rewardStatus,
    double? rewardAmount,
    double? totalEarnings,
    double? pendingEarnings,
    double? withdrawnEarnings,
    int? totalReferrals,
    String? orderId,
    bool? isActive,
    DateTime? completedAt,
    DateTime? rewardedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReferralModel(
      referralId: referralId ?? this.referralId,
      userId: userId ?? this.userId,
      referrerUserId: referrerUserId ?? this.referrerUserId,
      referredUserId: referredUserId ?? this.referredUserId,
      referralCode: referralCode ?? this.referralCode,
      status: status ?? this.status,
      rewardStatus: rewardStatus ?? this.rewardStatus,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      pendingEarnings: pendingEarnings ?? this.pendingEarnings,
      withdrawnEarnings: withdrawnEarnings ?? this.withdrawnEarnings,
      totalReferrals: totalReferrals ?? this.totalReferrals,
      orderId: orderId ?? this.orderId,
      isActive: isActive ?? this.isActive,
      completedAt: completedAt ?? this.completedAt,
      rewardedAt: rewardedAt ?? this.rewardedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ReferralModel(referralCode: $referralCode, status: $status, rewardAmount: $rewardAmount)';
  }
}

