import 'dart:convert';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/admin_models.dart';

class AdminService {
  static const String _baseUrl = '/admin';

  // =================== DASHBOARD & METRICS ===================

  /// Get admin dashboard metrics
  static Future<Map<String, dynamic>?> getDashboardMetrics() async {
    try {
      final response = await ApiService.get('$_baseUrl/dashboard');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['dashboard'] ?? data;
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to fetch admin dashboard metrics', error: e, tag: 'AdminService');
      return null;
    }
  }

  /// Get platform analytics
  static Future<Map<String, dynamic>?> getPlatformAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String period = 'month',
  }) async {
    try {
      final queryParams = <String>[];
      if (startDate != null) {
        queryParams.add('startDate=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        queryParams.add('endDate=${endDate.toIso8601String()}');
      }
      queryParams.add('period=$period');

      final endpoint = '$_baseUrl/analytics?${queryParams.join('&')}';
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['analytics'] ?? data;
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to fetch platform analytics', error: e, tag: 'AdminService');
      return null;
    }
  }

  // =================== USER MANAGEMENT ===================

  /// Get all users with filtering
  static Future<List<AdminUser>> getUsers({
    int page = 1,
    int limit = 20,
    String? role,
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      if (role != null) queryParams.add('role=$role');
      if (status != null) queryParams.add('status=$status');
      if (search != null) queryParams.add('search=$search');

      final endpoint = '$_baseUrl/users?${queryParams.join('&')}';
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['users'] as List? ?? [])
            .map((json) => AdminUser.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      LoggerService.error('Failed to fetch users', error: e, tag: 'AdminService');
      return [];
    }
  }

  /// Get user details
  static Future<AdminUser?> getUserDetails(String userId) async {
    try {
      final response = await ApiService.get('$_baseUrl/users/$userId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AdminUser.fromJson(data['user'] ?? data);
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to fetch user details', error: e, tag: 'AdminService');
      return null;
    }
  }

  /// Update user status
  static Future<bool> updateUserStatus(String userId, String status, {String? reason}) async {
    try {
      final requestData = {
        'status': status,
        if (reason != null) 'reason': reason,
      };

      final response = await ApiService.patch('$_baseUrl/users/$userId/status', requestData);
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to update user status', error: e, tag: 'AdminService');
      return false;
    }
  }

  /// Suspend user
  static Future<bool> suspendUser(String userId, String reason) async {
    try {
      final requestData = {'reason': reason};
      final response = await ApiService.post('$_baseUrl/users/$userId/suspend', requestData);
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to suspend user', error: e, tag: 'AdminService');
      return false;
    }
  }

  /// Unsuspend user
  static Future<bool> unsuspendUser(String userId) async {
    try {
      final response = await ApiService.post('$_baseUrl/users/$userId/unsuspend', {});
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to unsuspend user', error: e, tag: 'AdminService');
      return false;
    }
  }

  // =================== ORDER MANAGEMENT ===================

  /// Get all orders with filtering
  static Future<List<Map<String, dynamic>>> getOrders({
    int page = 1,
    int limit = 20,
    String? status,
    String? vendorId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      if (status != null) queryParams.add('status=$status');
      if (vendorId != null) queryParams.add('vendorId=$vendorId');
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
      LoggerService.error('Failed to fetch orders', error: e, tag: 'AdminService');
      return [];
    }
  }

  // =================== PLATFORM SETTINGS ===================

  /// Get platform settings
  static Future<Map<String, dynamic>?> getPlatformSettings() async {
    try {
      final response = await ApiService.get('$_baseUrl/settings');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['settings'] ?? data;
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to fetch platform settings', error: e, tag: 'AdminService');
      return null;
    }
  }

  /// Update platform settings
  static Future<bool> updatePlatformSettings(Map<String, dynamic> settings) async {
    try {
      final response = await ApiService.put('$_baseUrl/settings', settings);
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to update platform settings', error: e, tag: 'AdminService');
      return false;
    }
  }

  // =================== ACTIVITY LOGS ===================

  /// Get system activity logs
  static Future<List<Map<String, dynamic>>> getActivityLogs({
    int page = 1,
    int limit = 20,
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      if (userId != null) queryParams.add('userId=$userId');
      if (action != null) queryParams.add('action=$action');
      if (startDate != null) queryParams.add('startDate=${startDate.toIso8601String()}');
      if (endDate != null) queryParams.add('endDate=${endDate.toIso8601String()}');

      final endpoint = '$_baseUrl/activity-logs?${queryParams.join('&')}';
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['logs'] ?? []);
      }
      return [];
    } catch (e) {
      LoggerService.error('Failed to fetch activity logs', error: e, tag: 'AdminService');
      return [];
    }
  }

  // =================== ALERTS & NOTIFICATIONS ===================

  /// Get system alerts
  static Future<List<Map<String, dynamic>>> getSystemAlerts({bool unreadOnly = false}) async {
    try {
      final endpoint = unreadOnly ? '$_baseUrl/alerts?unread=true' : '$_baseUrl/alerts';
      final response = await ApiService.get(endpoint);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['alerts'] ?? []);
      }
      return [];
    } catch (e) {
      LoggerService.error('Failed to fetch system alerts', error: e, tag: 'AdminService');
      return [];
    }
  }

  /// Mark alert as read
  static Future<bool> markAlertAsRead(String alertId) async {
    try {
      final response = await ApiService.patch('$_baseUrl/alerts/$alertId/read', {});
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to mark alert as read', error: e, tag: 'AdminService');
      return false;
    }
  }

  // =================== BULK OPERATIONS ===================

  /// Bulk update users
  static Future<bool> bulkUpdateUsers({
    required List<String> userIds,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final requestData = {
        'userIds': userIds,
        'updates': updates,
      };

      final response = await ApiService.post('$_baseUrl/users/bulk-update', requestData);
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Failed to bulk update users', error: e, tag: 'AdminService');
      return false;
    }
  }

  // =================== REPORTS & EXPORTS ===================

  /// Generate platform report
  static Future<Map<String, dynamic>?> generateReport({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final requestData = {
        'reportType': reportType,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (filters != null) 'filters': filters,
      };

      final response = await ApiService.post('$_baseUrl/reports/generate', requestData);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to generate report', error: e, tag: 'AdminService');
      return null;
    }
  }
} 