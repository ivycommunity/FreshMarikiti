// Vendor Admin Models for managing multiple stalls and vendors

// Chart Data Point Model (reusable for vendor admin analytics)
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

// Stall Model - represents a physical stall/location managed by vendor admin
class Stall {
  final String id;
  final String name;
  final String location;
  final String? description;
  final List<String> categories;
  final Map<String, String> operatingHours;
  final String status; // active, inactive, suspended
  final String? managerId;
  final String? managerName;
  final String? phone;
  final int totalProducts;
  final int activeProducts;
  final int totalOrders;
  final double totalRevenue;
  
  // Eco Points System
  final int totalEcoPoints;
  final int availableEcoPoints;
  final double totalWasteCollected;
  final int wasteCollections;
  final String wasteCollectionRank;
  
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  Stall({
    required this.id,
    required this.name,
    required this.location,
    this.description,
    required this.categories,
    required this.operatingHours,
    required this.status,
    this.managerId,
    this.managerName,
    this.phone,
    this.totalProducts = 0,
    this.activeProducts = 0,
    this.totalOrders = 0,
    this.totalRevenue = 0.0,
    this.totalEcoPoints = 0,
    this.availableEcoPoints = 0,
    this.totalWasteCollected = 0.0,
    this.wasteCollections = 0,
    this.wasteCollectionRank = 'Bronze',
    required this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  factory Stall.fromJson(Map<String, dynamic> json) {
    return Stall(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      description: json['description'],
      categories: List<String>.from(json['categories'] ?? []),
      operatingHours: Map<String, String>.from(json['operatingHours'] ?? json['operating_hours'] ?? {}),
      status: json['status'] ?? 'active',
      managerId: json['manager_id'],
      managerName: json['manager_name'] ?? json['manager'],
      phone: json['phone'],
      totalProducts: json['total_products'] ?? json['totalProducts'] ?? 0,
      activeProducts: json['active_products'] ?? json['activeProducts'] ?? 0,
      totalOrders: json['total_orders'] ?? json['totalOrders'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? json['totalRevenue'] ?? 0).toDouble(),
      totalEcoPoints: json['total_eco_points'] ?? 0,
      availableEcoPoints: json['available_eco_points'] ?? 0,
      totalWasteCollected: (json['total_waste_collected'] ?? 0).toDouble(),
      wasteCollections: json['waste_collections'] ?? 0,
      wasteCollectionRank: json['waste_collection_rank'] ?? 'Bronze',
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'description': description,
      'categories': categories,
      'operating_hours': operatingHours,
      'status': status,
      'manager_id': managerId,
      'manager_name': managerName,
      'phone': phone,
      'total_products': totalProducts,
      'active_products': activeProducts,
      'total_orders': totalOrders,
      'total_revenue': totalRevenue,
      'total_eco_points': totalEcoPoints,
      'available_eco_points': availableEcoPoints,
      'total_waste_collected': totalWasteCollected,
      'waste_collections': wasteCollections,
      'waste_collection_rank': wasteCollectionRank,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
}

// Create Stall Request Model
class CreateStallRequest {
  final String name;
  final String location;
  final String? description;
  final List<String> categories;
  final Map<String, String> operatingHours;
  final String? managerId;
  final String? phone;

  CreateStallRequest({
    required this.name,
    required this.location,
    this.description,
    required this.categories,
    required this.operatingHours,
    this.managerId,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'description': description,
      'categories': categories,
      'operating_hours': operatingHours,
      'manager_id': managerId,
      'phone': phone,
    };
  }
}

// Update Stall Request Model
class UpdateStallRequest {
  final String? name;
  final String? location;
  final String? description;
  final List<String>? categories;
  final Map<String, String>? operatingHours;
  final String? status;
  final String? managerId;
  final String? phone;

  UpdateStallRequest({
    this.name,
    this.location,
    this.description,
    this.categories,
    this.operatingHours,
    this.status,
    this.managerId,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (name != null) data['name'] = name;
    if (location != null) data['location'] = location;
    if (description != null) data['description'] = description;
    if (categories != null) data['categories'] = categories;
    if (operatingHours != null) data['operating_hours'] = operatingHours;
    if (status != null) data['status'] = status;
    if (managerId != null) data['manager_id'] = managerId;
    if (phone != null) data['phone'] = phone;
    
    return data;
  }
}

// Vendor Admin Dashboard Metrics
class VendorAdminMetrics {
  final int totalStalls;
  final int activeStalls;
  final int totalProducts;
  final int activeProducts;
  final int totalOrders;
  final int todaysOrders;
  final double totalRevenue;
  final double todaysRevenue;
  final double averageOrderValue;
  final double revenueGrowth;
  final int totalCustomers;
  
  // Eco Points System Metrics
  final int totalEcoPoints;
  final int todaysEcoPoints;
  final int redeemedEcoPoints;
  final double totalWasteCollected;
  final double todaysWasteCollected;
  final int totalWasteCollections;
  final int todaysWasteCollections;
  final double carbonFootprintReduced;
  final Map<String, int> stallRankings; // stall_id -> rank
  final Map<String, double> wasteTypeBreakdown;
  
  final DateTime lastUpdated;

  VendorAdminMetrics({
    required this.totalStalls,
    required this.activeStalls,
    required this.totalProducts,
    required this.activeProducts,
    required this.totalOrders,
    required this.todaysOrders,
    required this.totalRevenue,
    required this.todaysRevenue,
    required this.averageOrderValue,
    required this.revenueGrowth,
    required this.totalCustomers,
    required this.totalEcoPoints,
    required this.todaysEcoPoints,
    required this.redeemedEcoPoints,
    required this.totalWasteCollected,
    required this.todaysWasteCollected,
    required this.totalWasteCollections,
    required this.todaysWasteCollections,
    required this.carbonFootprintReduced,
    required this.stallRankings,
    required this.wasteTypeBreakdown,
    required this.lastUpdated,
  });

  factory VendorAdminMetrics.fromJson(Map<String, dynamic> json) {
    return VendorAdminMetrics(
      totalStalls: json['total_stalls'] ?? 0,
      activeStalls: json['active_stalls'] ?? 0,
      totalProducts: json['total_products'] ?? 0,
      activeProducts: json['active_products'] ?? 0,
      totalOrders: json['total_orders'] ?? 0,
      todaysOrders: json['todays_orders'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      todaysRevenue: (json['todays_revenue'] ?? 0).toDouble(),
      averageOrderValue: (json['average_order_value'] ?? 0).toDouble(),
      revenueGrowth: (json['revenue_growth'] ?? 0).toDouble(),
      totalCustomers: json['total_customers'] ?? 0,
      totalEcoPoints: json['total_eco_points'] ?? 0,
      todaysEcoPoints: json['todays_eco_points'] ?? 0,
      redeemedEcoPoints: json['redeemed_eco_points'] ?? 0,
      totalWasteCollected: (json['total_waste_collected'] ?? 0).toDouble(),
      todaysWasteCollected: (json['todays_waste_collected'] ?? 0).toDouble(),
      totalWasteCollections: json['total_waste_collections'] ?? 0,
      todaysWasteCollections: json['todays_waste_collections'] ?? 0,
      carbonFootprintReduced: (json['carbon_footprint_reduced'] ?? 0).toDouble(),
      stallRankings: Map<String, int>.from(json['stall_rankings'] ?? {}),
      wasteTypeBreakdown: Map<String, double>.from(json['waste_type_breakdown'] ?? {}),
      lastUpdated: DateTime.parse(json['last_updated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_stalls': totalStalls,
      'active_stalls': activeStalls,
      'total_products': totalProducts,
      'active_products': activeProducts,
      'total_orders': totalOrders,
      'todays_orders': todaysOrders,
      'total_revenue': totalRevenue,
      'todays_revenue': todaysRevenue,
      'average_order_value': averageOrderValue,
      'revenue_growth': revenueGrowth,
      'total_customers': totalCustomers,
      'total_eco_points': totalEcoPoints,
      'todays_eco_points': todaysEcoPoints,
      'redeemed_eco_points': redeemedEcoPoints,
      'total_waste_collected': totalWasteCollected,
      'todays_waste_collected': todaysWasteCollected,
      'total_waste_collections': totalWasteCollections,
      'todays_waste_collections': todaysWasteCollections,
      'carbon_footprint_reduced': carbonFootprintReduced,
      'stall_rankings': stallRankings,
      'waste_type_breakdown': wasteTypeBreakdown,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

// Stall Analytics Model
class StallAnalytics {
  final String stallId;
  final String stallName;
  final String location;
  final double revenue;
  final int orders;
  final int products;
  final double averageOrderValue;
  final double growthRate;
  final List<ProductPerformance> topProducts;
  final List<ChartDataPoint> revenueChart;
  final List<ChartDataPoint> orderChart;

  StallAnalytics({
    required this.stallId,
    required this.stallName,
    required this.location,
    required this.revenue,
    required this.orders,
    required this.products,
    required this.averageOrderValue,
    required this.growthRate,
    required this.topProducts,
    required this.revenueChart,
    required this.orderChart,
  });

  factory StallAnalytics.fromJson(Map<String, dynamic> json) {
    return StallAnalytics(
      stallId: json['stall_id'] ?? '',
      stallName: json['stall_name'] ?? '',
      location: json['location'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
      orders: json['orders'] ?? 0,
      products: json['products'] ?? 0,
      averageOrderValue: (json['average_order_value'] ?? 0).toDouble(),
      growthRate: (json['growth_rate'] ?? 0).toDouble(),
      topProducts: (json['top_products'] as List? ?? [])
          .map((item) => ProductPerformance.fromJson(item))
          .toList(),
      revenueChart: (json['revenue_chart'] as List? ?? [])
          .map((item) => ChartDataPoint.fromJson(item))
          .toList(),
      orderChart: (json['order_chart'] as List? ?? [])
          .map((item) => ChartDataPoint.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stall_id': stallId,
      'stall_name': stallName,
      'location': location,
      'revenue': revenue,
      'orders': orders,
      'products': products,
      'average_order_value': averageOrderValue,
      'growth_rate': growthRate,
      'top_products': topProducts.map((item) => item.toJson()).toList(),
      'revenue_chart': revenueChart.map((item) => item.toJson()).toList(),
      'order_chart': orderChart.map((item) => item.toJson()).toList(),
    };
  }
}

// Product Performance Model
class ProductPerformance {
  final String productId;
  final String productName;
  final String category;
  final double revenue;
  final int quantitySold;
  final double averageRating;
  final int totalOrders;

  ProductPerformance({
    required this.productId,
    required this.productName,
    required this.category,
    required this.revenue,
    required this.quantitySold,
    required this.averageRating,
    required this.totalOrders,
  });

  factory ProductPerformance.fromJson(Map<String, dynamic> json) {
    return ProductPerformance(
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      category: json['category'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
      quantitySold: json['quantity_sold'] ?? 0,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalOrders: json['total_orders'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'category': category,
      'revenue': revenue,
      'quantity_sold': quantitySold,
      'average_rating': averageRating,
      'total_orders': totalOrders,
    };
  }
}

// Vendor Admin Analytics Model
class VendorAdminAnalytics {
  final VendorAdminMetrics metrics;
  final List<StallAnalytics> stallAnalytics;
  final List<ChartDataPoint> revenueHistory;
  final List<ChartDataPoint> orderHistory;
  final List<ProductPerformance> topProducts;
  final Map<String, double> categoryBreakdown;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String period;

  VendorAdminAnalytics({
    required this.metrics,
    required this.stallAnalytics,
    required this.revenueHistory,
    required this.orderHistory,
    required this.topProducts,
    required this.categoryBreakdown,
    required this.periodStart,
    required this.periodEnd,
    required this.period,
  });

  factory VendorAdminAnalytics.fromJson(Map<String, dynamic> json) {
    return VendorAdminAnalytics(
      metrics: VendorAdminMetrics.fromJson(json['metrics'] ?? {}),
      stallAnalytics: (json['stall_analytics'] as List? ?? [])
          .map((item) => StallAnalytics.fromJson(item))
          .toList(),
      revenueHistory: (json['revenue_history'] as List? ?? [])
          .map((item) => ChartDataPoint.fromJson(item))
          .toList(),
      orderHistory: (json['order_history'] as List? ?? [])
          .map((item) => ChartDataPoint.fromJson(item))
          .toList(),
      topProducts: (json['top_products'] as List? ?? [])
          .map((item) => ProductPerformance.fromJson(item))
          .toList(),
      categoryBreakdown: Map<String, double>.from(json['category_breakdown'] ?? {}),
      periodStart: DateTime.parse(json['period_start'] ?? DateTime.now().toIso8601String()),
      periodEnd: DateTime.parse(json['period_end'] ?? DateTime.now().toIso8601String()),
      period: json['period'] ?? 'month',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metrics': metrics.toJson(),
      'stall_analytics': stallAnalytics.map((item) => item.toJson()).toList(),
      'revenue_history': revenueHistory.map((item) => item.toJson()).toList(),
      'order_history': orderHistory.map((item) => item.toJson()).toList(),
      'top_products': topProducts.map((item) => item.toJson()).toList(),
      'category_breakdown': categoryBreakdown,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'period': period,
    };
  }
}

// Stall Product Model - represents products in a specific stall
class StallProduct {
  final String id;
  final String name;
  final String category;
  final String description;
  final double price;
  final int quantityAvailable;
  final String unit;
  final bool isActive;
  final List<String> images;
  final String stallId;
  final String stallLocation;
  final double? averageRating;
  final int totalSales;
  final DateTime createdAt;
  final DateTime? updatedAt;

  StallProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.quantityAvailable,
    required this.unit,
    this.isActive = true,
    required this.images,
    required this.stallId,
    required this.stallLocation,
    this.averageRating,
    this.totalSales = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory StallProduct.fromJson(Map<String, dynamic> json) {
    return StallProduct(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantityAvailable: json['quantity_available'] ?? json['quantityAvailable'] ?? 0,
      unit: json['unit'] ?? '',
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      images: List<String>.from(json['images'] ?? []),
      stallId: json['stall_id'] ?? json['stallId'] ?? '',
      stallLocation: json['stall_location'] ?? json['location'] ?? '',
      averageRating: json['average_rating'] != null ? (json['average_rating']).toDouble() : null,
      totalSales: json['total_sales'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'quantity_available': quantityAvailable,
      'unit': unit,
      'is_active': isActive,
      'images': images,
      'stall_id': stallId,
      'stall_location': stallLocation,
      'average_rating': averageRating,
      'total_sales': totalSales,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

// Stall Order Model - represents orders for a specific stall
class StallOrder {
  final String id;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String deliveryAddress;
  final String stallId;
  final String stallLocation;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  StallOrder({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryAddress,
    required this.stallId,
    required this.stallLocation,
    required this.items,
    required this.createdAt,
    this.deliveredAt,
  });

  factory StallOrder.fromJson(Map<String, dynamic> json) {
    return StallOrder(
      id: json['_id'] ?? json['id'] ?? '',
      orderNumber: json['order_number'] ?? json['orderNumber'] ?? '',
      customerId: json['customer_id'] ?? json['customerId'] ?? '',
      customerName: json['customer_name'] ?? json['customerName'] ?? '',
      customerPhone: json['customer_phone'] ?? json['customerPhone'],
      status: json['status'] ?? '',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['delivery_fee'] ?? json['deliveryFee'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? json['paymentMethod'] ?? '',
      paymentStatus: json['payment_status'] ?? json['paymentStatus'] ?? '',
      deliveryAddress: json['delivery_address'] ?? json['deliveryAddress'] ?? '',
      stallId: json['stall_id'] ?? json['stallId'] ?? '',
      stallLocation: json['stall_location'] ?? json['stallLocation'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'status': status,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'total': total,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'delivery_address': deliveryAddress,
      'stall_id': stallId,
      'stall_location': stallLocation,
      'items': items.map((item) => item.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
    };
  }
}

// Order Item Model (used in StallOrder)
class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final double totalPrice;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] ?? json['productId'] ?? '',
      productName: json['product_name'] ?? json['productName'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? json['totalPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'total_price': totalPrice,
    };
  }
}

// Waste Collection Model (for vendor admin oversight)
class WasteCollection {
  final String id;
  final String vendorId;
  final String vendorName;
  final String stallId;
  final String stallName;
  final String connectorId;
  final String connectorName;
  final double weight;
  final String wasteType;
  final String quality;
  final int ecoPointsAwarded;
  final String status;
  final DateTime collectionDate;
  final DateTime? processedDate;
  final String? notes;

  WasteCollection({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.stallId,
    required this.stallName,
    required this.connectorId,
    required this.connectorName,
    required this.weight,
    required this.wasteType,
    required this.quality,
    required this.ecoPointsAwarded,
    required this.status,
    required this.collectionDate,
    this.processedDate,
    this.notes,
  });

  factory WasteCollection.fromJson(Map<String, dynamic> json) {
    return WasteCollection(
      id: json['_id'] ?? json['id'] ?? '',
      vendorId: json['vendor_id'] ?? '',
      vendorName: json['vendor_name'] ?? '',
      stallId: json['stall_id'] ?? '',
      stallName: json['stall_name'] ?? '',
      connectorId: json['connector_id'] ?? '',
      connectorName: json['connector_name'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      wasteType: json['waste_type'] ?? '',
      quality: json['quality'] ?? '',
      ecoPointsAwarded: json['eco_points_awarded'] ?? json['ecoPointsAwarded'] ?? 0,
      status: json['status'] ?? '',
      collectionDate: DateTime.parse(json['collection_date'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      processedDate: json['processed_date'] != null ? DateTime.parse(json['processed_date']) : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'stall_id': stallId,
      'stall_name': stallName,
      'connector_id': connectorId,
      'connector_name': connectorName,
      'weight': weight,
      'waste_type': wasteType,
      'quality': quality,
      'eco_points_awarded': ecoPointsAwarded,
      'status': status,
      'collection_date': collectionDate.toIso8601String(),
      'processed_date': processedDate?.toIso8601String(),
      'notes': notes,
    };
  }
}

// Vendor Profile Model - represents vendors managed by vendor admin
class VendorProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? location;
  final String status; // active, inactive, pending, suspended
  final bool isVerified;
  final bool isActive;
  final String? profileImage;
  final String? description;
  final double averageRating;
  final int totalProducts;
  final int activeProducts;
  final int totalOrders;
  final double totalRevenue;
  final DateTime joinedAt;
  final DateTime? lastActiveAt;
  final Map<String, dynamic>? businessDetails;
  final List<String> categories;
  final String? businessLicense;
  final String? taxId;

  VendorProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.location,
    required this.status,
    this.isVerified = false,
    this.isActive = true,
    this.profileImage,
    this.description,
    this.averageRating = 0.0,
    this.totalProducts = 0,
    this.activeProducts = 0,
    this.totalOrders = 0,
    this.totalRevenue = 0.0,
    required this.joinedAt,
    this.lastActiveAt,
    this.businessDetails,
    this.categories = const [],
    this.businessLicense,
    this.taxId,
  });

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    return VendorProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      location: json['location'],
      status: json['status'] ?? 'pending',
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? true,
      profileImage: json['profile_image'],
      description: json['description'],
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalProducts: json['total_products'] ?? 0,
      activeProducts: json['active_products'] ?? 0,
      totalOrders: json['total_orders'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      joinedAt: DateTime.parse(json['joined_at'] ?? DateTime.now().toIso8601String()),
      lastActiveAt: json['last_active_at'] != null ? DateTime.parse(json['last_active_at']) : null,
      businessDetails: json['business_details'],
      categories: List<String>.from(json['categories'] ?? []),
      businessLicense: json['business_license'],
      taxId: json['tax_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
      'status': status,
      'is_verified': isVerified,
      'is_active': isActive,
      'profile_image': profileImage,
      'description': description,
      'average_rating': averageRating,
      'total_products': totalProducts,
      'active_products': activeProducts,
      'total_orders': totalOrders,
      'total_revenue': totalRevenue,
      'joined_at': joinedAt.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
      'business_details': businessDetails,
      'categories': categories,
      'business_license': businessLicense,
      'tax_id': taxId,
    };
  }
} 