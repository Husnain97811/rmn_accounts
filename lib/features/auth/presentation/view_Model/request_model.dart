class Request {
  final String id;
  final String type;
  final Map<String, dynamic> customerData;
  final String requesterId;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  Request({
    required this.type,
    required this.customerData,
    required this.requesterId,
    required this.status,
    required this.createdAt,
    this.id = '',
    this.resolvedAt,
  });

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      id: json['id'],
      type: json['type'],
      customerData: json['customerData'],
      requesterId: json['requesterId'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      resolvedAt:
          json['resolvedAt'] != null
              ? DateTime.parse(json['resolvedAt'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'customerData': customerData,
      'requesterId': requesterId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }
}
