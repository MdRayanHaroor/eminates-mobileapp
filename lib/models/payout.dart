class Payout {
  final String? id;
  final String requestId;
  final double amount;
  final String? transactionUtr;
  final DateTime? paymentDate;
  final String type; // 'Profit', 'Principal', 'Bonus'
  final String status; // 'Paid', 'Scheduled'
  final String? notes;
  final DateTime? createdAt;

  Payout({
    this.id,
    required this.requestId,
    required this.amount,
    this.transactionUtr,
    this.paymentDate,
    this.type = 'Profit',
    this.status = 'Paid',
    this.notes,
    this.createdAt,
  });

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      id: json['id'] as String?,
      requestId: json['request_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      transactionUtr: json['transaction_utr'] as String?,
      paymentDate: json['payment_date'] != null ? DateTime.tryParse(json['payment_date']) : null,
      type: json['type'] as String? ?? 'Profit',
      status: json['status'] as String? ?? 'Paid',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'request_id': requestId,
      'amount': amount,
      'transaction_utr': transactionUtr,
      'payment_date': paymentDate?.toIso8601String(),
      'type': type,
      'status': status,
      'notes': notes,
    };
  }
}
