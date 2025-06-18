class RouteNames {
  // =================== AUTHENTICATION ROUTES ===================
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  
  // =================== CUSTOMER ROUTES ===================
  static const String customerHome = '/customer/home';
  static const String customerBrowse = '/customer/browse';
  static const String customerCart = '/customer/cart';
  static const String customerOrders = '/customer/orders';
  static const String customerProfile = '/customer/profile';
  static const String customerEditProfile = '/customer/edit-profile';
  static const String productDetails = '/customer/product-details';
  static const String checkout = '/customer/checkout';
  static const String orderTracking = '/customer/order-tracking';
  static const String orderDetails = '/customer/order-details';
  static const String addresses = '/customer/addresses';
  static const String paymentMethods = '/customer/payment-methods';
  static const String favorites = '/customer/favorites';
  static const String reviews = '/customer/reviews';
  static const String orderHistory = '/customer/order-history';
  
  // =================== VENDOR ROUTES ===================
  static const String vendorHome = '/vendor/home';
  static const String vendorProducts = '/vendor/products';
  static const String vendorOrders = '/vendor/orders';
  static const String vendorProfile = '/vendor/profile';
  static const String vendorAnalytics = '/vendor/analytics';
  static const String addProduct = '/vendor/add-product';
  static const String editProduct = '/vendor/edit-product';
  static const String vendorInventory = '/vendor/inventory';
  static const String vendorEcoReport = '/vendor/eco-report';
  
  // =================== RIDER ROUTES ===================
  static const String riderHome = '/rider/home';
  static const String riderDeliveries = '/rider/deliveries';
  static const String deliveryList = '/rider/delivery-list';
  static const String riderEarnings = '/rider/earnings';
  static const String riderProfile = '/rider/profile';
  static const String riderAnalytics = '/rider/analytics';
  static const String deliveryDetails = '/rider/delivery-details';
  static const String riderNavigation = '/rider/navigation';
  
  // =================== CONNECTOR ROUTES ===================
  static const String connectorHome = '/connector/home';
  static const String connectorProfile = '/connector/profile';
  static const String connectorAnalytics = '/connector/analytics';
  static const String connectorActiveOrders = '/connector/active-orders';
  static const String connectorAvailableOrders = '/connector/available-orders';
  static const String assignmentDetails = '/connector/assignment-details';
  static const String customerOrderChat = '/connector/customer-order-chat';
  static const String riderHandoff = '/connector/rider-handoff';
  static const String shoppingProgress = '/connector/shopping-progress';
  static const String wasteLogging = '/connector/waste-logging';
  static const String wasteDetails = '/connector/waste-details';
  
  // =================== ADMIN ROUTES ===================
  static const String adminHome = '/admin/home';
  static const String adminReports = '/admin/reports';
  static const String userManagement = '/admin/user-management';
  static const String userCreation = '/admin/user-creation';
  static const String commissionManagement = '/admin/commission-management';
  static const String paymentReconciliation = '/admin/payment-reconciliation';
  static const String systemAnalytics = '/admin/system-analytics';
  static const String systemLogs = '/admin/system-logs';
  static const String systemSettings = '/admin/system-settings';
  
  // =================== VENDOR ADMIN ROUTES ===================
  static const String vendorAdminMain = '/vendor-admin/main';
  static const String vendorAdminHome = '/vendor-admin/home';
  static const String vendorAdminStalls = '/vendor-admin/stalls';
  static const String vendorAdminVendors = '/vendor-admin/vendors';
  static const String vendorAdminAnalytics = '/vendor-admin/analytics';
  static const String vendorAdminReports = '/vendor-admin/reports';
  static const String vendorAdminProfile = '/vendor-admin/profile';
  static const String vendorAdminAddStall = '/vendor-admin/add-stall';
  static const String vendorAdminNotifications = '/vendor-admin/notifications';
  static const String vendorAdminActivities = '/vendor-admin/activities';
  
  // =================== SHARED/COMMON ROUTES ===================
  static const String notifications = '/shared/notifications';
  static const String settings = '/shared/settings';
  static const String helpSupport = '/shared/help-support';
  static const String about = '/shared/about';
  static const String chat = '/shared/chat';
  static const String orderChat = '/shared/order-chat';
  static const String camera = '/shared/camera';
  static const String map = '/shared/map';
  static const String rating = '/shared/rating';
  
  // =================== UTILITY METHODS ===================
  
  /// Get home route based on user role
  static String getHomeRouteForRole(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return customerHome;
      case 'vendor':
        return vendorHome;
      case 'rider':
        return riderHome;
      case 'connector':
        return connectorHome;
      case 'admin':
        return adminHome;
      case 'vendoradmin':
        return vendorAdminHome;
      default:
        return login;
    }
  }
  
  /// Check if route requires authentication
  static bool requiresAuth(String route) {
    const publicRoutes = {
      splash,
      onboarding,
      login,
      register,
      forgotPassword,
      about,
    };
    return !publicRoutes.contains(route);
  }
  
  /// Check if route is role-specific
  static bool isRoleSpecific(String route) {
    return route.startsWith('/customer/') ||
           route.startsWith('/vendor/') ||
           route.startsWith('/rider/') ||
           route.startsWith('/connector/') ||
           route.startsWith('/admin/') ||
           route.startsWith('/vendor-admin/');
  }
  
  /// Get required role for a route
  static String? getRequiredRole(String route) {
    if (route.startsWith('/customer/')) return 'customer';
    if (route.startsWith('/vendor/')) return 'vendor';
    if (route.startsWith('/rider/')) return 'rider';
    if (route.startsWith('/connector/')) return 'connector';
    if (route.startsWith('/admin/')) return 'admin';
    if (route.startsWith('/vendor-admin/')) return 'vendoradmin';
    return null;
  }
  
  /// Get all routes for a specific role
  static List<String> getRoutesForRole(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return [
          customerHome,
          customerBrowse,
          customerCart,
          customerOrders,
          customerProfile,
          customerEditProfile,
          productDetails,
          checkout,
          orderTracking,
          orderDetails,
          addresses,
          paymentMethods,
          favorites,
          reviews,
          orderHistory,
        ];
      case 'vendor':
        return [
          vendorHome,
          vendorProducts,
          vendorOrders,
          vendorProfile,
          vendorAnalytics,
          addProduct,
          editProduct,
          vendorInventory,
          vendorEcoReport,
        ];
      case 'rider':
        return [
          riderHome,
          riderDeliveries,
          deliveryList,
          riderEarnings,
          riderProfile,
          riderAnalytics,
          deliveryDetails,
          riderNavigation,
        ];
      case 'connector':
        return [
          connectorHome,
          connectorProfile,
          connectorAnalytics,
          connectorActiveOrders,
          connectorAvailableOrders,
          assignmentDetails,
          customerOrderChat,
          riderHandoff,
          shoppingProgress,
          wasteLogging,
          wasteDetails,
        ];
      case 'admin':
        return [
          adminHome,
          adminReports,
          userManagement,
          userCreation,
          commissionManagement,
          paymentReconciliation,
          systemAnalytics,
          systemLogs,
          systemSettings,
        ];
      case 'vendoradmin':
        return [
          vendorAdminMain,
          vendorAdminHome,
          vendorAdminStalls,
          vendorAdminVendors,
          vendorAdminAnalytics,
          vendorAdminReports,
          vendorAdminProfile,
          vendorAdminAddStall,
          vendorAdminNotifications,
          vendorAdminActivities,
        ];
      default:
        return [];
    }
  }
  
  /// Get shared routes accessible to all authenticated users
  static List<String> getSharedRoutes() {
    return [
      notifications,
      settings,
      helpSupport,
      about,
      chat,
      orderChat,
      camera,
      map,
      rating,
    ];
  }
} 