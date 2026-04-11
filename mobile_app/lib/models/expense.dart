class Expense {
  int? id;
  double amount;
  String? note;
  String createdAt;

  Expense({
    this.id,
    required this.amount,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'note': note,
      'created_at': createdAt,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}
