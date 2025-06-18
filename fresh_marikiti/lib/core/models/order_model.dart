enum OrderStatus {
  pending,
  confirmed,
  processing,
  ready,
  pickedUp,
  outForDelivery,
  delivered,
  cancelled
}

// Extension for OrderStatus conversions
extension OrderStatusExtension on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.processing:
        return 'processing';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.pickedUp:
        return 'picked-up';
      case OrderStatus.outForDelivery:
        return 'out_for_delivery';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String toUpperCase() => value.toUpperCase();
  String toLowerCase() => value.toLowerCase();

  // Check status comparisons
  bool matches(String statusString) {
    return value.toLowerCase() == statusString.toLowerCase() ||
           displayName.toLowerCase() == statusString.toLowerCase();
  }
}

// Helper function to parse string to OrderStatus
OrderStatus parseOrderStatus(String status) {
  switch (status.toLowerCase().replaceAll('_', '').replaceAll('-', '')) {
    case 'pending':
      return OrderStatus.pending;
    case 'confirmed':
      return OrderStatus.confirmed;
    case 'processing':
      return OrderStatus.processing;
    case 'ready':
      return OrderStatus.ready;
    case 'pickedup':
      return OrderStatus.pickedUp;
    case 'outfordelivery':
      return OrderStatus.outForDelivery;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.pending;
  }
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded
}

enum PaymentMethod {
  mpesa,
  card,
  cash
}

class Address {
  final String? street;
  final String? area;
  final String? city;
  final String? postalCode;
  final String fullAddress;

  Address({
    this.street,
    this.area,
    this.city,
    this.postalCode,
    required this.fullAddress,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'],
      area: json['area'],
      city: json['city'],
      postalCode: json['postalCode'],
      fullAddress: json['fullAddress'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'area': area,
      'city': city,
      'postalCode': postalCode,
      'fullAddress': fullAddress,
    };
  }
}

class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({
    required this.latitude,
    required this.longitude,
  });

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class StatusHistory {
  final String status;
  final DateTime timestamp;
  final String? updatedBy;
  final String? notes;

  StatusHistory({
    required this.status,
    required this.timestamp,
    this.updatedBy,
    this.notes,
  });

  factory StatusHistory.fromJson(Map<String, dynamic> json) {
    return StatusHistory(
      status: json['status'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      updatedBy: json['updatedBy'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'updatedBy': updatedBy,
      'notes': notes,
    };
  }
}

class Order {
  final String id;
  final String? orderNumber;
  final String customerId;
  final String vendorId;
  final String? assignedConnector;
  final String? assignedRider;
  final List<OrderItem> products;
  final double subtotal;
  final double deliveryFee;
  final double totalPrice;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final String? checkoutRequestID;
  final String? mpesaReceiptNumber;
  final Address deliveryAddress;
  final Coordinates? deliveryCoordinates;
  final Coordinates? vendorCoordinates;
  final double? deliveryDistance;
  final String phoneNumber;
  final String? specialInstructions;
  final DateTime? estimatedPickupTime;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualPickupTime;
  final DateTime? actualDeliveryTime;
  final List<StatusHistory> statusHistory;
  final bool isRated;
  final String? customerRating;
  final double connectorCommission;
  final double riderCommission;
  final double platformFee;
  final DateTime? connectorAssignedAt;
  final DateTime? riderAssignedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    this.orderNumber,
    required this.customerId,
    required this.vendorId,
    this.assignedConnector,
    this.assignedRider,
    required this.products,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalPrice,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    this.checkoutRequestID,
    this.mpesaReceiptNumber,
    required this.deliveryAddress,
    this.deliveryCoordinates,
    this.vendorCoordinates,
    this.deliveryDistance,
    required this.phoneNumber,
    this.specialInstructions,
    this.estimatedPickupTime,
    this.estimatedDeliveryTime,
    this.actualPickupTime,
    this.actualDeliveryTime,
    this.statusHistory = const [],
    this.isRated = false,
    this.customerRating,
    this.connectorCommission = 0.0,
    this.riderCommission = 0.0,
    this.platformFee = 0.0,
    this.connectorAssignedAt,
    this.riderAssignedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? json['id'] ?? '',
      orderNumber: json['orderNumber'],
      customerId: json['customer'] is Map 
          ? json['customer']['_id'] ?? json['customer']['id'] 
          : json['customer'] ?? '',
      vendorId: json['vendor'] is Map 
          ? json['vendor']['_id'] ?? json['vendor']['id'] 
          : json['vendor'] ?? '',
      assignedConnector: json['assignedConnector'] is Map 
          ? json['assignedConnector']['_id'] ?? json['assignedConnector']['id'] 
          : json['assignedConnector'],
      assignedRider: json['assignedRider'] is Map 
          ? json['assignedRider']['_id'] ?? json['assignedRider']['id'] 
          : json['assignedRider'],
      products: (json['products'] as List?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: _parseOrderStatus(json['status'] ?? 'pending'),
      paymentStatus: _parsePaymentStatus(json['paymentStatus'] ?? 'pending'),
      paymentMethod: _parsePaymentMethod(json['paymentMethod'] ?? 'mpesa'),
      checkoutRequestID: json['checkoutRequestID'],
      mpesaReceiptNumber: json['mpesaReceiptNumber'],
      deliveryAddress: Address.fromJson(json['deliveryAddress'] ?? {}),
      deliveryCoordinates: json['deliveryCoordinates'] != null 
          ? Coordinates.fromJson(json['deliveryCoordinates']) 
          : null,
      vendorCoordinates: json['vendorCoordinates'] != null 
          ? Coordinates.fromJson(json['vendorCoordinates']) 
          : null,
      deliveryDistance: (json['deliveryDistance'] as num?)?.toDouble(),
      phoneNumber: json['phoneNumber'] ?? '',
      specialInstructions: json['specialInstructions'],
      estimatedPickupTime: json['estimatedPickupTime'] != null 
          ? DateTime.parse(json['estimatedPickupTime']) 
          : null,
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null 
          ? DateTime.parse(json['estimatedDeliveryTime']) 
          : null,
      actualPickupTime: json['actualPickupTime'] != null 
          ? DateTime.parse(json['actualPickupTime']) 
          : null,
      actualDeliveryTime: json['actualDeliveryTime'] != null 
          ? DateTime.parse(json['actualDeliveryTime']) 
          : null,
      statusHistory: (json['statusHistory'] as List?)
          ?.map((item) => StatusHistory.fromJson(item))
          .toList() ?? [],
      isRated: json['isRated'] ?? false,
      customerRating: json['customerRating'],
      connectorCommission: (json['connectorCommission'] as num?)?.toDouble() ?? 0.0,
      riderCommission: (json['riderCommission'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
      connectorAssignedAt: json['connectorAssignedAt'] != null 
          ? DateTime.parse(json['connectorAssignedAt']) 
          : null,
      riderAssignedAt: json['riderAssignedAt'] != null 
          ? DateTime.parse(json['riderAssignedAt']) 
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'customer': customerId,
      'vendor': vendorId,
      'assignedConnector': assignedConnector,
      'assignedRider': assignedRider,
      'products': products.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'totalPrice': totalPrice,
      'status': status.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'checkoutRequestID': checkoutRequestID,
      'mpesaReceiptNumber': mpesaReceiptNumber,
      'deliveryAddress': deliveryAddress.toJson(),
      'deliveryCoordinates': deliveryCoordinates?.toJson(),
      'vendorCoordinates': vendorCoordinates?.toJson(),
      'deliveryDistance': deliveryDistance,
      'phoneNumber': phoneNumber,
      'specialInstructions': specialInstructions,
      'estimatedPickupTime': estimatedPickupTime?.toIso8601String(),
      'estimatedDeliveryTime': estimatedDeliveryTime?.toIso8601String(),
      'actualPickupTime': actualPickupTime?.toIso8601String(),
      'actualDeliveryTime': actualDeliveryTime?.toIso8601String(),
      'statusHistory': statusHistory.map((item) => item.toJson()).toList(),
      'isRated': isRated,
      'customerRating': customerRating,
      'connectorCommission': connectorCommission,
      'riderCommission': riderCommission,
      'platformFee': platformFee,
      'connectorAssignedAt': connectorAssignedAt?.toIso8601String(),
      'riderAssignedAt': riderAssignedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static OrderStatus _parseOrderStatus(String status) {
    switch (status.toLowerCase().replaceAll('_', '').replaceAll('-', '')) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'ready':
        return OrderStatus.ready;
      case 'pickedup':
        return OrderStatus.pickedUp;
      case 'outfordelivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  static PaymentStatus _parsePaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'paid':
        return PaymentStatus.paid;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  static PaymentMethod _parsePaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'mpesa':
        return PaymentMethod.mpesa;
      case 'card':
        return PaymentMethod.card;
      case 'cash':
        return PaymentMethod.cash;
      default:
        return PaymentMethod.mpesa;
    }
  }

  // Helper methods
  bool get isPending => status == OrderStatus.pending;
  bool get isConfirmed => status == OrderStatus.confirmed;
  bool get isProcessing => status == OrderStatus.processing;
  bool get isReady => status == OrderStatus.ready;
  bool get isPickedUp => status == OrderStatus.pickedUp;
  bool get isOutForDelivery => status == OrderStatus.outForDelivery;
  bool get isDelivered => status == OrderStatus.delivered;
  bool get isCancelled => status == OrderStatus.cancelled;

  bool get isPaid => paymentStatus == PaymentStatus.paid;
  bool get hasConnector => assignedConnector != null;
  bool get hasRider => assignedRider != null;

  // Compatibility properties for old code
  String get userId => customerId; // Alias for compatibility
  String? get riderId => assignedRider; // Alias for compatibility
  List<OrderItem> get items => products; // Alias for compatibility
  double get total => totalPrice; // Alias for compatibility
  String? get notes => specialInstructions; // Alias for compatibility

  String get statusDisplay {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Order copyWith({
    String? id,
    String? orderNumber,
    String? customerId,
    String? vendorId,
    String? assignedConnector,
    String? assignedRider,
    List<OrderItem>? products,
    double? subtotal,
    double? deliveryFee,
    double? totalPrice,
    OrderStatus? status,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    String? checkoutRequestID,
    String? mpesaReceiptNumber,
    Address? deliveryAddress,
    Coordinates? deliveryCoordinates,
    Coordinates? vendorCoordinates,
    double? deliveryDistance,
    String? phoneNumber,
    String? specialInstructions,
    DateTime? estimatedPickupTime,
    DateTime? estimatedDeliveryTime,
    DateTime? actualPickupTime,
    DateTime? actualDeliveryTime,
    List<StatusHistory>? statusHistory,
    bool? isRated,
    String? customerRating,
    double? connectorCommission,
    double? riderCommission,
    double? platformFee,
    DateTime? connectorAssignedAt,
    DateTime? riderAssignedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      vendorId: vendorId ?? this.vendorId,
      assignedConnector: assignedConnector ?? this.assignedConnector,
      assignedRider: assignedRider ?? this.assignedRider,
      products: products ?? this.products,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      checkoutRequestID: checkoutRequestID ?? this.checkoutRequestID,
      mpesaReceiptNumber: mpesaReceiptNumber ?? this.mpesaReceiptNumber,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryCoordinates: deliveryCoordinates ?? this.deliveryCoordinates,
      vendorCoordinates: vendorCoordinates ?? this.vendorCoordinates,
      deliveryDistance: deliveryDistance ?? this.deliveryDistance,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      estimatedPickupTime: estimatedPickupTime ?? this.estimatedPickupTime,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      actualPickupTime: actualPickupTime ?? this.actualPickupTime,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      statusHistory: statusHistory ?? this.statusHistory,
      isRated: isRated ?? this.isRated,
      customerRating: customerRating ?? this.customerRating,
      connectorCommission: connectorCommission ?? this.connectorCommission,
      riderCommission: riderCommission ?? this.riderCommission,
      platformFee: platformFee ?? this.platformFee,
      connectorAssignedAt: connectorAssignedAt ?? this.connectorAssignedAt,
      riderAssignedAt: riderAssignedAt ?? this.riderAssignedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double subtotal;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  // Compatibility property
  double get total => subtotal; // Alias for compatibility

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product'] is Map 
          ? json['product']['_id'] ?? json['product']['id'] 
          : json['product'] ?? json['productId'] ?? '',
      productName: json['product'] is Map 
          ? json['product']['name'] 
          : json['productName'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': productId,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }
} 