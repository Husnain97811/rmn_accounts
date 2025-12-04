class CashFlowTransaction {
  final String id;
  final String type;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String? employeeId;
  final String? employeeName;
  final double? commission;
  final int? walletTransactionId;

  CashFlowTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.employeeId,
    this.employeeName,
    this.commission,
    this.walletTransactionId,
  });

  factory CashFlowTransaction.fromJson(Map<String, dynamic> json) {
    return CashFlowTransaction(
      id: json['id'].toString(),
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      description: json['description'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      employeeId: json['employee_id']?.toString(),
      employeeName: json['employee_name'] as String? ?? '',
      commission: json['employee_commission']?.toDouble(),
      walletTransactionId: json['wallet_transaction_id'] as int?,
    );
  }
}
