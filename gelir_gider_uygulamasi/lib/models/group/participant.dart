/// Grup / etkinlik katılımcısı.
class Participant {
  final String id;
  final String name;

  /// Uygulamayı kullanan kişinin kendisi mi?
  final bool isCurrentUser;

  const Participant({
    required this.id,
    required this.name,
    this.isCurrentUser = false,
  });

  /// Arayüzde gösterilecek ad ("Sen" etiketi ile)
  String get displayName => isCurrentUser ? 'Sen' : name;

  /// Avatar için baş harf
  String get initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }

  Participant copyWith({String? id, String? name, bool? isCurrentUser}) {
    return Participant(
      id: id ?? this.id,
      name: name ?? this.name,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isCurrentUser: json['isCurrentUser'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isCurrentUser': isCurrentUser,
      };
}

extension _FirstCharacter on String {
  /// Türkçe/emoji karakterleri bölmeden ilk karakteri alabilmek için
  /// basit bir rune tabanlı yardımcı.
  _Chars get characters => _Chars(this);
}

class _Chars {
  final String value;
  const _Chars(this.value);
  String get first => String.fromCharCode(value.runes.first);
}
