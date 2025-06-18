import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  // Environment Detection
  static bool get isProduction => 
      dotenv.env['ENVIRONMENT']?.toLowerCase() == 'production';
  static bool get isDevelopment => 
      dotenv.env['ENVIRONMENT']?.toLowerCase() == 'development';
  static bool get isStaging => 
      dotenv.env['ENVIRONMENT']?.toLowerCase() == 'staging';
  static bool get isDebug => kDebugMode;

  // API Configuration
  static String get apiBaseUrl => 
      dotenv.env['API_BASE_URL'] ?? 
      (isProduction 
          ? 'https://api.freshmarikiti.co.ke/api'
          : 'http://10.0.2.2:5000/api');
          
  static String get wsBaseUrl => 
      dotenv.env['WS_BASE_URL'] ?? 
      (isProduction 
          ? 'wss://api.freshmarikiti.co.ke'
          : 'ws://10.0.2.2:5000');

  static int get apiTimeout => 
      int.tryParse(dotenv.env['API_TIMEOUT'] ?? '') ?? 30000;

  // App Information
  static String get appName => dotenv.env['APP_NAME'] ?? 'Fresh Marikiti';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static String get supportEmail => 
      dotenv.env['SUPPORT_EMAIL'] ?? 'support@freshmarikiti.co.ke';
  static String get supportPhone => 
      dotenv.env['SUPPORT_PHONE'] ?? '+254700000000';

  // Payment Configuration
  static String get mpesaConsumerKey => dotenv.env['MPESA_CONSUMER_KEY'] ?? '';
  static String get mpesaConsumerSecret => dotenv.env['MPESA_CONSUMER_SECRET'] ?? '';
  static String get mpesaShortcode => dotenv.env['MPESA_SHORTCODE'] ?? '';
  static String get mpesaPasskey => dotenv.env['MPESA_PASSKEY'] ?? '';
  static String get mpesaCallbackUrl => 
      dotenv.env['MPESA_CALLBACK_URL'] ?? '$apiBaseUrl/payments/mpesa/callback';

  // Feature Flags
  static bool get enableChat => 
      dotenv.env['ENABLE_CHAT']?.toLowerCase() == 'true';
  static bool get enableRatings => 
      dotenv.env['ENABLE_RATINGS']?.toLowerCase() == 'true';
  static bool get enableEcoPoints => 
      dotenv.env['ENABLE_ECO_POINTS']?.toLowerCase() == 'true';
  static bool get enableWasteTracking => 
      dotenv.env['ENABLE_WASTE_TRACKING']?.toLowerCase() == 'true';
  static bool get enableAnalytics => 
      dotenv.env['ENABLE_ANALYTICS']?.toLowerCase() == 'true';

  // Performance Configuration
  static String get maxFileSize => dotenv.env['MAX_FILE_SIZE'] ?? '10MB';
  static double get imageCompressionQuality => 
      double.tryParse(dotenv.env['IMAGE_COMPRESSION_QUALITY'] ?? '') ?? 0.8;
  static int get cacheDuration => 
      int.tryParse(dotenv.env['CACHE_DURATION'] ?? '') ?? 3600;

  // Security Configuration
  static int get bcryptRounds => 
      int.tryParse(dotenv.env['BCRYPT_ROUNDS'] ?? '') ?? 12;
  static Duration get sessionTimeout => Duration(
      minutes: int.tryParse(dotenv.env['SESSION_TIMEOUT_MINUTES'] ?? '') ?? 30);

  // Rate Limiting
  static int get rateLimitWindowMs => 
      int.tryParse(dotenv.env['RATE_LIMIT_WINDOW_MS'] ?? '') ?? 900000;
  static int get rateLimitMaxRequests => 
      int.tryParse(dotenv.env['RATE_LIMIT_MAX_REQUESTS'] ?? '') ?? 100;

  // Database Configuration
  static String get mongodbUri => dotenv.env['MONGODB_URI'] ?? '';
  static String get redisUrl => dotenv.env['REDIS_URL'] ?? 'redis://localhost:6379';

  // Logging Configuration
  static String get logLevel => dotenv.env['LOG_LEVEL'] ?? 'info';
  static String get logFile => dotenv.env['LOG_FILE'] ?? 'logs/app.log';

  // Notification Configuration
  static String get fcmServerKey => dotenv.env['FCM_SERVER_KEY'] ?? '';

  // Cloud Storage Configuration
  static String get cloudinaryCloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get cloudinaryApiKey => dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static String get cloudinaryApiSecret => dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  // SMS Configuration
  static String get smsApiKey => dotenv.env['SMS_API_KEY'] ?? '';
  static String get smsSenderId => dotenv.env['SMS_SENDER_ID'] ?? 'FRESH_MARIKITI';

  // Email Configuration
  static String get smtpHost => dotenv.env['SMTP_HOST'] ?? 'smtp.gmail.com';
  static int get smtpPort => int.tryParse(dotenv.env['SMTP_PORT'] ?? '') ?? 587;
  static String get smtpUser => dotenv.env['SMTP_USER'] ?? '';
  static String get smtpPass => dotenv.env['SMTP_PASS'] ?? '';

  // Analytics
  static String get googleAnalyticsId => dotenv.env['GOOGLE_ANALYTICS_ID'] ?? '';

  // JWT Configuration
  static String get jwtSecret => dotenv.env['JWT_SECRET'] ?? '';
  static String get jwtExpiresIn => dotenv.env['JWT_EXPIRES_IN'] ?? '24h';
  static String get refreshTokenExpiresIn => 
      dotenv.env['REFRESH_TOKEN_EXPIRES_IN'] ?? '7d';

  // Initialize configuration
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
    _validateConfiguration();
  }

  // Validate critical configuration
  static void _validateConfiguration() {
    final criticalConfigs = <String, String>{
      'API_BASE_URL': apiBaseUrl,
      'APP_NAME': appName,
      'APP_VERSION': appVersion,
    };

    final missingConfigs = <String>[];
    
    for (final entry in criticalConfigs.entries) {
      if (entry.value.isEmpty) {
        missingConfigs.add(entry.key);
      }
    }

    if (missingConfigs.isNotEmpty && isProduction) {
      throw ConfigurationException(
        'Missing critical configuration: ${missingConfigs.join(', ')}'
      );
    }
  }

  // Get all configuration as a map (for debugging)
  static Map<String, dynamic> getAllConfig() {
    return {
      'environment': dotenv.env['ENVIRONMENT'],
      'isProduction': isProduction,
      'isDevelopment': isDevelopment,
      'isStaging': isStaging,
      'isDebug': isDebug,
      'apiBaseUrl': apiBaseUrl,
      'wsBaseUrl': wsBaseUrl,
      'apiTimeout': apiTimeout,
      'appName': appName,
      'appVersion': appVersion,
      'supportEmail': supportEmail,
      'supportPhone': supportPhone,
      'features': {
        'chat': enableChat,
        'ratings': enableRatings,
        'ecoPoints': enableEcoPoints,
        'wasteTracking': enableWasteTracking,
        'analytics': enableAnalytics,
      },
      'performance': {
        'maxFileSize': maxFileSize,
        'imageCompressionQuality': imageCompressionQuality,
        'cacheDuration': cacheDuration,
      },
      'security': {
        'bcryptRounds': bcryptRounds,
        'sessionTimeout': sessionTimeout.inMinutes,
      },
      'rateLimit': {
        'windowMs': rateLimitWindowMs,
        'maxRequests': rateLimitMaxRequests,
      },
    };
  }

  // Configuration validation for specific features
  static bool get isPaymentConfigured => 
      mpesaConsumerKey.isNotEmpty && 
      mpesaConsumerSecret.isNotEmpty && 
      mpesaShortcode.isNotEmpty;

  static bool get isNotificationConfigured => fcmServerKey.isNotEmpty;

  static bool get isStorageConfigured => 
      cloudinaryCloudName.isNotEmpty && 
      cloudinaryApiKey.isNotEmpty;

  static bool get isSmsConfigured => 
      smsApiKey.isNotEmpty && smsSenderId.isNotEmpty;

  static bool get isEmailConfigured => 
      smtpHost.isNotEmpty && smtpUser.isNotEmpty && smtpPass.isNotEmpty;

  // API Endpoints Configuration
  static Map<String, String> get apiEndpoints => {
    'auth': '/auth',
    'users': '/users',
    'products': '/products',
    'orders': '/orders',
    'payments': '/payments',
    'notifications': '/notifications',
    'chat': '/chat',
    'ratings': '/ratings',
    'analytics': '/analytics',
    'admin': '/admin',
    'vendor': '/vendor',
    'rider': '/rider',
    'connector': '/connector',
    'eco-redemption': '/eco-redemption',
    'waste-tracking': '/waste-tracking',
    'reports': '/reports',
    'settings': '/settings',
  };

  // Database Collections
  static Map<String, String> get collections => {
    'users': 'users',
    'products': 'products',
    'orders': 'orders',
    'payments': 'payments',
    'notifications': 'notifications',
    'chats': 'chats',
    'ratings': 'ratings',
    'waste_logs': 'waste_logs',
    'eco_transactions': 'eco_transactions',
    'analytics': 'analytics',
    'system_logs': 'system_logs',
  };

  // Default Values
  static const Map<String, dynamic> defaults = {
    'pagination': {
      'defaultLimit': 20,
      'maxLimit': 100,
    },
    'cache': {
      'defaultTtl': 3600, // 1 hour
      'longTtl': 86400, // 24 hours
      'shortTtl': 300, // 5 minutes
    },
    'upload': {
      'maxImageSize': 5 * 1024 * 1024, // 5MB
      'maxVideoSize': 50 * 1024 * 1024, // 50MB
      'allowedImageTypes': ['jpg', 'jpeg', 'png', 'webp'],
      'allowedVideoTypes': ['mp4', 'mov', 'avi'],
    },
    'validation': {
      'minPasswordLength': 8,
      'maxNameLength': 50,
      'maxDescriptionLength': 500,
    },
    'business': {
      'deliveryRadius': 20, // km
      'minOrderAmount': 100, // KES
      'ecoPointsRate': 0.01, // 1 point per 100 KES
      'deliveryFee': 100, // KES
    },
  };
}

class ConfigurationException implements Exception {
  final String message;
  
  const ConfigurationException(this.message);
  
  @override
  String toString() => 'ConfigurationException: $message';
} 