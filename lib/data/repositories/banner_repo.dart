import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rps_stationery/data/models/additional_models.dart';
import 'package:rps_stationery/utils/exceptions/firebase_exceptions.dart';
import 'package:rps_stationery/utils/exceptions/format_exceptions.dart';
import 'package:rps_stationery/utils/exceptions/platform_exceptions.dart';

class BannerRepo extends GetxController {
  static BannerRepo get instance => Get.find();

  final _db = FirebaseFirestore.instance;

  Future<List<BannerModel>> fetchBanners() async {
    try {
      log('🔥 Connecting to Firebase Firestore...');
      log('📁 Querying collection: banners, filter: isActive == true');
      
      final banners = await _db.collection('banners').where('isActive', isEqualTo: true).get();
      
      log('📊 Firebase query completed. Found ${banners.docs.length} documents');
      
      if (banners.docs.isEmpty) {
        log('⚠️ No active banners found in Firebase');
        return [];
      }
      
      final bannerList = banners.docs.map((snapshot) {
        final data = snapshot.data();
        log('📋 Processing banner document: ${snapshot.id}');
        log('📝 Raw data: $data');
        
        // Safely parse priority
        int parsePriority(dynamic value) {
          if (value == null) return 0;
          if (value is int) return value;
          if (value is double) return value.toInt();
          if (value is String) {
            final parsed = int.tryParse(value);
            return parsed ?? 0;
          }
          return 0;
        }
        
        // Safely parse boolean
        bool parseBool(dynamic value) {
          if (value == null) return true;
          if (value is bool) return value;
          if (value is String) return value.toLowerCase() == 'true';
          if (value is int) return value != 0;
          return true;
        }
        
        final imageUrl = data['imageUrl']?.toString() ?? '';
        final bannerId = data['bannerId']?.toString() ?? snapshot.id;
        final title = data['title']?.toString() ?? '';
        final linkTo = data['linkTo']?.toString() ?? '';
        final rank = parsePriority(data['rank']);
        final isActive = parseBool(data['isActive']);
        
        log('🇮🇲 Image URL: $imageUrl');
        log('🆔 Banner ID: $bannerId');
        log('📝 Title: $title');
        log('🔗 Link To: $linkTo');
        log('📊 Rank: $rank');
        log('✅ Active: $isActive');
        
        final bannerModel = BannerModel(
          bannerId: bannerId,
          imageUrl: imageUrl,
          redirectUrl: linkTo,
          active: isActive,
          priority: rank,
          validFrom: (data['createdAt'] is Timestamp)
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse((data['createdAt'] ?? '').toString()) ?? DateTime(2000, 1, 1),
          validTill: DateTime(2100, 1, 1), // No expiry in your schema, set far future
        );
        
        log('✅ Successfully created banner model for: $bannerId');
        return bannerModel;
      }).toList();
      
      log('🎆 Total banners processed: ${bannerList.length}');
      return bannerList;
    } on FirebaseException catch (e) {
      log('Firebase error fetching banners: ${e.code} - ${e.message}');
      // Return empty list on permission denied to avoid app crash
      if (e.code == 'permission-denied') {
        return [];
      }
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw TFormatException().message;
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      log('Unexpected error - fetchBanners()', error: e);
      // Return empty list instead of throwing to prevent app crash
      return [];
    }
  }
}
