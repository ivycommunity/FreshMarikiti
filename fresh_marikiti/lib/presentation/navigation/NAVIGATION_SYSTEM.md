# Fresh Marikiti Navigation System

## Overview

The Fresh Marikiti app now has a completely rebuilt navigation system that provides:
- **Type-safe navigation** with proper parameter validation
- **Comprehensive route coverage** for all 6 user roles
- **Centralized navigation service** for consistent navigation calls
- **Error handling** with user-friendly error screens
- **Role-based routing** with automatic home route detection

## Architecture

### Core Components

1. **RouteNames** (`lib/presentation/navigation/route_names.dart`)
   - Centralized route constants for all screens
   - Utility methods for role-based routing
   - Route validation helpers

2. **AppRouter** (`lib/presentation/navigation/app_router.dart`)
   - Route generation with parameter validation
   - Error handling for missing routes/parameters
   - Type-safe argument passing

3. **NavigationService** (`lib/core/services/navigation_service.dart`)
   - Centralized navigation methods
   - Global navigator key management
   - Utility methods for common navigation patterns

## Route Structure

### Authentication Routes
```dart
RouteNames.splash              // '/'
RouteNames.onboarding         // '/onboarding'
RouteNames.login              // '/login'
RouteNames.register           // '/register'
RouteNames.forgotPassword     // '/forgot-password'
```

### Customer Routes
```dart
RouteNames.customerHome       // '/customer/home'
RouteNames.customerBrowse     // '/customer/browse'
RouteNames.customerCart       // '/customer/cart'
RouteNames.productDetails     // '/customer/product-details'
RouteNames.checkout           // '/customer/checkout'
RouteNames.orderTracking      // '/customer/order-tracking'
// ... and more
```

### Vendor Routes
```dart
RouteNames.vendorHome         // '/vendor/home'
RouteNames.vendorProducts     // '/vendor/products'
RouteNames.addProduct         // '/vendor/add-product'
RouteNames.editProduct        // '/vendor/edit-product'
RouteNames.vendorAnalytics    // '/vendor/analytics'
// ... and more
```

### Rider Routes
```dart
RouteNames.riderHome          // '/rider/home'
RouteNames.deliveryList       // '/rider/delivery-list'
RouteNames.deliveryDetails    // '/rider/delivery-details'
RouteNames.riderNavigation    // '/rider/navigation'
RouteNames.riderEarnings      // '/rider/earnings'
// ... and more
```

### Connector Routes
```dart
RouteNames.connectorHome      // '/connector/home'
RouteNames.assignmentDetails  // '/connector/assignment-details'
RouteNames.shoppingProgress   // '/connector/shopping-progress'
RouteNames.wasteLogging       // '/connector/waste-logging'
// ... and more
```

### Admin Routes
```dart
RouteNames.adminHome          // '/admin/home'
RouteNames.userManagement     // '/admin/user-management'
RouteNames.systemAnalytics    // '/admin/system-analytics'
RouteNames.systemSettings     // '/admin/system-settings'
// ... and more
```

### Vendor Admin Routes
```dart
RouteNames.vendorAdminHome    // '/vendor-admin/home'
RouteNames.vendorAdminStalls  // '/vendor-admin/stalls'
RouteNames.vendorAdminVendors // '/vendor-admin/vendors'
// ... and more
```

### Shared Routes
```dart
RouteNames.notifications      // '/shared/notifications'
RouteNames.settings          // '/shared/settings'
RouteNames.helpSupport       // '/shared/help-support'
RouteNames.chat              // '/shared/chat'
RouteNames.camera            // '/shared/camera'
RouteNames.map               // '/shared/map'
RouteNames.rating            // '/shared/rating'
```

## Usage Examples

### Basic Navigation

```dart
// Simple navigation
NavigationService.toCustomerHome();
NavigationService.toVendorProducts();
NavigationService.toNotifications();

// Navigation with parameters
NavigationService.toProductDetails(product);
NavigationService.toDeliveryDetails(order);
NavigationService.toEditProduct(product);
```

### Navigation with Arguments

```dart
// Order tracking with multiple argument types
NavigationService.toOrderTracking(
  orderId: 'ORDER123',
  order: orderObject,
  arguments: {'source': 'notification'}
);

// Delivery list with filters
NavigationService.toDeliveryList(
  showAvailable: true,
  arguments: {'location': 'Nairobi CBD'}
);

// Rating with context
NavigationService.toRating(
  targetId: 'VENDOR123',
  ratingType: 'vendor',
  targetData: {'name': 'John\'s Vegetables'}
);
```

### Role-Based Navigation

```dart
// Automatically navigate to appropriate home based on user role
NavigationService.toRoleBasedHome(user.role);

// Get routes available for a specific role
final customerRoutes = RouteNames.getRoutesForRole('customer');
final vendorRoutes = RouteNames.getRoutesForRole('vendor');
```

### Utility Navigation

```dart
// Navigation with result waiting
final result = await NavigationService.pushAndWaitForResult<String>(
  RouteNames.productDetails,
  arguments: product
);

// Replace entire navigation stack
NavigationService.pushAndRemoveUntil(
  RouteNames.customerHome,
  arguments: {'welcome': true}
);

// Simple back navigation
NavigationService.goBack();
NavigationService.goBackWithResult(selectedProduct);
```

## Parameter Validation

The navigation system includes comprehensive parameter validation:

### Required Parameters
Routes that require specific parameters will show error screens if parameters are missing:

```dart
// These routes require parameters and will show errors if missing:
RouteNames.productDetails     // Requires Product object
RouteNames.editProduct        // Requires Product object  
RouteNames.deliveryDetails    // Requires Order object
RouteNames.assignmentDetails  // Requires Order object
RouteNames.riderHandoff       // Requires Order object
RouteNames.shoppingProgress   // Requires Order object
```

### Optional Parameters
Routes that accept optional parameters:

```dart
// These routes work with or without parameters:
RouteNames.orderTracking      // Optional: orderId, order, arguments
RouteNames.deliveryList       // Optional: showAvailable, arguments
RouteNames.camera             // Optional: arguments
RouteNames.map                // Optional: order, arguments
RouteNames.rating             // Optional: targetId, ratingType, targetData
```

## Error Handling

### Missing Routes
Unknown routes automatically redirect to an error screen with:
- Fresh Marikiti branding
- Clear error message
- Back navigation button

### Missing Parameters
Routes with missing required parameters show:
- Parameter-specific error messages
- Guidance on what's needed
- Safe fallback navigation

### Navigation Errors
The NavigationService includes error handling for:
- Navigator not available
- Invalid route names
- Parameter type mismatches

## Migration from Old System

### Before (Hard-coded strings)
```dart
// Old way - error prone
Navigator.pushNamed(context, '/customer/product-details', arguments: product);
Navigator.pushNamed(context, '/rider/delivery-list');
Navigator.pushNamed(context, '/shared/notifications');
```

### After (Type-safe NavigationService)
```dart
// New way - type safe and validated
NavigationService.toProductDetails(product);
NavigationService.toDeliveryList();
NavigationService.toNotifications();
```

## Best Practices

### 1. Always Use NavigationService
```dart
// ✅ Good
NavigationService.toCustomerHome();

// ❌ Avoid
Navigator.pushNamed(context, '/customer/home');
```

### 2. Use Specific Methods for Parameters
```dart
// ✅ Good - type safe
NavigationService.toProductDetails(product);

// ❌ Avoid - error prone
Navigator.pushNamed(context, RouteNames.productDetails, arguments: product);
```

### 3. Handle Navigation Errors
```dart
try {
  NavigationService.toProductDetails(product);
} catch (e) {
  // Handle navigation error
  NavigationService.showNavigationError('Failed to open product details');
}
```

### 4. Use Role-Based Navigation
```dart
// ✅ Good - automatically handles different roles
NavigationService.toRoleBasedHome(user.role);

// ❌ Avoid - manual role checking
switch (user.role) {
  case 'customer':
    NavigationService.toCustomerHome();
    break;
  // ... more cases
}
```

## Route Utilities

### Check Route Properties
```dart
// Check if route requires authentication
bool needsAuth = RouteNames.requiresAuth('/customer/home'); // true
bool publicRoute = RouteNames.requiresAuth('/login'); // false

// Check if route is role-specific
bool isRoleSpecific = RouteNames.isRoleSpecific('/vendor/products'); // true

// Get required role for route
String? role = RouteNames.getRequiredRole('/admin/settings'); // 'admin'

// Check if route supports arguments
bool hasArgs = AppRouter.supportsArguments(RouteNames.productDetails); // true
```

### Get Routes by Role
```dart
// Get all routes available to a customer
List<String> customerRoutes = RouteNames.getRoutesForRole('customer');

// Get shared routes available to all users
List<String> sharedRoutes = RouteNames.getSharedRoutes();
```

## Performance Optimizations

### Route Transition Durations
The system includes optimized transition durations:
- **Quick routes** (cart, notifications, settings): 200ms
- **Standard routes**: 300ms

### Route Caching
- Route validation is cached for performance
- Navigator key is globally accessible
- Error routes are pre-built for fast display

## Debugging

### Enable Navigation Logging
Navigation events are automatically logged with the `AppRouter` tag:

```dart
LoggerService.info('Navigating to: /customer/home', tag: 'AppRouter');
LoggerService.warning('Unknown route: /invalid/route', tag: 'AppRouter');
LoggerService.error('Missing required argument for route', tag: 'AppRouter');
```

### Common Issues

1. **Navigator not available**: Ensure NavigationService.navigatorKey is set in MaterialApp
2. **Missing parameters**: Check that required parameters are provided
3. **Route not found**: Verify route name exists in RouteNames
4. **Type errors**: Ensure parameter types match expected types

## Future Enhancements

The navigation system is designed to support:
- **Deep linking** for web and mobile
- **Route guards** for authentication/authorization
- **Navigation analytics** for user behavior tracking
- **A/B testing** for different navigation flows
- **Offline navigation** with cached routes

## Summary

The Fresh Marikiti navigation system provides:
- ✅ **Complete coverage** of all 6 user roles and functionality
- ✅ **Type safety** with parameter validation
- ✅ **Error handling** with user-friendly fallbacks
- ✅ **Centralized management** through NavigationService
- ✅ **Performance optimizations** for smooth user experience
- ✅ **Easy maintenance** with clear separation of concerns
- ✅ **Future-ready** architecture for scaling

This system eliminates navigation parameter issues and provides a robust foundation for the Fresh Marikiti marketplace platform. 