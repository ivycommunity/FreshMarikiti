import 'dart:convert';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class VendorService {
  static const String _baseUrl = '/vendor';

  // =================== DASHBOARD & METRICS ===================

  /// Get vendor dashboard metrics
  static Future<Map<String, dynamic>?> getDashboardMetrics() async {
    try {
      final response = await ApiService.get('$_baseUrl/dashboard');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['dashboard'] ?? data;
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to fetch vendor dashboard metrics', error: e, tag: 'VendorService');
      return null;
    }
  }

  // =================== PRODUCT MANAGEMENT ===================

  /// Get vendor products
  static Future<List<Map<String, dynamic>>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
    String? status,
  }) async {
    try {
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      if (search != null) queryParams.add('search=$search');
      if (category != null) queryParams.add('category=$category');
      if (status != null) queryParams.add('status=$status');

      final endpoint = '$_baseUrl/products?${queryParams.join('&')}';
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['products'] ?? []);
      }
      return [];
    } catch (e) {
      LoggerService.error('Failed to fetch products', error: e, tag: 'VendorService');
      return [];
    }
  }

  /// Create new product
  static Future<Map<String, dynamic>?> createProduct(Map<String, dynamic> productData) async {
    try {
      final response = await ApiService.post('$_baseUrl/products', productData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['product'] ?? data;
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to create product', error: e, tag: 'VendorService');
      return null;
    }
  }

  /// Update product
  static Future<bool> updateProduct(String productId, Map<String, dynamic> updates) async {
    try {
      final response = await ApiService.patch('$_baseUrl/products/$productId', updates);
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to update product', error: e, tag: 'VendorService');
      return false;
    }
  }

  /// Delete product
  static Future<bool> deleteProduct(String productId) async {
    try {
      final response = await ApiService.delete('$_baseUrl/products/$productId');
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to delete product', error: e, tag: 'VendorService');
      return false;
    }
  }

  // =================== ORDER MANAGEMENT ===================

  /// Get vendor orders
  static Future<List<Map<String, dynamic>>> getOrders({
    int page = 1,
    int limit = 20,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      if (status != null) queryParams.add('status=$status');
      if (startDate != null) queryParams.add('startDate=${startDate.toIso8601String()}');
      if (endDate != null) queryParams.add('endDate=${endDate.toIso8601String()}');

      final endpoint = '$_baseUrl/orders?${queryParams.join('&')}';
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['orders'] ?? []);
      }
      return [];
    } catch (e) {
      LoggerService.error('Failed to fetch orders', error: e, tag: 'VendorService');
      return [];
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
      LoggerService.error('Failed to update order status', error: e, tag: 'VendorService');
      return false;
    }
  }

  // =================== ANALYTICS ===================

  /// Get vendor analytics
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
      LoggerService.error('Failed to fetch analytics', error: e, tag: 'VendorService');
      return null;
    }
  }

  /// Get sustainability analytics
  static Future<Map<String, dynamic>?> getSustainabilityAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String>[];
      if (startDate != null) queryParams.add('startDate=${startDate.toIso8601String()}');
      if (endDate != null) queryParams.add('endDate=${endDate.toIso8601String()}');

      final endpoint = '$_baseUrl/analytics/sustainability?${queryParams.join('&')}';
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['sustainability'] ?? data;
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to fetch sustainability analytics', error: e, tag: 'VendorService');
      return null;
    }
  }

  // =================== REVENUE & FINANCE ===================

  /// Get revenue analytics
  static Future<Map<String, dynamic>?> getRevenueAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String period = 'month',
  }) async {
    try {
      final queryParams = <String>[];
      if (startDate != null) queryParams.add('startDate=${startDate.toIso8601String()}');
      if (endDate != null) queryParams.add('endDate=${endDate.toIso8601String()}');
      queryParams.add('period=$period');

      final endpoint = '$_baseUrl/revenue?${queryParams.join('&')}';
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['revenue'] ?? data;
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to fetch revenue analytics', error: e, tag: 'VendorService');
      return null;
    }
  }

  // =================== ECO POINTS ===================

  /// Get eco points summary
  static Future<Map<String, dynamic>?> getEcoPointsSummary() async {
    try {
      final response = await ApiService.get('$_baseUrl/eco-points');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ecoPoints'] ?? data;
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to fetch eco points summary', error: e, tag: 'VendorService');
      return null;
    }
  }

  /// Get eco points transactions
  static Future<List<Map<String, dynamic>>> getEcoPointsTransactions({
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    try {
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      if (type != null) queryParams.add('type=$type');

      final endpoint = '$_baseUrl/eco-points/transactions?${queryParams.join('&')}';
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['transactions'] ?? []);
      }
      return [];
    } catch (e) {
      LoggerService.error('Failed to fetch eco points transactions', error: e, tag: 'VendorService');
      return [];
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
      LoggerService.error('Failed to fetch notifications', error: e, tag: 'VendorService');
      return [];
    }
  }

  /// Mark notification as read
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final response = await ApiService.patch('$_baseUrl/notifications/$notificationId/read', {});
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to mark notification as read', error: e, tag: 'VendorService');
      return false;
    }
  }

  // =================== PROFILE ===================

  /// Get vendor profile
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await ApiService.get('$_baseUrl/profile');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['profile'] ?? data;
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to fetch profile', error: e, tag: 'VendorService');
      return null;
    }
  }

  /// Update vendor profile
  static Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await ApiService.patch('$_baseUrl/profile', profileData);
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to update profile', error: e, tag: 'VendorService');
      return false;
    }
  }
}