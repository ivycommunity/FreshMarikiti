import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/notification_provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/providers/theme_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/notification_model.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeNotifications();
  }

  void _initializeNotifications() {
    final notificationProvider = context.read<NotificationProvider>();
    if (!notificationProvider.isInitialized) {
      notificationProvider.initialize();
    }
    LoggerService.info('Notifications screen initialized', tag: 'NotificationsScreen');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<NotificationProvider, AuthProvider, ThemeProvider>(
      builder: (context, notificationProvider, authProvider, themeProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: _buildAppBar(context, notificationProvider),
          body: Column(
            children: [
              // Statistics header
              _buildStatsHeader(notificationProvider),
              
              // Tab bar
              _buildTabBar(context),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllNotificationsTab(notificationProvider),
                    _buildOrderNotificationsTab(notificationProvider),
                    _buildPromotionsTab(notificationProvider),
                    _buildSystemNotificationsTab(notificationProvider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, NotificationProvider notificationProvider) {
    return AppBar(
      backgroundColor: context.colors.freshGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Notifications',
        style: context.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (notificationProvider.unreadCount > 0)
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: () => _markAllAsRead(notificationProvider),
            tooltip: 'Mark all as read',
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(value, notificationProvider),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Refresh'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'clear_all',
              child: ListTile(
                leading: Icon(Icons.clear_all),
                title: Text('Clear All'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Notification Settings'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsHeader(NotificationProvider notificationProvider) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.freshGreen,
            context.colors.freshGreen.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              notificationProvider.notifications.length.toString(),
              Icons.notifications,
              Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard(
              'Unread',
              notificationProvider.unreadCount.toString(),
              Icons.mark_email_unread,
              context.colors.marketOrange,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard(
              'Today',
              notificationProvider.getRecentNotifications().length.toString(),
              Icons.today,
              context.colors.ecoBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, IconData icon, Color color) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: AppRadius.radiusLG,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            count,
            style: context.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
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
        isScrollable: true,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Orders'),
          Tab(text: 'Promotions'),
          Tab(text: 'System'),
        ],
      ),
    );
  }

  Widget _buildAllNotificationsTab(NotificationProvider notificationProvider) {
    if (notificationProvider.isLoading && notificationProvider.notifications.isEmpty) {
      return _buildLoadingState();
    }

    if (notificationProvider.notifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.notifications_none,
        title: 'No Notifications',
        message: 'You\'re all caught up! New notifications will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => notificationProvider.loadNotifications(refresh: true),
      child: ListView.builder(
        padding: AppSpacing.paddingMD,
        itemCount: notificationProvider.notifications.length,
        itemBuilder: (context, index) {
          final notification = notificationProvider.notifications[index];
          return _buildNotificationCard(notification, notificationProvider);
        },
      ),
    );
  }

  Widget _buildOrderNotificationsTab(NotificationProvider notificationProvider) {
    final orderNotifications = notificationProvider.getNotificationsByCategory('orders');

    if (orderNotifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'No Order Updates',
        message: 'Order status updates and delivery notifications will appear here.',
      );
    }

    return ListView.builder(
      padding: AppSpacing.paddingMD,
      itemCount: orderNotifications.length,
      itemBuilder: (context, index) {
        final notification = orderNotifications[index];
        return _buildNotificationCard(notification, notificationProvider);
      },
    );
  }

  Widget _buildPromotionsTab(NotificationProvider notificationProvider) {
    final promotionNotifications = notificationProvider.getNotificationsByCategory('promotions');

    if (promotionNotifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.local_offer_outlined,
        title: 'No Promotions',
        message: 'Special offers and deals will be shown here.',
      );
    }

    return ListView.builder(
      padding: AppSpacing.paddingMD,
      itemCount: promotionNotifications.length,
      itemBuilder: (context, index) {
        final notification = promotionNotifications[index];
        return _buildNotificationCard(notification, notificationProvider);
      },
    );
  }

  Widget _buildSystemNotificationsTab(NotificationProvider notificationProvider) {
    final systemNotifications = notificationProvider.getNotificationsByCategory('system');

    if (systemNotifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.info_outline,
        title: 'No System Updates',
        message: 'App updates and system announcements will appear here.',
      );
    }

    return ListView.builder(
      padding: AppSpacing.paddingMD,
      itemCount: systemNotifications.length,
      itemBuilder: (context, index) {
        final notification = systemNotifications[index];
        return _buildNotificationCard(notification, notificationProvider);
      },
    );
  }

  Widget _buildNotificationCard(AppNotification notification, NotificationProvider notificationProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: notification.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusLG,
          gradient: notification.isRead 
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getNotificationColor(notification.type).withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
        ),
        child: ListTile(
          contentPadding: AppSpacing.paddingMD,
          leading: _buildNotificationIcon(notification),
          title: Text(
            notification.title,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.body,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: context.colors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatNotificationTime(notification.createdAt),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type).withOpacity(0.2),
                      borderRadius: AppRadius.radiusSM,
                    ),
                    child: Text(
                      _getNotificationTypeText(notification.type),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: _getNotificationColor(notification.type),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: context.colors.textSecondary,
              size: 20,
            ),
            onSelected: (value) => _handleNotificationAction(value, notification, notificationProvider),
            itemBuilder: (context) => [
              if (!notification.isRead)
                const PopupMenuItem(
                  value: 'mark_read',
                  child: ListTile(
                    leading: Icon(Icons.mark_email_read, size: 16),
                    title: Text('Mark as Read'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, size: 16),
                  title: Text('Delete'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
          onTap: () => _handleNotificationTap(notification, notificationProvider),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(AppNotification notification) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getNotificationColor(notification.type).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              _getNotificationIcon(notification.type),
              color: _getNotificationColor(notification.type),
              size: 24,
            ),
          ),
          if (!notification.isRead)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: context.colors.marketOrange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
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
            'Loading notifications...',
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

  // Helper methods
  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'orders':
      case 'order_update':
        return context.colors.freshGreen;
      case 'promotions':
      case 'promotion':
        return context.colors.marketOrange;
      case 'chat':
      case 'message':
        return context.colors.ecoBlue;
      case 'system':
      case 'app_update':
        return Colors.purple;
      case 'delivery':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      default:
        return context.colors.textSecondary;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'orders':
      case 'order_update':
        return Icons.shopping_bag;
      case 'promotions':
      case 'promotion':
        return Icons.local_offer;
      case 'chat':
      case 'message':
        return Icons.chat_bubble;
      case 'system':
      case 'app_update':
        return Icons.system_update;
      case 'delivery':
        return Icons.delivery_dining;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  String _getNotificationTypeText(String type) {
    switch (type.toLowerCase()) {
      case 'orders':
      case 'order_update':
        return 'ORDER';
      case 'promotions':
      case 'promotion':
        return 'OFFER';
      case 'chat':
      case 'message':
        return 'CHAT';
      case 'system':
      case 'app_update':
        return 'SYSTEM';
      case 'delivery':
        return 'DELIVERY';
      case 'payment':
        return 'PAYMENT';
      default:
        return 'INFO';
    }
  }

  String _formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _handleNotificationTap(AppNotification notification, NotificationProvider notificationProvider) {
    // Mark as read if not already read
    if (!notification.isRead) {
      notificationProvider.markAsRead(notification.id);
    }

    // Handle navigation based on notification type and data
    if (notification.data != null) {
      final data = notification.data!;
      
      switch (notification.type.toLowerCase()) {
        case 'orders':
        case 'order_update':
          if (data['orderId'] != null) {
            NavigationService.toOrderDetails(orderId: data['orderId']);
          }
          break;
        case 'chat':
        case 'message':
          if (data['orderId'] != null) {
            NavigationService.toOrderChat();
          }
          break;
        case 'promotions':
        case 'promotion':
          if (data['productId'] != null) {
            // Navigate to browse since we can't create a Product object from notification data
            NavigationService.toCustomerBrowse();
          } else {
            NavigationService.toCustomerBrowse();
          }
          break;
        case 'system':
        case 'app_update':
          NavigationService.toSettings();
          break;
        default:
          // Show notification details
          _showNotificationDetails(notification);
          break;
      }
    } else {
      _showNotificationDetails(notification);
    }
  }

  void _showNotificationDetails(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.body),
        actions: [
          TextButton(
            onPressed: () => NavigationService.goBack(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationAction(String action, AppNotification notification, NotificationProvider notificationProvider) {
    switch (action) {
      case 'mark_read':
        notificationProvider.markAsRead(notification.id);
        break;
      case 'delete':
        _deleteNotification(notification, notificationProvider);
        break;
    }
  }

  void _deleteNotification(AppNotification notification, NotificationProvider notificationProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              notificationProvider.deleteNotification(notification.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _markAllAsRead(NotificationProvider notificationProvider) {
    notificationProvider.markAllAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All notifications marked as read'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }

  void _handleMenuAction(String action, NotificationProvider notificationProvider) {
    switch (action) {
      case 'refresh':
        notificationProvider.loadNotifications(refresh: true);
        break;
      case 'clear_all':
        _showClearAllDialog(notificationProvider);
        break;
      case 'settings':
        NavigationService.toSettings();
        break;
    }
  }

  void _showClearAllDialog(NotificationProvider notificationProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              notificationProvider.clearAllNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All notifications cleared'),
                  backgroundColor: context.colors.freshGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
} 