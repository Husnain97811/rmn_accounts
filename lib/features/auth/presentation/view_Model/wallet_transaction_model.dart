class WalletTransaction {
  final int id;
  final double amount;
  final String description;
  final String type; // 'credit' or 'debit'
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.type,
    required this.createdAt,
  });

  factory WalletTransaction.fromMap(Map<String, dynamic> data) {
    DateTime parseCreatedAt(dynamic createdAt) {
      try {
        if (createdAt == null) return DateTime.now();

        if (createdAt is String) {
          return DateTime.parse(createdAt);
        } else if (createdAt is int) {
          // Handle timestamp (seconds or milliseconds)
          if (createdAt > 1000000000000) {
            // Milliseconds since epoch
            return DateTime.fromMillisecondsSinceEpoch(createdAt);
          } else {
            // Seconds since epoch
            return DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
          }
        } else if (createdAt is Map<String, dynamic>) {
          // Handle PostgreSQL timestamp format
          if (createdAt['seconds'] != null) {
            return DateTime.fromMillisecondsSinceEpoch(
              createdAt['seconds'] * 1000,
            );
          }
        }
        return DateTime.now();
      } catch (e) {
        print('Error parsing createdAt: $createdAt, error: $e');
        return DateTime.now();
      }
    }

    return WalletTransaction(
      id: data['id'] as int,
      amount: (data['amount'] as num).toDouble(),
      type: data['type'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdAt: parseCreatedAt(data['created_at']),
    );
  }
}
