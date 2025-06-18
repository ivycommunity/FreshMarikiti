import 'dart:convert';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class VendorAdminService {
  static const String _baseUrl = '/vendor-admin';

  // =================== DASHBOARD & METRICS ===================

  /// Get vendor admin dashboard metrics
  static Future<Map<String, dynamic>?> getDashboardMetrics() async {
    try {
      final response = await ApiService.get('$_baseUrl/dashboard');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['dashboard'] ?? data;
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to fetch vendor admin dashboard metrics', error: e, tag: 'VendorAdminService');
      return null;
    }
  }

  // =================== STALL MANAGEMENT ===================

  /// Get managed stalls
  static Future<List<Map<String, dynamic>>> getStalls({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    try {
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      if (search != null) queryParams.add('search=$search');
      if (status != null) queryParams.add('status=$status');

      final endpoint = '$_baseUrl/stalls?${queryParams.join('&')}';
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['stalls'] ?? []);
      }
      return [];
    } catch (e) {
      LoggerService.error('Failed to fetch stalls', error: e, tag: 'VendorAdminService');
      return [];
    }
  }

  /// Get stall details
  static Future<Map<String, dynamic>?> getStallDetails(String stallId) async {
    try {
      final response = await ApiService.get('$_baseUrl/stalls/$stallId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['stall'] ?? data;
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to fetch stall details', error: e, tag: 'VendorAdminService');
      return null;
    }
  }

  /// Add new stall
  static Future<Map<String, dynamic>?> addStall(Map<String, dynamic> stallData) async {
    try {
      final response = await ApiService.post('$_baseUrl/stalls', stallData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['stall'] ?? data;
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to add stall', error: e, tag: 'VendorAdminService');
      return null;
    }
  }

  /// Update stall
  static Future<bool> updateStall(String stallId, Map<String, dynamic> updates) async {
    try {
      final response = await ApiService.patch('$_baseUrl/stalls/$stallId', updates);
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to update stall', error: e, tag: 'VendorAdminService');
      return false;
    }
  }

  /// Remove stall
  static Future<bool> removeStall(String stallId) async {
    try {
      final response = await ApiService.delete('$_baseUrl/stalls/$stallId');
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to remove stall', error: e, tag: 'VendorAdminService');
      return false;
    }
  }

  // =================== PRODUCT MANAGEMENT ===================

  /// Get products for a stall
  static Future<List<Map<String, dynamic>>> getStallProducts(String stallId, {
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
  }) async {
    try {
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      if (search != null) queryParams.add('search=$search');
      if (category != null) queryParams.add('category=$category');

      final endpoint = '$_baseUrl/stalls/$stallId/products?${queryParams.join('&')}';
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['products'] ?? []);
      }
      return [];
    } catch (e) {
      LoggerService.error('Failed to fetch stall products', error: e, tag: 'VendorAdminService');
      return [];
    }
  }

  /// Bulk update products
  static Future<bool> bulkUpdateProducts({
    required String stallId,
    required List<Map<String, dynamic>> products,
  }) async {
    try {
      final requestData = {'products': products};
      final response = await ApiService.post('$_baseUrl/stalls/$stallId/products/bulk-update', requestData);
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to bulk update products', error: e, tag: 'VendorAdminService');
      return false;
    }
  }

  // =================== ORDER MANAGEMENT ===================

  /// Get orders for all managed stalls
  static Future<List<Map<String, dynamic>>> getOrders({
    int page = 1,
    int limit = 20,
    String? stallId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      if (stallId != null) queryParams.add('stallId=$stallId');
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
      LoggerService.error('Failed to fetch orders', error: e, tag: 'VendorAdminService');
      return [];
    }
  }

  /// Get orders for a specific stall
  static Future<List<Map<String, dynamic>>> getStallOrders(String stallId, {
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      if (status != null) queryParams.add('status=$status');

      final endpoint = '$_baseUrl/stalls/$stallId/orders?${queryParams.join('&')}';
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['orders'] ?? []);
      }
      return [];
    } catch (e) {
      LoggerService.error('Failed to fetch stall orders', error: e, tag: 'VendorAdminService');
      return [];
    }
  }

  // =================== ANALYTICS ===================

  /// Get vendor admin analytics
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
      LoggerService.error('Failed to fetch analytics', error: e, tag: 'VendorAdminService');
      return null;
    }
  }

  /// Get performance reports for all managed stalls
  static Future<Map<String, dynamic>?> getPerformanceReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String>[];
      if (startDate != null) queryParams.add('startDate=${startDate.toIso8601String()}');
      if (endDate != null) queryParams.add('endDate=${endDate.toIso8601String()}');

      final endpoint = '$_baseUrl/reports/performance?${queryParams.join('&')}';
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['report'] ?? data;
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to fetch performance report', error: e, tag: 'VendorAdminService');
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
      LoggerService.error('Failed to fetch notifications', error: e, tag: 'VendorAdminService');
      return [];
    }
  }

  /// Mark notification as read
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final response = await ApiService.patch('$_baseUrl/notifications/$notificationId/read', {});
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to mark notification as read', error: e, tag: 'VendorAdminService');
      return false;
    }
  }

  // =================== BULK OPERATIONS ===================

  /// Bulk update stall statuses
  static Future<bool> bulkUpdateStallStatuses({
    required List<String> stallIds,
    required String status,
  }) async {
    try {
      final requestData = {
        'stallIds': stallIds,
        'status': status,
      };

      final response = await ApiService.post('$_baseUrl/stalls/bulk-status-update', requestData);
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to bulk update stall statuses', error: e, tag: 'VendorAdminService');
      return false;
    }
  }

  /// Generate report for all managed stalls
  static Future<Map<String, dynamic>?> generateReport({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? stallIds,
  }) async {
    try {
      final requestData = {
        'reportType': reportType,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (stallIds != null) 'stallIds': stallIds,
      };

      final response = await ApiService.post('$_baseUrl/reports/generate', requestData);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to generate report', error: e, tag: 'VendorAdminService');
      return null;
    }
  }
} 