import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:fresh_marikiti/core/config/app_config.dart';
import 'package:fresh_marikiti/core/services/auth_service.dart';
import 'package:fresh_marikiti/core/services/user_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class SocketService {
  static SocketService? _instance;
  static SocketService get instance => _instance ??= SocketService._();
  
  SocketService._();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  String? _currentUserRole;

  // Event callbacks
  final Map<String, List<Function(dynamic)>> _eventListeners = {};

  /// Initialize socket connection
  Future<void> init() async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      final user = await UserService.getCurrentUser();
      
      if (token == null || user == null) {
        LoggerService.warning('Cannot initialize socket: No authentication', tag: 'SocketService');
        return;
      }

      _currentUserId = user.id;
      _currentUserRole = user.role.toString().split('.').last;

      // Socket.io connection with authentication
      _socket = IO.io(
        AppConfig.wsBaseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setExtraHeaders({
              'Authorization': 'Bearer $token',
            })
            .build(),
      );

      _setupEventListeners();
      
      LoggerService.info('Socket initialized for user: ${user.role}', tag: 'SocketService');
    } catch (e) {
      LoggerService.error('Socket initialization failed', error: e, tag: 'SocketService');
    }
  }

  /// Setup default socket event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      _isConnected = true;
      LoggerService.info('Socket connected', tag: 'SocketService');
      
      // Join user-specific room
      _socket!.emit('join_user_room', {
        'userId': _currentUserId,
        'role': _currentUserRole,
      });
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      LoggerService.info('Socket disconnected', tag: 'SocketService');
    });

    _socket!.onError((error) {
      LoggerService.error('Socket error', error: error, tag: 'SocketService');
    });

    _socket!.onReconnect((_) {
      LoggerService.info('Socket reconnected', tag: 'SocketService');
    });
  }

  /// Connect socket if not already connected
  Future<void> connect() async {
    if (_socket == null) {
      await init();
    }
    
    if (_socket != null && !_isConnected) {
      _socket!.connect();
    }
  }

  /// Disconnect socket
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
      _eventListeners.clear();
      LoggerService.info('Socket disconnected manually', tag: 'SocketService');
    }
  }

  /// Check if socket is connected
  bool get isConnected => _isConnected && _socket != null;

  // =================== CHAT METHODS ===================

  /// Join a chat room for order-specific communication
  void joinOrderChat(String orderId) {
    if (!isConnected) return;
    
    _socket!.emit('join_order_chat', {
      'orderId': orderId,
      'userId': _currentUserId,
      'role': _currentUserRole,
    });
    
    LoggerService.info('Joined order chat: $orderId', tag: 'SocketService');
  }

  /// Leave order chat room
  void leaveOrderChat(String orderId) {
    if (!isConnected) return;
    
    _socket!.emit('leave_order_chat', {
      'orderId': orderId,
      'userId': _currentUserId,
    });
    
    LoggerService.info('Left order chat: $orderId', tag: 'SocketService');
  }

  /// Send chat message
  void sendMessage({
    required String orderId,
    required String recipientId,
    required String message,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
  }) {
    if (!isConnected) return;

    final messageData = {
      'orderId': orderId,
      'senderId': _currentUserId,
      'senderRole': _currentUserRole,
      'recipientId': recipientId,
      'message': message,
      'messageType': messageType,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
    };

    _socket!.emit('send_message', messageData);
    LoggerService.info('Message sent to order: $orderId', tag: 'SocketService');
  }

  /// Send typing indicator
  void sendTyping(String orderId, String recipientId, bool isTyping) {
    if (!isConnected) return;

    _socket!.emit('typing', {
      'orderId': orderId,
      'senderId': _currentUserId,
      'recipientId': recipientId,
      'isTyping': isTyping,
    });
  }

  /// Mark message as read
  void markMessageAsRead(String messageId) {
    if (!isConnected) return;

    _socket!.emit('mark_read', {
      'messageId': messageId,
      'userId': _currentUserId,
    });
  }

  // =================== ORDER STATUS METHODS ===================

  /// Subscribe to order status updates
  void subscribeToOrderUpdates(String orderId) {
    if (!isConnected) return;

    _socket!.emit('subscribe_order_updates', {
      'orderId': orderId,
      'userId': _currentUserId,
      'role': _currentUserRole,
    });
    
    LoggerService.info('Subscribed to order updates: $orderId', tag: 'SocketService');
  }

  /// Unsubscribe from order status updates
  void unsubscribeFromOrderUpdates(String orderId) {
    if (!isConnected) return;

    _socket!.emit('unsubscribe_order_updates', {
      'orderId': orderId,
      'userId': _currentUserId,
    });
  }

  /// Broadcast order status change
  void broadcastOrderStatusChange({
    required String orderId,
    required String newStatus,
    String? notes,
    Map<String, dynamic>? additionalData,
  }) {
    if (!isConnected) return;

    _socket!.emit('order_status_update', {
      'orderId': orderId,
      'status': newStatus,
      'updatedBy': _currentUserId,
      'role': _currentUserRole,
      'notes': notes,
      'timestamp': DateTime.now().toIso8601String(),
      'additionalData': additionalData ?? {},
    });
    
    LoggerService.info('Order status update broadcasted: $orderId -> $newStatus', tag: 'SocketService');
  }

  // =================== LOCATION TRACKING METHODS ===================

  /// Start broadcasting rider location
  void startLocationBroadcast(String orderId) {
    if (!isConnected) return;

    _socket!.emit('start_location_tracking', {
      'orderId': orderId,
      'riderId': _currentUserId,
    });
  }

  /// Stop broadcasting rider location
  void stopLocationBroadcast(String orderId) {
    if (!isConnected) return;

    _socket!.emit('stop_location_tracking', {
      'orderId': orderId,
      'riderId': _currentUserId,
    });
  }

  /// Broadcast rider location update
  void broadcastLocationUpdate({
    required String orderId,
    required double latitude,
    required double longitude,
    double? speed,
    double? bearing,
  }) {
    if (!isConnected) return;

    _socket!.emit('location_update', {
      'orderId': orderId,
      'riderId': _currentUserId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'bearing': bearing,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Subscribe to rider location updates
  void subscribeToLocationUpdates(String orderId) {
    if (!isConnected) return;

    _socket!.emit('subscribe_location_updates', {
      'orderId': orderId,
      'userId': _currentUserId,
    });
  }

  // =================== EVENT LISTENER METHODS ===================

  /// Add event listener
  void addEventListener(String event, Function(dynamic) callback) {
    if (_eventListeners[event] == null) {
      _eventListeners[event] = [];
    }
    _eventListeners[event]!.add(callback);

    // Register with socket
    if (_socket != null) {
      _socket!.off(event); // Remove previous listener
      _socket!.on(event, (data) {
        for (var callback in _eventListeners[event] ?? []) {
          try {
            callback(data);
          } catch (e) {
            LoggerService.error('Error in socket event callback', error: e, tag: 'SocketService');
          }
        }
      });
    }
  }

  /// Remove event listener
  void removeEventListener(String event, Function(dynamic) callback) {
    _eventListeners[event]?.remove(callback);
    
    if (_eventListeners[event]?.isEmpty == true) {
      _eventListeners.remove(event);
      _socket?.off(event);
    }
  }

  /// Remove all event listeners for an event
  void removeAllEventListeners(String event) {
    _eventListeners.remove(event);
    _socket?.off(event);
  }

  // =================== CONVENIENCE METHODS ===================

  /// Setup chat listeners for an order
  void setupOrderChatListeners({
    required String orderId,
    Function(dynamic)? onNewMessage,
    Function(dynamic)? onTyping,
    Function(dynamic)? onMessageRead,
  }) {
    if (onNewMessage != null) {
      addEventListener('new_message', (data) {
        if (data['orderId'] == orderId) {
          onNewMessage(data);
        }
      });
    }

    if (onTyping != null) {
      addEventListener('user_typing', (data) {
        if (data['orderId'] == orderId) {
          onTyping(data);
        }
      });
    }

    if (onMessageRead != null) {
      addEventListener('message_read', (data) {
        if (data['orderId'] == orderId) {
          onMessageRead(data);
        }
      });
    }
  }

  /// Setup order status listeners
  void setupOrderStatusListeners({
    Function(dynamic)? onStatusUpdate,
    Function(dynamic)? onLocationUpdate,
    Function(dynamic)? onAssignmentUpdate,
  }) {
    if (onStatusUpdate != null) {
      addEventListener('order_status_changed', onStatusUpdate);
    }

    if (onLocationUpdate != null) {
      addEventListener('rider_location_update', onLocationUpdate);
    }

    if (onAssignmentUpdate != null) {
      addEventListener('order_assignment_update', onAssignmentUpdate);
    }
  }

  /// Clean up all listeners and disconnect
  void cleanup() {
    _eventListeners.clear();
    disconnect();
  }
} 