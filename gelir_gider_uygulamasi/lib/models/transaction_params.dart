class Transaction {
  final String? id;
  final double? amount;
  final String? type;
  final String? description;
  final String? date;
  final String? categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String? userId;
  final String? paymentMethod;

  Transaction({
    this.id,
    this.amount,
    this.type,
    this.description,
    this.date,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.userId,
    this.paymentMethod,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    amount: json['amount'] != null ? double.tryParse(json['amount'].toString()) : null,
    type: json['type'],
    description: json['description'],
    date: json['date'],
    categoryId: json['category_id'] ?? json['categoryId'],
    categoryName: json['category_name'] ?? json['categoryName'] ?? json['category'],
    categoryIcon: json['category_icon'] ?? json['categoryIcon'],
    userId: json['user_id'],
    paymentMethod: json['payment_method'] ?? json['paymentMethod'] ?? json['account'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'type': type,
    'description': description,
    'date': date,
    'category_id': categoryId,
    if (categoryName != null) 'category_name': categoryName,
    if (categoryName != null) 'category': categoryName,
    if (categoryIcon != null) 'category_icon': categoryIcon,
    'user_id': userId,
    if (paymentMethod != null) 'payment_method': paymentMethod,
  };
}
