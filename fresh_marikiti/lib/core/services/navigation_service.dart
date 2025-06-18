import 'package:flutter/material.dart';
import 'package:fresh_marikiti/presentation/navigation/route_names.dart';
import 'package:fresh_marikiti/core/models/product.dart';
import 'package:fresh_marikiti/core/models/order_model.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static NavigatorState? get navigator => navigatorKey.currentState;
  static BuildContext? get context => navigatorKey.currentContext;

  // =================== AUTHENTICATION NAVIGATION ===================
  
  static Future<void> toSplash() async {
    await navigator?.pushNamedAndRemoveUntil(
      RouteNames.splash,
      (route) => false,
    );
  }

  static Future<void> toOnboarding() async {
    await navigator?.pushNamed(RouteNames.onboarding);
  }

  static Future<void> toLogin() async {
    await navigator?.pushNamedAndRemoveUntil(
      RouteNames.login,
      (route) => false,
    );
  }

  static Future<void> toRegister() async {
    await navigator?.pushNamed(RouteNames.register);
  }

  static Future<void> toForgotPassword() async {
    await navigator?.pushNamed(RouteNames.forgotPassword);
  }

  // =================== CUSTOMER NAVIGATION ===================
  
  static Future<void> toCustomerHome() async {
    await navigator?.pushNamedAndRemoveUntil(
      RouteNames.customerHome,
      (route) => false,
    );
  }

  static Future<void> toCustomerBrowse() async {
    await navigator?.pushNamed(RouteNames.customerBrowse);
  }

  static Future<void> toProductDetails(Product product) async {
    if (navigator == null) {
      LoggerService.error('Navigator not available', tag: 'NavigationService');
      return;
    }
    
    await navigator!.pushNamed(
      RouteNames.productDetails,
      arguments: product,
    );
  }

  static Future<void> toCart() async {
    await navigator?.pushNamed(RouteNames.customerCart);
  }

  static Future<void> toCheckout() async {
    await navigator?.pushNamed(RouteNames.checkout);
  }

  static Future<void> toOrderTracking({String? orderId, Order? order, Map<String, dynamic>? arguments}) async {
    final args = <String, dynamic>{};
    if (orderId != null) args['orderId'] = orderId;
    if (order != null) args['order'] = order;
    if (arguments != null) args.addAll(arguments);
    
    await navigator?.pushNamed(
      RouteNames.orderTracking,
      arguments: args.isNotEmpty ? args : null,
    );
  }

  static Future<void> toOrderDetails({String? orderId, Order? order, Map<String, dynamic>? arguments}) async {
    final args = <String, dynamic>{};
    if (orderId != null) args['orderId'] = orderId;
    if (order != null) args['order'] = order;
    if (arguments != null) args.addAll(arguments);
    
    await navigator?.pushNamed(
      RouteNames.orderDetails,
      arguments: args.isNotEmpty ? args : null,
    );
  }

  static Future<void> toCustomerProfile() async {
    await navigator?.pushNamed(RouteNames.customerProfile);
  }

  static Future<void> toCustomerEditProfile() async {
    await navigator?.pushNamed(RouteNames.customerEditProfile);
  }

  static Future<void> toAddresses() async {
    await navigator?.pushNamed(RouteNames.addresses);
  }

  static Future<void> toPaymentMethods() async {
    await navigator?.pushNamed(RouteNames.paymentMethods);
  }

  static Future<void> toFavorites() async {
    await navigator?.pushNamed(RouteNames.favorites);
  }

  static Future<void> toReviews() async {
    await navigator?.pushNamed(RouteNames.reviews);
  }

  static Future<void> toOrderHistory() async {
    await navigator?.pushNamed(RouteNames.orderHistory);
  }

  static Future<void> toCustomerOrders() async {
    await navigator?.pushNamed(RouteNames.customerOrders);
  }

  // =================== VENDOR NAVIGATION ===================
  
  static Future<void> toVendorHome() async {
    await navigator?.pushNamedAndRemoveUntil(
      RouteNames.vendorHome,
      (route) => false,
    );
  }

  static Future<void> toVendorProducts() async {
    await navigator?.pushNamed(RouteNames.vendorProducts);
  }

  static Future<void> toAddProduct() async {
    await navigator?.pushNamed(RouteNames.addProduct);
  }

  static Future<void> toEditProduct(Product product) async {
    await navigator?.pushNamed(
      RouteNames.editProduct,
      arguments: product,
    );
  }

  static Future<void> toVendorOrders() async {
    await navigator?.pushNamed(RouteNames.vendorOrders);
  }

  static Future<void> toVendorAnalytics() async {
    await navigator?.pushNamed(RouteNames.vendorAnalytics);
  }

  static Future<void> toVendorProfile() async {
    await navigator?.pushNamed(RouteNames.vendorProfile);
  }

  static Future<void> toVendorInventory() async {
    await navigator?.pushNamed(RouteNames.vendorInventory);
  }

  static Future<void> toVendorEcoReport() async {
    await navigator?.pushNamed(RouteNames.vendorEcoReport);
  }

  // =================== RIDER NAVIGATION ===================
  
  static Future<void> toRiderHome() async {
    await navigator?.pushNamedAndRemoveUntil(
      RouteNames.riderHome,
      (route) => false,
    );
  }

  static Future<void> toRiderDeliveries() async {
    await navigator?.pushNamed(RouteNames.riderDeliveries);
  }

  static Future<void> toDeliveryList({bool? showAvailable, Map<String, dynamic>? arguments}) async {
    final args = <String, dynamic>{};
    if (showAvailable != null) args['showAvailable'] = showAvailable;
    if (arguments != null) args.addAll(arguments);
    
    await navigator?.pushNamed(
      RouteNames.deliveryList,
      arguments: args.isNotEmpty ? args : null,
    );
  }

  static Future<void> toDeliveryDetails(Order order) async {
    await navigator?.pushNamed(
      RouteNames.deliveryDetails,
      arguments: order,
    );
  }

  static Future<void> toRiderNavigation({Order? order}) async {
    await navigator?.pushNamed(
      RouteNames.riderNavigation,
      arguments: order,
    );
  }

  static Future<void> toRiderEarnings() async {
    await navigator?.pushNamed(RouteNames.riderEarnings);
  }

  static Future<void> toRiderAnalytics() async {
    await navigator?.pushNamed(RouteNames.riderAnalytics);
  }

  static Future<void> toRiderProfile() async {
    await navigator?.pushNamed(RouteNames.riderProfile);
  }

  // =================== CONNECTOR NAVIGATION ===================
  
  static Future<void> toConnectorHome() async {
    await navigator?.pushNamedAndRemoveUntil(
      RouteNames.connectorHome,
      (route) => false,
    );
  }

  static Future<void> toConnectorProfile() async {
    await navigator?.pushNamed(RouteNames.connectorProfile);
  }

  static Future<void> toConnectorAnalytics() async {
    await navigator?.pushNamed(RouteNames.connectorAnalytics);
  }

  static Future<void> toConnectorActiveOrders() async {
    await navigator?.pushNamed(RouteNames.connectorActiveOrders);
  }

  static Future<void> toConnectorAvailableOrders() async {
    await navigator?.pushNamed(RouteNames.connectorAvailableOrders);
  }

  static Future<void> toAssignmentDetails(Order order) async {
    await navigator?.pushNamed(
      RouteNames.assignmentDetails,
      arguments: order,
    );
  }

  static Future<void> toCustomerOrderChat({Order? order, String? customerName}) async {
    final arguments = <String, dynamic>{};
    if (order != null) arguments['order'] = order;
    if (customerName != null) arguments['customerName'] = customerName;
    
    await navigator?.pushNamed(
      RouteNames.customerOrderChat,
      arguments: arguments.isNotEmpty ? arguments : null,
    );
  }

  static Future<void> toRiderHandoff(Order order) async {
    await navigator?.pushNamed(
      RouteNames.riderHandoff,
      arguments: order,
    );
  }

  static Future<void> toShoppingProgress(Order order) async {
    await navigator?.pushNamed(
      RouteNames.shoppingProgress,
      arguments: order,
    );
  }

  static Future<void> toWasteLogging() async {
    await navigator?.pushNamed(RouteNames.wasteLogging);
  }

  static Future<void> toWasteDetails() async {
    await navigator?.pushNamed(RouteNames.wasteDetails);
  }

  // =================== ADMIN NAVIGATION ===================
  
  static Future<void> toAdminHome() async {
    await navigator?.pushNamedAndRemoveUntil(
      RouteNames.adminHome,
      (route) => false,
    );
  }

  static Future<void> toAdminReports() async {
    await navigator?.pushNamed(RouteNames.adminReports);
  }

  static Future<void> toUserManagement() async {
    await navigator?.pushNamed(RouteNames.userManagement);
  }

  static Future<void> toUserCreation() async {
    await navigator?.pushNamed(RouteNames.userCreation);
  }

  static Future<void> toCommissionManagement() async {
    await navigator?.pushNamed(RouteNames.commissionManagement);
  }

  static Future<void> toPaymentReconciliation() async {
    await navigator?.pushNamed(RouteNames.paymentReconciliation);
  }

  static Future<void> toSystemAnalytics() async {
    await navigator?.pushNamed(RouteNames.systemAnalytics);
  }

  static Future<void> toSystemLogs() async {
    await navigator?.pushNamed(RouteNames.systemLogs);
  }

  static Future<void> toSystemSettings() async {
    await navigator?.pushNamed(RouteNames.systemSettings);
  }

  // =================== VENDOR ADMIN NAVIGATION ===================
  
  static Future<void> toVendorAdminMain() async {
    await navigator?.pushNamed(RouteNames.vendorAdminMain);
  }

  static Future<void> toVendorAdminHome() async {
    await navigator?.pushNamedAndRemoveUntil(
      RouteNames.vendorAdminHome,
      (route) => false,
    );
  }

  static Future<void> toVendorAdminStalls() async {
    await navigator?.pushNamed(RouteNames.vendorAdminStalls);
  }

  static Future<void> toVendorAdminAddStall() async {
    await navigator?.pushNamed(RouteNames.vendorAdminAddStall);
  }

  static Future<void> toVendorAdminVendors() async {
    await navigator?.pushNamed(RouteNames.vendorAdminVendors);
  }

  static Future<void> toVendorAdminAnalytics() async {
    await navigator?.pushNamed(RouteNames.vendorAdminAnalytics);
  }

  static Future<void> toVendorAdminReports() async {
    await navigator?.pushNamed(RouteNames.vendorAdminReports);
  }

  static Future<void> toVendorAdminProfile() async {
    await navigator?.pushNamed(RouteNames.vendorAdminProfile);
  }

  static Future<void> toVendorAdminNotifications() async {
    await navigator?.pushNamed(RouteNames.vendorAdminNotifications);
  }

  static Future<void> toVendorAdminActivities() async {
    await navigator?.pushNamed(RouteNames.vendorAdminActivities);
  }

  // =================== SHARED NAVIGATION ===================
  
  static Future<void> toNotifications() async {
    await navigator?.pushNamed(RouteNames.notifications);
  }

  static Future<void> toSettings() async {
    await navigator?.pushNamed(RouteNames.settings);
  }

  static Future<void> toHelpSupport() async {
    await navigator?.pushNamed(RouteNames.helpSupport);
  }

  static Future<void> toAbout() async {
    await navigator?.pushNamed(RouteNames.about);
  }

  static Future<void> toChat() async {
    await navigator?.pushNamed(RouteNames.chat);
  }

  static Future<void> toOrderChat() async {
    await navigator?.pushNamed(RouteNames.orderChat);
  }

  static Future<void> toCamera({Map<String, dynamic>? arguments}) async {
    await navigator?.pushNamed(
      RouteNames.camera,
      arguments: arguments,
    );
  }

  static Future<void> toMap({Order? order, Map<String, dynamic>? arguments}) async {
    final args = arguments ?? {};
    if (order != null) args['order'] = order;
    
    await navigator?.pushNamed(
      RouteNames.map,
      arguments: args.isNotEmpty ? args : null,
    );
  }

  static Future<void> toRating({
    String? targetId,
    String? ratingType,
    Map<String, dynamic>? targetData,
  }) async {
    final arguments = <String, dynamic>{};
    if (targetId != null) arguments['targetId'] = targetId;
    if (ratingType != null) arguments['ratingType'] = ratingType;
    if (targetData != null) arguments['targetData'] = targetData;
    
    await navigator?.pushNamed(
      RouteNames.rating,
      arguments: arguments.isNotEmpty ? arguments : null,
    );
  }

  // =================== UTILITY METHODS ===================
  
  static void goBack() {
    navigator?.pop();
  }

  static void goBackWithResult<T>(T result) {
    navigator?.pop(result);
  }

  static Future<void> pushAndRemoveUntil(String routeName, {Object? arguments}) async {
    await navigator?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static Future<T?> pushAndWaitForResult<T>(String routeName, {Object? arguments}) async {
    return await navigator?.pushNamed(routeName, arguments: arguments) as T?;
  }

  // =================== ROLE-BASED HOME NAVIGATION ===================
  
  static Future<void> toRoleBasedHome(String role) async {
    final routeName = RouteNames.getHomeRouteForRole(role);
    await navigator?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
    );
  }

  // =================== ERROR HANDLING ===================
  
  static void showNavigationError(String message) {
    LoggerService.error('Navigation Error: $message', tag: 'NavigationService');
    
    if (context != null) {
      ScaffoldMessenger.of(context!).showSnackBar(
        SnackBar(
          content: Text('Navigation Error: $message'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // =================== LEGACY SUPPORT (DEPRECATED) ===================
  // These methods provide backward compatibility for old navigation calls
  
  @Deprecated('Use toVendorInventory() instead')
  static Future<void> toInventory() async {
    await toVendorInventory();
  }

  @Deprecated('Use toVendorEcoReport() instead')
  static Future<void> toEcoReport() async {
    await toVendorEcoReport();
  }

  @Deprecated('Use toCustomerBrowse() instead')
  static Future<void> toProductBrowse() async {
    await toCustomerBrowse();
  }
} 