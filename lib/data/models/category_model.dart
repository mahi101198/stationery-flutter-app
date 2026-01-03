import 'package:cloud_firestore/cloud_firestore.dart';

/// Category model following the provided schema
class CategoryModel {
  final String id;
  final String name;
  final String image;
  final bool isActive;
  final int rank;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    required this.isActive,
    required this.rank,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'isActive': isActive,
      'rank': rank,
    };
  }

  /// Create from Firestore document
  factory CategoryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      isActive: data['isActive'] ?? true,
      rank: (data['rank'] ?? 0).toInt(),
    );
  }

  /// Create from Map (for nested data)
  factory CategoryModel.fromMap(Map<String, dynamic> data) {
    return CategoryModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      isActive: data['isActive'] ?? true,
      rank: (data['rank'] ?? 0).toInt(),
    );
  }

  /// Create empty category for fallbacks
  factory CategoryModel.empty() {
    return CategoryModel(
      id: '',
      name: 'Unknown Category',
      image: '',
      isActive: false,
      rank: 0,
    );
  }

  /// Create copy with optional parameter overrides
  CategoryModel copyWith({
    String? id,
    String? name,
    String? image,
    bool? isActive,
    int? rank,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      isActive: isActive ?? this.isActive,
      rank: rank ?? this.rank,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CategoryModel(id: $id, name: $name)';
}
