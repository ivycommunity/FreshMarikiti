import 'package:fresh_marikiti/core/models/user.dart';

class ChatConversation {
  final String id;
  final String orderId;
  final List<String> participants;
  final String participantId;
  final String participantName;
  final String participantRole;
  final String? participantAvatar;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ChatConversation({
    required this.id,
    required this.orderId,
    required this.participants,
    required this.participantId,
    required this.participantName,
    required this.participantRole,
    this.participantAvatar,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['_id'] ?? json['id'] ?? '',
      orderId: json['orderId'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
      participantId: json['participantId'] ?? '',
      participantName: json['participantName'] ?? 'Unknown',
      participantRole: json['participantRole'] ?? 'customer',
      participantAvatar: json['participantAvatar'],
      lastMessage: json['lastMessage'] != null 
          ? ChatMessage.fromJson(json['lastMessage']) 
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'participants': participants,
      'participantId': participantId,
      'participantName': participantName,
      'participantRole': participantRole,
      'participantAvatar': participantAvatar,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  ChatConversation copyWith({
    String? id,
    String? orderId,
    List<String>? participants,
    String? participantId,
    String? participantName,
    String? participantRole,
    String? participantAvatar,
    ChatMessage? lastMessage,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      participants: participants ?? this.participants,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      participantRole: participantRole ?? this.participantRole,
      participantAvatar: participantAvatar ?? this.participantAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Helper methods
  String get lastMessagePreview {
    if (lastMessage == null) return 'No messages yet';
    
    switch (lastMessage!.type) {
      case MessageType.image:
        return '📷 Image';
      case MessageType.document:
        return '📄 File';
      case MessageType.location:
        return '📍 Location';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.video:
        return '📹 Video';
      default:
        return lastMessage!.content;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';
    }
  }
}

enum MessageType { text, image, audio, video, location, document }

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

class ChatMessage {
  final String id;
  final String orderId;
  final String senderId;
  final String senderRole;
  final String recipientId;
  final String recipientRole;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final String? replyToMessageId;

  ChatMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderRole,
    required this.recipientId,
    required this.recipientRole,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.metadata,
    this.replyToMessageId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? json['id'] ?? '',
      orderId: json['orderId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderRole: json['senderRole'] ?? '',
      recipientId: json['recipientId'] ?? '',
      recipientRole: json['recipientRole'] ?? '',
      content: json['content'] ?? json['message'] ?? '',
      type: _messageTypeFromString(json['type'] ?? json['messageType'] ?? 'text'),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'sent'),
        orElse: () => MessageStatus.sent,
      ),
      timestamp: DateTime.tryParse(json['timestamp'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      replyToMessageId: json['replyToMessageId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'senderId': senderId,
      'senderRole': senderRole,
      'recipientId': recipientId,
      'recipientRole': recipientRole,
      'content': content,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'replyToMessageId': replyToMessageId,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? orderId,
    String? senderId,
    String? senderRole,
    String? recipientId,
    String? recipientRole,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
      recipientId: recipientId ?? this.recipientId,
      recipientRole: recipientRole ?? this.recipientRole,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
    );
  }

  // Helper methods
  bool get isImage => type == MessageType.image;
  bool get isLocation => type == MessageType.location;
  bool get isFile => type == MessageType.document;
  bool get isSystemMessage => type == MessageType.text || type == MessageType.location;
  bool get isRead => status == MessageStatus.read;
  bool get isSent => status == MessageStatus.sent || status == MessageStatus.delivered || status == MessageStatus.read;
  bool get isFailed => status == MessageStatus.failed;
  bool get isSending => status == MessageStatus.sending;

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get displayTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  static MessageType _messageTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'audio':
        return MessageType.audio;
      case 'video':
        return MessageType.video;
      case 'location':
        return MessageType.location;
      case 'document':
        return MessageType.document;
      default:
        return MessageType.text;
    }
  }

  String get displayText {
    switch (type) {
      case MessageType.text:
        return content;
      case MessageType.image:
        return '📷 Photo';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.video:
        return '📹 Video';
      case MessageType.location:
        return '📍 Location';
      case MessageType.document:
        return '📎 Document';
    }
  }

  String get typeIcon {
    switch (type) {
      case MessageType.text:
        return '💬';
      case MessageType.image:
        return '📷';
      case MessageType.audio:
        return '🎵';
      case MessageType.video:
        return '📹';
      case MessageType.location:
        return '📍';
      case MessageType.document:
        return '📎';
    }
  }
}

class ChatRoom {
  final String id;
  final String orderId;
  final String customerId;
  final String connectorId;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime lastActivity;
  final int unreadCount;
  final bool isActive;
  final Map<String, dynamic>? orderInfo;

  ChatRoom({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.connectorId,
    required this.messages,
    required this.createdAt,
    required this.lastActivity,
    this.unreadCount = 0,
    this.isActive = true,
    this.orderInfo,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['_id'] ?? json['id'] ?? '',
      orderId: json['orderId'] ?? '',
      customerId: json['customerId'] ?? '',
      connectorId: json['connectorId'] ?? '',
      messages: (json['messages'] as List? ?? [])
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      lastActivity: DateTime.tryParse(json['lastActivity'] ?? json['updatedAt'] ?? '') ?? DateTime.now(),
      unreadCount: json['unreadCount'] ?? 0,
      isActive: json['isActive'] ?? true,
      orderInfo: json['orderInfo'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'customerId': customerId,
      'connectorId': connectorId,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'unreadCount': unreadCount,
      'isActive': isActive,
      'orderInfo': orderInfo,
    };
  }

  ChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;
  
  bool hasUnreadMessages(String userId) {
    return messages.any((m) => 
        m.recipientId == userId && 
        m.status != MessageStatus.read);
  }

  int getUnreadCount(String userId) {
    return messages.where((m) => 
        m.recipientId == userId && 
        m.status != MessageStatus.read).length;
  }
}

class TypingIndicator {
  final String userId;
  final String orderId;
  final String userName;
  final DateTime timestamp;

  TypingIndicator({
    required this.userId,
    required this.orderId,
    required this.userName,
    required this.timestamp,
  });

  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      userId: json['userId'] ?? '',
      orderId: json['orderId'] ?? '',
      userName: json['userName'] ?? 'User',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isExpired {
    return DateTime.now().difference(timestamp).inSeconds > 5;
  }
}

class QuickReply {
  final String id;
  final String text;
  final String? payload;
  final bool isSelected;

  QuickReply({
    required this.id,
    required this.text,
    this.payload,
    this.isSelected = false,
  });

  factory QuickReply.fromJson(Map<String, dynamic> json) {
    return QuickReply(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      payload: json['payload'],
      isSelected: json['isSelected'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'payload': payload,
      'isSelected': isSelected,
    };
  }
}

// Predefined quick replies for different scenarios
class ChatQuickReplies {
  static final List<QuickReply> connectorToCustomer = [
    QuickReply(id: 'arrived', text: '🏪 Arrived at market'),
    QuickReply(id: 'shopping', text: '🛒 Shopping for your items'),
    QuickReply(id: 'almost_done', text: '✅ Almost done!'),
    QuickReply(id: 'ready', text: '📦 Items ready for pickup'),
    QuickReply(id: 'substitute', text: '🔄 Need to suggest substitute'),
    QuickReply(id: 'question', text: '❓ Have a question'),
  ];

  static final List<QuickReply> customerToConnector = [
    QuickReply(id: 'approve', text: '✅ Looks good!'),
    QuickReply(id: 'decline', text: '❌ Please find alternative'),
    QuickReply(id: 'question', text: '❓ I have a question'),
    QuickReply(id: 'urgent', text: '⚡ This is urgent'),
    QuickReply(id: 'thanks', text: '🙏 Thank you!'),
  ];

  static final List<QuickReply> orderUpdates = [
    QuickReply(id: 'item_found', text: '✅ Item found'),
    QuickReply(id: 'item_unavailable', text: '❌ Item not available'),
    QuickReply(id: 'suggest_substitute', text: '🔄 Suggest substitute'),
    QuickReply(id: 'price_change', text: '💰 Price different'),
    QuickReply(id: 'quality_concern', text: '⚠️ Quality concern'),
  ];
}

// Chat attachment model
class ChatAttachment {
  final String id;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final String? thumbnailPath;
  final DateTime uploadedAt;

  ChatAttachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    this.thumbnailPath,
    required this.uploadedAt,
  });

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      id: json['_id'] ?? json['id'] ?? '',
      fileName: json['fileName'] ?? '',
      filePath: json['filePath'] ?? '',
      fileType: json['fileType'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      thumbnailPath: json['thumbnailPath'],
      uploadedAt: DateTime.parse(json['uploadedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileType': fileType,
      'fileSize': fileSize,
      'thumbnailPath': thumbnailPath,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isImage => fileType.startsWith('image/');
  bool get isVideo => fileType.startsWith('video/');
  bool get isAudio => fileType.startsWith('audio/');
  bool get isDocument => !isImage && !isVideo && !isAudio;

  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}