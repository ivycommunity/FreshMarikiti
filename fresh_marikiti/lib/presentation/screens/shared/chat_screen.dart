import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/chat_provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/providers/theme_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/chat_model.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeChat();
  }

  void _initializeChat() {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.initialize();
    LoggerService.info('Chat screen initialized', tag: 'ChatScreen');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ChatProvider, AuthProvider, ThemeProvider>(
      builder: (context, chatProvider, authProvider, themeProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: _buildAppBar(context),
          body: Column(
            children: [
              // Search bar
              if (_isSearchMode) _buildSearchBar(),
              
              // Tab bar
              _buildTabBar(context),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllChatsTab(chatProvider),
                    _buildActiveOrdersTab(chatProvider),
                    _buildSupportTab(chatProvider),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(context),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.colors.freshGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Messages',
        style: context.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isSearchMode ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              _isSearchMode = !_isSearchMode;
              if (!_isSearchMode) {
                _searchController.clear();
                _searchQuery = '';
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showOptionsMenu(context),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.freshGreen,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
          border: OutlineInputBorder(
            borderRadius: AppRadius.radiusLG,
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: context.colors.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: context.colors.freshGreen,
        unselectedLabelColor: context.colors.textSecondary,
        indicatorColor: context.colors.freshGreen,
        tabs: const [
          Tab(text: 'All Chats'),
          Tab(text: 'Active Orders'),
          Tab(text: 'Support'),
        ],
      ),
    );
  }

  Widget _buildAllChatsTab(ChatProvider chatProvider) {
    if (chatProvider.isLoading && chatProvider.conversations.isEmpty) {
      return _buildLoadingState();
    }

    final conversations = _getFilteredConversations(chatProvider.conversations);

    if (conversations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No Conversations',
        message: 'Start chatting by placing an order or contacting support',
      );
    }

    return RefreshIndicator(
      onRefresh: () => chatProvider.loadConversations(refresh: true),
      child: ListView.builder(
        padding: AppSpacing.paddingMD,
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return _buildConversationCard(conversation);
        },
      ),
    );
  }

  Widget _buildActiveOrdersTab(ChatProvider chatProvider) {
    final activeConversations = chatProvider.conversations
        .where((conv) => conv.isActive && _isOrderConversation(conv))
        .toList();

    if (activeConversations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'No Active Orders',
        message: 'You don\'t have any active orders with ongoing conversations',
      );
    }

    return ListView.builder(
      padding: AppSpacing.paddingMD,
      itemCount: activeConversations.length,
      itemBuilder: (context, index) {
        final conversation = activeConversations[index];
        return _buildOrderConversationCard(conversation);
      },
    );
  }

  Widget _buildSupportTab(ChatProvider chatProvider) {
    final supportConversations = chatProvider.conversations
        .where((conv) => _isSupportConversation(conv))
        .toList();

    return Column(
      children: [
        // Support actions
        _buildSupportActions(),
        
        // Support conversations
        Expanded(
          child: supportConversations.isEmpty
              ? _buildEmptyState(
                  icon: Icons.support_agent,
                  title: 'No Support Chats',
                  message: 'Contact our support team for help with orders or app issues',
                )
              : ListView.builder(
                  padding: AppSpacing.paddingMD,
                  itemCount: supportConversations.length,
                  itemBuilder: (context, index) {
                    final conversation = supportConversations[index];
                    return _buildSupportConversationCard(conversation);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSupportActions() {
    return Container(
      margin: AppSpacing.paddingMD,
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.ecoBlue.withOpacity(0.1),
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: context.colors.ecoBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Need Help?',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _startSupportChat('general'),
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('Chat Support'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.ecoBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _startSupportChat('technical'),
                  icon: const Icon(Icons.bug_report, size: 18),
                  label: const Text('Report Issue'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.ecoBlue,
                    side: BorderSide(color: context.colors.ecoBlue),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(ChatConversation conversation) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: ListTile(
        contentPadding: AppSpacing.paddingMD,
        leading: _buildConversationAvatar(conversation),
        title: Text(
          conversation.participantName,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: _hasUnreadMessages(conversation) ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conversation.lastMessage?.content ?? 'No messages yet',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: context.colors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatMessageTime(conversation.updatedAt),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_hasUnreadMessages(conversation))
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: context.colors.freshGreen,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  conversation.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Icon(
              _isOrderConversation(conversation) 
                  ? Icons.shopping_bag 
                  : Icons.support_agent,
              size: 16,
              color: context.colors.textSecondary,
            ),
          ],
        ),
        onTap: () => _openConversation(conversation),
      ),
    );
  }

  Widget _buildOrderConversationCard(ChatConversation conversation) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusLG,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colors.freshGreen.withOpacity(0.05),
              context.colors.marketOrange.withOpacity(0.05),
            ],
          ),
        ),
        child: ListTile(
          contentPadding: AppSpacing.paddingMD,
          leading: Stack(
            children: [
              _buildConversationAvatar(conversation),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: context.colors.freshGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.shopping_bag,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  conversation.participantName,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.marketOrange,
                  borderRadius: AppRadius.radiusSM,
                ),
                child: Text(
                  'ACTIVE',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Order #${conversation.orderId.substring(0, 8)}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.freshGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                conversation.lastMessage?.content ?? 'No messages yet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
          trailing: _hasUnreadMessages(conversation)
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.colors.marketOrange,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    conversation.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: context.colors.textSecondary,
                ),
          onTap: () => _openConversation(conversation),
        ),
      ),
    );
  }

  Widget _buildSupportConversationCard(ChatConversation conversation) {
    final status = _getSupportStatus(conversation);
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusLG,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colors.ecoBlue.withOpacity(0.05),
              context.colors.freshGreen.withOpacity(0.05),
            ],
          ),
        ),
        child: ListTile(
          contentPadding: AppSpacing.paddingMD,
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: context.colors.ecoBlue,
                child: const Icon(
                  Icons.support_agent,
                  color: Colors.white,
                ),
              ),
              if (status == 'resolved')
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: context.colors.freshGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  _getSupportTitle(conversation),
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: status == 'resolved' 
                      ? context.colors.freshGreen 
                      : context.colors.ecoBlue,
                  borderRadius: AppRadius.radiusSM,
                ),
                child: Text(
                  status.toUpperCase(),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                _getSupportCategory(conversation),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.ecoBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                conversation.lastMessage?.content ?? 'No messages yet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
          trailing: _hasUnreadMessages(conversation)
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.colors.ecoBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    conversation.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: context.colors.textSecondary,
                ),
          onTap: () => _openConversation(conversation),
        ),
      ),
    );
  }

  Widget _buildConversationAvatar(ChatConversation conversation) {
    return CircleAvatar(
      backgroundColor: _isOrderConversation(conversation) 
          ? context.colors.freshGreen 
          : context.colors.ecoBlue,
      child: Text(
        conversation.participantName.isNotEmpty 
            ? conversation.participantName[0].toUpperCase()
            : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(context.colors.freshGreen),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Loading conversations...',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingXL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: context.colors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: context.textTheme.headlineSmall?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.colors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showNewChatOptions(context),
      backgroundColor: context.colors.freshGreen,
      child: const Icon(Icons.add_comment, color: Colors.white),
    );
  }

  // Helper methods for conversation classification
  bool _isOrderConversation(ChatConversation conversation) {
    return conversation.orderId.isNotEmpty && 
           conversation.orderId != 'support' && 
           !conversation.orderId.startsWith('support_');
  }

  bool _isSupportConversation(ChatConversation conversation) {
    return conversation.orderId.startsWith('support_') || 
           conversation.participantRole == 'support' ||
           conversation.participantId == 'support_team';
  }

  bool _hasUnreadMessages(ChatConversation conversation) {
    return conversation.unreadCount > 0;
  }

  String _getSupportStatus(ChatConversation conversation) {
    // Determine status based on conversation activity and properties
    if (!conversation.isActive) return 'resolved';
    if (conversation.lastMessage == null) return 'new';
    return 'open';
  }

  String _getSupportTitle(ChatConversation conversation) {
    if (conversation.orderId.contains('technical')) return 'Technical Support';
    if (conversation.orderId.contains('general')) return 'General Support';
    return 'Support Chat';
  }

  String _getSupportCategory(ChatConversation conversation) {
    if (conversation.orderId.contains('technical')) return 'Technical Issue';
    if (conversation.orderId.contains('general')) return 'General Support';
    return 'Support';
  }

  List<ChatConversation> _getFilteredConversations(List<ChatConversation> conversations) {
    if (_searchQuery.isEmpty) return conversations;
    
    return conversations.where((conversation) {
      return conversation.participantName.toLowerCase().contains(_searchQuery) ||
             (conversation.lastMessage?.content.toLowerCase().contains(_searchQuery) ?? false) ||
             (conversation.orderId.toLowerCase().contains(_searchQuery));
    }).toList();
  }

  String _formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
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

  void _openConversation(ChatConversation conversation) {
    Navigator.pushNamed(
      context,
      '/shared/order-chat',
      arguments: {'conversation': conversation},
    );
  }

  void _startSupportChat(String category) async {
    final chatProvider = context.read<ChatProvider>();
    final authProvider = context.read<AuthProvider>();
    
    if (authProvider.user == null) return;
    
    final conversation = await chatProvider.startConversation(
      orderId: 'support_${category}_${DateTime.now().millisecondsSinceEpoch}',
      participantId: 'support_team',
    );
    
    if (conversation != null) {
      _openConversation(conversation);
    }
  }

  void _showNewChatOptions(BuildContext context) {
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
              'Start New Chat',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: context.colors.ecoBlue,
                child: const Icon(Icons.support_agent, color: Colors.white),
              ),
              title: const Text('Contact Support'),
              subtitle: const Text('Get help with your orders or app issues'),
              onTap: () {
                Navigator.pop(context);
                _startSupportChat('general');
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: context.colors.marketOrange,
                child: const Icon(Icons.bug_report, color: Colors.white),
              ),
              title: const Text('Report Technical Issue'),
              subtitle: const Text('Report bugs or technical problems'),
              onTap: () {
                Navigator.pop(context);
                _startSupportChat('technical');
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
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
              'Chat Options',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.mark_email_read),
              title: const Text('Mark All as Read'),
              onTap: () {
                Navigator.pop(context);
                final chatProvider = context.read<ChatProvider>();
                for (final conversation in chatProvider.conversations) {
                  if (conversation.unreadCount > 0) {
                    chatProvider.markMessagesAsRead(conversation.orderId);
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh Conversations'),
              onTap: () {
                Navigator.pop(context);
                context.read<ChatProvider>().loadConversations(refresh: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Chat Settings'),
              onTap: () {
                Navigator.pop(context);
                NavigationService.toSettings();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
} 