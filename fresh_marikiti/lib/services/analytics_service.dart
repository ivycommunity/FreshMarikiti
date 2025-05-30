import 'dart:convert';
import 'api_service.dart';

class AnalyticsService {
  static Future<Map<String, dynamic>> fetchVendorAnalytics() async {
    final response = await ApiService.get('/products/analytics');
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load analytics');
    }
  }

  static Future<Map<String, dynamic>> fetchAdminAnalytics({String? period}) async {
    final endpoint = period != null ? '/admin/analytics?period=$period' : '/admin/analytics';
    final response = await ApiService.get(endpoint);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load admin analytics');
    }
  }

  static Future<Map<String, dynamic>> fetchUserMetrics({String? period}) async {
    final endpoint = period != null ? '/admin/analytics/users?period=$period' : '/admin/analytics/users';
    final response = await ApiService.get(endpoint);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load user metrics');
    }
  }

  static Future<Map<String, dynamic>> fetchOrderMetrics({String? period}) async {
    final endpoint = period != null ? '/admin/analytics/orders?period=$period' : '/admin/analytics/orders';
    final response = await ApiService.get(endpoint);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load order metrics');
    }
  }

  static Future<Map<String, dynamic>> fetchVendorMetrics({String? period}) async {
    final endpoint = period != null ? '/admin/analytics/vendors?period=$period' : '/admin/analytics/vendors';
    final response = await ApiService.get(endpoint);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load vendor metrics');
    }
  }

  static Future<Map<String, dynamic>> fetchWasteMetrics({String? period}) async {
    final endpoint = period != null ? '/admin/analytics/waste?period=$period' : '/admin/analytics/waste';
    final response = await ApiService.get(endpoint);
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load waste metrics');
    }
  }
} 