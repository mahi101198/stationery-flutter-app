// Quick test to verify image URL extraction works
import 'dart:convert';

void main() {
  // Simulate Firestore data for register-172-pages
  final firestoreData = {
    'product_id': 'register-172-pages',
    'title': 'Classmate Register - 172 Pages',
    'media': {
      'main_image': {
        'url': 'https://images.unsplash.com/photo-1517842645767-c639042777db?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxub3RlYm9vayUyMHN0YXRpb25lcnl8ZW58MXx8fHwxNzM4MzQ5NDM4fDA&ixlib=rb-4.1.0&q=80&w=1080',
        'alt_text': 'Classmate Register - 172 Pages'
      },
      'gallery_images': []
    },
    'product_skus': [
      {
        'sku_id': 'register-172-pages-hb',
        'price': 125
      }
    ]
  };

  print('🧪 Testing image URL extraction...\n');
  
  // Simulate ProductMediaModel.fromFirestore
  final mediaData = firestoreData['media'] as Map<String, dynamic>;
  
  print('📸 Media data type: ${mediaData.runtimeType}');
  print('   media keys: ${mediaData.keys.toList()}');
  
  final mainImageData = mediaData['main_image'];
  print('\n🔍 main_image data:');
  print('   Type: ${mainImageData.runtimeType}');
  print('   Is Map: ${mainImageData is Map}');
  
  String mainImageUrl = '';
  
  if (mainImageData is String) {
    print('   ✓ Extracted as String');
    mainImageUrl = mainImageData;
  } else if (mainImageData is Map) {
    print('   ✓ Extracted as Map');
    final url = mainImageData['url'] ?? '';
    print('   ✓ Got URL from map: ${url.isNotEmpty ? "✓ YES" : "❌ NO"}');
    mainImageUrl = url;
  }
  
  print('\n✅ Final image URL:');
  print('   Length: ${mainImageUrl.length}');
  print('   Starts with https: ${mainImageUrl.startsWith("https")}');
  print('   URL: ${mainImageUrl.substring(0, 50)}...');
  
  if (mainImageUrl.isNotEmpty) {
    print('\n✅ SUCCESS: Image URL would be loaded correctly!');
  } else {
    print('\n❌ FAIL: No image URL extracted!');
  }
}
