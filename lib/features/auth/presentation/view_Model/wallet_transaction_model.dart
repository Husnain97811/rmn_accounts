class WalletTransaction {
  final double amount;
  final String description;
  final String type; // 'credit' or 'debit'
  final DateTime createdAt;

  WalletTransaction({
    required this.amount,
    required this.description,
    required this.type,
    required this.createdAt,
  });

  factory WalletTransaction.fromMap(Map<String, dynamic> map) {
    return WalletTransaction(
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] ?? '',
      type: map['type'] ?? 'credit',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
