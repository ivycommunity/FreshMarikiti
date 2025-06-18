import 'package:flutter/material.dart';
import 'package:fresh_marikiti/core/models/notification_model.dart';
import 'package:fresh_marikiti/core/services/notification_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'dart:async';

class NotificationProvider with ChangeNotifier {
  List<AppNotification> _notifications = [];
  List<AppNotification> _unreadNotifications = [];
  NotificationPreferences _preferences = NotificationPreferences();
  
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  
  // Real-time updates
  Timer? _refreshTimer;
  StreamSubscription? _notificationStream;
  
  // Notification counts
  int _unreadCount = 0;
  final Map<String, int> _categoryUnreadCounts = {};

  // Getters
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<AppNotification> get unreadNotifications => List.unmodifiable(_unreadNotifications);
  NotificationPreferences get preferences => _preferences;
  
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  
  int get unreadCount => _unreadCount;
  Map<String, int> get categoryUnreadCounts => Map.unmodifiable(_categoryUnreadCounts);

  /// Initialize provider
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      // Initialize notification service
      await NotificationService.initialize();
      
      // Load preferences
      await loadPreferences();
      
      // Load notifications
      await loadNotifications();
      
      // Set up real-time listeners
      _setupNotificationListeners();
      
      // Start refresh timer
      _startRefreshTimer();
      
      _isInitialized = true;
      _error = null;
    } catch (e) {
      LoggerService.error('Failed to initialize notifications', error: e, tag: 'NotificationProvider');
      _error = 'Failed to initialize notifications: ${e.toString()}';
      _notifications = [];
      _updateUnreadNotifications();
      _updateCategoryCounts();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load notifications from backend
  Future<void> loadNotifications({bool refresh = false}) async {
    if (_isLoading && !refresh) return;
    
    _isLoading = true;
    if (refresh) _error = null;
    notifyListeners();

    try {
      final result = await NotificationService.getNotifications();
      _notifications = result.map((data) => AppNotification.fromJson(data)).toList();
      _updateUnreadNotifications();
      _updateCategoryCounts();
      _error = null;
    } catch (e) {
      LoggerService.error('Failed to load notifications', error: e, tag: 'NotificationProvider');
      _error = 'Failed to load notifications: ${e.toString()}';
      _notifications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load notification preferences
  Future<void> loadPreferences() async {
    try {
      final result = await NotificationService.getPreferences();
      _preferences = NotificationPreferences.fromJson(result);
      notifyListeners();
    } catch (e) {
      LoggerService.error('Failed to load notification preferences', error: e, tag: 'NotificationProvider');
      _preferences = NotificationPreferences();
    }
  }

  /// Update notification preferences
  Future<bool> updatePreferences(NotificationPreferences newPreferences) async {
    try {
      final success = await NotificationService.updatePreferences(newPreferences.toJson());
      if (success) {
        _preferences = newPreferences;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.error('Failed to update notification preferences', error: e, tag: 'NotificationProvider');
      _error = 'Failed to update preferences: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final success = await NotificationService.markAsRead(notificationId);
      if (success) {
        final notificationIndex = _notifications.indexWhere((n) => n.id == notificationId);
        if (notificationIndex != -1) {
          _notifications[notificationIndex] = _notifications[notificationIndex].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
          
          _updateUnreadNotifications();
          _updateCategoryCounts();
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      LoggerService.error('Failed to mark notification as read', error: e, tag: 'NotificationProvider');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final success = await NotificationService.markAllAsRead();
      if (success) {
        final now = DateTime.now();
        _notifications = _notifications.map((notification) => 
          notification.copyWith(isRead: true, readAt: now)
        ).toList();
        
        _updateUnreadNotifications();
        _updateCategoryCounts();
        notifyListeners();
      }
      return success;
    } catch (e) {
      LoggerService.error('Failed to mark all notifications as read', error: e, tag: 'NotificationProvider');
      _error = 'Failed to mark all as read: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final success = await NotificationService.deleteNotification(notificationId);
      if (success) {
        _notifications.removeWhere((n) => n.id == notificationId);
        _updateUnreadNotifications();
        _updateCategoryCounts();
        notifyListeners();
      }
      return success;
    } catch (e) {
      LoggerService.error('Failed to delete notification', error: e, tag: 'NotificationProvider');
      return false;
    }
  }

  /// Clear all notifications
  Future<bool> clearAllNotifications() async {
    try {
      final success = await NotificationService.clearAll();
      if (success) {
        _notifications.clear();
        _updateUnreadNotifications();
        _updateCategoryCounts();
        notifyListeners();
      }
      return success;
    } catch (e) {
      LoggerService.error('Failed to clear all notifications', error: e, tag: 'NotificationProvider');
      _error = 'Failed to clear notifications: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Send notification
  Future<bool> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Show local notification
      await NotificationService.showLocalNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        payload: data?.toString(),
      );
      
      // Refresh notifications to show the new one
      await loadNotifications(refresh: true);
      return true;
    } catch (e) {
      LoggerService.error('Failed to send notification', error: e, tag: 'NotificationProvider');
      return false;
    }
  }

  /// Get notifications by category
  List<AppNotification> getNotificationsByCategory(String category) {
    return _notifications.where((n) => n.type == category).toList();
  }

  /// Get notifications by type
  List<AppNotification> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Get recent notifications (last 24 hours)
  List<AppNotification> getRecentNotifications() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _notifications.where((n) => n.createdAt.isAfter(yesterday)).toList();
  }

  /// Check if notifications are enabled for a category
  bool isCategoryEnabled(String category) {
    switch (category.toLowerCase()) {
      case 'orders':
        return _preferences.orderUpdatesEnabled;
      case 'promotions':
        return _preferences.promotionsEnabled;
      case 'chat':
        return _preferences.chatMessagesEnabled;
      case 'waste':
        return _preferences.wastePickupEnabled;
      case 'system':
        return _preferences.systemNotificationsEnabled;
      default:
        return _preferences.pushNotificationsEnabled;
    }
  }

  /// Toggle category notification
  Future<void> toggleCategoryNotification(String category, bool enabled) async {
    NotificationPreferences newPreferences;
    
    switch (category.toLowerCase()) {
      case 'orders':
        newPreferences = _preferences.copyWith(orderUpdatesEnabled: enabled);
        break;
      case 'promotions':
        newPreferences = _preferences.copyWith(promotionsEnabled: enabled);
        break;
      case 'chat':
        newPreferences = _preferences.copyWith(chatMessagesEnabled: enabled);
        break;
      case 'waste':
        newPreferences = _preferences.copyWith(wastePickupEnabled: enabled);
        break;
      case 'system':
        newPreferences = _preferences.copyWith(systemNotificationsEnabled: enabled);
        break;
      default:
        newPreferences = _preferences.copyWith(pushNotificationsEnabled: enabled);
        break;
    }
    
    await updatePreferences(newPreferences);
  }

  /// Refresh notifications
  Future<void> refresh() async {
    await loadNotifications(refresh: true);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Update unread notifications list
  void _updateUnreadNotifications() {
    _unreadNotifications = _notifications.where((n) => !n.isRead).toList();
    _unreadCount = _unreadNotifications.length;
  }

  /// Update category unread counts
  void _updateCategoryCounts() {
    _categoryUnreadCounts.clear();
    for (final notification in _unreadNotifications) {
      final category = notification.type;
      _categoryUnreadCounts[category] = (_categoryUnreadCounts[category] ?? 0) + 1;
    }
  }

  /// Setup notification listeners
  void _setupNotificationListeners() {
    // Listen for new notifications
    NotificationService.addEventListener('foreground_message', (data) {
      if (data is Map<String, dynamic>) {
        final appNotification = AppNotification.fromJson(data);
        _notifications.insert(0, appNotification);
        _updateUnreadNotifications();
        _updateCategoryCounts();
        notifyListeners();
      }
    });
  }

  /// Start periodic refresh timer
  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      loadNotifications(refresh: true);
    });
  }

  /// Dispose resources
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationStream?.cancel();
    super.dispose();
  }
} 