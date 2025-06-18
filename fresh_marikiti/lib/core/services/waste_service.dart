import 'dart:convert';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/models/waste_request_model.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class WasteService {
  static const String _baseEndpoint = '/waste';

  // ===== Customer Functions =====

  /// Create a new waste pickup request
  static Future<Map<String, dynamic>> createWastePickupRequest({
    required String wasteType,
    required double estimatedWeight,
    required String location,
    required DateTime preferredPickupDate,
    String? description,
    Map<String, double>? coordinates,
  }) async {
    try {
      final requestData = {
        'wasteType': wasteType,
        'estimatedWeight': estimatedWeight,
        'location': location,
        'preferredPickupDate': preferredPickupDate.toIso8601String(),
        if (description != null) 'description': description,
        if (coordinates != null) 'coordinates': coordinates,
      };

      final response = await ApiService.post('$_baseEndpoint/request', requestData);
      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Waste pickup request created successfully',
          'request': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create request',
        };
      }
    } catch (e) {
      LoggerService.error('Error creating waste pickup request', tag: 'WasteService', error: e);
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get user's waste pickup requests
  static Future<List<WasteRequest>> getMyWasteRequests() async {
    try {
      final response = await ApiService.get('$_baseEndpoint/my-requests');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final requestsData = responseData['requests'] ?? responseData['data'] ?? [];
        
        return (requestsData as List)
            .map((data) => WasteRequest.fromJson(data))
            .toList();
      } else {
        LoggerService.error('Failed to fetch requests: ${response.statusCode}', tag: 'WasteService');
        return [];
      }
    } catch (e) {
      LoggerService.error('Error fetching waste requests', tag: 'WasteService', error: e);
      return [];
    }
  }

  /// Cancel a waste pickup request
  static Future<Map<String, dynamic>> cancelWasteRequest(String requestId) async {
    try {
      final response = await ApiService.delete('$_baseEndpoint/requests/$requestId');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Request cancelled successfully',
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to cancel request',
        };
      }
    } catch (e) {
      LoggerService.error('Error cancelling waste request', tag: 'WasteService', error: e);
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // ===== Connector Functions =====

  /// Get available waste pickup requests for connectors
  static Future<List<WasteRequest>> getAvailableRequests() async {
    try {
      final response = await ApiService.get('$_baseEndpoint/connector/available-requests');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final requestsData = responseData['requests'] ?? responseData['data'] ?? [];
        
        return (requestsData as List)
            .map((data) => WasteRequest.fromJson(data))
            .toList();
      } else {
        LoggerService.error('Failed to fetch available requests: ${response.statusCode}', tag: 'WasteService');
        return [];
      }
    } catch (e) {
      LoggerService.error('Error fetching available requests', tag: 'WasteService', error: e);
      return [];
    }
  }

  /// Accept a waste pickup request
  static Future<Map<String, dynamic>> acceptWasteRequest(String requestId) async {
    try {
      final response = await ApiService.patch('$_baseEndpoint/requests/$requestId/accept', {});
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Request accepted successfully',
          'request': responseData,
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to accept request',
        };
      }
    } catch (e) {
      LoggerService.error('Error accepting waste request', tag: 'WasteService', error: e);
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Complete a waste pickup
  static Future<Map<String, dynamic>> completeWastePickup({
    required String requestId,
    required double actualWeight,
    required int qualityRating,
    String? notes,
  }) async {
    try {
      final completionData = {
        'actualWeight': actualWeight,
        'qualityRating': qualityRating,
        if (notes != null) 'notes': notes,
      };

      final response = await ApiService.patch(
        '$_baseEndpoint/requests/$requestId/complete',
        completionData,
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Pickup completed successfully',
          'ecoPoints': responseData['ecoPointsAwarded'],
          'request': responseData,
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to complete pickup',
        };
      }
    } catch (e) {
      LoggerService.error('Error completing waste pickup', tag: 'WasteService', error: e);
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get connector's assigned requests
  static Future<List<WasteRequest>> getMyAssignedRequests() async {
    try {
      final response = await ApiService.get('$_baseEndpoint/connector/my-requests');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final requestsData = responseData['requests'] ?? responseData['data'] ?? [];
        
        return (requestsData as List)
            .map((data) => WasteRequest.fromJson(data))
            .toList();
      } else {
        LoggerService.error('Failed to fetch assigned requests: ${response.statusCode}', tag: 'WasteService');
        return [];
      }
    } catch (e) {
      LoggerService.error('Error fetching assigned requests', tag: 'WasteService', error: e);
      return [];
    }
  }

  // ===== Vendor Functions =====

  /// Get vendor's waste collection logs
  static Future<List<Map<String, dynamic>>> getVendorWasteLogs() async {
    try {
      final response = await ApiService.get('$_baseEndpoint/vendor/logs');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final logsData = responseData['logs'] ?? responseData['data'] ?? [];
        
        return List<Map<String, dynamic>>.from(logsData);
      } else {
        LoggerService.error('Failed to fetch vendor logs: ${response.statusCode}', tag: 'WasteService');
        return [];
      }
    } catch (e) {
      LoggerService.error('Error fetching vendor waste logs', tag: 'WasteService', error: e);
      return [];
    }
  }

  // ===== Eco Points Functions =====

  /// Get user's eco points balance
  static Future<Map<String, dynamic>> getEcoPointsBalance() async {
    try {
      final response = await ApiService.get('/eco-redemption/balance');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        LoggerService.error('Failed to fetch eco points balance: ${response.statusCode}', tag: 'WasteService');
        return {'ecoPoints': 0, 'totalEarned': 0, 'totalRedeemed': 0};
      }
    } catch (e) {
      LoggerService.error('Error fetching eco points balance', tag: 'WasteService', error: e);
      return {'ecoPoints': 0, 'totalEarned': 0, 'totalRedeemed': 0};
    }
  }

  /// Get available rewards for redemption
  static Future<List<Map<String, dynamic>>> getAvailableRewards() async {
    try {
      final response = await ApiService.get('/eco-redemption/rewards');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final rewardsData = responseData['rewards'] ?? responseData['data'] ?? [];
        
        return List<Map<String, dynamic>>.from(rewardsData);
      } else {
        LoggerService.error('Failed to fetch rewards: ${response.statusCode}', tag: 'WasteService');
        return [];
      }
    } catch (e) {
      LoggerService.error('Error fetching available rewards', tag: 'WasteService', error: e);
      return [];
    }
  }

  /// Redeem reward with eco points
  static Future<Map<String, dynamic>> redeemReward(String rewardId) async {
    try {
      final response = await ApiService.post('/eco-redemption/redeem', {
        'rewardId': rewardId,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Reward redeemed successfully',
          'redemption': responseData,
        };
      } else {
        final responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to redeem reward',
        };
      }
    } catch (e) {
      LoggerService.error('Error redeeming reward', tag: 'WasteService', error: e);
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get user's points history
  static Future<List<Map<String, dynamic>>> getPointsHistory() async {
    try {
      final response = await ApiService.get('/eco-redemption/history');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final historyData = responseData['history'] ?? responseData['data'] ?? [];
        
        return List<Map<String, dynamic>>.from(historyData);
      } else {
        LoggerService.error('Failed to fetch points history: ${response.statusCode}', tag: 'WasteService');
        return [];
      }
    } catch (e) {
      LoggerService.error('Error fetching points history', tag: 'WasteService', error: e);
      return [];
    }
  }

  /// Get leaderboard
  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final response = await ApiService.get('/eco-redemption/leaderboard');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final leaderboardData = responseData['leaderboard'] ?? responseData['data'] ?? [];
        
        return List<Map<String, dynamic>>.from(leaderboardData);
      } else {
        LoggerService.error('Failed to fetch leaderboard: ${response.statusCode}', tag: 'WasteService');
        return [];
      }
    } catch (e) {
      LoggerService.error('Error fetching leaderboard', tag: 'WasteService', error: e);
      return [];
    }
  }

  // ===== Analytics Functions =====

  /// Get admin analytics
  static Future<Map<String, dynamic>> getAdminAnalytics({String period = 'week'}) async {
    try {
      final response = await ApiService.get('/eco-redemption/admin/analytics?period=$period');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        LoggerService.error('Failed to fetch admin analytics: ${response.statusCode}', tag: 'WasteService');
        return {};
      }
    } catch (e) {
      LoggerService.error('Error fetching admin analytics', tag: 'WasteService', error: e);
      return {};
    }
  }

  /// Get vendor admin analytics
  static Future<Map<String, dynamic>> getVendorAdminAnalytics({String period = 'week'}) async {
    try {
      final response = await ApiService.get('/eco-redemption/vendor-admin/analytics?period=$period');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        LoggerService.error('Failed to fetch vendor admin analytics: ${response.statusCode}', tag: 'WasteService');
        return {};
      }
    } catch (e) {
      LoggerService.error('Error fetching vendor admin analytics', tag: 'WasteService', error: e);
      return {};
    }
  }

  /// Calculate eco points for waste type and weight
  static int calculateEcoPoints(String wasteType, double weight, {int qualityRating = 5}) {
    const Map<String, int> pointsPerKg = {
      'organic': 5,
      'recyclable': 8,
      'plastic': 8,
      'paper': 6,
      'metal': 10,
      'glass': 7,
      'mixed': 4,
      'hazardous': 15,
      'electronic': 12,
    };

    final basePoints = pointsPerKg[wasteType.toLowerCase()] ?? 4;
    final qualityMultiplier = 0.8 + (qualityRating - 1) * 0.1; // 0.8 to 1.2
    
    return (basePoints * weight * qualityMultiplier).round();
  }

  /// Get waste type options
  static List<String> getWasteTypes() {
    return const [
      'Organic',
      'Recyclable',
      'Plastic',
      'Paper',
      'Metal',
      'Glass',
      'Mixed',
      'Hazardous',
      'Electronic',
    ];
  }

  /// Get quality rating descriptions
  static Map<int, String> getQualityRatingDescriptions() {
    return const {
      1: 'Poor - Mixed contamination',
      2: 'Fair - Some contamination',
      3: 'Good - Minor sorting needed',
      4: 'Very Good - Well sorted',
      5: 'Excellent - Perfect condition',
    };
  }
} 