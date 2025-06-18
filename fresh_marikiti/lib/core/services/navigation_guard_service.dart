import 'package:flutter/material.dart';
import 'package:fresh_marikiti/core/models/user.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class NavigationGuardService {
  
  // =================== ROUTE PROTECTION DEFINITIONS ===================
  
  static const Map<String, List<UserRole>> _routePermissions = {
    // Customer routes
    '/customer/home': [UserRole.customer],
    '/customer/products': [UserRole.customer],
    '/customer/cart': [UserRole.customer],
    '/customer/orders': [UserRole.customer],
    '/customer/profile': [UserRole.customer],
    '/customer/chat': [UserRole.customer],
    
    // Vendor routes
    '/vendor/home': [UserRole.vendor, UserRole.vendorAdmin],
    '/vendor/products': [UserRole.vendor, UserRole.vendorAdmin],
    '/vendor/orders': [UserRole.vendor, UserRole.vendorAdmin],
    '/vendor/analytics': [UserRole.vendor, UserRole.vendorAdmin],
    '/vendor/profile': [UserRole.vendor, UserRole.vendorAdmin],
    
    // Rider routes
    '/rider/home': [UserRole.rider],
    '/rider/deliveries': [UserRole.rider],
    '/rider/earnings': [UserRole.rider],
    '/rider/profile': [UserRole.rider],
    
    // Connector routes
    '/connector/home': [UserRole.connector],
    '/connector/assignments': [UserRole.connector],
    '/connector/shopping': [UserRole.connector],
    '/connector/earnings': [UserRole.connector],
    '/connector/profile': [UserRole.connector],
    '/connector/chat': [UserRole.connector],
    
    // Vendor Admin routes
    '/vendor-admin/home': [UserRole.vendorAdmin],
    '/vendor-admin/vendors': [UserRole.vendorAdmin],
    '/vendor-admin/products': [UserRole.vendorAdmin],
    '/vendor-admin/analytics': [UserRole.vendorAdmin],
    '/vendor-admin/settings': [UserRole.vendorAdmin],
    
    // System Admin routes
    '/admin/home': [UserRole.admin],
    '/admin/users': [UserRole.admin],
    '/admin/vendors': [UserRole.admin],
    '/admin/orders': [UserRole.admin],
    '/admin/analytics': [UserRole.admin],
    '/admin/settings': [UserRole.admin],
  };

  // Public routes that don't require authentication
  static const List<String> _publicRoutes = [
    '/',
    '/login',
    '/register',
    '/forgot-password',
    '/reset-password',
    '/privacy-policy',
    '/terms-of-service',
  ];

  // Routes that require authentication but are accessible to all roles
  static const List<String> _authenticatedRoutes = [
    '/profile',
    '/settings',
    '/notifications',
    '/help',
    '/support',
  ];

  // =================== MAIN GUARD FUNCTIONS ===================

  /// Check if user can access a specific route
  static bool canAccessRoute(String route, User? user) {
    try {
      // Allow access to public routes
      if (_publicRoutes.contains(route)) {
        return true;
      }

      // Require authentication for protected routes
      if (user == null) {
        LoggerService.warning('Access denied: User not authenticated for route $route', tag: 'NavigationGuard');
        return false;
      }

      // Allow access to general authenticated routes
      if (_authenticatedRoutes.contains(route)) {
        return true;
      }

      // Check role-specific permissions
      final allowedRoles = _routePermissions[route];
      if (allowedRoles == null) {
        // Route not defined in permissions, allow access (default behavior)
        LoggerService.warning('Route $route not defined in permissions, allowing access', tag: 'NavigationGuard');
        return true;
      }

      final hasPermission = allowedRoles.contains(user.role);
      
      if (!hasPermission) {
        LoggerService.warning('Access denied: User role ${user.role} not allowed for route $route', tag: 'NavigationGuard');
      }

      return hasPermission;
    } catch (e) {
      LoggerService.error('Error checking route access', error: e, tag: 'NavigationGuard');
      return false;
    }
  }

  /// Get appropriate home route based on user role
  static String getHomeRouteForRole(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return '/customer/home';
      case UserRole.vendor:
        return '/vendor/home';
      case UserRole.rider:
        return '/rider/home';
      case UserRole.connector:
        return '/connector/home';
      case UserRole.vendorAdmin:
        return '/vendor-admin/home';
      case UserRole.admin:
        return '/admin/home';
    }
  }

  /// Get redirect route if user doesn't have access
  static String getRedirectRoute(User? user, String attemptedRoute) {
    if (user == null) {
      // Redirect to login if not authenticated
      return '/login?redirect=${Uri.encodeComponent(attemptedRoute)}';
    }

    // Redirect to appropriate home route if user doesn't have access
    return getHomeRouteForRole(user.role);
  }

  /// Check if route is public (doesn't require authentication)
  static bool isPublicRoute(String route) {
    return _publicRoutes.contains(route);
  }

  /// Check if route requires authentication
  static bool requiresAuthentication(String route) {
    return !_publicRoutes.contains(route);
  }

  // =================== ROLE-BASED FEATURE ACCESS ===================

  /// Check if user can access a specific feature
  static bool canAccessFeature(String feature, User? user) {
    if (user == null) return false;

    final featurePermissions = {
      // Customer features
      'place_order': [UserRole.customer],
      'view_products': [UserRole.customer, UserRole.vendor, UserRole.vendorAdmin],
      'manage_cart': [UserRole.customer],
      'track_orders': [UserRole.customer],
      'chat_with_connector': [UserRole.customer],
      'rate_orders': [UserRole.customer],
      'eco_points': [UserRole.customer],
      
      // Vendor features
      'manage_products': [UserRole.vendor, UserRole.vendorAdmin],
      'view_vendor_orders': [UserRole.vendor, UserRole.vendorAdmin],
      'vendor_analytics': [UserRole.vendor, UserRole.vendorAdmin],
      'update_inventory': [UserRole.vendor, UserRole.vendorAdmin],
      'manage_business_profile': [UserRole.vendor, UserRole.vendorAdmin],
      
      // Rider features
      'view_deliveries': [UserRole.rider],
      'update_delivery_status': [UserRole.rider],
      'track_location': [UserRole.rider],
      'delivery_earnings': [UserRole.rider],
      'delivery_history': [UserRole.rider],
      
      // Connector features
      'view_assignments': [UserRole.connector],
      'manage_shopping': [UserRole.connector],
      'chat_with_customer': [UserRole.connector],
      'connector_earnings': [UserRole.connector],
      'market_navigation': [UserRole.connector],
      
      // Vendor Admin features
      'manage_vendors': [UserRole.vendorAdmin],
      'vendor_admin_analytics': [UserRole.vendorAdmin],
      'manage_vendor_products': [UserRole.vendorAdmin],
      'vendor_approvals': [UserRole.vendorAdmin],
      
      // System Admin features
      'manage_all_users': [UserRole.admin],
      'system_analytics': [UserRole.admin],
      'platform_settings': [UserRole.admin],
      'financial_reports': [UserRole.admin],
      'system_monitoring': [UserRole.admin],
    };

    final allowedRoles = featurePermissions[feature];
    return allowedRoles?.contains(user.role) ?? false;
  }

  // =================== ORDER STATE ACCESS CONTROL ===================

  /// Check if user can perform order actions based on current state
  static bool canPerformOrderAction(String action, String orderStatus, UserRole userRole) {
    final orderActionPermissions = {
      // Customer actions
      'cancel_order': {
        'roles': [UserRole.customer],
        'allowedStatuses': ['pending', 'confirmed'],
      },
      'rate_order': {
        'roles': [UserRole.customer],
        'allowedStatuses': ['delivered'],
      },
      'track_order': {
        'roles': [UserRole.customer, UserRole.connector, UserRole.rider],
        'allowedStatuses': ['confirmed', 'processing', 'ready', 'picked_up', 'out_for_delivery'],
      },
      
      // Vendor actions
      'confirm_order': {
        'roles': [UserRole.vendor, UserRole.vendorAdmin],
        'allowedStatuses': ['pending'],
      },
      'mark_ready': {
        'roles': [UserRole.vendor, UserRole.vendorAdmin],
        'allowedStatuses': ['confirmed', 'processing'],
      },
      'update_inventory': {
        'roles': [UserRole.vendor, UserRole.vendorAdmin],
        'allowedStatuses': ['pending', 'confirmed'],
      },
      
      // Connector actions
      'accept_assignment': {
        'roles': [UserRole.connector],
        'allowedStatuses': ['confirmed'],
      },
      'start_shopping': {
        'roles': [UserRole.connector],
        'allowedStatuses': ['assigned'],
      },
      'complete_shopping': {
        'roles': [UserRole.connector],
        'allowedStatuses': ['shopping'],
      },
      'handover_to_rider': {
        'roles': [UserRole.connector],
        'allowedStatuses': ['ready'],
      },
      
      // Rider actions
      'accept_delivery': {
        'roles': [UserRole.rider],
        'allowedStatuses': ['ready'],
      },
      'start_delivery': {
        'roles': [UserRole.rider],
        'allowedStatuses': ['picked_up'],
      },
      'complete_delivery': {
        'roles': [UserRole.rider],
        'allowedStatuses': ['out_for_delivery'],
      },
      'update_location': {
        'roles': [UserRole.rider],
        'allowedStatuses': ['picked_up', 'out_for_delivery'],
      },
      
      // Admin actions
      'force_status_change': {
        'roles': [UserRole.admin],
        'allowedStatuses': ['*'], // Admins can change any status
      },
      'refund_order': {
        'roles': [UserRole.admin, UserRole.vendorAdmin],
        'allowedStatuses': ['delivered', 'cancelled'],
      },
    };

    final actionConfig = orderActionPermissions[action];
    if (actionConfig == null) return false;

    final allowedRoles = actionConfig['roles'] as List<UserRole>;
    final allowedStatuses = actionConfig['allowedStatuses'] as List<String>;

    // Check role permission
    if (!allowedRoles.contains(userRole)) {
      return false;
    }

    // Check status permission (admins can override with '*')
    if (allowedStatuses.contains('*') || allowedStatuses.contains(orderStatus)) {
      return true;
    }

    return false;
  }

  // =================== NAVIGATION HELPERS ===================

  /// Get navigation structure based on user role
  static List<NavigationItem> getNavigationItemsForRole(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return [
          NavigationItem(icon: Icons.home, label: 'Home', route: '/customer/home'),
          NavigationItem(icon: Icons.search, label: 'Browse', route: '/customer/products'),
          NavigationItem(icon: Icons.shopping_cart, label: 'Cart', route: '/customer/cart'),
          NavigationItem(icon: Icons.receipt_long, label: 'Orders', route: '/customer/orders'),
          NavigationItem(icon: Icons.person, label: 'Profile', route: '/customer/profile'),
        ];
      
      case UserRole.vendor:
        return [
          NavigationItem(icon: Icons.dashboard, label: 'Dashboard', route: '/vendor/home'),
          NavigationItem(icon: Icons.inventory, label: 'Products', route: '/vendor/products'),
          NavigationItem(icon: Icons.receipt, label: 'Orders', route: '/vendor/orders'),
          NavigationItem(icon: Icons.analytics, label: 'Analytics', route: '/vendor/analytics'),
          NavigationItem(icon: Icons.person, label: 'Profile', route: '/vendor/profile'),
        ];
      
      case UserRole.rider:
        return [
          NavigationItem(icon: Icons.dashboard, label: 'Dashboard', route: '/rider/home'),
          NavigationItem(icon: Icons.delivery_dining, label: 'Deliveries', route: '/rider/deliveries'),
          NavigationItem(icon: Icons.attach_money, label: 'Earnings', route: '/rider/earnings'),
          NavigationItem(icon: Icons.person, label: 'Profile', route: '/rider/profile'),
        ];
      
      case UserRole.connector:
        return [
          NavigationItem(icon: Icons.dashboard, label: 'Dashboard', route: '/connector/home'),
          NavigationItem(icon: Icons.assignment, label: 'Assignments', route: '/connector/assignments'),
          NavigationItem(icon: Icons.shopping_basket, label: 'Shopping', route: '/connector/shopping'),
          NavigationItem(icon: Icons.attach_money, label: 'Earnings', route: '/connector/earnings'),
          NavigationItem(icon: Icons.person, label: 'Profile', route: '/connector/profile'),
        ];
      
      case UserRole.vendorAdmin:
        return [
          NavigationItem(icon: Icons.dashboard, label: 'Dashboard', route: '/vendor-admin/home'),
          NavigationItem(icon: Icons.store, label: 'Vendors', route: '/vendor-admin/vendors'),
          NavigationItem(icon: Icons.inventory, label: 'Products', route: '/vendor-admin/products'),
          NavigationItem(icon: Icons.analytics, label: 'Analytics', route: '/vendor-admin/analytics'),
          NavigationItem(icon: Icons.settings, label: 'Settings', route: '/vendor-admin/settings'),
        ];
      
      case UserRole.admin:
        return [
          NavigationItem(icon: Icons.dashboard, label: 'Dashboard', route: '/admin/home'),
          NavigationItem(icon: Icons.people, label: 'Users', route: '/admin/users'),
          NavigationItem(icon: Icons.store, label: 'Vendors', route: '/admin/vendors'),
          NavigationItem(icon: Icons.receipt, label: 'Orders', route: '/admin/orders'),
          NavigationItem(icon: Icons.analytics, label: 'Analytics', route: '/admin/analytics'),
          NavigationItem(icon: Icons.settings, label: 'Settings', route: '/admin/settings'),
        ];
    }
  }

  /// Validate order state transition
  static bool isValidOrderStateTransition(String currentStatus, String newStatus, UserRole userRole) {
    // Define valid state transitions based on Fresh Marikiti workflow
    final validTransitions = {
      'pending': ['confirmed', 'cancelled'],
      'confirmed': ['assigned', 'cancelled'],
      'assigned': ['shopping', 'cancelled'],
      'shopping': ['ready', 'cancelled'],
      'ready': ['picked_up', 'cancelled'],
      'picked_up': ['out_for_delivery', 'cancelled'],
      'out_for_delivery': ['delivered', 'cancelled'],
      'delivered': [], // Final state
      'cancelled': [], // Final state
    };

    final allowedTransitions = validTransitions[currentStatus] ?? [];
    if (!allowedTransitions.contains(newStatus)) {
      return false;
    }

    // Additional role-based transition validation
    final roleTransitionPermissions = {
      'pending': {
        'confirmed': [UserRole.vendor, UserRole.vendorAdmin],
        'cancelled': [UserRole.customer, UserRole.vendor, UserRole.admin],
      },
      'confirmed': {
        'assigned': [UserRole.connector, UserRole.admin],
        'cancelled': [UserRole.customer, UserRole.vendor, UserRole.admin],
      },
      'assigned': {
        'shopping': [UserRole.connector],
        'cancelled': [UserRole.connector, UserRole.admin],
      },
      'shopping': {
        'ready': [UserRole.connector],
        'cancelled': [UserRole.connector, UserRole.admin],
      },
      'ready': {
        'picked_up': [UserRole.rider],
        'cancelled': [UserRole.admin],
      },
      'picked_up': {
        'out_for_delivery': [UserRole.rider],
        'cancelled': [UserRole.admin],
      },
      'out_for_delivery': {
        'delivered': [UserRole.rider],
        'cancelled': [UserRole.admin],
      },
    };

    final transitionPermissions = roleTransitionPermissions[currentStatus]?[newStatus];
    return transitionPermissions?.contains(userRole) ?? false;
  }
}

/// Navigation item model for role-based navigation
class NavigationItem {
  final IconData icon;
  final String label;
  final String route;
  final int? badgeCount;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
    this.badgeCount,
  });
} 