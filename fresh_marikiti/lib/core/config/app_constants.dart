class AppConstants {
  // App Information
  static const String appName = 'Fresh Marikiti';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Fresh produce delivered to your doorstep';
  
  // API Configuration (moved to .env file)
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  
  // Storage Keys
  static const String userDataKey = 'user_data';
  static const String authTokenKey = 'auth_token';
  static const String cartDataKey = 'cart_data';
  static const String themePreferencesKey = 'theme_preferences';
  static const String notificationSettingsKey = 'notification_settings';
  static const String languageKey = 'selected_language';
  
  // Product Categories
  static const List<String> productCategories = [
    'All',
    'Vegetables',
    'Fruits',
    'Grains',
    'Dairy',
    'Meat',
    'Spices',
  ];
  
  // Order Status
  static const String orderPending = 'pending';
  static const String orderConfirmed = 'confirmed';
  static const String orderPreparing = 'preparing';
  static const String orderReadyForPickup = 'ready_for_pickup';
  static const String orderInTransit = 'in_transit';
  static const String orderDelivered = 'delivered';
  static const String orderCancelled = 'cancelled';
  
  // Delivery Configuration
  static const double baseDeliveryFee = 50.0;
  static const double perKilometerFee = 15.0;
  static const double maxDeliveryFee = 300.0;
  static const double premiumDistanceThreshold = 10.0; // km
  static const double premiumPercentage = 25.0; // %
  static const double extremeDistanceThreshold = 20.0; // km
  static const double extremePremiumPercentage = 50.0; // %
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int maxProductNameLength = 100;
  static const int maxDescriptionLength = 500;
  
  // UI Constants
  static const double defaultBorderRadius = 8.0;
  static const double cardBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Image Configuration
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  
  // Cache Configuration
  static const Duration cacheValidDuration = Duration(minutes: 5);
  static const Duration longCacheDuration = Duration(hours: 1);
  static const Duration shortCacheDuration = Duration(minutes: 1);
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Network Configuration
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  // Eco Points Configuration
  static const int ecoPointsPerKgWaste = 10;
  static const double ecoPointsToMoneyRate = 0.1; // 1 point = 0.1 KSh
  static const int minRedemptionPoints = 100;
  
  // Rating Configuration
  static const double minRating = 1.0;
  static const double maxRating = 5.0;
  static const double featuredProductRatingThreshold = 4.8;
  static const int minRatingCountForFeatured = 5;
  
  // Support Contact
  static const String supportPhoneNumber = '+254 700 000 000';
  static const String supportEmail = 'support@freshmarikiti.com';
  static const String supportHours = 'Monday - Sunday\n6:00 AM - 10:00 PM EAT';
  
  // Social Media (if applicable)
  static const String facebookUrl = '';
  static const String twitterUrl = '';
  static const String instagramUrl = '';
  
  // Legal
  static const String privacyPolicyUrl = '';
  static const String termsOfServiceUrl = '';
  
  // Feature Flags
  static const bool enableDarkMode = true;
  static const bool enablePushNotifications = true;
  static const bool enableLocationServices = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  
  // Debug Configuration
  static const bool enableDebugMode = true;
  static const bool enableLogging = true;
  static const bool enablePerformanceMonitoring = true;
} 