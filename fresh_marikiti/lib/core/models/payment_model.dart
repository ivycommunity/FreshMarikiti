enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
  expired,
}

enum PaymentMethod {
  mpesa,
  card,
  cash,
  wallet,
}

enum TransactionType {
  payment,
  refund,
  reversal,
  cashout,
  topup,
}

class PaymentTransaction {
  final String id;
  final String orderId;
  final String userId;
  final double amount;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final TransactionType type;
  final String? reference;
  final String? mpesaReceiptNumber;
  final String? checkoutRequestId;
  final String? merchantRequestId;
  final String? phoneNumber;
  final String? description;
  final String? failureReason;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  PaymentTransaction({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.type,
    this.reference,
    this.mpesaReceiptNumber,
    this.checkoutRequestId,
    this.merchantRequestId,
    this.phoneNumber,
    this.description,
    this.failureReason,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['_id'] ?? json['id'] ?? '',
      orderId: json['orderId'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == (json['paymentMethod'] ?? 'mpesa'),
        orElse: () => PaymentMethod.mpesa,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'pending'),
        orElse: () => PaymentStatus.pending,
      ),
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == (json['type'] ?? 'payment'),
        orElse: () => TransactionType.payment,
      ),
      reference: json['reference'],
      mpesaReceiptNumber: json['mpesaReceiptNumber'],
      checkoutRequestId: json['checkoutRequestId'],
      merchantRequestId: json['merchantRequestId'],
      phoneNumber: json['phoneNumber'],
      description: json['description'],
      failureReason: json['failureReason'],
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
      completedAt: DateTime.tryParse(json['completedAt'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'amount': amount,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'status': status.toString().split('.').last,
      'type': type.toString().split('.').last,
      'reference': reference,
      'mpesaReceiptNumber': mpesaReceiptNumber,
      'checkoutRequestId': checkoutRequestId,
      'merchantRequestId': merchantRequestId,
      'phoneNumber': phoneNumber,
      'description': description,
      'failureReason': failureReason,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  PaymentTransaction copyWith({
    String? id,
    String? orderId,
    String? userId,
    double? amount,
    PaymentMethod? paymentMethod,
    PaymentStatus? status,
    TransactionType? type,
    String? reference,
    String? mpesaReceiptNumber,
    String? checkoutRequestId,
    String? merchantRequestId,
    String? phoneNumber,
    String? description,
    String? failureReason,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      type: type ?? this.type,
      reference: reference ?? this.reference,
      mpesaReceiptNumber: mpesaReceiptNumber ?? this.mpesaReceiptNumber,
      checkoutRequestId: checkoutRequestId ?? this.checkoutRequestId,
      merchantRequestId: merchantRequestId ?? this.merchantRequestId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      description: description ?? this.description,
      failureReason: failureReason ?? this.failureReason,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // Helper methods
  bool get isPending => status == PaymentStatus.pending;
  bool get isProcessing => status == PaymentStatus.processing;
  bool get isCompleted => status == PaymentStatus.completed;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isCancelled => status == PaymentStatus.cancelled;
  bool get isRefunded => status == PaymentStatus.refunded;
  bool get isExpired => status == PaymentStatus.expired;

  bool get isMpesa => paymentMethod == PaymentMethod.mpesa;
  bool get isCard => paymentMethod == PaymentMethod.card;
  bool get isCash => paymentMethod == PaymentMethod.cash;

  String get statusText {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.expired:
        return 'Expired';
    }
  }

  String get paymentMethodText {
    switch (paymentMethod) {
      case PaymentMethod.mpesa:
        return 'M-Pesa';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.wallet:
        return 'Wallet';
    }
  }

  String get displayAmount => 'KES ${amount.toStringAsFixed(2)}';
}

class PaymentFee {
  final double amount;
  final double feeAmount;
  final double totalAmount;
  final String description;
  final Map<String, dynamic>? breakdown;

  PaymentFee({
    required this.amount,
    required this.feeAmount,
    required this.totalAmount,
    required this.description,
    this.breakdown,
  });

  factory PaymentFee.fromJson(Map<String, dynamic> json) {
    return PaymentFee(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      feeAmount: (json['feeAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      breakdown: json['breakdown'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'feeAmount': feeAmount,
      'totalAmount': totalAmount,
      'description': description,
      'breakdown': breakdown,
    };
  }
}

class RefundRequest {
  final String id;
  final String transactionId;
  final String orderId;
  final String userId;
  final double amount;
  final String reason;
  final String status;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime? processedAt;

  RefundRequest({
    required this.id,
    required this.transactionId,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.reason,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    this.processedAt,
  });

  factory RefundRequest.fromJson(Map<String, dynamic> json) {
    return RefundRequest(
      id: json['_id'] ?? json['id'] ?? '',
      transactionId: json['transactionId'] ?? '',
      orderId: json['orderId'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
      adminNotes: json['adminNotes'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      processedAt: DateTime.tryParse(json['processedAt'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'orderId': orderId,
      'userId': userId,
      'amount': amount,
      'reason': reason,
      'status': status,
      'adminNotes': adminNotes,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isProcessed => status == 'processed';

  String get displayAmount => 'KES ${amount.toStringAsFixed(2)}';
}

class PaymentAnalytics {
  final double totalRevenue;
  final double totalFees;
  final int totalTransactions;
  final int successfulTransactions;
  final int failedTransactions;
  final double successRate;
  final Map<String, dynamic> methodBreakdown;
  final Map<String, dynamic> dailyTrends;
  final List<Map<String, dynamic>> topFailureReasons;

  PaymentAnalytics({
    required this.totalRevenue,
    required this.totalFees,
    required this.totalTransactions,
    required this.successfulTransactions,
    required this.failedTransactions,
    required this.successRate,
    required this.methodBreakdown,
    required this.dailyTrends,
    required this.topFailureReasons,
  });

  factory PaymentAnalytics.fromJson(Map<String, dynamic> json) {
    return PaymentAnalytics(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalFees: (json['totalFees'] as num?)?.toDouble() ?? 0.0,
      totalTransactions: json['totalTransactions'] ?? 0,
      successfulTransactions: json['successfulTransactions'] ?? 0,
      failedTransactions: json['failedTransactions'] ?? 0,
      successRate: (json['successRate'] as num?)?.toDouble() ?? 0.0,
      methodBreakdown: json['methodBreakdown'] as Map<String, dynamic>? ?? {},
      dailyTrends: json['dailyTrends'] as Map<String, dynamic>? ?? {},
      topFailureReasons: List<Map<String, dynamic>>.from(json['topFailureReasons'] ?? []),
    );
  }
} 