

class AppTransaction {
  String id;
  String amount;
  String type;
  String description;
  String date;
  String userId;
  String categoryId;
  String createdAt;
  String updatedAt;
  Category? category; // Null olabilmesi için '?' eklendi

  AppTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.date,
    required this.userId,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    this.category, // required kaldırıldı, opsiyonel yapıldı
  });

  factory AppTransaction.fromJson(Map<String, dynamic> json) {
    return AppTransaction(
      id: json['id'] ?? '',
      amount: json['amount']?.toString() ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      userId: json['user_id'] ?? '',
      categoryId: json['category_id'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      category: json['Category'] != null
          ? Category.fromJson(json['Category'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['amount'] = amount;
    data['type'] = type;
    data['description'] = description;
    data['date'] = date;
    data['user_id'] = userId;
    data['category_id'] = categoryId;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    if (category != null) {
      data['Category'] = category!.toJson();
    }
    return data;
  }
}

class Category {
  String name;
  String icon;
  String type;

  Category({
    required this.name,
    required this.icon,
    required this.type,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['icon'] = icon;
    data['type'] = type;
    return data;
  }
}