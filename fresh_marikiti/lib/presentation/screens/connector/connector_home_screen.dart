import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/providers/order_provider.dart';
import 'package:fresh_marikiti/core/providers/notification_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/connector_service.dart';
import 'package:fresh_marikiti/core/models/connector_models.dart';
import 'package:fresh_marikiti/core/models/order_model.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class ConnectorHomeScreen extends StatefulWidget {
  const ConnectorHomeScreen({super.key});

  @override
  State<ConnectorHomeScreen> createState() => _ConnectorHomeScreenState();
}

class _ConnectorHomeScreenState extends State<ConnectorHomeScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;
  
  ConnectorMetrics? _metrics;
  List<Order> _availableOrders = [];
  List<Order> _activeOrders = [];
  bool _isLoading = true;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadDashboardData();
    _startAutoRefresh();
    _animationController.forward();
    LoggerService.info('Connector home screen initialized', tag: 'ConnectorHomeScreen');
  }

  void _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        ConnectorService.getDashboardMetrics(),
        ConnectorService.getAvailableOrders(),
        _getActiveOrders(),
      ]);

      if (mounted) {
        setState(() {
          _metrics = results[0] != null ? ConnectorMetrics.fromJson(results[0] as Map<String, dynamic>) : null;
          _availableOrders = _parseOrdersFromData(results[1] as List<Map<String, dynamic>>);
          _activeOrders = results[2] as List<Order>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      LoggerService.error('Failed to load connector dashboard', error: e, tag: 'ConnectorHomeScreen');
    }
  }

  Future<List<Order>> _getActiveOrders() async {
    // Mock active orders - would come from actual service
    return [
      Order(
        id: '1',
        orderNumber: 'ORD001',
        customerId: 'cust1',
        vendorId: 'vendor1',
        products: [],
        subtotal: 1500.0,
        deliveryFee: 200.0,
        totalPrice: 1700.0,
        status: OrderStatus.processing,
        paymentStatus: PaymentStatus.paid,
        paymentMethod: PaymentMethod.mpesa,
        deliveryAddress: Address(fullAddress: 'Nairobi CBD'),
        phoneNumber: '+254712345678',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  List<Order> _parseOrdersFromData(List<Map<String, dynamic>> data) {
    return data.map((orderData) {
      return Order(
        id: orderData['id'] ?? '',
        orderNumber: orderData['orderNumber'] ?? '',
        customerId: orderData['customerId'] ?? '',
        vendorId: orderData['vendorId'] ?? '',
        products: [],
        subtotal: (orderData['subtotal'] ?? 0).toDouble(),
        deliveryFee: (orderData['deliveryFee'] ?? 0).toDouble(),
        totalPrice: (orderData['total'] ?? 0).toDouble(),
        status: OrderStatus.pending,
        paymentStatus: PaymentStatus.paid,
        paymentMethod: PaymentMethod.mpesa,
        deliveryAddress: Address(fullAddress: orderData['deliveryAddress'] ?? ''),
        phoneNumber: orderData['phoneNumber'] ?? '',
        createdAt: DateTime.parse(orderData['createdAt'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(orderData['updatedAt'] ?? DateTime.now().toIso8601String()),
      );
    }).toList();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isOnline && mounted) {
        _loadDashboardData();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shimmerController.dispose();
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, OrderProvider, NotificationProvider>(
      builder: (context, authProvider, orderProvider, notificationProvider, child) {
        final user = authProvider.user;
        
        return Scaffold(
          backgroundColor: context.colors.surface,
          body: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: RefreshIndicator(
                    onRefresh: () => _refreshData(),
                    color: context.colors.freshGreen,
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        _buildAppBar(user, notificationProvider),
                        _buildStatusBar(),
                        _buildMetricsCards(),
                        _buildQuickActions(),
                        _buildActiveOrdersSection(),
                        _buildAvailableOrdersSection(),
                        _buildWasteCollectionSummary(),
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          floatingActionButton: _buildFloatingActionButton(),
        );
      },
    );
  }

  Widget _buildAppBar(user, NotificationProvider notificationProvider) {
    return SliverAppBar(
      backgroundColor: context.colors.freshGreen,
      foregroundColor: Colors.white,
      expandedHeight: 120,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.name?.split(' ').first ?? 'Connector'}!',
              style: context.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Ready to coordinate orders?',
              style: context.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications),
              if (notificationProvider.unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '${notificationProvider.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () => NavigationService.toNotifications(),
        ),
        IconButton(
          icon: Icon(_isOnline ? Icons.wifi : Icons.wifi_off),
          onPressed: () => _toggleOnlineStatus(),
        ),
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () => NavigationService.toConnectorProfile(),
        ),
      ],
    );
  }

  Widget _buildStatusBar() {
    return SliverToBoxAdapter(
      child: Container(
        margin: AppSpacing.paddingMD,
        padding: AppSpacing.paddingMD,
        decoration: BoxDecoration(
          color: _isOnline ? context.colors.freshGreen : Colors.grey,
          borderRadius: AppRadius.radiusLG,
        ),
        child: Row(
          children: [
            Icon(
              _isOnline ? Icons.check_circle : Icons.pause_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _isOnline ? 'Online - Available for assignments' : 'Offline - Not accepting new orders',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _toggleOnlineStatus(),
              child: Text(
                _isOnline ? 'Go Offline' : 'Go Online',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCards() {
    if (_isLoading) {
      return _buildMetricsLoading();
    }

    if (_metrics == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        padding: AppSpacing.paddingMD,
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.3,
          children: [
            _buildMetricCard(
              'Today\'s Orders',
              '${_metrics!.todaysOrders}',
              Icons.assignment,
              context.colors.freshGreen,
              subtitle: 'Total: ${_metrics!.totalOrders}',
            ),
            _buildMetricCard(
              'Active Orders',
              '${_activeOrders.length}',
              Icons.pending_actions,
              context.colors.ecoBlue,
              subtitle: 'In progress',
            ),
            _buildMetricCard(
              'Waste Collected',
              '${_metrics!.todaysWasteCollected.toStringAsFixed(1)}kg',
              Icons.eco,
              context.colors.marketOrange,
              subtitle: 'Total: ${_metrics!.totalWasteCollected.toStringAsFixed(1)}kg',
            ),
            _buildMetricCard(
              'Eco Points Issued',
              '${_metrics!.todaysEcoPointsIssued}',
              Icons.stars,
              Colors.amber,
              subtitle: 'Total: ${_metrics!.totalEcoPointsIssued}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: animValue,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
            child: Container(
              padding: AppSpacing.paddingMD,
              decoration: BoxDecoration(
                borderRadius: AppRadius.radiusLG,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color,
                    color.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 24),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: AppRadius.radiusSM,
                        ),
                        child: Icon(
                          Icons.trending_up,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: context.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Container(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.eco,
                    title: 'Log Waste',
                    subtitle: 'Record collection',
                    color: context.colors.marketOrange,
                    onTap: () => NavigationService.toWasteLogging(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.analytics,
                    title: 'Analytics',
                    subtitle: 'View performance',
                    color: context.colors.ecoBlue,
                    onTap: () => NavigationService.toConnectorAnalytics(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.local_shipping,
                    title: 'Riders',
                    subtitle: 'Manage delivery',
                    color: Colors.purple,
                    onTap: () => _showRiderManagement(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.paddingMD,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.radiusLG,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadius.radiusMD,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrdersSection() {
    return SliverToBoxAdapter(
      child: Container(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Orders',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_activeOrders.isNotEmpty)
                  TextButton(
                    onPressed: () => NavigationService.toConnectorActiveOrders(),
                    child: Text(
                      'View All (${_activeOrders.length})',
                      style: TextStyle(
                        color: context.colors.freshGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_isLoading)
              _buildOrdersLoading()
            else if (_activeOrders.isEmpty)
              _buildEmptyActiveOrders()
            else
              Column(
                children: _activeOrders.take(3).map((order) => 
                  _buildOrderCard(order, isActive: true)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableOrdersSection() {
    return SliverToBoxAdapter(
      child: Container(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Orders',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_availableOrders.isNotEmpty)
                  TextButton(
                    onPressed: () => NavigationService.toConnectorAvailableOrders(),
                    child: Text(
                      'View All (${_availableOrders.length})',
                      style: TextStyle(
                        color: context.colors.ecoBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_isLoading)
              _buildOrdersLoading()
            else if (_availableOrders.isEmpty)
              _buildEmptyAvailableOrders()
            else
              Column(
                children: _availableOrders.take(3).map((order) => 
                  _buildOrderCard(order, isActive: false)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order, {required bool isActive}) {
    final statusColor = isActive ? context.colors.freshGreen : context.colors.ecoBlue;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
        child: InkWell(
          borderRadius: AppRadius.radiusLG,
          onTap: () => NavigationService.toAssignmentDetails(order,
          ),
          child: Padding(
            padding: AppSpacing.paddingMD,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isActive ? Icons.pending_actions : Icons.assignment,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    
                    const SizedBox(width: AppSpacing.sm),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.orderNumber}',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Customer: ${_getCustomerName(order)}',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'KSh ${order.totalPrice.toStringAsFixed(2)}',
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: AppRadius.radiusSM,
                          ),
                          child: Text(
                            order.statusDisplay,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: context.colors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.deliveryAddress.fullAddress,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: context.colors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(order.createdAt),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                
                if (!isActive) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _acceptOrder(order),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.colors.freshGreen),
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => NavigationService.toAssignmentDetails(order,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.freshGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                          ),
                          child: const Text('View Details'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWasteCollectionSummary() {
    return SliverToBoxAdapter(
      child: Container(
        margin: AppSpacing.paddingMD,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
          child: Container(
            padding: AppSpacing.paddingLG,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.colors.marketOrange,
                  context.colors.marketOrange.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: AppRadius.radiusLG,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.eco, color: Colors.white, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Sustainability Impact',
                      style: context.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => NavigationService.toWasteLogging(),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                if (_metrics != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildSustainabilityMetric(
                          'Waste Collected',
                          '${_metrics!.totalWasteCollected.toStringAsFixed(1)} kg',
                          Icons.delete_outline,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: _buildSustainabilityMetric(
                          'Eco Points',
                          '${_metrics!.totalEcoPointsIssued}',
                          Icons.stars,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: _buildSustainabilityMetric(
                          'CO2 Reduced',
                          '${(_metrics!.totalWasteCollected * 0.5).toStringAsFixed(1)} kg',
                          Icons.eco,
                        ),
                      ),
                    ],
                  ),
                ] else
                  _buildSustainabilityLoading(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSustainabilityMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: context.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickActions(),
      backgroundColor: context.colors.freshGreen,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'Quick Action',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Loading states
  Widget _buildMetricsLoading() {
    return SliverToBoxAdapter(
      child: Container(
        padding: AppSpacing.paddingMD,
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.3,
          children: List.generate(4, (index) => _buildShimmerCard()),
        ),
      ),
    );
  }

  Widget _buildOrdersLoading() {
    return Column(
      children: List.generate(2, (index) => _buildShimmerCard()),
    );
  }

  Widget _buildSustainabilityLoading() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusMD,
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusLG,
            gradient: LinearGradient(
              begin: Alignment(-1.0, 0.0),
              end: Alignment(1.0, 0.0),
              colors: [
                context.colors.surfaceColor,
                Colors.grey[300]!,
                context.colors.surfaceColor,
              ],
              stops: [
                _shimmerController.value - 0.3,
                _shimmerController.value,
                _shimmerController.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }

  // Empty states
  Widget _buildEmptyActiveOrders() {
    return Container(
      padding: AppSpacing.paddingLG,
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: context.colors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 48,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No active orders',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Check available orders to get started',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAvailableOrders() {
    return Container(
      padding: AppSpacing.paddingLG,
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: context.colors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No available orders',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'New orders will appear here when available',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatTime(DateTime dateTime) {
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

  Future<void> _refreshData() async {
    _loadDashboardData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Dashboard refreshed'),
          backgroundColor: context.colors.freshGreen,
        ),
      );
    }
  }

  void _toggleOnlineStatus() {
    setState(() {
      _isOnline = !_isOnline;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isOnline 
            ? 'You are now online and available for assignments'
            : 'You are now offline and won\'t receive new assignments'),
        backgroundColor: _isOnline ? context.colors.freshGreen : Colors.grey,
      ),
    );
  }

  void _acceptOrder(Order order) async {
    final success = await ConnectorService.acceptOrder(order.id);
    
    if (success && mounted) {
      setState(() {
        _availableOrders.removeWhere((o) => o.id == order.id);
        _activeOrders.add(order);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #${order.orderNumber} accepted'),
          backgroundColor: context.colors.freshGreen,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () => NavigationService.toAssignmentDetails(order,
            ),
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to accept order'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Actions',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.eco,
                    label: 'Log Waste',
                    onTap: () {
                      Navigator.pop(context);
                      NavigationService.toWasteLogging();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.local_shipping,
                    label: 'Assign Rider',
                    onTap: () {
                      Navigator.pop(context);
                      _showRiderManagement();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.analytics,
                    label: 'Analytics',
                    onTap: () {
                      Navigator.pop(context);
                      NavigationService.toConnectorAnalytics();
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.chat,
                    label: 'Support Chat',
                    onTap: () {
                      Navigator.pop(context);
                      NavigationService.toChat();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRiderManagement() {
    NavigationService.toRiderHandoff;
  }

  String _getCustomerName(Order order) {
    // In real implementation, this would fetch customer name
    return 'Customer ${order.customerId.substring(0, 4)}';
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.freshGreen.withValues(alpha: 0.1),
          borderRadius: AppRadius.radiusLG,
          border: Border.all(color: context.colors.freshGreen.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: context.colors.freshGreen, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 