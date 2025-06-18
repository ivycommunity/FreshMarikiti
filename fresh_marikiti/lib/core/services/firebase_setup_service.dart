import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fresh_marikiti/firebase_options.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/notification_service.dart';

class FirebaseSetupService {
  static bool _isInitialized = false;
  static String? _fcmToken;
  
  /// Complete Firebase initialization including all necessary services
  static Future<Map<String, dynamic>> initializeFirebase() async {
    try {
      if (_isInitialized) {
        return {
          'success': true,
          'message': 'Firebase already initialized',
          'fcmToken': _fcmToken,
        };
      }

      // Initialize Firebase Core
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Setup Firebase Messaging
      final messagingResult = await _setupFirebaseMessaging();
      if (!messagingResult['success']) {
        return messagingResult;
      }

      // Initialize Enhanced Notification Service
      final notificationResult = await NotificationService.initialize();
      if (!notificationResult['success']) {
        return notificationResult;
      }

      // Setup message handlers
      await _setupMessageHandlers();

      _isInitialized = true;
      _fcmToken = messagingResult['token'];

      LoggerService.info('Firebase setup completed successfully', tag: 'FirebaseSetupService');
      
      return {
        'success': true,
        'message': 'Firebase initialized successfully',
        'fcmToken': _fcmToken,
        'notificationPermission': messagingResult['permissionStatus'],
      };
    } catch (e) {
      LoggerService.error('Firebase setup failed', tag: 'FirebaseSetupService', error: e);
      return {
        'success': false,
        'error': 'Firebase initialization failed: $e',
      };
    }
  }

  /// Setup Firebase Messaging with permissions
  static Future<Map<String, dynamic>> _setupFirebaseMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return {
          'success': false,
          'error': 'Notification permissions denied',
          'permissionStatus': 'denied',
        };
      }

      // Get FCM token
      final token = await messaging.getToken();
      
      if (token != null) {
        LoggerService.info('FCM Token obtained: ${token.substring(0, 20)}...', tag: 'FirebaseSetupService');
      }

      // Handle token refresh
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        LoggerService.info('FCM Token refreshed', tag: 'FirebaseSetupService');
        // TODO: Update token on server
      });

      return {
        'success': true,
        'token': token,
        'permissionStatus': settings.authorizationStatus.toString(),
      };
    } catch (e) {
      LoggerService.error('Firebase Messaging setup failed', tag: 'FirebaseSetupService', error: e);
      return {
        'success': false,
        'error': 'Firebase Messaging setup failed: $e',
      };
    }
  }

  /// Setup comprehensive message handlers for all notification scenarios
  static Future<void> _setupMessageHandlers() async {
    try {
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        LoggerService.info('Foreground message received: ${message.messageId}', tag: 'FirebaseSetupService');
        _handleForegroundMessage(message);
      });

      // Handle background message taps
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        LoggerService.info('Background message tapped: ${message.messageId}', tag: 'FirebaseSetupService');
        _handleNotificationTap(message);
      });

      // Handle app launch from terminated state
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        LoggerService.info('App launched from notification: ${initialMessage.messageId}', tag: 'FirebaseSetupService');
        _handleNotificationTap(initialMessage);
      }

      LoggerService.info('Message handlers setup completed', tag: 'FirebaseSetupService');
    } catch (e) {
      LoggerService.error('Message handlers setup failed', tag: 'FirebaseSetupService', error: e);
    }
  }

  /// Handle foreground messages with local notifications
  static void _handleForegroundMessage(RemoteMessage message) {
    try {
      // Show local notification for foreground messages
      NotificationService.showLocalNotification(
        id: message.hashCode,
        title: message.notification?.title ?? 'Fresh Marikiti',
        body: message.notification?.body ?? 'You have a new notification',
        payload: _encodeMessageData(message.data),
      );
    } catch (e) {
      LoggerService.error('Failed to handle foreground message', tag: 'FirebaseSetupService', error: e);
    }
  }

  /// Handle notification taps with deep linking
  static void _handleNotificationTap(RemoteMessage message) {
    try {
      final action = message.data['action'];
      final data = message.data;

      LoggerService.info('Processing notification action: $action', tag: 'FirebaseSetupService');

      // Process different notification actions
      switch (action) {
        case 'view_order':
          _handleOrderNotification(data);
          break;
        case 'track_delivery':
          _handleDeliveryNotification(data);
          break;
        case 'open_chat':
          _handleChatNotification(data);
          break;
        case 'view_promotion':
          _handlePromotionNotification(data);
          break;
        case 'rate_order':
          _handleRatingNotification(data);
          break;
        default:
          _handleGenericNotification(data);
      }
    } catch (e) {
      LoggerService.error('Failed to handle notification tap', tag: 'FirebaseSetupService', error: e);
    }
  }

  /// Handle order-related notifications
  static void _handleOrderNotification(Map<String, dynamic> data) {
    final orderId = data['orderId'];
    LoggerService.info('Navigating to order: $orderId', tag: 'FirebaseSetupService');
    // TODO: Navigate to order details screen
  }

  /// Handle delivery tracking notifications
  static void _handleDeliveryNotification(Map<String, dynamic> data) {
    final deliveryId = data['deliveryId'];
    LoggerService.info('Navigating to delivery tracking: $deliveryId', tag: 'FirebaseSetupService');
    // TODO: Navigate to delivery tracking screen
  }

  /// Handle chat notifications
  static void _handleChatNotification(Map<String, dynamic> data) {
    final conversationId = data['conversationId'];
    LoggerService.info('Opening chat: $conversationId', tag: 'FirebaseSetupService');
    // TODO: Navigate to chat screen
  }

  /// Handle promotion notifications
  static void _handlePromotionNotification(Map<String, dynamic> data) {
    final promotionId = data['promotionId'];
    LoggerService.info('Showing promotion: $promotionId', tag: 'FirebaseSetupService');
    // TODO: Navigate to promotion details
  }

  /// Handle rating notifications
  static void _handleRatingNotification(Map<String, dynamic> data) {
    final orderId = data['orderId'];
    LoggerService.info('Opening rating screen for order: $orderId', tag: 'FirebaseSetupService');
    // TODO: Navigate to rating screen
  }

  /// Handle generic notifications
  static void _handleGenericNotification(Map<String, dynamic> data) {
    LoggerService.info('Handling generic notification', tag: 'FirebaseSetupService');
    // TODO: Navigate to notification center or home screen
  }

  /// Encode message data for local notification payload
  static String _encodeMessageData(Map<String, dynamic> data) {
    try {
      // Simple encoding for payload
      return data.entries.map((e) => '${e.key}=${e.value}').join('&');
    } catch (e) {
      return '';
    }
  }

  /// Get current FCM token
  static String? get fcmToken => _fcmToken;

  /// Check if Firebase is initialized
  static bool get isInitialized => _isInitialized;

  /// Update FCM token on server
  static Future<bool> updateTokenOnServer(String token) async {
    try {
      // TODO: Implement server token update
      LoggerService.info('FCM token should be updated on server', tag: 'FirebaseSetupService');
      return true;
    } catch (e) {
      LoggerService.error('Failed to update token on server', tag: 'FirebaseSetupService', error: e);
      return false;
    }
  }

  /// Reset Firebase setup state
  static void reset() {
    _isInitialized = false;
    _fcmToken = null;
    LoggerService.info('Firebase setup state reset', tag: 'FirebaseSetupService');
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  LoggerService.info('Background message processed: ${message.messageId}', tag: 'BackgroundHandler');
} 