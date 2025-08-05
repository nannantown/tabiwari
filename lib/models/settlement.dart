class Settlement {
  final Map<String, double> balances; // 各参加者の精算額（+受け取り/-支払い）
  final List<Payment> payments; // 最適化された送金リスト

  Settlement({
    required this.balances,
    required this.payments,
  });

  Map<String, dynamic> toJson() {
    return {
      'balances': balances,
      'payments': payments.map((p) => p.toJson()).toList(),
    };
  }

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      balances: Map<String, double>.from(json['balances']),
      payments:
          (json['payments'] as List).map((p) => Payment.fromJson(p)).toList(),
    );
  }
}

class Payment {
  final String fromId;
  final String toId;
  final double amount;

  Payment({
    required this.fromId,
    required this.toId,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'fromId': fromId,
      'toId': toId,
      'amount': amount,
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      fromId: json['fromId'],
      toId: json['toId'],
      amount: json['amount'].toDouble(),
    );
  }

  @override
  String toString() => '$fromId → $toId: ¥${amount.toStringAsFixed(0)}';
}
