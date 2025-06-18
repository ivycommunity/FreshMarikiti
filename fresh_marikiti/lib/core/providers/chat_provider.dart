import 'package:flutter/material.dart';
import 'package:fresh_marikiti/core/models/chat_model.dart';
import 'package:fresh_marikiti/core/services/chat_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'dart:async';

class ChatProvider with ChangeNotifier {
  List<ChatConversation> _conversations = [];
  List<ChatMessage> _currentMessages = [];
  ChatConversation? _currentConversation;
  
  bool _isLoading = false;
  bool _isSendingMessage = false;
  String? _error;
  
  // Real-time updates
  Timer? _refreshTimer;

  // Getters
  List<ChatConversation> get conversations => List.unmodifiable(_conversations);
  List<ChatMessage> get currentMessages => List.unmodifiable(_currentMessages);
  ChatConversation? get currentConversation => _currentConversation;
  
  bool get isLoading => _isLoading;
  bool get isSendingMessage => _isSendingMessage;
  String? get error => _error;

  /// Initialize provider
  Future<void> initialize() async {
    await loadConversations();
    _startRefreshTimer();
  }

  /// Load conversations
  Future<void> loadConversations({bool refresh = false}) async {
    if (_isLoading && !refresh) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ChatService.getConversations();
      if (result['success'] == true) {
        final conversationsData = List<Map<String, dynamic>>.from(result['conversations'] ?? []);
        _conversations = conversationsData.map((data) => ChatConversation.fromJson(data)).toList();
      } else {
        _conversations = [];
      }
      _error = null;
    } catch (e) {
      LoggerService.error('Failed to load conversations', error: e, tag: 'ChatProvider');
      _error = 'Failed to load conversations: ${e.toString()}';
      _conversations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load messages for an order
  Future<void> loadMessages(String orderId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentMessages = await ChatService.getOrderMessages(orderId: orderId);
      _error = null;
    } catch (e) {
      LoggerService.error('Failed to load messages', error: e, tag: 'ChatProvider');
      _error = 'Failed to load messages: ${e.toString()}';
      _currentMessages = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send message
  Future<bool> sendMessage({
    required String orderId,
    required String content,
    String type = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    _isSendingMessage = true;
    notifyListeners();

    try {
      final success = await ChatService.sendMessage(
        orderId: orderId,
        message: content,
        type: type,
        metadata: metadata,
      );

      if (success) {
        // Reload messages to get the latest
        await loadMessages(orderId);
        return true;
      }
      _error = 'Failed to send message';
      notifyListeners();
      return false;
    } catch (e) {
      LoggerService.error('Failed to send message', error: e, tag: 'ChatProvider');
      _error = 'Failed to send message: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// Set current conversation
  void setCurrentConversation(ChatConversation conversation) {
    _currentConversation = conversation;
    loadMessages(conversation.orderId);
    notifyListeners();
  }

  /// Clear current conversation
  void clearCurrentConversation() {
    _currentConversation = null;
    _currentMessages.clear();
    notifyListeners();
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String orderId) async {
    try {
      await ChatService.markAllMessagesAsRead(orderId);
      
      // Update local data
      _currentMessages = _currentMessages.map((message) => 
        ChatMessage(
          id: message.id,
          orderId: message.orderId,
          senderId: message.senderId,
          senderRole: message.senderRole,
          recipientId: message.recipientId,
          recipientRole: message.recipientRole,
          content: message.content,
          type: message.type,
          status: MessageStatus.read,
          timestamp: message.timestamp,
          metadata: message.metadata,
          replyToMessageId: message.replyToMessageId,
        )
      ).toList();
      
      // Update conversation unread count
      final convIndex = _conversations.indexWhere((conv) => conv.orderId == orderId);
      if (convIndex != -1) {
        _conversations[convIndex] = _conversations[convIndex].copyWith(unreadCount: 0);
      }
      
      notifyListeners();
    } catch (e) {
      LoggerService.error('Failed to mark messages as read', error: e, tag: 'ChatProvider');
    }
  }

  /// Get unread message count
  int getUnreadCount() {
    return _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
  }

  /// Search messages
  List<ChatMessage> searchMessages(String query) {
    return _currentMessages.where((message) =>
        message.content.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  /// Start conversation
  Future<ChatConversation?> startConversation({
    required String orderId,
    required String participantId,
  }) async {
    try {
      final result = await ChatService.startConversation(
        orderId: orderId,
        participantId: participantId,
      );
      
      if (result['success'] == true) {
        final conversation = ChatConversation.fromJson(result['conversation']);
        _conversations.insert(0, conversation);
        notifyListeners();
        return conversation;
      }
      return null;
    } catch (e) {
      LoggerService.error('Failed to start conversation', error: e, tag: 'ChatProvider');
      return null;
    }
  }

  /// Send image message
  Future<bool> sendImageMessage({
    required String orderId,
    required dynamic imageFile, // Using dynamic to avoid File import issues
    String? caption,
  }) async {
    _isSendingMessage = true;
    notifyListeners();

    try {
      final result = await ChatService.sendImageMessage(
        orderId: orderId,
        imageFile: imageFile,
        caption: caption,
      );

      if (result['success'] == true) {
        await loadMessages(orderId);
        return true;
      }
      _error = result['error'] ?? 'Failed to send image';
      notifyListeners();
      return false;
    } catch (e) {
      LoggerService.error('Failed to send image message', error: e, tag: 'ChatProvider');
      _error = 'Failed to send image: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// Send location message
  Future<bool> sendLocationMessage({
    required String orderId,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    _isSendingMessage = true;
    notifyListeners();

    try {
      final success = await ChatService.sendLocationMessage(
        orderId: orderId,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );

      if (success) {
        await loadMessages(orderId);
        return true;
      }
      _error = 'Failed to send location';
      notifyListeners();
      return false;
    } catch (e) {
      LoggerService.error('Failed to send location message', error: e, tag: 'ChatProvider');
      _error = 'Failed to send location: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// Send typing indicator
  void sendTypingIndicator(String orderId, bool isTyping) {
    try {
      ChatService.sendTypingIndicator(orderId, isTyping);
    } catch (e) {
      LoggerService.error('Failed to send typing indicator', error: e, tag: 'ChatProvider');
    }
  }

  /// Join order chat
  void joinOrderChat(String orderId) {
    try {
      ChatService.joinOrderChat(orderId);
    } catch (e) {
      LoggerService.error('Failed to join order chat', error: e, tag: 'ChatProvider');
    }
  }

  /// Leave order chat
  void leaveOrderChat(String orderId) {
    try {
      ChatService.leaveOrderChat(orderId);
    } catch (e) {
      LoggerService.error('Failed to leave order chat', error: e, tag: 'ChatProvider');
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadConversations(refresh: true);
    if (_currentConversation != null) {
      await loadMessages(_currentConversation!.orderId);
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Start refresh timer for real-time updates
  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => refresh(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
} 