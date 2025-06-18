import 'package:fresh_marikiti/core/config/app_config.dart';

/// Centralized API endpoint management
/// This class provides all API endpoints using the configured base URL
class ApiEndpoints {
  // Base API URL from configuration
  static String get baseUrl => AppConfig.apiBaseUrl;
  
  // Authentication endpoints
  static String get login => '/auth/login';
  static String get register => '/auth/register';
  static String get refreshToken => '/auth/refresh';
  static String get logout => '/auth/logout';
  
  // User endpoints
  static String get userProfile => '/users/profile';
  static String users(String? userId) => userId != null ? '/users/$userId' : '/users';
  
  // Admin endpoints
  static String get adminOverview => '/admin/system/overview';
  static String get adminAlerts => '/admin/system/alerts';
  static String get adminQuickStats => '/admin/system/quick-stats';
  static String get adminUsers => '/admin/users';
  static String adminUserStatus(String userId) => '/admin/users/$userId/status';
  static String adminUser(String userId) => '/admin/users/$userId';
  static String get adminUserCreate => '/admin/users/create';
  static String get adminUserBulkCreate => '/admin/users/bulk-create';
  static String get adminSystemSettings => '/admin/system/settings';
  static String adminAnalytics({String? period}) => '/admin/analytics${period != null ? '?period=$period' : ''}';
  static String adminPaymentsSummary({String? period}) => '/admin/payments/summary${period != null ? '?period=$period' : ''}';
  static String adminPaymentsTransactions({String? status, String? method}) {
    final params = <String>[];
    if (status != null) params.add('status=$status');
    if (method != null) params.add('method=$method');
    return '/admin/payments/transactions${params.isNotEmpty ? '?${params.join('&')}' : ''}';
  }
  static String get adminPaymentsReconciliationReports => '/admin/payments/reconciliation-reports';
  static String get adminPaymentsDisputes => '/admin/payments/disputes';
  static String get adminPaymentsReconcile => '/admin/payments/reconcile';
  static String get adminReportsExport => '/admin/reports/export';
  static String adminReportsBusiness({String? period}) => '/admin/reports/business${period != null ? '?period=$period' : ''}';
  static String adminCommissionOverview({String? period}) => '/admin/commission/overview${period != null ? '?period=$period' : ''}';
  static String adminCommissionRiders({String? period}) => '/admin/commission/riders${period != null ? '?period=$period' : ''}';
  static String adminCommissionPayouts({String? status}) => '/admin/commission/payouts${status != null ? '?status=$status' : ''}';
  static String get adminCommissionBulkPayout => '/admin/commission/bulk-payout';
  static String adminSystemLogs({String? level, int? limit}) {
    final params = <String>[];
    if (level != null && level != 'all') params.add('level=$level');
    if (limit != null) params.add('limit=$limit');
    return '/admin/system/logs${params.isNotEmpty ? '?${params.join('&')}' : ''}';
  }
  
  // Vendor endpoints
  static String get vendorProfile => '/vendor/profile';
  static String get vendorOperatingHours => '/vendor/operating-hours';
  static String get vendorProfileImage => '/vendor/profile/image';
  static String get vendorStoreToggleStatus => '/vendor/store/toggle-status';
  static String get vendorOrders => '/vendor/orders';
  static String vendorOrderStatus(String orderId) => '/vendor/orders/$orderId/status';
  static String vendorAnalytics({String? period}) => '/vendor/analytics${period != null ? '?period=$period' : ''}';
  static String get vendorInventory => '/vendor/inventory';
  static String get vendorInventoryAlerts => '/vendor/inventory/alerts';
  static String vendorInventoryStock(String productId) => '/vendor/inventory/$productId/stock';
  static String get vendorInventoryBulkStock => '/vendor/inventory/bulk/stock';
  static String get vendorEcoReport => '/vendor/eco-report';
  static String get vendorEcoRewards => '/vendor/eco-rewards';
  static String vendorEcoRewardRedeem(String rewardId) => '/vendor/eco-rewards/$rewardId/redeem';
  
  // Vendor Admin endpoints
  static String get vendorAdminProfile => '/vendor-admin/profile';
  static String get vendorAdminSettings => '/vendor-admin/settings';
  static String get vendorAdminOverview => '/vendor-admin/overview';
  static String get vendorAdminStallsSummary => '/vendor-admin/stalls/summary';
  static String get vendorAdminActivitiesRecent => '/vendor-admin/activities/recent';
  static String get vendorAdminStalls => '/vendor-admin/stalls';
  static String vendorAdminStallStatus(String stallId) => '/vendor-admin/stalls/$stallId/status';
  static String vendorAdminStall(String stallId) => '/vendor-admin/stalls/$stallId';
  static String get vendorAdminVendors => '/vendor-admin/vendors';
  static String vendorAdminAnalytics({String? period}) => '/vendor-admin/analytics${period != null ? '?period=$period' : ''}';
  static String vendorAdminVendorPerformances({String? period}) => '/vendor-admin/vendor-performances${period != null ? '?period=$period' : ''}';
  static String vendorAdminReports({String? period}) => '/vendor-admin/reports${period != null ? '?period=$period' : ''}';
  static String vendorAdminReportsExport({String? format, String? period}) {
    final params = <String>[];
    if (format != null) params.add('format=$format');
    if (period != null) params.add('period=$period');
    return '/vendor-admin/reports/export${params.isNotEmpty ? '?${params.join('&')}' : ''}';
  }
  
  // Product endpoints
  static String get products => '/products';
  static String product(String productId) => '/products/$productId';
  
  // Order endpoints
  static String get orders => '/orders';
  static String order(String orderId) => '/orders/$orderId';
  static String orderStatus(String orderId) => '/orders/$orderId/status';
  
  // Chat endpoints
  static String get chat => '/chat';
  static String chatConversation(String conversationId) => '/chat/$conversationId';
  
  // Rating endpoints
  static String get ratings => '/ratings';
  static String rating(String ratingId) => '/ratings/$ratingId';
  
  // Waste management endpoints
  static String get waste => '/waste';
  static String wasteReport(String reportId) => '/waste/$reportId';
  
  // Notification endpoints
  static String get notifications => '/notifications';
  static String notification(String notificationId) => '/notifications/$notificationId';
  
  /// Helper method to get full URL
  static String getFullUrl(String endpoint) {
    return '${baseUrl}$endpoint';
  }
  
  /// Helper method to build URL with query parameters
  static String buildUrl(String endpoint, Map<String, String>? queryParams) {
    if (queryParams == null || queryParams.isEmpty) {
      return getFullUrl(endpoint);
    }
    
    final uri = Uri.parse(getFullUrl(endpoint));
    final newUri = uri.replace(queryParameters: queryParams);
    return newUri.toString();
  }
} 