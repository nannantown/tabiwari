class Expense {
  final String id;
  final double amount;
  final String item;
  final String payerId;
  final List<String> excludeIds;
  final List<String> includeIds;

  Expense({
    required this.id,
    required this.amount,
    required this.item,
    required this.payerId,
    this.excludeIds = const [],
    this.includeIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'item': item,
      'payerId': payerId,
      'excludeIds': excludeIds,
      'includeIds': includeIds,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      amount: json['amount'].toDouble(),
      item: json['item'],
      payerId: json['payerId'],
      excludeIds: List<String>.from(json['excludeIds'] ?? []),
      includeIds: List<String>.from(json['includeIds'] ?? []),
    );
  }



  @override
  String toString() => '$item: ¥${amount.toStringAsFixed(0)} ($payerIdが支払い)';
}
