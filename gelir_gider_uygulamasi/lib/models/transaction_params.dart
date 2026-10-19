class Transaction {
  final String? id;
  final double? amount;
  final String? type;
  final String? description;
  final String? date;
  final String? categoryId;
  final String? userId;
  final String? paymentMethod;

  Transaction({
    this.id,
    this.amount,
    this.type,
    this.description,
    this.date,
    this.categoryId,
    this.userId,
    this.paymentMethod,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    amount: json['amount'] != null ? double.tryParse(json['amount'].toString()) : null,
    type: json['type'],
    description: json['description'],
    date: json['date'],
    categoryId: json['category_id'],
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
    'user_id': userId,
    if (paymentMethod != null) 'payment_method': paymentMethod,
  };
}
