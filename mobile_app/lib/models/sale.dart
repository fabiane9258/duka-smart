class Sale {
  int? id;
  double totalAmount;
  double amountPaid;
  double changeAmount;
  String createdAt;

  Sale({
    this.id,
    required this.totalAmount,
    required this.amountPaid,
    required this.changeAmount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_amount': totalAmount,
      'amount_paid': amountPaid,
      'change_amount': changeAmount,
      'created_at': createdAt,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      totalAmount: (map['total_amount'] as num).toDouble(),
      amountPaid: (map['amount_paid'] as num).toDouble(),
      changeAmount: (map['change_amount'] as num).toDouble(),
      createdAt: map['created_at'],
    );
  }
}
