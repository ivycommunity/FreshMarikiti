import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/chat_provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/providers/theme_provider.dart';
import 'package:fresh_marikiti/core/providers/order_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/chat_model.dart';
import 'package:fresh_marikiti/core/models/order_model.dart';
import 'package:fresh_marikiti/core/models/user.dart';
import 'dart:async';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class OrderChatScreen extends StatefulWidget {
  final ChatConversation? conversation;
  final String? orderId;

  const OrderChatScreen({
    super.key,
    this.conversation,
    this.orderId,
  });

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _fabAnimationController;
  
  ChatConversation? _conversation;
  Order? _order;
  bool _isTyping = false;
  Timer? _typingTimer;
  bool _showQuickReplies = false;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _initializeChat();
  }

  void _initializeChat() async {
    final chatProvider = context.read<ChatProvider>();
    final orderProvider = context.read<OrderProvider>();
    
    if (_conversation != null) {
      chatProvider.setCurrentConversation(_conversation!);
      await chatProvider.loadMessages(_conversation!.orderId);
      
      // Load order details
      _order = await orderProvider.getOrderDetails(_conversation!.orderId);
      setState(() {});
    } else if (widget.orderId != null) {
      await chatProvider.loadMessages(widget.orderId!);
      _order = await orderProvider.getOrderDetails(widget.orderId!);
      setState(() {});
    }
    
    LoggerService.info('Order chat initialized', tag: 'OrderChatScreen');
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer4<ChatProvider, AuthProvider, ThemeProvider, OrderProvider>(
      builder: (context, chatProvider, authProvider, themeProvider, orderProvider, child) {
        final currentUser = authProvider.user;
        if (currentUser == null) {
          return const Scaffold(
            body: Center(child: Text('Authentication required')),
          );
        }

        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: _buildAppBar(context, currentUser),
          body: Column(
            children: [
              // Order info header
              if (_order != null) _buildOrderHeader(),
              
              // Messages list
              Expanded(
                child: _buildMessagesList(chatProvider, currentUser),
              ),
              
              // Quick replies
              if (_showQuickReplies) _buildQuickReplies(currentUser),
              
              // Message input
              _buildMessageInput(chatProvider, currentUser),
            ],
          ),
          floatingActionButton: _buildFloatingActionButtons(currentUser),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, User currentUser) {
    return AppBar(
      backgroundColor: context.colors.freshGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _conversation?.participantName ?? 'Chat',
            style: context.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_order != null)
            Text(
              'Order #${_order!.id.substring(0, 8)}',
              style: context.textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
        ],
      ),
      actions: [
        if (_conversation?.participantRole == 'connector')
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () => _callConnector(),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'order_details',
              child: ListTile(
                leading: Icon(Icons.receipt_long),
                title: Text('Order Details'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'clear_chat',
              child: ListTile(
                leading: Icon(Icons.clear_all),
                title: Text('Clear Chat'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'report_issue',
              child: ListTile(
                leading: Icon(Icons.report),
                title: Text('Report Issue'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderHeader() {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.freshGreen.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: context.colors.freshGreen.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colors.freshGreen,
              borderRadius: AppRadius.radiusSM,
            ),
            child: const Icon(
              Icons.shopping_bag,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${_order!.id.substring(0, 8)}',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                Text(
                  '${_order!.items.length} items • ${_getOrderStatusText(_order!.status)}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getOrderStatusColor(_order!.status),
              borderRadius: AppRadius.radiusSM,
            ),
            child: Text(
              _getOrderStatusText(_order!.status),
              style: context.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ChatProvider chatProvider, User currentUser) {
    if (chatProvider.isLoading && chatProvider.currentMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(context.colors.freshGreen),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Loading messages...',
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (chatProvider.currentMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: context.colors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Start the conversation',
              style: context.textTheme.headlineSmall?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Send a message to begin chatting about your order',
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: AppSpacing.paddingMD,
      itemCount: chatProvider.currentMessages.length,
      itemBuilder: (context, index) {
        final message = chatProvider.currentMessages[index];
        final isOwnMessage = message.senderId == currentUser.id;
        final showAvatar = index == chatProvider.currentMessages.length - 1 ||
            chatProvider.currentMessages[index + 1].senderId != message.senderId;

        return _buildMessageBubble(message, isOwnMessage, showAvatar);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isOwnMessage, bool showAvatar) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwnMessage && showAvatar) _buildAvatar(message),
          if (!isOwnMessage && !showAvatar) const SizedBox(width: 40),
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: AppSpacing.paddingMD,
              decoration: BoxDecoration(
                color: isOwnMessage 
                    ? context.colors.freshGreen 
                    : context.colors.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isOwnMessage ? 16 : 4),
                  bottomRight: Radius.circular(isOwnMessage ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.type == MessageType.image)
                    _buildImageMessage(message)
                  else if (message.type == MessageType.location)
                    _buildLocationMessage(message)
                  else
                    _buildTextMessage(message, isOwnMessage),
                  
                  const SizedBox(height: 4),
                  
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.displayTime,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: isOwnMessage 
                              ? Colors.white.withOpacity(0.8)
                              : context.colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      if (isOwnMessage) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _getMessageStatusIcon(message.status),
                          size: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isOwnMessage && showAvatar) _buildAvatar(message),
          if (isOwnMessage && !showAvatar) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildAvatar(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: context.colors.freshGreen,
        child: Text(
          message.senderRole == 'customer' ? 'C' : 'K',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTextMessage(ChatMessage message, bool isOwnMessage) {
    return Text(
      message.content,
      style: context.textTheme.bodyMedium?.copyWith(
        color: isOwnMessage ? Colors.white : context.colors.textPrimary,
        height: 1.3,
      ),
    );
  }

  Widget _buildImageMessage(ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: AppRadius.radiusMD,
          ),
          child: const Center(
            child: Icon(
              Icons.image,
              size: 40,
              color: Colors.grey,
            ),
          ),
        ),
        if (message.content.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            message.content,
            style: context.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationMessage(ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: AppRadius.radiusMD,
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_pin,
                  size: 32,
                  color: Colors.red,
                ),
                Text(
                  'Location Shared',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (message.content.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            message.content,
            style: context.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickReplies(User currentUser) {
    final quickReplies = currentUser.role == UserRole.customer 
        ? ChatQuickReplies.customerToConnector
        : ChatQuickReplies.connectorToCustomer;

    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        border: Border(
          top: BorderSide(
            color: context.colors.textSecondary.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Quick Replies',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () {
                  setState(() {
                    _showQuickReplies = false;
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: quickReplies.map((reply) => 
              _buildQuickReplyChip(reply)
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplyChip(QuickReply reply) {
    return GestureDetector(
      onTap: () => _sendQuickReply(reply),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.colors.freshGreen.withOpacity(0.1),
          border: Border.all(color: context.colors.freshGreen),
          borderRadius: AppRadius.radiusLG,
        ),
        child: Text(
          reply.text,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colors.freshGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(ChatProvider chatProvider, User currentUser) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(
            color: context.colors.textSecondary.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: context.colors.freshGreen,
            ),
            onPressed: () => _showAttachmentOptions(),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: AppRadius.radiusLG,
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: context.colors.surfaceColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _handleTyping,
              onSubmitted: (text) => _sendMessage(chatProvider, currentUser),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AnimatedBuilder(
            animation: _fabAnimationController,
            builder: (context, child) => Transform.scale(
              scale: _messageController.text.isNotEmpty ? 1.0 : 0.0,
              child: FloatingActionButton.small(
                onPressed: () => _sendMessage(chatProvider, currentUser),
                backgroundColor: context.colors.freshGreen,
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButtons(User currentUser) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          onPressed: () {
            setState(() {
              _showQuickReplies = !_showQuickReplies;
            });
          },
          backgroundColor: context.colors.ecoBlue,
          heroTag: 'quick_replies',
          child: Icon(
            _showQuickReplies ? Icons.close : Icons.quick_contacts_dialer,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FloatingActionButton.small(
          onPressed: () => _scrollToBottom(),
          backgroundColor: context.colors.marketOrange,
          heroTag: 'scroll_bottom',
          child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
        ),
      ],
    );
  }

  // Helper methods
  void _handleTyping(String text) {
    if (text.isNotEmpty && !_isTyping) {
      setState(() {
        _isTyping = true;
      });
      _fabAnimationController.forward();
    } else if (text.isEmpty && _isTyping) {
      setState(() {
        _isTyping = false;
      });
      _fabAnimationController.reverse();
    }

    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      setState(() {
        _isTyping = false;
      });
    });
  }

  void _sendMessage(ChatProvider chatProvider, User currentUser) async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    _fabAnimationController.reverse();
    setState(() {
      _isTyping = false;
    });

    final orderId = _conversation?.orderId ?? widget.orderId ?? '';
    if (orderId.isNotEmpty) {
      await chatProvider.sendMessage(
        orderId: orderId,
        content: message,
      );
      _scrollToBottom();
    }
  }

  void _sendQuickReply(QuickReply reply) async {
    final chatProvider = context.read<ChatProvider>();
    final orderId = _conversation?.orderId ?? widget.orderId ?? '';
    
    if (orderId.isNotEmpty) {
      await chatProvider.sendMessage(
        orderId: orderId,
        content: reply.text,
        type: 'quickReply',
        metadata: {'replyId': reply.id, 'payload': reply.payload},
      );
      
      setState(() {
        _showQuickReplies = false;
      });
      
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: AppSpacing.paddingLG,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Send Attachment',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: context.colors.freshGreen,
                  onTap: () => _takePhoto(),
                ),
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: context.colors.ecoBlue,
                  onTap: () => _pickImage(),
                ),
                _buildAttachmentOption(
                  icon: Icons.location_on,
                  label: 'Location',
                  color: context.colors.marketOrange,
                  onTap: () => _shareLocation(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _takePhoto() {
    // Navigate to camera screen
    NavigationService.toCamera();
  }

  void _pickImage() {
    // Implementation for image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image picker will be implemented')),
    );
  }

  void _shareLocation() {
    // Navigate to map screen for location sharing
    NavigationService.toMap();
  }

  void _callConnector() {
    // Implementation for calling connector
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calling feature will be implemented')),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'order_details':
        if (_order != null) {
          Navigator.pushNamed(context, '/customer/order-details', arguments: {
            'order': _order,
          });
        }
        break;
      case 'clear_chat':
        _showClearChatDialog();
        break;
      case 'report_issue':
        NavigationService.toHelpSupport();
        break;
    }
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear this chat? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Clear chat implementation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat cleared')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  String _getOrderStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _getOrderStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return context.colors.ecoBlue;
      case OrderStatus.processing:
        return context.colors.marketOrange;
      case OrderStatus.ready:
        return context.colors.freshGreen;
      case OrderStatus.pickedUp:
        return Colors.blue;
      case OrderStatus.outForDelivery:
        return Colors.purple;
      case OrderStatus.delivered:
        return context.colors.freshGreen;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }
} 