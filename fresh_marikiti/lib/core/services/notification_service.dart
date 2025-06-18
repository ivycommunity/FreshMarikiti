import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';

class NotificationService {
  static const String _baseUrl = '/notifications';
  static FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  static FirebaseMessaging? _firebaseMessaging;
  static bool _isInitialized = false;
  static String? _fcmToken;
  
  // Notification queues and scheduling
  static final List<Map<String, dynamic>> _pendingNotifications = [];
  static Timer? _processingTimer;
  
  // Notification listeners
  static final Map<String, Function> _notificationListeners = {};
  static final List<Map<String, dynamic>> _notificationQueue = [];
  static final List<Map<String, dynamic>> _notificationHistory = [];
  
  // User preferences
  static Map<String, dynamic> _notificationPreferences = {
    'orders': true,
    'deliveries': true,
    'chat': true,
    'promotions': true,
    'system': true,
    'sound': true,
    'vibration': true,
    'quietHours': {
      'enabled': false,
      'start': '22:00',
      'end': '08:00',
    },
  };
  
  // Notification categories
  static const Map<String, Map<String, dynamic>> _notificationCategories = {
    'order_created': {
      'title': 'Order Confirmed',
      'priority': 'high',
      'sound': 'default',
      'channel': 'orders',
    },
    'order_updated': {
      'title': 'Order Update',
      'priority': 'normal',
      'sound': 'default',
      'channel': 'orders',
    },
    'delivery_started': {
      'title': 'Delivery Started',
      'priority': 'high',
      'sound': 'default',
      'channel': 'deliveries',
    },
    'delivery_arrived': {
      'title': 'Delivery Arrived',
      'priority': 'urgent',
      'sound': 'custom',
      'channel': 'deliveries',
    },
    'chat_message': {
      'title': 'New Message',
      'priority': 'normal',
      'sound': 'message',
      'channel': 'chat',
    },
    'promotion': {
      'title': 'Special Offer',
      'priority': 'low',
      'sound': 'none',
      'channel': 'promotions',
    },
    'rating_reminder': {
      'title': 'Rate Your Order',
      'priority': 'low',
      'sound': 'default',
      'channel': 'system',
    },
    'payment_due': {
      'title': 'Payment Required',
      'priority': 'urgent',
      'sound': 'alert',
      'channel': 'orders',
    },
  };

  // =================== INITIALIZATION ===================

  /// Initialize notification services
  static Future<Map<String, dynamic>> initialize() async {
    try {
      if (_isInitialized) {
        return {'success': true, 'token': _fcmToken};
      }

      // Initialize Firebase Messaging
      _firebaseMessaging = FirebaseMessaging.instance;
      
      // Request permissions
      final notificationSettings = await _firebaseMessaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (notificationSettings.authorizationStatus == AuthorizationStatus.denied) {
        return {
          'success': false,
          'error': 'Notification permissions denied',
          'action': 'request_permissions',
        };
      }

      // Get FCM token
      _fcmToken = await _firebaseMessaging!.getToken();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Setup message handlers
      await _setupMessageHandlers();
      
      // Load user preferences
      await _loadNotificationPreferences();
      
      // Send token to server
      if (_fcmToken != null) {
        await _sendTokenToServer(_fcmToken!);
      }
      
      _isInitialized = true;
      LoggerService.info('Notification service initialized', tag: 'NotificationService');
      
      return {
        'success': true,
        'token': _fcmToken,
        'settings': notificationSettings,
      };
    } catch (e) {
      LoggerService.error('Failed to initialize notification service', tag: 'NotificationService', error: e);
      return {
        'success': false,
        'error': 'Notification initialization failed: $e',
      };
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin!.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Create notification channels for Android
  static Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'orders',
        'Order Notifications',
        description: 'Notifications about order status updates',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'deliveries',
        'Delivery Notifications',
        description: 'Notifications about delivery updates',
        importance: Importance.max,
      ),
      AndroidNotificationChannel(
        'chat',
        'Chat Messages',
        description: 'New chat messages',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'promotions',
        'Promotions',
        description: 'Special offers and promotions',
        importance: Importance.low,
      ),
      AndroidNotificationChannel(
        'system',
        'System Notifications',
        description: 'General app notifications',
        importance: Importance.defaultImportance,
      ),
    ];

    final androidPlugin = _flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      for (final channel in channels) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }
  }

  /// Setup Firebase message handlers
  static Future<void> _setupMessageHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Handle app launch from notification
    final initialMessage = await _firebaseMessaging!.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    // Handle token refresh
    _firebaseMessaging!.onTokenRefresh.listen((token) async {
      _fcmToken = token;
      await _sendTokenToServer(token);
    });
  }

  // =================== SENDING NOTIFICATIONS ===================

  /// Send push notification
  static Future<bool> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
    DateTime? scheduledTime,
    bool urgent = false,
  }) async {
    try {
      final response = await ApiService.post('$_baseUrl/send', {
        'userId': userId,
        'type': type,
        'title': title,
        'body': body,
        'data': data ?? {},
        'imageUrl': imageUrl,
        'scheduledTime': scheduledTime?.toIso8601String(),
        'urgent': urgent,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        LoggerService.info('Notification sent successfully', tag: 'NotificationService');
        return true;
      } else {
        throw Exception('Failed to send notification: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to send notification', tag: 'NotificationService', error: e);
      return false;
    }
  }

  /// Send bulk notifications
  static Future<Map<String, dynamic>> sendBulkNotifications({
    required List<String> userIds,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      final response = await ApiService.post('$_baseUrl/send-bulk', {
        'userIds': userIds,
        'type': type,
        'title': title,
        'body': body,
        'data': data ?? {},
        'imageUrl': imageUrl,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'sent': responseData['sent'] ?? 0,
          'failed': responseData['failed'] ?? 0,
        };
      } else {
        throw Exception('Failed to send bulk notifications: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to send bulk notifications', tag: 'NotificationService', error: e);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Show local notification
  static Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channelId,
    String? imageUrl,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'fresh_marikiti_default',
        'Fresh Marikiti',
        channelDescription: 'Fresh Marikiti notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin!.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      LoggerService.error('Failed to show local notification', tag: 'NotificationService', error: e);
    }
  }

  /// Schedule notification
  static Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    String? channelId,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'fresh_marikiti_scheduled',
        'Scheduled Notifications',
        channelDescription: 'Scheduled notifications',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Convert DateTime to TZDateTime
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      await _flutterLocalNotificationsPlugin!.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        notificationDetails,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      return true;
    } catch (e) {
      LoggerService.error('Failed to schedule notification', tag: 'NotificationService', error: e);
      return false;
    }
  }

  // =================== NOTIFICATION MANAGEMENT ===================

  /// Get notifications
  static Future<List<Map<String, dynamic>>> getNotifications({
    int page = 1,
    int limit = 20,
    String? type,
    bool? read,
  }) async {
    try {
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      
      if (type != null) {
        queryParams.add('type=$type');
      }
      if (read != null) {
        queryParams.add('read=$read');
      }

      final url = '$_baseUrl?${queryParams.join('&')}';
      final response = await ApiService.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      LoggerService.error('Failed to get notifications', tag: 'NotificationService', error: e);
      return [];
    }
  }

  /// Mark notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await ApiService.patch('$_baseUrl/$notificationId/read', {
        'readAt': DateTime.now().toIso8601String(),
      });
      
      if (response.statusCode == 200) {
        LoggerService.info('Notification marked as read: $notificationId', tag: 'NotificationService');
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.error('Failed to mark notification as read', tag: 'NotificationService', error: e);
      return false;
    }
  }

  /// Mark all notifications as read
  static Future<bool> markAllAsRead() async {
    try {
      final response = await ApiService.patch('$_baseUrl/mark-all-read', {
        'readAt': DateTime.now().toIso8601String(),
      });
      
      if (response.statusCode == 200) {
        LoggerService.info('All notifications marked as read', tag: 'NotificationService');
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.error('Failed to mark all notifications as read', tag: 'NotificationService', error: e);
      return false;
    }
  }

  /// Delete notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await ApiService.delete('$_baseUrl/$notificationId');
      
      if (response.statusCode == 200) {
        LoggerService.info('Notification deleted: $notificationId', tag: 'NotificationService');
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.error('Failed to delete notification', tag: 'NotificationService', error: e);
      return false;
    }
  }

  /// Clear all notifications
  static Future<bool> clearAll() async {
    try {
      final response = await ApiService.delete('$_baseUrl/clear-all');
      
      if (response.statusCode == 200) {
        LoggerService.info('All notifications cleared', tag: 'NotificationService');
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.error('Failed to clear notifications', tag: 'NotificationService', error: e);
      return false;
    }
  }

  /// Get unread count
  static Future<int> getUnreadCount() async {
    try {
      final response = await ApiService.get('$_baseUrl/unread-count');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      LoggerService.error('Failed to get unread count', tag: 'NotificationService', error: e);
      return 0;
    }
  }

  // =================== PREFERENCES MANAGEMENT ===================

  /// Update notification preferences
  static Future<bool> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      final response = await ApiService.patch('$_baseUrl/preferences', preferences);
      
      if (response.statusCode == 200) {
        _notificationPreferences = {..._notificationPreferences, ...preferences};
        await _saveNotificationPreferences();
        LoggerService.info('Notification preferences updated', tag: 'NotificationService');
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.error('Failed to update preferences', tag: 'NotificationService', error: e);
      return false;
    }
  }

  /// Get notification preferences
  static Future<Map<String, dynamic>> getPreferences() async {
    try {
      final response = await ApiService.get('$_baseUrl/preferences');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final serverPrefs = data['preferences'] ?? {};
        _notificationPreferences = {..._notificationPreferences, ...serverPrefs};
        await _saveNotificationPreferences();
        return _notificationPreferences;
      }
      return _notificationPreferences;
    } catch (e) {
      LoggerService.error('Failed to get preferences', tag: 'NotificationService', error: e);
      return _notificationPreferences;
    }
  }

  /// Load preferences from local storage
  static Future<void> _loadNotificationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsString = prefs.getString('notification_preferences');
      
      if (prefsString != null) {
        final decoded = json.decode(prefsString);
        _notificationPreferences = {..._notificationPreferences, ...decoded};
      }
    } catch (e) {
      LoggerService.error('Failed to load notification preferences', tag: 'NotificationService', error: e);
    }
  }

  /// Save preferences to local storage
  static Future<void> _saveNotificationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notification_preferences', json.encode(_notificationPreferences));
    } catch (e) {
      LoggerService.error('Failed to save notification preferences', tag: 'NotificationService', error: e);
    }
  }

  // =================== TOKEN MANAGEMENT ===================

  /// Update FCM token
  static Future<bool> updateFcmToken(String token) async {
    try {
      final response = await ApiService.post('$_baseUrl/fcm-token', {
        'fcmToken': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      if (response.statusCode == 200) {
        _fcmToken = token;
        LoggerService.info('FCM token updated successfully', tag: 'NotificationService');
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.error('Failed to update FCM token', tag: 'NotificationService', error: e);
      return false;
    }
  }

  /// Send token to server
  static Future<void> _sendTokenToServer(String token) async {
    try {
      await updateFcmToken(token);
    } catch (e) {
      LoggerService.error('Failed to send token to server', tag: 'NotificationService', error: e);
    }
  }

  // =================== MESSAGE HANDLERS ===================

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    try {
      LoggerService.info('Foreground message received: ${message.messageId}', tag: 'NotificationService');
      
      // Check if notifications are enabled for this type
      final messageType = message.data['type'] ?? 'system';
      if (!_shouldShowNotification(messageType)) {
        return;
      }

      // Show local notification
      showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: message.notification?.title ?? 'Fresh Marikiti',
        body: message.notification?.body ?? '',
        payload: json.encode(message.data),
        channelId: _getChannelForType(messageType),
      );

      // Notify listeners
      _notifyListeners('foreground_message', message);
    } catch (e) {
      LoggerService.error('Error handling foreground message', tag: 'NotificationService', error: e);
    }
  }

  /// Handle message tap
  static void _handleMessageTap(RemoteMessage message) {
    try {
      LoggerService.info('Message tapped: ${message.messageId}', tag: 'NotificationService');
      _notifyListeners('message_tap', message);
    } catch (e) {
      LoggerService.error('Error handling message tap', tag: 'NotificationService', error: e);
    }
  }

  /// Handle local notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    try {
      LoggerService.info('Local notification tapped: ${response.id}', tag: 'NotificationService');
      
      if (response.payload != null) {
        final data = json.decode(response.payload!);
        _notifyListeners('local_notification_tap', data);
      }
    } catch (e) {
      LoggerService.error('Error handling notification tap', tag: 'NotificationService', error: e);
    }
  }

  // =================== HELPER METHODS ===================

  /// Check if notification should be shown based on preferences
  static bool _shouldShowNotification(String type) {
    final preference = _notificationPreferences[type];
    if (preference == false) return false;

    // Check quiet hours
    final quietHours = _notificationPreferences['quietHours'];
    if (quietHours['enabled'] == true) {
      final now = DateTime.now();
      final start = _parseTime(quietHours['start']);
      final end = _parseTime(quietHours['end']);
      
      if (_isInQuietHours(now, start, end)) {
        return false;
      }
    }

    return true;
  }

  /// Get notification channel for type
  static String _getChannelForType(String type) {
    final category = _notificationCategories[type];
    return category?['channel'] ?? 'system';
  }

  /// Parse time string (HH:MM) to DateTime
  static DateTime _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Check if current time is in quiet hours
  static bool _isInQuietHours(DateTime now, DateTime start, DateTime end) {
    if (start.isBefore(end)) {
      return now.isAfter(start) && now.isBefore(end);
    } else {
      // Quiet hours span midnight
      return now.isAfter(start) || now.isBefore(end);
    }
  }

  /// Add event listener
  static void addEventListener(String event, Function callback) {
    _notificationListeners[event] = callback;
  }

  /// Remove event listener
  static void removeEventListener(String event) {
    _notificationListeners.remove(event);
  }

  /// Notify listeners
  static void _notifyListeners(String event, dynamic data) {
    final callback = _notificationListeners[event];
    if (callback != null) {
      try {
        callback(data);
      } catch (e) {
        LoggerService.error('Error in notification listener for $event', tag: 'NotificationService', error: e);
      }
    }
  }

  // =================== GETTERS ===================

  /// Check if notifications are initialized
  static bool get isInitialized => _isInitialized;

  /// Get FCM token
  static String? get fcmToken => _fcmToken;

  /// Get current preferences
  static Map<String, dynamic> get preferences => Map.from(_notificationPreferences);

  /// Get pending notifications count
  static int get pendingCount => _pendingNotifications.length;

  // =================== CLEANUP ===================

  /// Dispose notification service
  static void dispose() {
    _processingTimer?.cancel();
    _notificationListeners.clear();
    _pendingNotifications.clear();
    _notificationQueue.clear();
    _notificationHistory.clear();
    LoggerService.info('Notification service disposed', tag: 'NotificationService');
  }
} 