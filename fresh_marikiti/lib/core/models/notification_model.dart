import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? imageUrl;
  final String? actionUrl;
  final int priority;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.imageUrl,
    this.actionUrl,
    this.priority = 0,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'general',
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      imageUrl: json['imageUrl'],
      actionUrl: json['actionUrl'],
      priority: json['priority'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'priority': priority,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    String? imageUrl,
    String? actionUrl,
    int? priority,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      priority: priority ?? this.priority,
    );
  }

  // Helper methods
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case 'order_update':
        return 'Order Update';
      case 'chat_message':
        return 'New Message';
      case 'promotion':
        return 'Promotion';
      case 'waste_pickup':
        return 'Waste Pickup';
      case 'payment':
        return 'Payment';
      case 'system':
        return 'System';
      default:
        return 'Notification';
    }
  }

  String get typeIcon {
    switch (type) {
      case 'order_update':
        return '📦';
      case 'chat_message':
        return '💬';
      case 'promotion':
        return '🎉';
      case 'waste_pickup':
        return '♻️';
      case 'payment':
        return '💳';
      case 'system':
        return '⚙️';
      default:
        return '🔔';
    }
  }

  bool get isHighPriority => priority > 5;
  bool get hasCTA => actionUrl != null && actionUrl!.isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
}

// Notification preference model
class NotificationPreferences {
  final bool pushNotificationsEnabled;
  final bool orderUpdatesEnabled;
  final bool promotionsEnabled;
  final bool chatMessagesEnabled;
  final bool wastePickupEnabled;
  final bool systemNotificationsEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool soundEnabled;
  final bool vibrationEnabled;

  NotificationPreferences({
    this.pushNotificationsEnabled = true,
    this.orderUpdatesEnabled = true,
    this.promotionsEnabled = true,
    this.chatMessagesEnabled = true,
    this.wastePickupEnabled = true,
    this.systemNotificationsEnabled = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      pushNotificationsEnabled: json['pushNotificationsEnabled'] ?? true,
      orderUpdatesEnabled: json['orderUpdatesEnabled'] ?? true,
      promotionsEnabled: json['promotionsEnabled'] ?? true,
      chatMessagesEnabled: json['chatMessagesEnabled'] ?? true,
      wastePickupEnabled: json['wastePickupEnabled'] ?? true,
      systemNotificationsEnabled: json['systemNotificationsEnabled'] ?? true,
      quietHoursStart: json['quietHoursStart'] ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] ?? '08:00',
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'orderUpdatesEnabled': orderUpdatesEnabled,
      'promotionsEnabled': promotionsEnabled,
      'chatMessagesEnabled': chatMessagesEnabled,
      'wastePickupEnabled': wastePickupEnabled,
      'systemNotificationsEnabled': systemNotificationsEnabled,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  NotificationPreferences copyWith({
    bool? pushNotificationsEnabled,
    bool? orderUpdatesEnabled,
    bool? promotionsEnabled,
    bool? chatMessagesEnabled,
    bool? wastePickupEnabled,
    bool? systemNotificationsEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return NotificationPreferences(
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      orderUpdatesEnabled: orderUpdatesEnabled ?? this.orderUpdatesEnabled,
      promotionsEnabled: promotionsEnabled ?? this.promotionsEnabled,
      chatMessagesEnabled: chatMessagesEnabled ?? this.chatMessagesEnabled,
      wastePickupEnabled: wastePickupEnabled ?? this.wastePickupEnabled,
      systemNotificationsEnabled: systemNotificationsEnabled ?? this.systemNotificationsEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  // Helper methods
  bool isInQuietHours() {
    final now = DateTime.now();
    final start = _parseTime(quietHoursStart);
    final end = _parseTime(quietHoursEnd);
    final current = TimeOfDay.fromDateTime(now);
    
    if (start.hour < end.hour) {
      // Same day range (e.g., 22:00 to 23:00)
      return _isTimeBetween(current, start, end);
    } else {
      // Overnight range (e.g., 22:00 to 08:00)
      return _isTimeBetween(current, start, const TimeOfDay(hour: 23, minute: 59)) ||
             _isTimeBetween(current, const TimeOfDay(hour: 0, minute: 0), end);
    }
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  bool _isTimeBetween(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }
}