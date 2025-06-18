// Connector Models for order assistance and waste collection management

// Connector Dashboard Metrics
class ConnectorMetrics {
  final int totalOrders;
  final int todaysOrders;
  final int pendingOrders;
  final int completedOrders;
  final double totalWasteCollected; // in kg
  final double todaysWasteCollected;
  final int totalEcoPointsIssued;
  final int todaysEcoPointsIssued;
  final double totalCommissions;
  final double todaysCommissions;
  final int activeVendors;
  final DateTime lastUpdated;

  ConnectorMetrics({
    required this.totalOrders,
    required this.todaysOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.totalWasteCollected,
    required this.todaysWasteCollected,
    required this.totalEcoPointsIssued,
    required this.todaysEcoPointsIssued,
    required this.totalCommissions,
    required this.todaysCommissions,
    required this.activeVendors,
    required this.lastUpdated,
  });

  factory ConnectorMetrics.fromJson(Map<String, dynamic> json) {
    return ConnectorMetrics(
      totalOrders: json['total_orders'] ?? 0,
      todaysOrders: json['todays_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      totalWasteCollected: (json['total_waste_collected'] ?? 0).toDouble(),
      todaysWasteCollected: (json['todays_waste_collected'] ?? 0).toDouble(),
      totalEcoPointsIssued: json['total_eco_points_issued'] ?? 0,
      todaysEcoPointsIssued: json['todays_eco_points_issued'] ?? 0,
      totalCommissions: (json['total_commissions'] ?? 0).toDouble(),
      todaysCommissions: (json['todays_commissions'] ?? 0).toDouble(),
      activeVendors: json['active_vendors'] ?? 0,
      lastUpdated: DateTime.parse(json['last_updated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_orders': totalOrders,
      'todays_orders': todaysOrders,
      'pending_orders': pendingOrders,
      'completed_orders': completedOrders,
      'total_waste_collected': totalWasteCollected,
      'todays_waste_collected': todaysWasteCollected,
      'total_eco_points_issued': totalEcoPointsIssued,
      'todays_eco_points_issued': todaysEcoPointsIssued,
      'total_commissions': totalCommissions,
      'todays_commissions': todaysCommissions,
      'active_vendors': activeVendors,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

// Connector Order Model - orders assigned to connector
class ConnectorOrder {
  final String id;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String vendorId;
  final String vendorName;
  final String vendorLocation;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final double connectorCommission;
  final String paymentMethod;
  final String paymentStatus;
  final String deliveryAddress;
  final Map<String, double>? deliveryCoordinates;
  final List<ConnectorOrderItem> items;
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? completedAt;
  final String? notes;

  ConnectorOrder({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.vendorId,
    required this.vendorName,
    required this.vendorLocation,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.connectorCommission,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryAddress,
    this.deliveryCoordinates,
    required this.items,
    required this.createdAt,
    this.assignedAt,
    this.completedAt,
    this.notes,
  });

  factory ConnectorOrder.fromJson(Map<String, dynamic> json) {
    return ConnectorOrder(
      id: json['_id'] ?? json['id'] ?? '',
      orderNumber: json['order_number'] ?? json['orderNumber'] ?? '',
      customerId: json['customer_id'] ?? json['customerId'] ?? '',
      customerName: json['customer_name'] ?? json['customerName'] ?? '',
      customerPhone: json['customer_phone'] ?? json['customerPhone'],
      vendorId: json['vendor_id'] ?? json['vendorId'] ?? '',
      vendorName: json['vendor_name'] ?? json['vendorName'] ?? '',
      vendorLocation: json['vendor_location'] ?? json['vendorLocation'] ?? '',
      status: json['status'] ?? '',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['delivery_fee'] ?? json['deliveryFee'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      connectorCommission: (json['connector_commission'] ?? json['connectorCommission'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? json['paymentMethod'] ?? '',
      paymentStatus: json['payment_status'] ?? json['paymentStatus'] ?? '',
      deliveryAddress: json['delivery_address'] ?? json['deliveryAddress'] ?? '',
      deliveryCoordinates: json['delivery_coordinates'] != null 
          ? Map<String, double>.from(json['delivery_coordinates'])
          : null,
      items: (json['items'] as List? ?? [])
          .map((item) => ConnectorOrderItem.fromJson(item))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      assignedAt: json['assigned_at'] != null ? DateTime.parse(json['assigned_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'vendor_location': vendorLocation,
      'status': status,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'total': total,
      'connector_commission': connectorCommission,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'delivery_address': deliveryAddress,
      'delivery_coordinates': deliveryCoordinates,
      'items': items.map((item) => item.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'assigned_at': assignedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }
}

// Connector Order Item
class ConnectorOrderItem {
  final String productId;
  final String productName;
  final String category;
  final int quantity;
  final double price;
  final double totalPrice;
  final String unit;

  ConnectorOrderItem({
    required this.productId,
    required this.productName,
    required this.category,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    required this.unit,
  });

  factory ConnectorOrderItem.fromJson(Map<String, dynamic> json) {
    return ConnectorOrderItem(
      productId: json['product_id'] ?? json['productId'] ?? '',
      productName: json['product_name'] ?? json['productName'] ?? '',
      category: json['category'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? json['totalPrice'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'category': category,
      'quantity': quantity,
      'price': price,
      'total_price': totalPrice,
      'unit': unit,
    };
  }
}

// Waste Collection Model
class WasteCollection {
  final String id;
  final String vendorId;
  final String vendorName;
  final String vendorLocation;
  final String connectorId;
  final String connectorName;
  final double weight; // in kg
  final String wasteType; // organic, packaging, mixed
  final String quality; // excellent, good, fair, poor
  final int ecoPointsAwarded;
  final double ecoPointRate; // points per kg
  final String status; // pending, collected, processed
  final DateTime collectionDate;
  final DateTime? processedDate;
  final String? notes;
  final List<String>? images;
  final Map<String, dynamic>? metadata;
  final double? estimatedValue;
  final Map<String, double>? coordinates;
  final String? collectionAddress;
  final DateTime? createdAt;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  WasteCollection({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.vendorLocation,
    required this.connectorId,
    required this.connectorName,
    required this.weight,
    required this.wasteType,
    required this.quality,
    required this.ecoPointsAwarded,
    required this.ecoPointRate,
    required this.status,
    required this.collectionDate,
    this.processedDate,
    this.notes,
    this.images,
    this.metadata,
    this.estimatedValue,
    this.coordinates,
    this.collectionAddress,
    this.createdAt,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
  });

  factory WasteCollection.fromJson(Map<String, dynamic> json) {
    return WasteCollection(
      id: json['_id'] ?? json['id'] ?? '',
      vendorId: json['vendor_id'] ?? json['vendorId'] ?? '',
      vendorName: json['vendor_name'] ?? json['vendorName'] ?? '',
      vendorLocation: json['vendor_location'] ?? json['vendorLocation'] ?? '',
      connectorId: json['connector_id'] ?? json['connectorId'] ?? '',
      connectorName: json['connector_name'] ?? json['connectorName'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      wasteType: json['waste_type'] ?? json['wasteType'] ?? '',
      quality: json['quality'] ?? '',
      ecoPointsAwarded: json['eco_points_awarded'] ?? json['ecoPointsAwarded'] ?? 0,
      ecoPointRate: (json['eco_point_rate'] ?? json['ecoPointRate'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      collectionDate: DateTime.parse(json['collection_date'] ?? json['collectionDate'] ?? DateTime.now().toIso8601String()),
      processedDate: json['processed_date'] != null ? DateTime.parse(json['processed_date']) : null,
      notes: json['notes'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      metadata: json['metadata'],
      estimatedValue: json['estimated_value'] != null ? (json['estimated_value'] as num).toDouble() : null,
      coordinates: json['coordinates'] != null ? Map<String, double>.from(json['coordinates']) : null,
      collectionAddress: json['collection_address'] ?? json['collectionAddress'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at']) : null,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'vendor_location': vendorLocation,
      'connector_id': connectorId,
      'connector_name': connectorName,
      'weight': weight,
      'waste_type': wasteType,
      'quality': quality,
      'eco_points_awarded': ecoPointsAwarded,
      'eco_point_rate': ecoPointRate,
      'status': status,
      'collection_date': collectionDate.toIso8601String(),
      'processed_date': processedDate?.toIso8601String(),
      'notes': notes,
      'images': images,
      'metadata': metadata,
      'estimated_value': estimatedValue,
      'coordinates': coordinates,
      'collection_address': collectionAddress,
      'created_at': createdAt?.toIso8601String(),
      'scheduled_at': scheduledAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}

// Create Waste Collection Request
class CreateWasteCollectionRequest {
  final String vendorId;
  final double weight;
  final String wasteType;
  final String quality;
  final String? notes;
  final List<String>? images;

  CreateWasteCollectionRequest({
    required this.vendorId,
    required this.weight,
    required this.wasteType,
    required this.quality,
    this.notes,
    this.images,
  });

  Map<String, dynamic> toJson() {
    return {
      'vendor_id': vendorId,
      'weight': weight,
      'waste_type': wasteType,
      'quality': quality,
      'notes': notes,
      'images': images,
    };
  }
}

// Eco Points Transaction Model
class EcoPointsTransaction {
  final String id;
  final String vendorId;
  final String vendorName;
  final String type; // earned, redeemed, expired, bonus
  final int points;
  final String source; // waste_collection, bonus, redemption, etc.
  final String? sourceId; // waste collection id, redemption id, etc.
  final String description;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  EcoPointsTransaction({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.type,
    required this.points,
    required this.source,
    this.sourceId,
    required this.description,
    required this.createdAt,
    this.metadata,
  });

  factory EcoPointsTransaction.fromJson(Map<String, dynamic> json) {
    return EcoPointsTransaction(
      id: json['_id'] ?? json['id'] ?? '',
      vendorId: json['vendor_id'] ?? json['vendorId'] ?? '',
      vendorName: json['vendor_name'] ?? json['vendorName'] ?? '',
      type: json['type'] ?? '',
      points: json['points'] ?? 0,
      source: json['source'] ?? '',
      sourceId: json['source_id'] ?? json['sourceId'],
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'type': type,
      'points': points,
      'source': source,
      'source_id': sourceId,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

// Vendor Summary for Connector
class ConnectorVendor {
  final String id;
  final String name;
  final String location;
  final String? phone;
  final String status;
  final int totalOrders;
  final double totalRevenue;
  final double totalWasteCollected;
  final int totalEcoPoints;
  final int availableEcoPoints;
  final DateTime lastWasteCollection;
  final DateTime lastOrder;
  final double averageWastePerWeek;

  ConnectorVendor({
    required this.id,
    required this.name,
    required this.location,
    this.phone,
    required this.status,
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalWasteCollected,
    required this.totalEcoPoints,
    required this.availableEcoPoints,
    required this.lastWasteCollection,
    required this.lastOrder,
    required this.averageWastePerWeek,
  });

  factory ConnectorVendor.fromJson(Map<String, dynamic> json) {
    return ConnectorVendor(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      phone: json['phone'],
      status: json['status'] ?? '',
      totalOrders: json['total_orders'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      totalWasteCollected: (json['total_waste_collected'] ?? 0).toDouble(),
      totalEcoPoints: json['total_eco_points'] ?? 0,
      availableEcoPoints: json['available_eco_points'] ?? 0,
      lastWasteCollection: DateTime.parse(json['last_waste_collection'] ?? DateTime.now().toIso8601String()),
      lastOrder: DateTime.parse(json['last_order'] ?? DateTime.now().toIso8601String()),
      averageWastePerWeek: (json['average_waste_per_week'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'phone': phone,
      'status': status,
      'total_orders': totalOrders,
      'total_revenue': totalRevenue,
      'total_waste_collected': totalWasteCollected,
      'total_eco_points': totalEcoPoints,
      'available_eco_points': availableEcoPoints,
      'last_waste_collection': lastWasteCollection.toIso8601String(),
      'last_order': lastOrder.toIso8601String(),
      'average_waste_per_week': averageWastePerWeek,
    };
  }
}

// Connector Analytics Model
class ConnectorAnalytics {
  final ConnectorMetrics metrics;
  final List<ChartDataPoint> orderHistory;
  final List<ChartDataPoint> wasteCollectionHistory;
  final List<ChartDataPoint> ecoPointsHistory;
  final List<ChartDataPoint> commissionHistory;
  final Map<String, double> wasteTypeBreakdown;
  final Map<String, int> orderStatusBreakdown;
  final List<ConnectorVendor> topVendorsByWaste;
  final List<ConnectorVendor> topVendorsByOrders;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String period;

  ConnectorAnalytics({
    required this.metrics,
    required this.orderHistory,
    required this.wasteCollectionHistory,
    required this.ecoPointsHistory,
    required this.commissionHistory,
    required this.wasteTypeBreakdown,
    required this.orderStatusBreakdown,
    required this.topVendorsByWaste,
    required this.topVendorsByOrders,
    required this.periodStart,
    required this.periodEnd,
    required this.period,
  });

  factory ConnectorAnalytics.fromJson(Map<String, dynamic> json) {
    return ConnectorAnalytics(
      metrics: ConnectorMetrics.fromJson(json['metrics'] ?? {}),
      orderHistory: (json['order_history'] as List? ?? [])
          .map((item) => ChartDataPoint.fromJson(item))
          .toList(),
      wasteCollectionHistory: (json['waste_collection_history'] as List? ?? [])
          .map((item) => ChartDataPoint.fromJson(item))
          .toList(),
      ecoPointsHistory: (json['eco_points_history'] as List? ?? [])
          .map((item) => ChartDataPoint.fromJson(item))
          .toList(),
      commissionHistory: (json['commission_history'] as List? ?? [])
          .map((item) => ChartDataPoint.fromJson(item))
          .toList(),
      wasteTypeBreakdown: Map<String, double>.from(json['waste_type_breakdown'] ?? {}),
      orderStatusBreakdown: Map<String, int>.from(json['order_status_breakdown'] ?? {}),
      topVendorsByWaste: (json['top_vendors_by_waste'] as List? ?? [])
          .map((item) => ConnectorVendor.fromJson(item))
          .toList(),
      topVendorsByOrders: (json['top_vendors_by_orders'] as List? ?? [])
          .map((item) => ConnectorVendor.fromJson(item))
          .toList(),
      periodStart: DateTime.parse(json['period_start'] ?? DateTime.now().toIso8601String()),
      periodEnd: DateTime.parse(json['period_end'] ?? DateTime.now().toIso8601String()),
      period: json['period'] ?? 'month',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metrics': metrics.toJson(),
      'order_history': orderHistory.map((item) => item.toJson()).toList(),
      'waste_collection_history': wasteCollectionHistory.map((item) => item.toJson()).toList(),
      'eco_points_history': ecoPointsHistory.map((item) => item.toJson()).toList(),
      'commission_history': commissionHistory.map((item) => item.toJson()).toList(),
      'waste_type_breakdown': wasteTypeBreakdown,
      'order_status_breakdown': orderStatusBreakdown,
      'top_vendors_by_waste': topVendorsByWaste.map((item) => item.toJson()).toList(),
      'top_vendors_by_orders': topVendorsByOrders.map((item) => item.toJson()).toList(),
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'period': period,
    };
  }
}

// Chart Data Point (reusable for analytics charts)
class ChartDataPoint {
  final String label;
  final double value;
  final DateTime date;
  final Map<String, dynamic>? metadata;

  ChartDataPoint({
    required this.label,
    required this.value,
    required this.date,
    this.metadata,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      label: json['label'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'date': date.toIso8601String(),
      'metadata': metadata,
    };
  }
} 