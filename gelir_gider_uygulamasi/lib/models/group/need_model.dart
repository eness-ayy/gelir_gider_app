import 'package:cloud_firestore/cloud_firestore.dart';

/// Ortak Oda / Ev için 'İhtiyaçlar' (Odaya Lazım) veri modeli.
class NeedModel {
  final String id;
  final String title;
  final String addedBy;
  final bool isCompleted;
  final String? completedBy;
  final DateTime createdAt;

  const NeedModel({
    required this.id,
    required this.title,
    required this.addedBy,
    this.isCompleted = false,
    this.completedBy,
    required this.createdAt,
  });

  /// Firestore dokümanına yazılacak veri haritası
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'addedBy': addedBy,
      'isCompleted': isCompleted,
      if (completedBy != null) 'completedBy': completedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Map verisinden null-safe model üretimi
  factory NeedModel.fromMap(Map<String, dynamic>? map, {String id = ''}) {
    if (map == null) {
      return NeedModel(
        id: id,
        title: '',
        addedBy: '',
        isCompleted: false,
        createdAt: DateTime.now(),
      );
    }

    final rawCreatedAt = map['createdAt'];
    DateTime parsedDate;
    if (rawCreatedAt is Timestamp) {
      parsedDate = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedDate = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else if (rawCreatedAt is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
    } else {
      parsedDate = DateTime.now();
    }

    return NeedModel(
      id: id.isNotEmpty ? id : (map['id']?.toString() ?? ''),
      title: map['title']?.toString().trim() ?? '',
      addedBy: map['addedBy']?.toString().trim() ?? '',
      isCompleted: map['isCompleted'] == true,
      completedBy: map['completedBy']?.toString().trim(),
      createdAt: parsedDate,
    );
  }

  /// Firestore DocumentSnapshot üzerinden null-safe model üretimi
  factory NeedModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return NeedModel.fromMap(data, id: snapshot.id);
  }

  NeedModel copyWith({
    String? id,
    String? title,
    String? addedBy,
    bool? isCompleted,
    String? completedBy,
    DateTime? createdAt,
  }) {
    return NeedModel(
      id: id ?? this.id,
      title: title ?? this.title,
      addedBy: addedBy ?? this.addedBy,
      isCompleted: isCompleted ?? this.isCompleted,
      completedBy: completedBy ?? this.completedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'NeedModel(id: $id, title: $title, addedBy: $addedBy, isCompleted: $isCompleted, completedBy: $completedBy, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NeedModel &&
        other.id == id &&
        other.title == title &&
        other.addedBy == addedBy &&
        other.isCompleted == isCompleted &&
        other.completedBy == completedBy &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, title, addedBy, isCompleted, completedBy, createdAt);
}
