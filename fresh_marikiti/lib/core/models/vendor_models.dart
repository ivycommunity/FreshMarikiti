// Vendor Models with full eco points system integration

import 'package:fresh_marikiti/core/models/connector_models.dart';

// Vendor Dashboard Metrics
class VendorMetrics {
  final int totalProducts;
  final int activeProducts;
  final int totalOrders;
  final int todaysOrders;
  final int pendingOrders;
  final int completedOrders;
  final double totalRevenue;
  final double todaysRevenue;
  final double averageOrderValue;
  final double revenueGrowth;
  final int totalCustomers;
  final int returningCustomers;
  final double customerRetentionRate;
  
  // Eco Points System
  final int totalEcoPoints;
  final int availableEcoPoints;
  final int redeemedEcoPoints;
  final double totalWasteCollected;
  final double todaysWaste;
  final int wasteCollections;
  final int todaysWasteCollections;
  final double carbonFootprintReduced;
  final String wasteCollectionRank;
  
  final DateTime lastUpdated;

  VendorMetrics({
    required this.totalProducts,
    required this.activeProducts,
    required this.totalOrders,
    required this.todaysOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.totalRevenue,
    required this.todaysRevenue,
    required this.averageOrderValue,
    required this.revenueGrowth,
    required this.totalCustomers,
    required this.returningCustomers,
    required this.customerRetentionRate,
    required this.totalEcoPoints,
    required this.availableEcoPoints,
    required this.redeemedEcoPoints,
    required this.totalWasteCollected,
    required this.todaysWaste,
    required this.wasteCollections,
    required this.todaysWasteCollections,
    required this.carbonFootprintReduced,
    required this.wasteCollectionRank,
    required this.lastUpdated,
  });

  factory VendorMetrics.fromJson(Map<String, dynamic> json) {
    return VendorMetrics(
      totalProducts: json['total_products'] ?? 0,
      activeProducts: json['active_products'] ?? 0,
      totalOrders: json['total_orders'] ?? 0,
      todaysOrders: json['todays_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      todaysRevenue: (json['todays_revenue'] ?? 0).toDouble(),
      averageOrderValue: (json['average_order_value'] ?? 0).toDouble(),
      revenueGrowth: (json['revenue_growth'] ?? 0).toDouble(),
      totalCustomers: json['total_customers'] ?? 0,
      returningCustomers: json['returning_customers'] ?? 0,
      customerRetentionRate: (json['customer_retention_rate'] ?? 0).toDouble(),
      totalEcoPoints: json['total_eco_points'] ?? 0,
      availableEcoPoints: json['available_eco_points'] ?? 0,
      redeemedEcoPoints: json['redeemed_eco_points'] ?? 0,
      totalWasteCollected: (json['total_waste_collected'] ?? 0).toDouble(),
      todaysWaste: (json['todays_waste'] ?? 0).toDouble(),
      wasteCollections: json['waste_collections'] ?? 0,
      todaysWasteCollections: json['todays_waste_collections'] ?? 0,
      carbonFootprintReduced: (json['carbon_footprint_reduced'] ?? 0).toDouble(),
      wasteCollectionRank: json['waste_collection_rank'] ?? 'Bronze',
      lastUpdated: DateTime.parse(json['last_updated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_products': totalProducts,
      'active_products': activeProducts,
      'total_orders': totalOrders,
      'todays_orders': todaysOrders,
      'pending_orders': pendingOrders,
      'completed_orders': completedOrders,
      'total_revenue': totalRevenue,
      'todays_revenue': todaysRevenue,
      'average_order_value': averageOrderValue,
      'revenue_growth': revenueGrowth,
      'total_customers': totalCustomers,
      'returning_customers': returningCustomers,
      'customer_retention_rate': customerRetentionRate,
      'total_eco_points': totalEcoPoints,
      'available_eco_points': availableEcoPoints,
      'redeemed_eco_points': redeemedEcoPoints,
      'total_waste_collected': totalWasteCollected,
      'todays_waste': todaysWaste,
      'waste_collections': wasteCollections,
      'todays_waste_collections': todaysWasteCollections,
      'carbon_footprint_reduced': carbonFootprintReduced,
      'waste_collection_rank': wasteCollectionRank,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

// Vendor Waste Collection Model
class VendorWasteCollection {
  final String id;
  final String connectorId;
  final String connectorName;
  final double weight;
  final String wasteType;
  final String quality;
  final int ecoPointsEarned;
  final String status;
  final DateTime collectionDate;
  final DateTime? processedDate;
  final String? notes;
  final List<String>? images;

  VendorWasteCollection({
    required this.id,
    required this.connectorId,
    required this.connectorName,
    required this.weight,
    required this.wasteType,
    required this.quality,
    required this.ecoPointsEarned,
    required this.status,
    required this.collectionDate,
    this.processedDate,
    this.notes,
    this.images,
  });

  factory VendorWasteCollection.fromJson(Map<String, dynamic> json) {
    return VendorWasteCollection(
      id: json['_id'] ?? json['id'] ?? '',
      connectorId: json['connector_id'] ?? '',
      connectorName: json['connector_name'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      wasteType: json['waste_type'] ?? '',
      quality: json['quality'] ?? '',
      ecoPointsEarned: json['eco_points_earned'] ?? json['ecoPointsAwarded'] ?? 0,
      status: json['status'] ?? '',
      collectionDate: DateTime.parse(json['collection_date'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      processedDate: json['processed_date'] != null ? DateTime.parse(json['processed_date']) : null,
      notes: json['notes'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'connector_id': connectorId,
      'connector_name': connectorName,
      'weight': weight,
      'waste_type': wasteType,
      'quality': quality,
      'eco_points_earned': ecoPointsEarned,
      'status': status,
      'collection_date': collectionDate.toIso8601String(),
      'processed_date': processedDate?.toIso8601String(),
      'notes': notes,
      'images': images,
    };
  }
}

// Vendor Eco Points Balance
class VendorEcoPointsBalance {
  final int currentBalance;
  final int totalEarned;
  final int totalRedeemed;
  final double walletBalance;
  final List<VendorEcoPointsTransaction> recentTransactions;

  VendorEcoPointsBalance({
    required this.currentBalance,
    required this.totalEarned,
    required this.totalRedeemed,
    required this.walletBalance,
    required this.recentTransactions,
  });

  factory VendorEcoPointsBalance.fromJson(Map<String, dynamic> json) {
    return VendorEcoPointsBalance(
      currentBalance: json['currentBalance'] ?? json['current_balance'] ?? 0,
      totalEarned: json['totalEarned'] ?? json['total_earned'] ?? 0,
      totalRedeemed: json['totalRedeemed'] ?? json['total_redeemed'] ?? 0,
      walletBalance: (json['walletBalance'] ?? json['wallet_balance'] ?? 0).toDouble(),
      recentTransactions: (json['pointsHistory'] ?? json['recent_transactions'] ?? [])
          .map((item) => VendorEcoPointsTransaction.fromJson(item))
          .toList()
          .cast<VendorEcoPointsTransaction>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_balance': currentBalance,
      'total_earned': totalEarned,
      'total_redeemed': totalRedeemed,
      'wallet_balance': walletBalance,
      'recent_transactions': recentTransactions.map((item) => item.toJson()).toList(),
    };
  }
}

// Vendor Eco Points Transaction
class VendorEcoPointsTransaction {
  final String id;
  final int points;
  final String description;
  final DateTime date;
  final String type; // earned, redeemed
  final String? status;

  VendorEcoPointsTransaction({
    required this.id,
    required this.points,
    required this.description,
    required this.date,
    required this.type,
    this.status,
  });

  factory VendorEcoPointsTransaction.fromJson(Map<String, dynamic> json) {
    return VendorEcoPointsTransaction(
      id: json['id'] ?? json['_id'] ?? '',
      points: json['points'] ?? 0,
      description: json['description'] ?? '',
      date: DateTime.parse(json['date'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      type: json['type'] ?? '',
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points,
      'description': description,
      'date': date.toIso8601String(),
      'type': type,
      'status': status,
    };
  }
}

// Vendor Analytics Model
class VendorAnalytics {
  final VendorMetrics metrics;
  final List<ChartDataPoint> revenueHistory;
  final List<ChartDataPoint> orderHistory;
  final List<ChartDataPoint> ecoPointsHistory;
  final List<ChartDataPoint> wasteCollectionHistory;
  final Map<String, double> productCategoryBreakdown;
  final Map<String, double> wasteTypeBreakdown;
  final List<VendorTopProduct> topProducts;
  final List<VendorCustomerInsight> topCustomers;
  final VendorSustainabilityReport sustainabilityReport;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String period;

  VendorAnalytics({
    required this.metrics,
    required this.revenueHistory,
    required this.orderHistory,
    required this.ecoPointsHistory,
    required this.wasteCollectionHistory,
    required this.productCategoryBreakdown,
    required this.wasteTypeBreakdown,
    required this.topProducts,
    required this.topCustomers,
    required this.sustainabilityReport,
    required this.periodStart,
    required this.periodEnd,
    required this.period,
  });

  factory VendorAnalytics.fromJson(Map<String, dynamic> json) {
    return VendorAnalytics(
      metrics: VendorMetrics.fromJson(json['metrics'] ?? {}),
      revenueHistory: (json['revenue_history'] as List? ?? [])
          .map((item) => ChartDataPoint.fromJson(item))
          .toList(),
      orderHistory: (json['order_history'] as List? ?? [])
          .map((item) => ChartDataPoint.fromJson(item))
          .toList(),
      ecoPointsHistory: (json['eco_points_history'] as List? ?? [])
          .map((item) => ChartDataPoint.fromJson(item))
          .toList(),
      wasteCollectionHistory: (json['waste_collection_history'] as List? ?? [])
          .map((item) => ChartDataPoint.fromJson(item))
          .toList(),
      productCategoryBreakdown: Map<String, double>.from(json['product_category_breakdown'] ?? {}),
      wasteTypeBreakdown: Map<String, double>.from(json['waste_type_breakdown'] ?? {}),
      topProducts: (json['top_products'] as List? ?? [])
          .map((item) => VendorTopProduct.fromJson(item))
          .toList(),
      topCustomers: (json['top_customers'] as List? ?? [])
          .map((item) => VendorCustomerInsight.fromJson(item))
          .toList(),
      sustainabilityReport: VendorSustainabilityReport.fromJson(json['sustainability_report'] ?? {}),
      periodStart: DateTime.parse(json['period_start'] ?? DateTime.now().toIso8601String()),
      periodEnd: DateTime.parse(json['period_end'] ?? DateTime.now().toIso8601String()),
      period: json['period'] ?? 'month',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metrics': metrics.toJson(),
      'revenue_history': revenueHistory.map((item) => item.toJson()).toList(),
      'order_history': orderHistory.map((item) => item.toJson()).toList(),
      'eco_points_history': ecoPointsHistory.map((item) => item.toJson()).toList(),
      'waste_collection_history': wasteCollectionHistory.map((item) => item.toJson()).toList(),
      'product_category_breakdown': productCategoryBreakdown,
      'waste_type_breakdown': wasteTypeBreakdown,
      'top_products': topProducts.map((item) => item.toJson()).toList(),
      'top_customers': topCustomers.map((item) => item.toJson()).toList(),
      'sustainability_report': sustainabilityReport.toJson(),
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'period': period,
    };
  }
}

// Vendor Top Product Model
class VendorTopProduct {
  final String id;
  final String name;
  final String category;
  final double revenue;
  final int quantitySold;
  final double averageRating;
  final int totalOrders;

  VendorTopProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.revenue,
    required this.quantitySold,
    required this.averageRating,
    required this.totalOrders,
  });

  factory VendorTopProduct.fromJson(Map<String, dynamic> json) {
    return VendorTopProduct(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
      quantitySold: json['quantity_sold'] ?? 0,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalOrders: json['total_orders'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'revenue': revenue,
      'quantity_sold': quantitySold,
      'average_rating': averageRating,
      'total_orders': totalOrders,
    };
  }
}

// Vendor Customer Insight Model
class VendorCustomerInsight {
  final String id;
  final String name;
  final double totalSpent;
  final int totalOrders;
  final DateTime lastOrder;
  final String status; // regular, vip, new

  VendorCustomerInsight({
    required this.id,
    required this.name,
    required this.totalSpent,
    required this.totalOrders,
    required this.lastOrder,
    required this.status,
  });

  factory VendorCustomerInsight.fromJson(Map<String, dynamic> json) {
    return VendorCustomerInsight(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      totalSpent: (json['total_spent'] ?? 0).toDouble(),
      totalOrders: json['total_orders'] ?? 0,
      lastOrder: DateTime.parse(json['last_order'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'total_spent': totalSpent,
      'total_orders': totalOrders,
      'last_order': lastOrder.toIso8601String(),
      'status': status,
    };
  }
}

// Vendor Sustainability Report Model
class VendorSustainabilityReport {
  final double totalWasteCollected;
  final double carbonFootprintReduced;
  final int ecoPointsEarned;
  final Map<String, double> wasteTypeBreakdown;
  final String environmentalImpactRating;
  final List<String> sustainabilityAchievements;
  final String nextMilestone;
  final double milestoneProgress; // percentage

  VendorSustainabilityReport({
    required this.totalWasteCollected,
    required this.carbonFootprintReduced,
    required this.ecoPointsEarned,
    required this.wasteTypeBreakdown,
    required this.environmentalImpactRating,
    required this.sustainabilityAchievements,
    required this.nextMilestone,
    required this.milestoneProgress,
  });

  factory VendorSustainabilityReport.fromJson(Map<String, dynamic> json) {
    return VendorSustainabilityReport(
      totalWasteCollected: (json['total_waste_collected'] ?? 0).toDouble(),
      carbonFootprintReduced: (json['carbon_footprint_reduced'] ?? 0).toDouble(),
      ecoPointsEarned: json['eco_points_earned'] ?? 0,
      wasteTypeBreakdown: Map<String, double>.from(json['waste_type_breakdown'] ?? {}),
      environmentalImpactRating: json['environmental_impact_rating'] ?? 'Bronze',
      sustainabilityAchievements: List<String>.from(json['sustainability_achievements'] ?? []),
      nextMilestone: json['next_milestone'] ?? '',
      milestoneProgress: (json['milestone_progress'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_waste_collected': totalWasteCollected,
      'carbon_footprint_reduced': carbonFootprintReduced,
      'eco_points_earned': ecoPointsEarned,
      'waste_type_breakdown': wasteTypeBreakdown,
      'environmental_impact_rating': environmentalImpactRating,
      'sustainability_achievements': sustainabilityAchievements,
      'next_milestone': nextMilestone,
      'milestone_progress': milestoneProgress,
    };
  }
}

// Eco Points Redemption Item Model
class EcoPointsRedemptionItem {
  final String id;
  final String name;
  final String description;
  final int pointsCost;
  final String type; // cash, discount, product, service
  final double value;
  final String category;
  final bool available;
  final String? imageUrl;
  final Map<String, dynamic>? terms;

  EcoPointsRedemptionItem({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsCost,
    required this.type,
    required this.value,
    required this.category,
    required this.available,
    this.imageUrl,
    this.terms,
  });

  factory EcoPointsRedemptionItem.fromJson(Map<String, dynamic> json) {
    return EcoPointsRedemptionItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      pointsCost: json['points_cost'] ?? json['pointsCost'] ?? 0,
      type: json['type'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      available: json['available'] ?? true,
      imageUrl: json['image_url'] ?? json['imageUrl'],
      terms: json['terms'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'points_cost': pointsCost,
      'type': type,
      'value': value,
      'category': category,
      'available': available,
      'image_url': imageUrl,
      'terms': terms,
    };
  }
}

// Eco Points Redemption Request Model
class EcoPointsRedemptionRequest {
  final String rewardId;
  final int quantity;

  EcoPointsRedemptionRequest({
    required this.rewardId,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'rewardId': rewardId,
      'quantity': quantity,
    };
  }
} 