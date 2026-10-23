import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String type; // 'gelir' | 'gider'
  final String icon; // İkon adı veya codepoint
  final int color; // Renk ARGB int kodu (Örn: 0xFF4CAF50)
  final bool isDefault; // Varsayılan sistem kategorisi mi?
  final DateTime? createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isDefault = true,
    this.createdAt,
  });

  /// Firestore dokümanından nesne üretme
  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Renk alanını güvenli dönüştürme (int veya String gelebilir)
    int parsedColor = 0xFF757575;
    final rawColor = data['color'];
    if (rawColor is int) {
      parsedColor = rawColor;
    } else if (rawColor is String) {
      parsedColor = int.tryParse(rawColor) ??
          int.tryParse(rawColor.replaceAll('#', '0xFF')) ??
          0xFF757575;
    }

    // Tarih alanını güvenli dönüştürme
    DateTime? parsedDate;
    final rawDate = data['createdAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    // Tür alanını 'gelir' veya 'gider' olarak normalize et
    String rawType = (data['type'] as String? ?? 'gider').toLowerCase().trim();
    if (rawType == 'expense') rawType = 'gider';
    if (rawType == 'income') rawType = 'gelir';

    return CategoryModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      type: rawType,
      icon: data['icon'] as String? ?? 'category',
      color: parsedColor,
      isDefault: data['isDefault'] as bool? ?? data['is_system'] as bool? ?? false,
      createdAt: parsedDate,
    );
  }

  /// Map üzerinden nesne üretme
  factory CategoryModel.fromMap(Map<String, dynamic> map, {String? id}) {
    int parsedColor = 0xFF757575;
    final rawColor = map['color'];
    if (rawColor is int) {
      parsedColor = rawColor;
    } else if (rawColor is String) {
      parsedColor = int.tryParse(rawColor) ??
          int.tryParse(rawColor.replaceAll('#', '0xFF')) ??
          0xFF757575;
    }

    String rawType = (map['type'] as String? ?? 'gider').toLowerCase().trim();
    if (rawType == 'expense') rawType = 'gider';
    if (rawType == 'income') rawType = 'gelir';

    return CategoryModel(
      id: id ?? map['id'] ?? '',
      name: map['name'] as String? ?? '',
      type: rawType,
      icon: map['icon'] as String? ?? 'category',
      color: parsedColor,
      isDefault: map['isDefault'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(map['createdAt'].toString()))
          : null,
    );
  }

  /// Firestore'a kaydetmek üzere Map formatına dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'isDefault': isDefault,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? type,
    String? icon,
    int? color,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
