import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/providers/notification_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/models/order_model.dart';
import 'dart:convert';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class VendorMetrics {
  final double totalRevenue;
  final double todaysRevenue;
  final int totalOrders;
  final int todaysOrders;
  final int pendingOrders;
  final int completedOrders;
  final int totalProducts;
  final int lowStockProducts;
  final double averageOrderValue;
  final double conversionRate;
  final List<SalesData> recentSales;
  final Map<String, double> salesTrends;
  final DateTime lastUpdated;

  VendorMetrics({
    required this.totalRevenue,
    required this.todaysRevenue,
    required this.totalOrders,
    required this.todaysOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.totalProducts,
    required this.lowStockProducts,
    required this.averageOrderValue,
    required this.conversionRate,
    required this.recentSales,
    required this.salesTrends,
    required this.lastUpdated,
  });

  factory VendorMetrics.fromJson(Map<String, dynamic> json) {
    return VendorMetrics(
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      todaysRevenue: (json['todays_revenue'] ?? 0).toDouble(),
      totalOrders: json['total_orders'] ?? 0,
      todaysOrders: json['todays_orders'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      totalProducts: json['total_products'] ?? 0,
      lowStockProducts: json['low_stock_products'] ?? 0,
      averageOrderValue: (json['average_order_value'] ?? 0).toDouble(),
      conversionRate: (json['conversion_rate'] ?? 0).toDouble(),
      recentSales: (json['recent_sales'] as List? ?? [])
          .map((sale) => SalesData.fromJson(sale))
          .toList(),
      salesTrends: Map<String, double>.from(json['sales_trends'] ?? {}),
      lastUpdated: DateTime.parse(json['last_updated'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class SalesData {
  final String orderId;
  final String customerName;
  final double amount;
  final DateTime timestamp;
  final String status;

  SalesData({
    required this.orderId,
    required this.customerName,
    required this.amount,
    required this.timestamp,
    required this.status,
  });

  factory SalesData.fromJson(Map<String, dynamic> json) {
    return SalesData(
      orderId: json['order_id'] ?? '',
      customerName: json['customer_name'] ?? 'Unknown',
      amount: (json['amount'] ?? 0).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      status: json['status'] ?? 'pending',
    );
  }
}

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;
  
  VendorMetrics? _metrics;
  List<Order> _recentOrders = [];
  bool _isLoading = true;
  bool _isStoreOpen = true;
  String? _error;

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
    _startPeriodicRefresh();
    _animationController.forward();
    
    LoggerService.info('Vendor home screen initialized', tag: 'VendorHomeScreen');
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch vendor dashboard metrics
      final metricsResponse = await ApiService.get('/vendor/dashboard');
      // Fetch recent orders
      final ordersResponse = await ApiService.get('/vendor/orders/recent?limit=5');
      
      if (metricsResponse.statusCode == 200 && ordersResponse.statusCode == 200) {
        final metricsData = json.decode(metricsResponse.body);
        final ordersData = json.decode(ordersResponse.body);
        
        if (mounted) {
          setState(() {
            _metrics = VendorMetrics.fromJson(metricsData['metrics']);
            _recentOrders = (ordersData['orders'] as List)
                .map((json) => Order.fromJson(json))
                .toList();
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load dashboard data');
      }
    } catch (e) {
      LoggerService.error('Failed to load vendor dashboard', error: e, tag: 'VendorHomeScreen');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted && !_isLoading) {
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
    return Consumer2<AuthProvider, NotificationProvider>(
      builder: (context, authProvider, notificationProvider, child) {
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
                  child: _error != null
                      ? _buildErrorState()
                      : RefreshIndicator(
                          onRefresh: _loadDashboardData,
                          color: context.colors.freshGreen,
                          child: CustomScrollView(
                            controller: _scrollController,
                            slivers: [
                              _buildAppBar(user, notificationProvider),
                              _buildStoreStatusCard(),
                              _buildRevenueCard(),
                              _buildQuickStats(),
                              _buildRecentOrders(),
                              _buildQuickActions(),
                              const SliverToBoxAdapter(child: SizedBox(height: 100)),
                            ],
                          ),
                        ),
                ),
              );
            },
          ),
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
              'Hello, ${user?.name?.split(' ').first ?? 'Vendor'}!',
              style: context.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Manage your business',
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
          icon: const Icon(Icons.analytics),
          onPressed: () => NavigationService.toVendorAnalytics(),
          tooltip: 'Analytics',
        ),
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () => NavigationService.toVendorProfile(),
        ),
      ],
    );
  }

  Widget _buildStoreStatusCard() {
    return SliverToBoxAdapter(
      child: Container(
        margin: AppSpacing.paddingMD,
        padding: AppSpacing.paddingLG,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _isStoreOpen ? context.colors.freshGreen : Colors.grey,
              (_isStoreOpen ? context.colors.freshGreen : Colors.grey).withValues(alpha: 0.8),
            ],
          ),
          borderRadius: AppRadius.radiusLG,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isStoreOpen ? Icons.store : Icons.store_mall_directory_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            
            const SizedBox(width: AppSpacing.md),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isStoreOpen ? 'Store Open - Accepting Orders' : 'Store Closed - Not accepting orders',
                    style: context.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStoreHours(),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            Switch(
              value: _isStoreOpen,
              onChanged: (value) => _toggleStoreStatus(),
              activeColor: Colors.white,
              activeTrackColor: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard() {
    return SliverToBoxAdapter(
      child: Container(
        margin: AppSpacing.paddingMD,
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
          children: [
            Row(
              children: [
                Icon(
                  Icons.monetization_on,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Today\'s Revenue',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => NavigationService.toVendorAnalytics(),
                  child: const Text(
                    'View Analytics',
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
                  _buildRevenueMetric(
                    'Today',
                    'KSh ${_metrics!.todaysRevenue.toStringAsFixed(0)}',
                    Icons.today,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  _buildRevenueMetric(
                    'Total',
                    'KSh ${_metrics!.totalRevenue.toStringAsFixed(0)}',
                    Icons.account_balance,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  _buildRevenueMetric(
                    'Avg Order',
                    'KSh ${_metrics!.averageOrderValue.toStringAsFixed(0)}',
                    Icons.shopping_cart,
                  ),
                ],
              ),
            ] else
              _buildRevenueLoading(),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueMetric(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: context.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_isLoading || _metrics == null) {
      return _buildStatsLoading();
    }

    return SliverToBoxAdapter(
      child: Container(
        padding: AppSpacing.paddingMD,
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.0,
          children: [
            _buildStatCard(
              'Orders',
              '${_metrics!.todaysOrders}',
              Icons.shopping_bag,
              context.colors.ecoBlue,
            ),
            _buildStatCard(
              'Pending',
              '${_metrics!.pendingOrders}',
              Icons.pending,
              context.colors.marketOrange,
            ),
            _buildStatCard(
              'Products',
              '${_metrics!.totalProducts}',
              Icons.inventory,
              context.colors.freshGreen,
            ),
            _buildStatCard(
              'Low Stock',
              '${_metrics!.lowStockProducts}',
              Icons.warning,
              _metrics!.lowStockProducts > 0 ? Colors.red : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
      child: Container(
        padding: AppSpacing.paddingSM,
        decoration: BoxDecoration(
          borderRadius: AppRadius.radiusMD,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: context.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              title,
              style: context.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
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
                  'Recent Orders',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => NavigationService.toVendorOrders(),
                  child: Text(
                    'View All',
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
            else if (_recentOrders.isEmpty)
              _buildEmptyOrders()
            else
              Column(
                children: _recentOrders.map((order) => _buildOrderCard(order)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final statusColor = _getStatusColor(order.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
        child: InkWell(
          borderRadius: AppRadius.radiusLG,
          onTap: () => NavigationService.toVendorOrders(),
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
                        _getStatusIcon(order.status),
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
                            '${order.products.length} items',
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
                          'KSh ${order.subtotal.toStringAsFixed(0)}',
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
                      Icons.person,
                      size: 16,
                      color: context.colors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Connector Order',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
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
              ],
            ),
          ),
        ),
      ),
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
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.5,
              children: [
                _buildActionCard(
                  'Add Product',
                  Icons.add_box,
                  context.colors.freshGreen,
                  () => NavigationService.toAddProduct(),
                ),
                _buildActionCard(
                  'Manage Inventory',
                  Icons.inventory_2,
                  context.colors.ecoBlue,
                  () => NavigationService.toVendorInventory(),
                ),
                _buildActionCard(
                  'View Orders',
                  Icons.shopping_bag,
                  context.colors.marketOrange,
                  () => NavigationService.toVendorOrders(),
                ),
                _buildActionCard(
                  'Eco Report',
                  Icons.eco,
                  Colors.green,
                  () => Navigator.pushNamed(context, '/vendor/eco-report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: InkWell(
        borderRadius: AppRadius.radiusLG,
        onTap: onTap,
        child: Container(
          padding: AppSpacing.paddingMD,
          decoration: BoxDecoration(
            borderRadius: AppRadius.radiusLG,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Loading states
  Widget _buildStatsLoading() {
    return SliverToBoxAdapter(
      child: Container(
        padding: AppSpacing.paddingMD,
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.0,
          children: List.generate(4, (index) => _buildShimmerCard()),
        ),
      ),
    );
  }

  Widget _buildOrdersLoading() {
    return Column(
      children: List.generate(3, (index) => _buildShimmerCard()),
    );
  }

  Widget _buildRevenueLoading() {
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
              begin: const Alignment(-1.0, 0.0),
              end: const Alignment(1.0, 0.0),
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

  Widget _buildEmptyOrders() {
    return Container(
      padding: AppSpacing.paddingLG,
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: context.colors.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 48,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No recent orders',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Orders from connectors will appear here',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Failed to load dashboard',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          Text(
            _error ?? 'Unknown error occurred',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: _loadDashboardData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return context.colors.marketOrange;
      case OrderStatus.confirmed:
        return context.colors.ecoBlue;
      case OrderStatus.processing:
        return Colors.purple;
      case OrderStatus.ready:
        return context.colors.freshGreen;
      case OrderStatus.pickedUp:
      case OrderStatus.outForDelivery:
        return Colors.blue;
      case OrderStatus.delivered:
        return context.colors.freshGreen;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.processing:
        return Icons.kitchen;
      case OrderStatus.ready:
        return Icons.done_all;
      case OrderStatus.pickedUp:
        return Icons.local_shipping;
      case OrderStatus.outForDelivery:
        return Icons.delivery_dining;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

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

  String _getStoreHours() {
    // Would fetch from backend or user settings
    return 'Today: 8:00 AM - 8:00 PM';
  }

  Future<void> _toggleStoreStatus() async {
    try {
      final response = await ApiService.post('/vendor/store/toggle-status', {
        'is_open': !_isStoreOpen,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      if (response.statusCode == 200) {
        setState(() {
          _isStoreOpen = !_isStoreOpen;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isStoreOpen 
                ? 'Store is now open and accepting orders'
                : 'Store is now closed'),
            backgroundColor: _isStoreOpen ? context.colors.freshGreen : Colors.grey,
          ),
        );
      } else {
        throw Exception('Failed to update store status');
      }
    } catch (e) {
      LoggerService.error('Failed to toggle store status', error: e, tag: 'VendorHomeScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update store status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 