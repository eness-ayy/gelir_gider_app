class AppCategory {
  String? id;
  String? name;
  String? type;
  String? icon;
  int? color;
  bool? isSystem;
  String? userId;
  String? createdAt;
  String? updatedAt;

  AppCategory({
    this.id,
    this.name,
    this.type,
    this.icon,
    this.color,
    this.isSystem,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory AppCategory.fromJson(Map<String, dynamic> json) {
    int? parsedColor;
    final rawColor = json['color'];
    if (rawColor is int) {
      parsedColor = rawColor;
    } else if (rawColor is String) {
      parsedColor =
          int.tryParse(rawColor) ??
          int.tryParse(rawColor.replaceAll('#', '0xFF'));
    }

    return AppCategory(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      icon: json['icon'],
      color: parsedColor,
      isSystem: json['is_system'] ?? json['isDefault'],
      userId: json['user_id'] ?? json['userId'],
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      if (color != null) 'color': color,
      'is_system': isSystem,
      'user_id': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
