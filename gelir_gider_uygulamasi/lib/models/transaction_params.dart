class Transaction {
  final String? id;
  final double? amount;
  final String? type;
  final String? description;
  final String? date;
  final String? categoryId;
  final String? userId;

  Transaction({
    this.id,
    this.amount,
    this.type,
    this.description,
    this.date,
    this.categoryId,
    this.userId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    amount: json['amount'],
    type: json['type'],
    description: json['description'],
    date: json['date'],
    categoryId: json['category_id'],
    userId: json['user_id'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'type': type,
    'description': description,
    'date': date,
    'category_id': categoryId,
    'user_id': userId,
  };
}
