import 'package:flutter/material.dart';
import 'package:fresh_marikiti/presentation/navigation/route_names.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

// Auth screens
import 'package:fresh_marikiti/presentation/screens/auth/splash_screen.dart';
import 'package:fresh_marikiti/presentation/screens/auth/onboarding_screen.dart';
import 'package:fresh_marikiti/presentation/screens/auth/login_screen.dart';
import 'package:fresh_marikiti/presentation/screens/auth/register_screen.dart';
import 'package:fresh_marikiti/presentation/screens/auth/forgot_password_screen.dart';

// Customer screens
import 'package:fresh_marikiti/presentation/screens/customer/customer_home_screen.dart';
import 'package:fresh_marikiti/presentation/screens/customer/product_browse_screen.dart';
import 'package:fresh_marikiti/presentation/screens/customer/cart_screen.dart';
import 'package:fresh_marikiti/presentation/screens/customer/order_history_screen.dart';
import 'package:fresh_marikiti/presentation/screens/customer/customer_profile_screen.dart';
import 'package:fresh_marikiti/presentation/screens/customer/product_details_screen.dart';
import 'package:fresh_marikiti/presentation/screens/customer/checkout_screen.dart';
import 'package:fresh_marikiti/presentation/screens/customer/order_tracking_screen.dart';
import 'package:fresh_marikiti/presentation/screens/customer/addresses_screen.dart';
import 'package:fresh_marikiti/presentation/screens/customer/payment_methods_screen.dart';
import 'package:fresh_marikiti/presentation/screens/customer/favorites_screen.dart';
import 'package:fresh_marikiti/presentation/screens/customer/reviews_screen.dart';

// Vendor screens
import 'package:fresh_marikiti/presentation/screens/vendor/vendor_home_screen.dart';
import 'package:fresh_marikiti/presentation/screens/vendor/product_management_screen.dart' as vendor_screens;
import 'package:fresh_marikiti/presentation/screens/vendor/vendor_orders_screen.dart';
import 'package:fresh_marikiti/presentation/screens/vendor/vendor_profile_screen.dart';
import 'package:fresh_marikiti/presentation/screens/vendor/vendor_analytics_screen.dart';
import 'package:fresh_marikiti/presentation/screens/vendor/add_product_screen.dart';
import 'package:fresh_marikiti/presentation/screens/vendor/edit_product_screen.dart';
import 'package:fresh_marikiti/presentation/screens/vendor/inventory_screen.dart';
import 'package:fresh_marikiti/presentation/screens/vendor/eco_report_screen.dart';

// Rider screens
import 'package:fresh_marikiti/presentation/screens/rider/rider_home_screen.dart';
import 'package:fresh_marikiti/presentation/screens/rider/delivery_list_screen.dart';
import 'package:fresh_marikiti/presentation/screens/rider/rider_earnings_screen.dart';
import 'package:fresh_marikiti/presentation/screens/rider/rider_profile_screen.dart';
import 'package:fresh_marikiti/presentation/screens/rider/rider_analytics_screen.dart';
import 'package:fresh_marikiti/presentation/screens/rider/delivery_details_screen.dart';
import 'package:fresh_marikiti/presentation/screens/rider/navigation_screen.dart';

// Connector screens
import 'package:fresh_marikiti/presentation/screens/connector/connector_home_screen.dart';
import 'package:fresh_marikiti/presentation/screens/connector/assignment_details_screen.dart';
import 'package:fresh_marikiti/presentation/screens/connector/customer_order_chat_screen.dart';
import 'package:fresh_marikiti/presentation/screens/connector/rider_handoff_screen.dart';
import 'package:fresh_marikiti/presentation/screens/connector/shopping_progress_screen.dart';
import 'package:fresh_marikiti/presentation/screens/connector/waste_logging_screen.dart';

// Admin screens
import 'package:fresh_marikiti/presentation/screens/admin/admin_home_screen.dart';
import 'package:fresh_marikiti/presentation/screens/admin/admin_reports_screen.dart';
import 'package:fresh_marikiti/presentation/screens/admin/user_management_screen.dart';
import 'package:fresh_marikiti/presentation/screens/admin/user_creation_screen.dart';
import 'package:fresh_marikiti/presentation/screens/admin/commission_management_screen.dart';
import 'package:fresh_marikiti/presentation/screens/admin/payment_reconciliation_screen.dart';
import 'package:fresh_marikiti/presentation/screens/admin/system_analytics_screen.dart';
import 'package:fresh_marikiti/presentation/screens/admin/system_logs_screen.dart';
import 'package:fresh_marikiti/presentation/screens/admin/system_settings_screen.dart';

// Vendor Admin screens
import 'package:fresh_marikiti/presentation/screens/vendor_admin/vendor_admin_main_screen.dart';
import 'package:fresh_marikiti/presentation/screens/vendor_admin/vendor_admin_home_screen.dart';
import 'package:fresh_marikiti/presentation/screens/vendor_admin/stall_management_screen.dart';
import 'package:fresh_marikiti/presentation/screens/vendor_admin/vendor_management_screen.dart';
import 'package:fresh_marikiti/presentation/screens/vendor_admin/market_analytics_screen.dart';
import 'package:fresh_marikiti/presentation/screens/vendor_admin/vendor_admin_reports_screen.dart';
import 'package:fresh_marikiti/presentation/screens/vendor_admin/vendor_admin_profile_screen.dart';

// Shared screens
import 'package:fresh_marikiti/presentation/screens/shared/notifications_screen.dart';
import 'package:fresh_marikiti/presentation/screens/shared/settings_screen.dart';
import 'package:fresh_marikiti/presentation/screens/shared/help_support_screen.dart';
import 'package:fresh_marikiti/presentation/screens/shared/about_screen.dart';
import 'package:fresh_marikiti/presentation/screens/shared/chat_screen.dart';
import 'package:fresh_marikiti/presentation/screens/shared/order_chat_screen.dart';
import 'package:fresh_marikiti/presentation/screens/shared/camera_screen.dart';
import 'package:fresh_marikiti/presentation/screens/shared/rating_screen.dart';

// Models
import 'package:fresh_marikiti/core/models/product.dart' as product_model;
import 'package:fresh_marikiti/core/models/order_model.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    LoggerService.info('Navigating to: ${settings.name}', tag: 'AppRouter');

    // Extract and validate arguments
    final arguments = settings.arguments;
    
    try {
      switch (settings.name) {
        // =================== AUTHENTICATION ROUTES ===================
        case RouteNames.splash:
          return _createRoute(const SplashScreen(), settings);

        case RouteNames.onboarding:
          return _createRoute(const OnboardingScreen(), settings);

        case RouteNames.login:
          return _createRoute(const LoginScreen(), settings);

        case RouteNames.register:
          return _createRoute(const RegisterScreen(), settings);

        case RouteNames.forgotPassword:
          return _createRoute(const ForgotPasswordScreen(), settings);

        // =================== CUSTOMER ROUTES ===================
        case RouteNames.customerHome:
          return _createRoute(const CustomerHomeScreen(), settings);

        case RouteNames.customerBrowse:
          return _createRoute(const ProductBrowseScreen(), settings);

        case RouteNames.customerCart:
          return _createRoute(const CartScreen(), settings);

        case RouteNames.customerOrders:
          return _createRoute(const OrderHistoryScreen(), settings);

        case RouteNames.customerProfile:
          return _createRoute(const CustomerProfileScreen(), settings);

        case RouteNames.customerEditProfile:
          return _createRoute(const CustomerProfileScreen(), settings);

        case RouteNames.productDetails:
          return _createRouteWithValidation<dynamic, product_model.Product>(
            settings,
            (product) => ProductDetailsScreen(product: product),
            'Product data is required for product details',
          );

        case RouteNames.checkout:
          return _createRoute(const CheckoutScreen(), settings);

        case RouteNames.orderTracking:
          final orderArgs = arguments as Map<String, dynamic>?;
          return _createRoute(
            OrderTrackingScreen(arguments: orderArgs),
            settings,
          );

        case RouteNames.orderDetails:
          final orderArgs = arguments as Map<String, dynamic>?;
          return _createRoute(
            OrderTrackingScreen(arguments: orderArgs),
            settings,
          );

        case RouteNames.addresses:
          return _createRoute(const AddressesScreen(), settings);

        case RouteNames.paymentMethods:
          return _createRoute(const PaymentMethodsScreen(), settings);

        case RouteNames.favorites:
          return _createRoute(const FavoritesScreen(), settings);

        case RouteNames.reviews:
          return _createRoute(const ReviewsScreen(), settings);

        case RouteNames.orderHistory:
          return _createRoute(const OrderHistoryScreen(), settings);

        // =================== VENDOR ROUTES ===================
        case RouteNames.vendorHome:
          return _createRoute(const VendorHomeScreen(), settings);

        case RouteNames.vendorProducts:
          return _createRoute(const vendor_screens.ProductManagementScreen(), settings);

        case RouteNames.vendorOrders:
          return _createRoute(const VendorOrdersScreen(), settings);

        case RouteNames.vendorProfile:
          return _createRoute(const VendorProfileScreen(), settings);

        case RouteNames.vendorAnalytics:
          return _createRoute(const VendorAnalyticsScreen(), settings);

        case RouteNames.addProduct:
          return _createRoute(const AddProductScreen(), settings);

        case RouteNames.editProduct:
          return _createRouteWithValidation<dynamic, product_model.Product>(
            settings,
            (product) => EditProductScreen(product: product),
            'Product data is required for editing',
          );

        case RouteNames.vendorInventory:
          return _createRoute(const InventoryScreen(), settings);

        case RouteNames.vendorEcoReport:
          return _createRoute(const EcoReportScreen(), settings);

        // =================== RIDER ROUTES ===================
        case RouteNames.riderHome:
          return _createRoute(const RiderHomeScreen(), settings);

        case RouteNames.riderDeliveries:
          return _createRoute(const DeliveryListScreen(), settings);

        case RouteNames.deliveryList:
          return _createRoute(const DeliveryListScreen(), settings);

        case RouteNames.riderEarnings:
          return _createRoute(const RiderEarningsScreen(), settings);

        case RouteNames.riderProfile:
          return _createRoute(const RiderProfileScreen(), settings);

        case RouteNames.riderAnalytics:
          return _createRoute(const RiderAnalyticsScreen(), settings);

        case RouteNames.deliveryDetails:
          return _createRouteWithValidation<dynamic, Order>(
            settings,
            (order) => DeliveryDetailsScreen(order: order),
            'Order data is required for delivery details',
          );

        case RouteNames.riderNavigation:
          final order = arguments as Order?;
          return _createRoute(NavigationScreen(order: order), settings);

        // =================== CONNECTOR ROUTES ===================
        case RouteNames.connectorHome:
          return _createRoute(const ConnectorHomeScreen(), settings);

        case RouteNames.assignmentDetails:
          return _createRouteWithValidation<dynamic, Order>(
            settings,
            (order) => AssignmentDetailsScreen(order: order),
            'Order data is required for assignment details',
          );

        case RouteNames.customerOrderChat:
          final chatData = arguments as Map<String, dynamic>?;
          return _createRoute(
            CustomerOrderChatScreen(
              order: chatData?['order'],
              customerName: chatData?['customerName'] ?? 'Customer',
            ),
            settings,
          );

        case RouteNames.riderHandoff:
          return _createRouteWithValidation<dynamic, Order>(
            settings,
            (order) => RiderHandoffScreen(order: order),
            'Order data is required for rider handoff',
          );

        case RouteNames.shoppingProgress:
          return _createRouteWithValidation<dynamic, Order>(
            settings,
            (order) => ShoppingProgressScreen(order: order),
            'Order data is required for shopping progress',
          );

        case RouteNames.wasteLogging:
          return _createRoute(const WasteLoggingScreen(), settings);

        // Connector routes that map to existing screens (temporary)
        case RouteNames.connectorProfile:
          return _createRoute(const ConnectorHomeScreen(), settings);

        case RouteNames.connectorAnalytics:
          return _createRoute(const ConnectorHomeScreen(), settings);

        case RouteNames.connectorActiveOrders:
          return _createRoute(const ConnectorHomeScreen(), settings);

        case RouteNames.connectorAvailableOrders:
          return _createRoute(const ConnectorHomeScreen(), settings);

        case RouteNames.wasteDetails:
          return _createRoute(const WasteLoggingScreen(), settings);

        // =================== ADMIN ROUTES ===================
        case RouteNames.adminHome:
          return _createRoute(const AdminHomeScreen(), settings);

        case RouteNames.adminReports:
          return _createRoute(const AdminReportsScreen(), settings);

        case RouteNames.userManagement:
          return _createRoute(const UserManagementScreen(), settings);

        case RouteNames.userCreation:
          return _createRoute(const UserCreationScreen(), settings);

        case RouteNames.commissionManagement:
          return _createRoute(const CommissionManagementScreen(), settings);

        case RouteNames.paymentReconciliation:
          return _createRoute(const PaymentReconciliationScreen(), settings);

        case RouteNames.systemAnalytics:
          return _createRoute(const SystemAnalyticsScreen(), settings);

        case RouteNames.systemLogs:
          return _createRoute(const SystemLogsScreen(), settings);

        case RouteNames.systemSettings:
          return _createRoute(const SystemSettingsScreen(), settings);

        // =================== VENDOR ADMIN ROUTES ===================
        case RouteNames.vendorAdminMain:
          return _createRoute(const VendorAdminMainScreen(), settings);

        case RouteNames.vendorAdminHome:
          return _createRoute(const VendorAdminHomeScreen(), settings);

        case RouteNames.vendorAdminStalls:
          return _createRoute(const StallManagementScreen(), settings);

        case RouteNames.vendorAdminVendors:
          return _createRoute(const VendorManagementScreen(), settings);

        case RouteNames.vendorAdminAnalytics:
          return _createRoute(const MarketAnalyticsScreen(), settings);

        case RouteNames.vendorAdminReports:
          return _createRoute(const VendorAdminReportsScreen(), settings);

        case RouteNames.vendorAdminProfile:
          return _createRoute(const VendorAdminProfileScreen(), settings);

        // Vendor admin routes that don't have dedicated screens yet
        case RouteNames.vendorAdminAddStall:
          return _createRoute(const StallManagementScreen(), settings);

        case RouteNames.vendorAdminNotifications:
          return _createRoute(const NotificationsScreen(), settings);

        case RouteNames.vendorAdminActivities:
          return _createRoute(const VendorAdminHomeScreen(), settings);

        // =================== SHARED ROUTES ===================
        case RouteNames.notifications:
          return _createRoute(const NotificationsScreen(), settings);

        case RouteNames.settings:
          return _createRoute(const SettingsScreen(), settings);

        case RouteNames.helpSupport:
          return _createRoute(const HelpSupportScreen(), settings);

        case RouteNames.about:
          return _createRoute(const AboutScreen(), settings);

        case RouteNames.chat:
          return _createRoute(const ChatScreen(), settings);

        case RouteNames.orderChat:
          return _createRoute(const OrderChatScreen(), settings);

        case RouteNames.camera:
          return _createRoute(const CameraScreen(), settings);

        case RouteNames.map:
          // Map functionality using navigation screen
          final order = arguments as Order?;
          return _createRoute(NavigationScreen(order: order), settings);

        case RouteNames.rating:
          final ratingData = arguments as Map<String, dynamic>?;
          return _createRoute(
            RatingScreen(
              targetId: ratingData?['targetId'],
              ratingType: ratingData?['ratingType'] ?? 'general',
              targetData: ratingData?['targetData'],
            ),
            settings,
          );

        // =================== DEFAULT ROUTE ===================
        default:
          LoggerService.warning('Unknown route: ${settings.name}', tag: 'AppRouter');
          return _createErrorRoute('Route not found: ${settings.name}');
      }
    } catch (e, stackTrace) {
      LoggerService.error(
        'Error creating route for ${settings.name}',
        error: e,
        stackTrace: stackTrace,
        tag: 'AppRouter',
      );
      return _createErrorRoute('Error loading page: ${e.toString()}');
    }
  }

  /// Create a standard route with page transition
  static MaterialPageRoute<T> _createRoute<T>(
    Widget screen,
    RouteSettings settings, {
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return MaterialPageRoute<T>(
      builder: (_) => screen,
      settings: settings,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );
  }

  /// Create a route with argument validation
  static MaterialPageRoute<T> _createRouteWithValidation<T, A>(
    RouteSettings settings,
    Widget Function(A) builder,
    String errorMessage,
  ) {
    final argument = settings.arguments as A?;
    if (argument == null) {
      LoggerService.error(
        'Missing required argument for route ${settings.name}',
        tag: 'AppRouter',
      );
      return _createErrorRoute(errorMessage) as MaterialPageRoute<T>;
    }
    return _createRoute<T>(builder(argument), settings);
  }

  /// Create error route with Fresh Marikiti styling
  static MaterialPageRoute<dynamic> _createErrorRoute(String message) {
    return MaterialPageRoute<dynamic>(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Fresh Marikiti'),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Error icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Error title
                  Text(
                    'Navigation Error',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Error message
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Back button
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Validate route arguments
  static bool validateArguments(RouteSettings settings, Type expectedType) {
    final arguments = settings.arguments;
    if (arguments == null) return false;
    return arguments.runtimeType == expectedType;
  }

  /// Get route transition duration
  static Duration getTransitionDuration(String? routeName) {
    // Faster transitions for frequently used routes
    const quickRoutes = {
      RouteNames.customerCart,
      RouteNames.notifications,
      RouteNames.settings,
    };
    
    if (quickRoutes.contains(routeName)) {
      return const Duration(milliseconds: 200);
    }
    
    return const Duration(milliseconds: 300);
  }

  /// Check if route supports arguments
  static bool supportsArguments(String routeName) {
    const routesWithArguments = {
      RouteNames.productDetails,
      RouteNames.editProduct,
      RouteNames.deliveryDetails,
      RouteNames.assignmentDetails,
      RouteNames.customerOrderChat,
      RouteNames.riderHandoff,
      RouteNames.shoppingProgress,
      RouteNames.orderTracking,
      RouteNames.orderDetails,
      RouteNames.rating,
      RouteNames.riderNavigation,
      RouteNames.map,
      RouteNames.camera,
    };
    
    return routesWithArguments.contains(routeName);
  }
} 