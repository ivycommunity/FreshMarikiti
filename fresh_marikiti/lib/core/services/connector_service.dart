import 'dart:convert';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/connector_models.dart';

class ConnectorService {
  static const String _baseUrl = '/connector';

  // =================== DASHBOARD & METRICS ===================

  /// Get connector dashboard metrics
  static Future<Map<String, dynamic>?> getDashboardMetrics() async {
    try {
      final response = await ApiService.get('$_baseUrl/dashboard');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['dashboard'] ?? data;
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to fetch connector dashboard metrics', error: e, tag: 'ConnectorService');
      return null;
    }
  }

  // =================== ORDER MANAGEMENT ===================

  /// Get available orders for connector
  static Future<List<Map<String, dynamic>>> getAvailableOrders({
    int page = 1,
    int limit = 20,
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    try {
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      if (latitude != null) queryParams.add('latitude=$latitude');
      if (longitude != null) queryParams.add('longitude=$longitude');
      if (radius != null) queryParams.add('radius=$radius');

      final endpoint = '$_baseUrl/orders/available?${queryParams.join('&')}';
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['orders'] ?? []);
      }
      return [];
    } catch (e) {
      LoggerService.error('Failed to fetch available orders', error: e, tag: 'ConnectorService');
      return [];
    }
  }

  /// Accept an order
  static Future<bool> acceptOrder(String orderId) async {
    try {
      final response = await ApiService.post('$_baseUrl/orders/$orderId/accept', {});
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to accept order', error: e, tag: 'ConnectorService');
      return false;
    }
  }

  /// Update order status
  static Future<bool> updateOrderStatus(String orderId, String status, {String? notes}) async {
    try {
      final requestData = {
        'status': status,
        if (notes != null) 'notes': notes,
      };

      final response = await ApiService.patch('$_baseUrl/orders/$orderId/status', requestData);
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to update order status', error: e, tag: 'ConnectorService');
      return false;
    }
  }

  // =================== WASTE COLLECTION ===================

  /// Get waste collections
  static Future<List<WasteCollection>> getWasteCollections({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      if (status != null) queryParams.add('status=$status');

      final endpoint = '$_baseUrl/waste-collections?${queryParams.join('&')}';
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['collections'] as List? ?? [])
            .map((json) => WasteCollection.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      LoggerService.error('Failed to fetch waste collections', error: e, tag: 'ConnectorService');
      return [];
    }
  }

  /// Log new waste collection
  static Future<WasteCollection?> logWasteCollection({
    required String vendorId,
    required Map<String, dynamic> wasteData,
    String? notes,
  }) async {
    try {
      final requestData = {
        'vendorId': vendorId,
        'wasteData': wasteData,
        if (notes != null) 'notes': notes,
      };

      final response = await ApiService.post('$_baseUrl/waste-collections', requestData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return WasteCollection.fromJson(data['collection'] ?? data);
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to log waste collection', error: e, tag: 'ConnectorService');
      return null;
    }
  }

  /// Update waste collection
  static Future<bool> updateWasteCollection(String collectionId, Map<String, dynamic> updates) async {
    try {
      final response = await ApiService.patch('$_baseUrl/waste-collections/$collectionId', updates);
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to update waste collection', error: e, tag: 'ConnectorService');
      return false;
    }
  }

  // =================== ECO POINTS ===================

  /// Get eco points summary
  static Future<Map<String, dynamic>?> getEcoPointsSummary() async {
    try {
      final response = await ApiService.get('$_baseUrl/eco-points');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['summary'] ?? data;
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to fetch eco points summary', error: e, tag: 'ConnectorService');
      return null;
    }
  }

  /// Award eco points to vendor
  static Future<bool> awardEcoPoints({
    required String vendorId,
    required int points,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final requestData = {
        'vendorId': vendorId,
        'points': points,
        'reason': reason,
        'metadata': metadata ?? {},
      };

      final response = await ApiService.post('$_baseUrl/eco-points/award', requestData);
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to award eco points', error: e, tag: 'ConnectorService');
      return false;
    }
  }

  // =================== VENDOR MANAGEMENT ===================

  /// Get nearby vendors
  static Future<List<Map<String, dynamic>>> getNearbyVendors({
    required double latitude,
    required double longitude,
    double radius = 5.0,
  }) async {
    try {
      final queryParams = [
        'latitude=$latitude',
        'longitude=$longitude',
        'radius=$radius',
      ];

      final endpoint = '$_baseUrl/vendors/nearby?${queryParams.join('&')}';
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['vendors'] ?? []);
      }
      return [];
    } catch (e) {
      LoggerService.error('Failed to fetch nearby vendors', error: e, tag: 'ConnectorService');
      return [];
    }
  }

  /// Get vendor details
  static Future<Map<String, dynamic>?> getVendorDetails(String vendorId) async {
    try {
      final response = await ApiService.get('$_baseUrl/vendors/$vendorId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['vendor'] ?? data;
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to fetch vendor details', error: e, tag: 'ConnectorService');
      return null;
    }
  }

  // =================== LOCATION & TRACKING ===================

  /// Update connector location
  static Future<bool> updateLocation({
    required double latitude,
    required double longitude,
    String? orderId,
  }) async {
    try {
      final requestData = {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
        if (orderId != null) 'orderId': orderId,
      };

      final response = await ApiService.post('$_baseUrl/location', requestData);
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to update location', error: e, tag: 'ConnectorService');
      return false;
    }
  }

  // =================== RIDER MANAGEMENT ===================

  /// Get available riders
  static Future<List<Map<String, dynamic>>> getAvailableRiders({
    double? latitude,
    double? longitude,
    double radius = 10.0,
  }) async {
    try {
      final queryParams = <String>[];
      if (latitude != null) queryParams.add('latitude=$latitude');
      if (longitude != null) queryParams.add('longitude=$longitude');
      queryParams.add('radius=$radius');

      final endpoint = '$_baseUrl/riders/available?${queryParams.join('&')}';
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['riders'] ?? []);
      }
      return [];
    } catch (e) {
      LoggerService.error('Failed to fetch available riders', error: e, tag: 'ConnectorService');
      return [];
    }
  }

  /// Assign rider to order
  static Future<bool> assignRider(String orderId, String riderId) async {
    try {
      final requestData = {'riderId': riderId};
      final response = await ApiService.post('$_baseUrl/orders/$orderId/assign-rider', requestData);
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to assign rider', error: e, tag: 'ConnectorService');
      return false;
    }
  }

  // =================== ANALYTICS ===================

  /// Get connector analytics
  static Future<Map<String, dynamic>?> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String period = 'month',
  }) async {
    try {
      final queryParams = <String>[];
      if (startDate != null) queryParams.add('startDate=${startDate.toIso8601String()}');
      if (endDate != null) queryParams.add('endDate=${endDate.toIso8601String()}');
      queryParams.add('period=$period');

      final endpoint = '$_baseUrl/analytics?${queryParams.join('&')}';
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['analytics'] ?? data;
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to fetch analytics', error: e, tag: 'ConnectorService');
      return null;
    }
  }

  // =================== NOTIFICATIONS ===================

  /// Get notifications
  static Future<List<Map<String, dynamic>>> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      if (unreadOnly) queryParams.add('unread=true');

      final endpoint = '$_baseUrl/notifications?${queryParams.join('&')}';
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
      }
      return [];
    } catch (e) {
      LoggerService.error('Failed to fetch notifications', error: e, tag: 'ConnectorService');
      return [];
    }
  }

  /// Mark notification as read
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final response = await ApiService.patch('$_baseUrl/notifications/$notificationId/read', {});
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to mark notification as read', error: e, tag: 'ConnectorService');
      return false;
    }
  }

  // =================== PROFILE ===================

  /// Get connector profile
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await ApiService.get('$_baseUrl/profile');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['profile'] ?? data;
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to fetch profile', error: e, tag: 'ConnectorService');
      return null;
    }
  }

  /// Update connector profile
  static Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await ApiService.patch('$_baseUrl/profile', profileData);
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to update profile', error: e, tag: 'ConnectorService');
      return false;
    }
  }
} 