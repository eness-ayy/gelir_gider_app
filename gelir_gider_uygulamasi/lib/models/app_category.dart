class AppCategory {
  String? id;
  String? name;
  String? type;
  String? icon;
  bool? isSystem;
  String? userId;
  String? createdAt;
  String? updatedAt;

  AppCategory({
    this.id,
    this.name,
    this.type,
    this.icon,
    this.isSystem,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory AppCategory.fromJson(Map<String, dynamic> json) {
    return AppCategory(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      icon: json['icon'],
      isSystem: json['is_system'],
      userId: json['user_id'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'is_system': isSystem,
      'user_id': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
