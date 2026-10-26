import 'package:cloud_firestore/cloud_firestore.dart';

/// Ortak harcama ve bütçe grubu veri modeli.
class GroupModel {
  final String id;
  final String name;
  final String inviteCode;
  final List<String> members;
  final List<String> memberUids;
  final String? createdById;
  final DateTime createdAt;

  const GroupModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.members,
    this.memberUids = const [],
    this.createdById,
    required this.createdAt,
  });

  /// Geriye dönük uyumluluk için isim alanı
  String get title => name;

  /// Firestore dokümanına yazılacak veri haritası
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'inviteCode': inviteCode,
      'members': members,
      'memberUids': memberUids,
      if (createdById != null && createdById!.isNotEmpty) 'createdById': createdById,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Map verisinden null-safe model üretimi
  factory GroupModel.fromMap(Map<String, dynamic>? map, {String id = ''}) {
    if (map == null) {
      return GroupModel(
        id: id,
        name: '',
        inviteCode: '',
        members: const [],
        createdAt: DateTime.now(),
      );
    }

    // Üye isimleri listesini güvenli dönüştür
    final rawMembers = map['members'];
    final List<String> parsedMembers;
    if (rawMembers is List) {
      parsedMembers = rawMembers
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    } else {
      parsedMembers = const [];
    }

    // Üye UID'leri listesini güvenli dönüştür
    final rawMemberUids = map['memberUids'];
    final List<String> parsedMemberUids;
    if (rawMemberUids is List) {
      parsedMemberUids = rawMemberUids
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    } else {
      parsedMemberUids = const [];
    }

    // Oluşturulma tarihini güvenli dönüştür (Timestamp, String veya int destekler)
    final rawCreatedAt = map['createdAt'];
    DateTime parsedCreatedAt;
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else if (rawCreatedAt is int) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return GroupModel(
      id: id.isNotEmpty ? id : (map['id']?.toString() ?? ''),
      name: map['name']?.toString().trim() ?? '',
      inviteCode: map['inviteCode']?.toString().trim().toUpperCase() ?? '',
      members: parsedMembers,
      memberUids: parsedMemberUids,
      createdById: map['createdById']?.toString().trim(),
      createdAt: parsedCreatedAt,
    );
  }

  /// Firestore DocumentSnapshot üzerinden null-safe model üretimi
  factory GroupModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return GroupModel.fromMap(data, id: snapshot.id);
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? inviteCode,
    List<String>? members,
    List<String>? memberUids,
    String? createdById,
    DateTime? createdAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      members: members ?? this.members,
      memberUids: memberUids ?? this.memberUids,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'GroupModel(id: $id, name: $name, inviteCode: $inviteCode, members: $members, memberUids: $memberUids, createdById: $createdById, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupModel &&
        other.id == id &&
        other.name == name &&
        other.inviteCode == inviteCode;
  }

  @override
  int get hashCode => Object.hash(id, name, inviteCode);
}
