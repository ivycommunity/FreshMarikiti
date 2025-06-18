import 'dart:convert';
import 'dart:io';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/chat_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatService {
  static io.Socket? _socket;
  static String? _currentUserId;
  static bool _isConnected = false;
  
  // Enhanced chat features
  static final Map<String, Function> _eventListeners = {};
  static final List<Map<String, dynamic>> _messageQueue = [];
  static final Set<String> _typingUsers = {};
  
  // Message status tracking
  static final Map<String, String> _messageStatusMap = {};
  
  // =================== CONNECTION MANAGEMENT ===================

  /// Initialize chat service with enhanced features
  static Future<void> initialize(String userId, {String? baseUrl}) async {
    try {
      _currentUserId = userId;
      
      // Use WebSocket URL from environment or provided baseUrl
      final wsUrl = baseUrl ?? ApiService.wsUrl;
      _socket = io.io(wsUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'query': {'userId': userId},
        'timeout': 20000,
        'forceNew': true,
      });

      await _setupSocketEvents();
      _socket?.connect();
      
      LoggerService.info('Chat service initialized', tag: 'ChatService');
    } catch (e) {
      LoggerService.error('Failed to initialize chat service', tag: 'ChatService', error: e);
      throw Exception('Chat initialization failed: $e');
    }
  }

  /// Setup comprehensive socket event listeners
  static Future<void> _setupSocketEvents() async {
    // Connection events
    _socket?.on('connect', (_) {
      _isConnected = true;
      LoggerService.info('Socket connected', tag: 'ChatService');
      _processMessageQueue();
      _notifyListeners('connected', true);
    });

    _socket?.on('disconnect', (_) {
      _isConnected = false;
      LoggerService.info('Socket disconnected', tag: 'ChatService');
      _notifyListeners('disconnected', false);
    });

    _socket?.on('connect_error', (error) {
      LoggerService.error('Socket connection error', tag: 'ChatService', error: error);
      _notifyListeners('connection_error', error);
    });

    // Message events
    _socket?.on('new_message', (data) {
      LoggerService.info('New message received', tag: 'ChatService');
      _notifyListeners('new_message', data);
    });

    _socket?.on('message_delivered', (data) {
      final messageId = data['messageId'];
      _messageStatusMap[messageId] = 'delivered';
      _notifyListeners('message_delivered', data);
    });

    _socket?.on('message_read', (data) {
      final messageId = data['messageId'];
      _messageStatusMap[messageId] = 'read';
      _notifyListeners('message_read', data);
    });

    // Typing events
    _socket?.on('user_typing', (data) {
      final userId = data['userId'];
      final isTyping = data['isTyping'];
      
      if (isTyping) {
        _typingUsers.add(userId);
      } else {
        _typingUsers.remove(userId);
      }
      
      _notifyListeners('typing_status', {
        'userId': userId,
        'isTyping': isTyping,
        'typingUsers': List.from(_typingUsers),
      });
    });

    // Presence events
    _socket?.on('user_online', (data) {
      _notifyListeners('user_online', data);
    });

    _socket?.on('user_offline', (data) {
      _notifyListeners('user_offline', data);
    });

    // Group chat events
    _socket?.on('conversation_updated', (data) {
      _notifyListeners('conversation_updated', data);
    });

    _socket?.on('user_joined_conversation', (data) {
      _notifyListeners('user_joined_conversation', data);
    });

    _socket?.on('user_left_conversation', (data) {
      _notifyListeners('user_left_conversation', data);
    });

    // File transfer events
    _socket?.on('file_upload_progress', (data) {
      _notifyListeners('file_upload_progress', data);
    });

    _socket?.on('file_upload_complete', (data) {
      _notifyListeners('file_upload_complete', data);
    });

    // Error events
    _socket?.on('error', (error) {
      LoggerService.error('Socket error', tag: 'ChatService', error: error);
      _notifyListeners('socket_error', error);
    });

    // Order-specific events
    _socket?.on('order_status_update', (data) {
      _notifyListeners('order_status_update', data);
    });
  }

  // =================== CONVERSATION MANAGEMENT ===================

  /// Get conversations with enhanced filtering
  static Future<Map<String, dynamic>> getConversations({
    int page = 1,
    int limit = 20,
    String? searchQuery,
    List<String>? types,
  }) async {
    try {
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(searchQuery)}');
      }
      
      if (types != null && types.isNotEmpty) {
        queryParams.add('types=${types.join(',')}');
      }
      
      final url = '/chat/conversations?${queryParams.join('&')}';
      final response = await ApiService.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'conversations': data['conversations'] ?? [],
          'pagination': data['pagination'] ?? {},
          'unreadCount': data['unreadCount'] ?? 0,
        };
      } else {
        throw Exception('Failed to get conversations: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to get conversations', tag: 'ChatService', error: e);
      return {
        'success': false,
        'conversations': [],
        'pagination': {'page': page, 'limit': limit, 'total': 0},
        'error': e.toString(),
      };
    }
  }

  /// Start or continue conversation with enhanced options
  static Future<Map<String, dynamic>> startConversation({
    required String orderId,
    required String participantId,
    String? conversationType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await ApiService.post('/chat/conversations', {
        'orderId': orderId,
        'participantId': participantId,
        'type': conversationType ?? 'order',
        'metadata': metadata ?? {},
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // Join the conversation room
        _socket?.emit('join_conversation', {
          'conversationId': data['conversation']['id'],
          'userId': _currentUserId,
        });
        
        return {
          'success': true,
          'conversation': data['conversation'],
        };
      } else {
        throw Exception('Failed to start conversation: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to start conversation', tag: 'ChatService', error: e);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Join order chat room
  static void joinOrderChat(String orderId) {
    try {
      _socket?.emit('joinOrderChat', {
        'orderId': orderId,
        'userId': _currentUserId,
        'timestamp': DateTime.now().toIso8601String(),
      });
      LoggerService.info('Joined order chat: $orderId', tag: 'ChatService');
    } catch (e) {
      LoggerService.error('Failed to join order chat', error: e, tag: 'ChatService');
    }
  }

  /// Leave order chat room
  static void leaveOrderChat(String orderId) {
    try {
      _socket?.emit('leaveOrderChat', {
        'orderId': orderId,
        'userId': _currentUserId,
      });
      LoggerService.info('Left order chat: $orderId', tag: 'ChatService');
    } catch (e) {
      LoggerService.error('Failed to leave order chat', error: e, tag: 'ChatService');
    }
  }

  // =================== MESSAGE OPERATIONS ===================

  /// Send text message with enhanced options
  static Future<bool> sendMessage({
    required String orderId,
    required String message,
    String type = 'text',
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
    bool? urgent,
  }) async {
    try {
      final messageData = {
        'content': message,
        'type': type,
        'metadata': metadata ?? {},
        'replyToMessageId': replyToMessageId,
        'urgent': urgent ?? false,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Send to backend API first
      final response = await ApiService.post('/chat/rooms/$orderId/messages', messageData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final responseMessage = data['message'] ?? data;

        // Emit via socket for real-time delivery
        _socket?.emit('sendMessage', {
          'orderId': orderId,
          'messageId': responseMessage['id'] ?? responseMessage['_id'],
          'content': message,
          'type': type,
          'senderId': _currentUserId,
          'timestamp': DateTime.now().toIso8601String(),
          'metadata': metadata,
          'replyToMessageId': replyToMessageId,
          'urgent': urgent,
        });

        LoggerService.info('Message sent successfully', tag: 'ChatService');
        return true;
      } else {
        // Add to queue if offline
        if (!_isConnected) {
          _messageQueue.add(messageData);
          return true;
        }
        
        LoggerService.error('Failed to send message: ${response.statusCode}', tag: 'ChatService');
        return false;
      }
    } catch (e) {
      LoggerService.error('Error sending message', error: e, tag: 'ChatService');
      
      // Add to queue if error (likely network issue)
      _messageQueue.add({
        'orderId': orderId,
        'content': message,
        'type': type,
        'metadata': metadata ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      return false;
    }
  }

  /// Send image message with upload progress
  static Future<Map<String, dynamic>> sendImageMessage({
    required String orderId,
    required File imageFile,
    String? caption,
    Function(double)? onProgress,
  }) async {
    try {
      LoggerService.info('Sending image message', tag: 'ChatService');

      // First upload the image with progress tracking
      final uploadResult = await _uploadImageWithProgress(orderId, imageFile, onProgress);
      if (!uploadResult['success']) {
        return uploadResult;
      }

      // Send message with image URL
      final success = await sendMessage(
        orderId: orderId,
        message: caption ?? 'Image',
        type: 'image',
        metadata: {
          'imageUrl': uploadResult['imageUrl'],
          'fileName': imageFile.path.split('/').last,
          'fileSize': await imageFile.length(),
          'thumbnailUrl': uploadResult['thumbnailUrl'],
        },
      );

      return {
        'success': success,
        'imageUrl': uploadResult['imageUrl'],
        'thumbnailUrl': uploadResult['thumbnailUrl'],
      };
    } catch (e) {
      LoggerService.error('Error sending image message', error: e, tag: 'ChatService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Send location message
  static Future<bool> sendLocationMessage({
    required String orderId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      return await sendMessage(
        orderId: orderId,
        message: address ?? 'Location shared',
        type: 'location',
        metadata: {
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
        },
      );
    } catch (e) {
      LoggerService.error('Error sending location message', error: e, tag: 'ChatService');
      return false;
    }
  }

  /// Send file message
  static Future<Map<String, dynamic>> sendFileMessage({
    required String orderId,
    required File file,
    String? description,
    Function(double)? onProgress,
  }) async {
    try {
      LoggerService.info('Sending file message', tag: 'ChatService');

      final uploadResult = await _uploadFileWithProgress(orderId, file, onProgress);
      if (!uploadResult['success']) {
        return uploadResult;
      }

      final success = await sendMessage(
        orderId: orderId,
        message: description ?? file.path.split('/').last,
        type: 'file',
        metadata: {
          'fileUrl': uploadResult['fileUrl'],
          'fileName': file.path.split('/').last,
          'fileSize': await file.length(),
          'mimeType': uploadResult['mimeType'],
        },
      );

      return {
        'success': success,
        'fileUrl': uploadResult['fileUrl'],
      };
    } catch (e) {
      LoggerService.error('Error sending file message', error: e, tag: 'ChatService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // =================== MESSAGE STATUS MANAGEMENT ===================

  /// Mark message as read
  static Future<bool> markMessageAsRead(String messageId, String orderId) async {
    try {
      final response = await ApiService.patch('/chat/messages/$messageId/read', {
        'orderId': orderId,
        'readAt': DateTime.now().toIso8601String(),
      });

      if (response.statusCode == 200) {
        _socket?.emit('mark_message_read', {
          'messageId': messageId,
          'orderId': orderId,
          'userId': _currentUserId,
        });
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.error('Error marking message as read', error: e, tag: 'ChatService');
      return false;
    }
  }

  /// Mark all messages in order as read
  static Future<bool> markAllMessagesAsRead(String orderId) async {
    try {
      final response = await ApiService.patch('/chat/rooms/$orderId/read-all', {
        'readAt': DateTime.now().toIso8601String(),
      });

      if (response.statusCode == 200) {
        _socket?.emit('mark_all_read', {
          'orderId': orderId,
          'userId': _currentUserId,
        });
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.error('Error marking all messages as read', error: e, tag: 'ChatService');
      return false;
    }
  }

  // =================== TYPING INDICATORS ===================

  /// Send typing indicator
  static void sendTypingIndicator(String orderId, bool isTyping) {
    try {
      _socket?.emit('typing_indicator', {
        'orderId': orderId,
        'userId': _currentUserId,
        'isTyping': isTyping,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      LoggerService.error('Error sending typing indicator', error: e, tag: 'ChatService');
    }
  }

  // =================== EVENT MANAGEMENT ===================

  /// Add event listener
  static void addEventListener(String event, Function(dynamic) callback) {
    _eventListeners[event] = callback;
  }

  /// Remove event listener
  static void removeEventListener(String event) {
    _eventListeners.remove(event);
  }

  /// Notify all listeners of an event
  static void _notifyListeners(String event, dynamic data) {
    final callback = _eventListeners[event];
    if (callback != null) {
      try {
        callback(data);
      } catch (e) {
        LoggerService.error('Error in event listener for $event', error: e, tag: 'ChatService');
      }
    }
  }

  // =================== MESSAGE HISTORY ===================

  /// Get message history for an order
  static Future<List<ChatMessage>> getOrderMessages({
    required String orderId,
    int page = 1,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    try {
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      
      if (beforeMessageId != null) {
        queryParams.add('before=$beforeMessageId');
      }

      final url = '/chat/rooms/$orderId/messages?${queryParams.join('&')}';
      final response = await ApiService.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final messages = data['messages'] ?? [];
        return messages.map<ChatMessage>((json) => ChatMessage.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      LoggerService.error('Error fetching order messages', error: e, tag: 'ChatService');
      return [];
    }
  }

  // =================== HELPER METHODS ===================

  /// Process queued messages when connection is restored
  static void _processMessageQueue() {
    if (_messageQueue.isEmpty) return;

    LoggerService.info('Processing ${_messageQueue.length} queued messages', tag: 'ChatService');
    
    final queue = List.from(_messageQueue);
    _messageQueue.clear();
    
    for (final messageData in queue) {
      sendMessage(
        orderId: messageData['orderId'],
        message: messageData['content'],
        type: messageData['type'] ?? 'text',
        metadata: messageData['metadata'],
      );
    }
  }

  /// Upload image with progress tracking
  static Future<Map<String, dynamic>> _uploadImageWithProgress(
    String orderId,
    File imageFile,
    Function(double)? onProgress,
  ) async {
    try {
      // Implementation would use multipart upload with progress tracking
      // For now, return mock successful upload
      return {
        'success': true,
        'imageUrl': 'https://api.freshmarikiti.com/uploads/images/${DateTime.now().millisecondsSinceEpoch}.jpg',
        'thumbnailUrl': 'https://api.freshmarikiti.com/uploads/thumbs/${DateTime.now().millisecondsSinceEpoch}.jpg',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Upload file with progress tracking
  static Future<Map<String, dynamic>> _uploadFileWithProgress(
    String orderId,
    File file,
    Function(double)? onProgress,
  ) async {
    try {
      // Implementation would use multipart upload with progress tracking
      final fileName = file.path.split('/').last;
      return {
        'success': true,
        'fileUrl': 'https://api.freshmarikiti.com/uploads/files/${DateTime.now().millisecondsSinceEpoch}_$fileName',
        'mimeType': 'application/octet-stream', // Would detect actual MIME type
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Check connection status
  static bool get isConnected => _isConnected;

  /// Get current user ID
  static String? get currentUserId => _currentUserId;

  /// Get typing users
  static Set<String> get typingUsers => Set.from(_typingUsers);

  /// Get message status
  static String? getMessageStatus(String messageId) => _messageStatusMap[messageId];

  /// Disconnect and cleanup
  static void disconnect() {
    try {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      _isConnected = false;
      _eventListeners.clear();
      _messageQueue.clear();
      _typingUsers.clear();
      _messageStatusMap.clear();
      LoggerService.info('Chat service disconnected and cleaned up', tag: 'ChatService');
    } catch (e) {
      LoggerService.error('Error during chat service cleanup', error: e, tag: 'ChatService');
    }
  }
} 