

import 'package:gelir_gider_uygulamasi/models/payment_method.dart';

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
  String? paymentMethod; // 'cash', 'bank_card', 'credit_card'

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
    this.paymentMethod,
  });

  PaymentMethod get paymentMethodEnum => PaymentMethod.fromKey(paymentMethod);

  factory AppTransaction.fromJson(Map<String, dynamic> json) {
    Category? parsedCategory;
    final descStr = (json['description'] ?? json['title'] ?? '').toString().trim();

    if (json['Category'] != null && json['Category'] is Map<String, dynamic>) {
      parsedCategory =
          Category.fromJson(json['Category'] as Map<String, dynamic>);
    } else if (json['category'] != null &&
        json['category'] is Map<String, dynamic>) {
      parsedCategory =
          Category.fromJson(json['category'] as Map<String, dynamic>);
    } else if (json['categoryName'] != null || json['category_name'] != null) {
      final nameStr = (json['categoryName'] ?? json['category_name'] ?? '').toString().trim();
      final isMistakenDesc = descStr.isNotEmpty &&
          nameStr == descStr &&
          descStr != 'Gelir İşlemi' &&
          descStr != 'Gider İşlemi';

      if (nameStr.isNotEmpty && !isMistakenDesc && nameStr != 'İsimsiz Kategori') {
        parsedCategory = Category(
          name: nameStr,
          icon: (json['categoryIcon'] ?? json['category_icon'] ?? 'category')
              .toString(),
          type: (json['type'] ?? 'expense').toString(),
        );
      }
    } else if (json['category'] != null &&
        json['category'] is String &&
        (json['category'] as String).isNotEmpty) {
      final catStr = (json['category'] as String).trim();
      final isMistakenDesc = descStr.isNotEmpty &&
          catStr == descStr &&
          descStr != 'Gelir İşlemi' &&
          descStr != 'Gider İşlemi';

      if (!catStr.startsWith('def_') &&
          !catStr.startsWith('cat_') &&
          !isMistakenDesc &&
          catStr != 'İsimsiz Kategori') {
        parsedCategory = Category(
          name: catStr,
          icon: (json['categoryIcon'] ?? 'category').toString(),
          type: (json['type'] ?? 'expense').toString(),
        );
      }
    }

    return AppTransaction(
      id: json['id'] ?? '',
      amount: json['amount']?.toString() ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      userId: json['user_id'] ?? '',
      categoryId: json['category_id'] ?? json['categoryId'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      category: parsedCategory,
      paymentMethod:
          json['payment_method'] ?? json['paymentMethod'] ?? json['account'],
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
    if (paymentMethod != null) {
      data['payment_method'] = paymentMethod;
    }
    if (category != null) {
      data['Category'] = category!.toJson();
      data['category'] = category!.name;
      data['categoryName'] = category!.name;
      data['categoryIcon'] = category!.icon;
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