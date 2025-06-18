
// System Metrics Model
class SystemMetrics {
  final int totalUsers;
  final int activeOrders;
  final double totalRevenue;
  final int totalVendors;
  final int totalRiders;
  final int totalConnectors;
  final double systemLoad;
  final String systemStatus;
  final String uptime;
  final double revenueGrowth;
  final double orderGrowthRate;
  final double userGrowthRate;
  
  // Eco Points System Metrics
  final int totalEcoPoints;
  final int ecoPointsEarnedToday;
  final int ecoPointsRedeemedToday;
  final double totalWasteCollected;
  final double wasteCollectedToday;
  final int totalWasteCollections;
  final int wasteCollectionsToday;
  final double carbonFootprintReduced;
  final int activeConnectors;
  final Map<String, int> userRoleBreakdown;
  final Map<String, double> wasteTypeBreakdown;
  final Map<String, int> ecoPointsLeaderboard; // user_id -> points
  
  final DateTime lastUpdated;

  SystemMetrics({
    required this.totalUsers,
    required this.activeOrders,
    required this.totalRevenue,
    required this.totalVendors,
    required this.totalRiders,
    required this.totalConnectors,
    required this.systemLoad,
    required this.systemStatus,
    required this.uptime,
    required this.revenueGrowth,
    required this.orderGrowthRate,
    required this.userGrowthRate,
    required this.totalEcoPoints,
    required this.ecoPointsEarnedToday,
    required this.ecoPointsRedeemedToday,
    required this.totalWasteCollected,
    required this.wasteCollectedToday,
    required this.totalWasteCollections,
    required this.wasteCollectionsToday,
    required this.carbonFootprintReduced,
    required this.activeConnectors,
    required this.userRoleBreakdown,
    required this.wasteTypeBreakdown,
    required this.ecoPointsLeaderboard,
    required this.lastUpdated,
  });

  factory SystemMetrics.fromJson(Map<String, dynamic> json) {
    return SystemMetrics(
      totalUsers: json['total_users'] ?? 0,
      activeOrders: json['active_orders'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      totalVendors: json['total_vendors'] ?? 0,
      totalRiders: json['total_riders'] ?? 0,
      totalConnectors: json['total_connectors'] ?? 0,
      systemLoad: (json['system_load'] ?? 0).toDouble(),
      systemStatus: json['system_status'] ?? 'unknown',
      uptime: json['uptime'] ?? '0%',
      revenueGrowth: (json['revenue_growth'] ?? 0).toDouble(),
      orderGrowthRate: (json['order_growth_rate'] ?? 0).toDouble(),
      userGrowthRate: (json['user_growth_rate'] ?? 0).toDouble(),
      totalEcoPoints: json['total_eco_points'] ?? 0,
      ecoPointsEarnedToday: json['eco_points_earned_today'] ?? 0,
      ecoPointsRedeemedToday: json['eco_points_redeemed_today'] ?? 0,
      totalWasteCollected: (json['total_waste_collected'] ?? 0).toDouble(),
      wasteCollectedToday: (json['waste_collected_today'] ?? 0).toDouble(),
      totalWasteCollections: json['total_waste_collections'] ?? 0,
      wasteCollectionsToday: json['waste_collections_today'] ?? 0,
      carbonFootprintReduced: (json['carbon_footprint_reduced'] ?? 0).toDouble(),
      activeConnectors: json['active_connectors'] ?? 0,
      userRoleBreakdown: Map<String, int>.from(json['user_role_breakdown'] ?? {}),
      wasteTypeBreakdown: Map<String, double>.from(json['waste_type_breakdown'] ?? {}),
      ecoPointsLeaderboard: Map<String, int>.from(json['eco_points_leaderboard'] ?? {}),
      lastUpdated: DateTime.parse(json['last_updated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_users': totalUsers,
      'active_orders': activeOrders,
      'total_revenue': totalRevenue,
      'total_vendors': totalVendors,
      'total_riders': totalRiders,
      'total_connectors': totalConnectors,
      'system_load': systemLoad,
      'system_status': systemStatus,
      'uptime': uptime,
      'revenue_growth': revenueGrowth,
      'order_growth_rate': orderGrowthRate,
      'user_growth_rate': userGrowthRate,
      'total_eco_points': totalEcoPoints,
      'eco_points_earned_today': ecoPointsEarnedToday,
      'eco_points_redeemed_today': ecoPointsRedeemedToday,
      'total_waste_collected': totalWasteCollected,
      'waste_collected_today': wasteCollectedToday,
      'total_waste_collections': totalWasteCollections,
      'waste_collections_today': wasteCollectionsToday,
      'carbon_footprint_reduced': carbonFootprintReduced,
      'active_connectors': activeConnectors,
      'user_role_breakdown': userRoleBreakdown,
      'waste_type_breakdown': wasteTypeBreakdown,
      'eco_points_leaderboard': ecoPointsLeaderboard,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

// Recent Activity Model
class RecentActivity {
  final String id;
  final String type;
  final String description;
  final String userId;
  final String userName;
  final DateTime timestamp;
  final bool isImportant;
  final Map<String, dynamic>? metadata;

  RecentActivity({
    required this.id,
    required this.type,
    required this.description,
    required this.userId,
    required this.userName,
    required this.timestamp,
    this.isImportant = false,
    this.metadata,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isImportant: json['is_important'] ?? false,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'user_id': userId,
      'user_name': userName,
      'timestamp': timestamp.toIso8601String(),
      'is_important': isImportant,
      'metadata': metadata,
    };
  }
}

// System Alert Model
class SystemAlert {
  final String id;
  final String title;
  final String message;
  final String severity;
  final DateTime timestamp;
  final bool isRead;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;

  SystemAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.isRead = false,
    this.actionUrl,
    this.metadata,
  });

  factory SystemAlert.fromJson(Map<String, dynamic> json) {
    return SystemAlert(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      severity: json['severity'] ?? 'info',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['is_read'] ?? false,
      actionUrl: json['action_url'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'severity': severity,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'action_url': actionUrl,
      'metadata': metadata,
    };
  }
}

// Admin User Model
class AdminUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final bool isActive;
  final bool isVerified;
  final String? location;
  final int ecoPoints;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String? profileImage;
  final Map<String, dynamic>? metadata;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.isActive = true,
    this.isVerified = false,
    this.location,
    this.ecoPoints = 0,
    required this.createdAt,
    this.lastLogin,
    this.profileImage,
    this.metadata,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'customer',
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
      location: json['location'],
      ecoPoints: json['eco_points'] ?? json['ecoPoints'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      profileImage: json['profile_image'] ?? json['profileImage'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'is_active': isActive,
      'is_verified': isVerified,
      'location': location,
      'eco_points': ecoPoints,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'profile_image': profileImage,
      'metadata': metadata,
    };
  }
}

// Create User Request Model
class CreateUserRequest {
  final String name;
  final String email;
  final String password;
  final String role;
  final String? phone;
  final String? location;
  final bool isActive;

  CreateUserRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.phone,
    this.location,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'phone': phone,
      'location': location,
      'is_active': isActive,
    };
  }
}

// Update User Request Model
class UpdateUserRequest {
  final String? name;
  final String? email;
  final String? phone;
  final String? role;
  final String? location;
  final bool? isActive;
  final bool? isVerified;

  UpdateUserRequest({
    this.name,
    this.email,
    this.phone,
    this.role,
    this.location,
    this.isActive,
    this.isVerified,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (role != null) data['role'] = role;
    if (location != null) data['location'] = location;
    if (isActive != null) data['is_active'] = isActive;
    if (isVerified != null) data['is_verified'] = isVerified;
    
    return data;
  }
}

// Admin Analytics Model
class AdminAnalytics {
  final Map<String, dynamic> revenue;
  final Map<String, dynamic> orders;
  final Map<String, dynamic> users;
  final Map<String, dynamic> vendors;
  final List<ChartData> revenueChart;
  final List<ChartData> orderChart;
  final List<ChartData> userChart;
  final DateTime generatedAt;

  AdminAnalytics({
    required this.revenue,
    required this.orders,
    required this.users,
    required this.vendors,
    required this.revenueChart,
    required this.orderChart,
    required this.userChart,
    required this.generatedAt,
  });

  factory AdminAnalytics.fromJson(Map<String, dynamic> json) {
    return AdminAnalytics(
      revenue: json['revenue'] ?? {},
      orders: json['orders'] ?? {},
      users: json['users'] ?? {},
      vendors: json['vendors'] ?? {},
      revenueChart: (json['revenue_chart'] as List? ?? [])
          .map((item) => ChartData.fromJson(item))
          .toList(),
      orderChart: (json['order_chart'] as List? ?? [])
          .map((item) => ChartData.fromJson(item))
          .toList(),
      userChart: (json['user_chart'] as List? ?? [])
          .map((item) => ChartData.fromJson(item))
          .toList(),
      generatedAt: DateTime.parse(json['generated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'revenue': revenue,
      'orders': orders,
      'users': users,
      'vendors': vendors,
      'revenue_chart': revenueChart.map((item) => item.toJson()).toList(),
      'order_chart': orderChart.map((item) => item.toJson()).toList(),
      'user_chart': userChart.map((item) => item.toJson()).toList(),
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

// Chart Data Model
class ChartData {
  final String label;
  final double value;
  final DateTime date;

  ChartData({
    required this.label,
    required this.value,
    required this.date,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      label: json['label'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'date': date.toIso8601String(),
    };
  }
}

// Financial Report Model
class FinancialReport {
  final double totalRevenue;
  final double totalCommissions;
  final double vendorEarnings;
  final double riderEarnings;
  final double platformEarnings;
  final Map<String, double> revenueByCategory;
  final Map<String, double> commissionBreakdown;
  final List<ChartData> revenueHistory;
  final DateTime reportPeriodStart;
  final DateTime reportPeriodEnd;
  final DateTime generatedAt;

  FinancialReport({
    required this.totalRevenue,
    required this.totalCommissions,
    required this.vendorEarnings,
    required this.riderEarnings,
    required this.platformEarnings,
    required this.revenueByCategory,
    required this.commissionBreakdown,
    required this.revenueHistory,
    required this.reportPeriodStart,
    required this.reportPeriodEnd,
    required this.generatedAt,
  });

  factory FinancialReport.fromJson(Map<String, dynamic> json) {
    return FinancialReport(
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      totalCommissions: (json['total_commissions'] ?? 0).toDouble(),
      vendorEarnings: (json['vendor_earnings'] ?? 0).toDouble(),
      riderEarnings: (json['rider_earnings'] ?? 0).toDouble(),
      platformEarnings: (json['platform_earnings'] ?? 0).toDouble(),
      revenueByCategory: Map<String, double>.from(json['revenue_by_category'] ?? {}),
      commissionBreakdown: Map<String, double>.from(json['commission_breakdown'] ?? {}),
      revenueHistory: (json['revenue_history'] as List? ?? [])
          .map((item) => ChartData.fromJson(item))
          .toList(),
      reportPeriodStart: DateTime.parse(json['report_period_start'] ?? DateTime.now().toIso8601String()),
      reportPeriodEnd: DateTime.parse(json['report_period_end'] ?? DateTime.now().toIso8601String()),
      generatedAt: DateTime.parse(json['generated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_revenue': totalRevenue,
      'total_commissions': totalCommissions,
      'vendor_earnings': vendorEarnings,
      'rider_earnings': riderEarnings,
      'platform_earnings': platformEarnings,
      'revenue_by_category': revenueByCategory,
      'commission_breakdown': commissionBreakdown,
      'revenue_history': revenueHistory.map((item) => item.toJson()).toList(),
      'report_period_start': reportPeriodStart.toIso8601String(),
      'report_period_end': reportPeriodEnd.toIso8601String(),
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

// Admin Order Model
class AdminOrder {
  final String id;
  final String customerId;
  final String customerName;
  final String vendorId;
  final String vendorName;
  final String? riderId;
  final String? riderName;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String deliveryAddress;
  final List<OrderItem> items;

  AdminOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.vendorId,
    required this.vendorName,
    this.riderId,
    this.riderName,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    this.deliveredAt,
    required this.deliveryAddress,
    required this.items,
  });

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    return AdminOrder(
      id: json['_id'] ?? json['id'] ?? '',
      customerId: json['customer_id'] ?? '',
      customerName: json['customer_name'] ?? '',
      vendorId: json['vendor_id'] ?? '',
      vendorName: json['vendor_name'] ?? '',
      riderId: json['rider_id'],
      riderName: json['rider_name'],
      status: json['status'] ?? '',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['delivery_fee'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? '',
      paymentStatus: json['payment_status'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
      deliveryAddress: json['delivery_address'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((item) => OrderItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'rider_id': riderId,
      'rider_name': riderName,
      'status': status,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'total': total,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'created_at': createdAt.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'delivery_address': deliveryAddress,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

// Order Item Model
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
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
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

// System Settings Model
class SystemSettings {
  final bool maintenanceMode;
  final bool allowNewRegistrations;
  final bool enableNotifications;
  final bool requireEmailVerification;
  final double platformFeePercentage;
  final double deliveryCommissionPercentage;
  final double minOrderAmount;
  final double maxOrderAmount;
  final double defaultDeliveryFee;
  final String supportEmail;
  final String supportPhone;
  final Map<String, dynamic> features;
  final Map<String, dynamic> limits;

  SystemSettings({
    required this.maintenanceMode,
    required this.allowNewRegistrations,
    required this.enableNotifications,
    required this.requireEmailVerification,
    required this.platformFeePercentage,
    required this.deliveryCommissionPercentage,
    required this.minOrderAmount,
    required this.maxOrderAmount,
    required this.defaultDeliveryFee,
    required this.supportEmail,
    required this.supportPhone,
    required this.features,
    required this.limits,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      maintenanceMode: json['maintenance_mode'] ?? false,
      allowNewRegistrations: json['allow_new_registrations'] ?? true,
      enableNotifications: json['enable_notifications'] ?? true,
      requireEmailVerification: json['require_email_verification'] ?? true,
      platformFeePercentage: (json['platform_fee_percentage'] ?? 0).toDouble(),
      deliveryCommissionPercentage: (json['delivery_commission_percentage'] ?? 5).toDouble(),
      minOrderAmount: (json['min_order_amount'] ?? 100).toDouble(),
      maxOrderAmount: (json['max_order_amount'] ?? 10000).toDouble(),
      defaultDeliveryFee: (json['default_delivery_fee'] ?? 50).toDouble(),
      supportEmail: json['support_email'] ?? '',
      supportPhone: json['support_phone'] ?? '',
      features: json['features'] ?? {},
      limits: json['limits'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maintenance_mode': maintenanceMode,
      'allow_new_registrations': allowNewRegistrations,
      'enable_notifications': enableNotifications,
      'require_email_verification': requireEmailVerification,
      'platform_fee_percentage': platformFeePercentage,
      'delivery_commission_percentage': deliveryCommissionPercentage,
      'min_order_amount': minOrderAmount,
      'max_order_amount': maxOrderAmount,
      'default_delivery_fee': defaultDeliveryFee,
      'support_email': supportEmail,
      'support_phone': supportPhone,
      'features': features,
      'limits': limits,
    };
  }
}

// System Log Model
class SystemLog {
  final String id;
  final String level;
  final String category;
  final String message;
  final DateTime timestamp;
  final String? userId;
  final String? ipAddress;
  final Map<String, dynamic>? metadata;

  SystemLog({
    required this.id,
    required this.level,
    required this.category,
    required this.message,
    required this.timestamp,
    this.userId,
    this.ipAddress,
    this.metadata,
  });

  factory SystemLog.fromJson(Map<String, dynamic> json) {
    return SystemLog(
      id: json['_id'] ?? json['id'] ?? '',
      level: json['level'] ?? 'info',
      category: json['category'] ?? 'system',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      userId: json['user_id'],
      ipAddress: json['ip_address'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level,
      'category': category,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
      'ip_address': ipAddress,
      'metadata': metadata,
    };
  }
} 