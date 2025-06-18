import 'dart:convert';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/user.dart';

enum WasteType {
  organic,
  plastic,
  paper,
  metal,
  glass,
  electronic,
  textile,
  hazardous,
}

enum EcoActionType {
  organicPurchase,
  localSourcing,
  wasteReduction,
  reusablePackaging,
  carbonFootprintReduction,
  waterConservation,
  energySaving,
}

class WasteLog {
  final String id;
  final String userId;
  final String orderId;
  final WasteType wasteType;
  final double weight; // in kg
  final String description;
  final double ecoPointsEarned;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  WasteLog({
    required this.id,
    required this.userId,
    required this.orderId,
    required this.wasteType,
    required this.weight,
    required this.description,
    required this.ecoPointsEarned,
    this.imageUrl,
    this.metadata,
    required this.createdAt,
  });

  factory WasteLog.fromJson(Map<String, dynamic> json) {
    return WasteLog(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      orderId: json['orderId'] ?? '',
      wasteType: WasteType.values.firstWhere(
        (e) => e.toString().split('.').last == (json['wasteType'] ?? 'organic'),
        orElse: () => WasteType.organic,
      ),
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      ecoPointsEarned: (json['ecoPointsEarned'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'],
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'orderId': orderId,
      'wasteType': wasteType.toString().split('.').last,
      'weight': weight,
      'description': description,
      'ecoPointsEarned': ecoPointsEarned,
      'imageUrl': imageUrl,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class EcoAction {
  final String id;
  final String userId;
  final String? orderId;
  final EcoActionType actionType;
  final String description;
  final double impact; // Quantified environmental impact
  final double ecoPointsEarned;
  final String? verificationImageUrl;
  final Map<String, dynamic>? additionalData;
  final DateTime createdAt;

  EcoAction({
    required this.id,
    required this.userId,
    this.orderId,
    required this.actionType,
    required this.description,
    required this.impact,
    required this.ecoPointsEarned,
    this.verificationImageUrl,
    this.additionalData,
    required this.createdAt,
  });

  factory EcoAction.fromJson(Map<String, dynamic> json) {
    return EcoAction(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      orderId: json['orderId'],
      actionType: EcoActionType.values.firstWhere(
        (e) => e.toString().split('.').last == (json['actionType'] ?? 'organicPurchase'),
        orElse: () => EcoActionType.organicPurchase,
      ),
      description: json['description'] ?? '',
      impact: (json['impact'] as num?)?.toDouble() ?? 0.0,
      ecoPointsEarned: (json['ecoPointsEarned'] as num?)?.toDouble() ?? 0.0,
      verificationImageUrl: json['verificationImageUrl'],
      additionalData: json['additionalData'] as Map<String, dynamic>?,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'orderId': orderId,
      'actionType': actionType.toString().split('.').last,
      'description': description,
      'impact': impact,
      'ecoPointsEarned': ecoPointsEarned,
      'verificationImageUrl': verificationImageUrl,
      'additionalData': additionalData,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class EcoPointsBalance {
  final String userId;
  final double totalPoints;
  final double availablePoints;
  final double redeemedPoints;
  final int rank;
  final String tier; // Bronze, Silver, Gold, Platinum
  final DateTime lastUpdated;

  EcoPointsBalance({
    required this.userId,
    required this.totalPoints,
    required this.availablePoints,
    required this.redeemedPoints,
    required this.rank,
    required this.tier,
    required this.lastUpdated,
  });

  factory EcoPointsBalance.fromJson(Map<String, dynamic> json) {
    return EcoPointsBalance(
      userId: json['userId'] ?? '',
      totalPoints: (json['totalPoints'] as num?)?.toDouble() ?? 0.0,
      availablePoints: (json['availablePoints'] as num?)?.toDouble() ?? 0.0,
      redeemedPoints: (json['redeemedPoints'] as num?)?.toDouble() ?? 0.0,
      rank: json['rank'] ?? 0,
      tier: json['tier'] ?? 'Bronze',
      lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
    );
  }

  double get progressToNextTier {
    switch (tier) {
      case 'Bronze':
        return (totalPoints % 1000) / 1000; // Next tier at 1000 points
      case 'Silver':
        return (totalPoints % 5000) / 5000; // Next tier at 5000 points
      case 'Gold':
        return (totalPoints % 10000) / 10000; // Next tier at 10000 points
      default:
        return 1.0; // Platinum is max tier
    }
  }

  String get nextTier {
    switch (tier) {
      case 'Bronze':
        return 'Silver';
      case 'Silver':
        return 'Gold';
      case 'Gold':
        return 'Platinum';
      default:
        return 'Platinum';
    }
  }
}

class RedemptionItem {
  final String id;
  final String name;
  final String description;
  final String category;
  final double pointsCost;
  final String imageUrl;
  final bool isAvailable;
  final int? stockQuantity;
  final Map<String, dynamic>? terms;

  RedemptionItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.pointsCost,
    required this.imageUrl,
    required this.isAvailable,
    this.stockQuantity,
    this.terms,
  });

  factory RedemptionItem.fromJson(Map<String, dynamic> json) {
    return RedemptionItem(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      pointsCost: (json['pointsCost'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      stockQuantity: json['stockQuantity'],
      terms: json['terms'] as Map<String, dynamic>?,
    );
  }
}

class EcoPointsService {
  // =================== POINTS MANAGEMENT ===================

  /// Get user's eco-points balance
  static Future<EcoPointsBalance?> getBalance() async {
    try {
      final response = await ApiService.get('/eco-points/balance');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return EcoPointsBalance.fromJson(data['balance'] ?? data);
      }
      return null;
    } catch (e) {
      LoggerService.error('Error fetching eco-points balance', error: e, tag: 'EcoPointsService');
      return null;
    }
  }

  /// Award eco-points for specific action
  static Future<bool> awardPoints({
    required EcoActionType actionType,
    required String description,
    required double impact,
    String? orderId,
    String? verificationImageUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final requestData = {
        'actionType': actionType.toString().split('.').last,
        'description': description,
        'impact': impact,
        'orderId': orderId,
        'verificationImageUrl': verificationImageUrl,
        'additionalData': additionalData,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await ApiService.post('/eco-points/award', requestData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      LoggerService.error('Error awarding eco-points', error: e, tag: 'EcoPointsService');
      return false;
    }
  }

  /// Get eco-actions history
  static Future<List<EcoAction>> getEcoActionsHistory({
    int page = 1,
    int limit = 20,
    EcoActionType? filterType,
  }) async {
    try {
      String url = '/eco-points/actions?page=$page&limit=$limit';
      if (filterType != null) {
        url += '&type=${filterType.toString().split('.').last}';
      }

      final response = await ApiService.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final actions = data['actions'] ?? data['data'] ?? [];
        return actions.map<EcoAction>((json) => EcoAction.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      LoggerService.error('Error fetching eco-actions', error: e, tag: 'EcoPointsService');
      return [];
    }
  }

  // =================== WASTE TRACKING ===================

  /// Log waste reduction activity
  static Future<bool> logWasteReduction({
    required String orderId,
    required WasteType wasteType,
    required double weight,
    required String description,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final requestData = {
        'orderId': orderId,
        'wasteType': wasteType.toString().split('.').last,
        'weight': weight,
        'description': description,
        'imageUrl': imageUrl,
        'metadata': metadata,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await ApiService.post('/eco-points/waste-log', requestData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      LoggerService.error('Error logging waste reduction', error: e, tag: 'EcoPointsService');
      return false;
    }
  }

  /// Get waste logs history
  static Future<List<WasteLog>> getWasteLogs({
    int page = 1,
    int limit = 20,
    WasteType? filterType,
  }) async {
    try {
      String url = '/eco-points/waste-logs?page=$page&limit=$limit';
      if (filterType != null) {
        url += '&type=${filterType.toString().split('.').last}';
      }

      final response = await ApiService.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final logs = data['wasteLogs'] ?? data['data'] ?? [];
        return logs.map<WasteLog>((json) => WasteLog.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      LoggerService.error('Error fetching waste logs', error: e, tag: 'EcoPointsService');
      return [];
    }
  }

  /// Get waste reduction statistics
  static Future<Map<String, dynamic>> getWasteStats() async {
    try {
      final response = await ApiService.get('/eco-points/waste-stats');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['stats'] ?? {};
      }
      return {};
    } catch (e) {
      LoggerService.error('Error fetching waste stats', error: e, tag: 'EcoPointsService');
      return {};
    }
  }

  // =================== REDEMPTION SYSTEM ===================

  /// Get available redemption items
  static Future<List<RedemptionItem>> getRedemptionCatalog({
    String? category,
    double? maxPoints,
  }) async {
    try {
      String url = '/eco-points/redemption/catalog';
      List<String> params = [];
      
      if (category != null) params.add('category=$category');
      if (maxPoints != null) params.add('maxPoints=$maxPoints');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await ApiService.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] ?? data['data'] ?? [];
        return items.map<RedemptionItem>((json) => RedemptionItem.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      LoggerService.error('Error fetching redemption catalog', error: e, tag: 'EcoPointsService');
      return [];
    }
  }

  /// Redeem points for an item
  static Future<Map<String, dynamic>> redeemPoints({
    required String itemId,
    required double pointsCost,
    Map<String, dynamic>? deliveryInfo,
  }) async {
    try {
      final requestData = {
        'itemId': itemId,
        'pointsCost': pointsCost,
        'deliveryInfo': deliveryInfo,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await ApiService.post('/eco-points/redemption/redeem', requestData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'redemption': data['redemption'] ?? data,
          'newBalance': data['newBalance'],
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Redemption failed',
        };
      }
    } catch (e) {
      LoggerService.error('Error redeeming points', error: e, tag: 'EcoPointsService');
      return {
        'success': false,
        'message': 'Network error: Failed to redeem points',
      };
    }
  }

  /// Get redemption history
  static Future<List<Map<String, dynamic>>> getRedemptionHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await ApiService.get('/eco-points/redemption/history?page=$page&limit=$limit');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['redemptions'] ?? data['data'] ?? []);
      }
      return [];
    } catch (e) {
      LoggerService.error('Error fetching redemption history', error: e, tag: 'EcoPointsService');
      return [];
    }
  }

  // =================== LEADERBOARD & GAMIFICATION ===================

  /// Get eco-points leaderboard
  static Future<List<Map<String, dynamic>>> getLeaderboard({
    String period = 'monthly', // daily, weekly, monthly, all-time
    int limit = 50,
  }) async {
    try {
      final response = await ApiService.get('/eco-points/leaderboard?period=$period&limit=$limit');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['leaderboard'] ?? data['data'] ?? []);
      }
      return [];
    } catch (e) {
      LoggerService.error('Error fetching leaderboard', error: e, tag: 'EcoPointsService');
      return [];
    }
  }

  /// Get user's eco-impact analytics
  static Future<Map<String, dynamic>> getEcoImpactAnalytics() async {
    try {
      final response = await ApiService.get('/eco-points/impact-analytics');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      LoggerService.error('Error fetching eco-impact analytics', error: e, tag: 'EcoPointsService');
      return {};
    }
  }

  // =================== AUTOMATIC CALCULATIONS ===================

  /// Calculate eco-points for organic purchase
  static double calculateOrganicPurchasePoints(double orderValue) {
    // 1 point per KES 50 spent on organic items
    return (orderValue / 50).floor().toDouble();
  }

  /// Calculate eco-points for waste reduction
  static double calculateWasteReductionPoints(WasteType wasteType, double weight) {
    // Points multiplier based on waste type
    final multipliers = {
      WasteType.organic: 10.0,
      WasteType.plastic: 20.0,
      WasteType.electronic: 50.0,
      WasteType.hazardous: 100.0,
      WasteType.paper: 5.0,
      WasteType.glass: 15.0,
      WasteType.metal: 25.0,
      WasteType.textile: 8.0,
    };
    
    return weight * (multipliers[wasteType] ?? 10.0);
  }

  /// Calculate eco-points for local sourcing
  static double calculateLocalSourcingPoints(double distance) {
    // More points for shorter distances (local sourcing)
    if (distance <= 5) return 20.0; // Within 5km
    if (distance <= 10) return 15.0; // Within 10km
    if (distance <= 20) return 10.0; // Within 20km
    return 5.0; // Beyond 20km
  }

  /// Calculate carbon footprint reduction points
  static double calculateCarbonReductionPoints(double co2Saved) {
    // 10 points per kg of CO2 saved
    return co2Saved * 10;
  }

  // =================== AUTOMATIC AWARD TRIGGERS ===================

  /// Auto-award points for order completion
  static Future<void> autoAwardForOrder(String orderId, Map<String, dynamic> orderData) async {
    try {
      // Award points for organic purchases
      final organicValue = orderData['organicValue'] as double? ?? 0.0;
      if (organicValue > 0) {
        await awardPoints(
          actionType: EcoActionType.organicPurchase,
          description: 'Purchased organic items worth KES ${organicValue.toStringAsFixed(2)}',
          impact: organicValue,
          orderId: orderId,
        );
      }

      // Award points for local sourcing
      final distance = orderData['deliveryDistance'] as double? ?? 0.0;
      if (distance > 0) {
        await awardPoints(
          actionType: EcoActionType.localSourcing,
          description: 'Supported local vendor (${distance.toStringAsFixed(1)}km away)',
          impact: distance,
          orderId: orderId,
        );
      }

      // Award points for reusable packaging
      final reusablePackaging = orderData['reusablePackaging'] as bool? ?? false;
      if (reusablePackaging) {
        await awardPoints(
          actionType: EcoActionType.reusablePackaging,
          description: 'Used reusable packaging for delivery',
          impact: 1.0,
          orderId: orderId,
        );
      }
    } catch (e) {
      LoggerService.error('Error auto-awarding points for order', error: e, tag: 'EcoPointsService');
    }
  }

  // =================== UTILITY METHODS ===================

  /// Get tier color for UI
  static String getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return '#CD7F32';
      case 'silver':
        return '#C0C0C0';
      case 'gold':
        return '#FFD700';
      case 'platinum':
        return '#E5E4E2';
      default:
        return '#8E8E93';
    }
  }

  /// Get tier icon
  static String getTierIcon(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return '🥉';
      case 'silver':
        return '🥈';
      case 'gold':
        return '🥇';
      case 'platinum':
        return '💎';
      default:
        return '⭐';
    }
  }

  /// Format eco-points for display
  static String formatPoints(double points) {
    if (points >= 1000000) {
      return '${(points / 1000000).toStringAsFixed(1)}M';
    } else if (points >= 1000) {
      return '${(points / 1000).toStringAsFixed(1)}K';
    } else {
      return points.toStringAsFixed(0);
    }
  }

  /// Get waste type icon
  static String getWasteTypeIcon(WasteType type) {
    switch (type) {
      case WasteType.organic:
        return '🌿';
      case WasteType.plastic:
        return '♻️';
      case WasteType.paper:
        return '📄';
      case WasteType.glass:
        return '🍃';
      case WasteType.metal:
        return '🔧';
      case WasteType.electronic:
        return '📱';
      case WasteType.textile:
        return '👕';
      case WasteType.hazardous:
        return '☢️';
    }
  }
} 