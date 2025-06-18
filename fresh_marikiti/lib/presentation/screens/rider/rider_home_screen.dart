import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/providers/order_provider.dart';
import 'package:fresh_marikiti/core/providers/notification_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';
import 'package:fresh_marikiti/core/models/order_model.dart';
import 'package:fresh_marikiti/core/models/user.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'dart:convert';

class RiderMetrics {
  final int totalDeliveries;
  final int todaysDeliveries;
  final int activeDeliveries;
  final double totalEarnings;
  final double todaysEarnings;
  final double averageRating;
  final int totalRatings;
  final double distanceCovered;
  final DateTime lastUpdated;

  RiderMetrics({
    required this.totalDeliveries,
    required this.todaysDeliveries,
    required this.activeDeliveries,
    required this.totalEarnings,
    required this.todaysEarnings,
    required this.averageRating,
    required this.totalRatings,
    required this.distanceCovered,
    required this.lastUpdated,
  });

  factory RiderMetrics.fromJson(Map<String, dynamic> json) {
    return RiderMetrics(
      totalDeliveries: json['total_deliveries'] ?? 0,
      todaysDeliveries: json['todays_deliveries'] ?? 0,
      activeDeliveries: json['active_deliveries'] ?? 0,
      totalEarnings: (json['total_earnings'] ?? 0).toDouble(),
      todaysEarnings: (json['todays_earnings'] ?? 0).toDouble(),
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalRatings: json['total_ratings'] ?? 0,
      distanceCovered: (json['distance_covered'] ?? 0).toDouble(),
      lastUpdated: DateTime.parse(json['last_updated'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;
  
  RiderMetrics? _metrics;
  List<Order> _availableDeliveries = [];
  List<Order> _activeDeliveries = [];
  bool _isLoading = true;
  bool _isOnline = true;
  String _currentLocation = 'Nairobi CBD';

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
    _startLocationUpdates();
    _animationController.forward();
    LoggerService.info('Rider home screen initialized', tag: 'RiderHomeScreen');
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch rider metrics/dashboard data
      final metricsResponse = await ApiService.get('/rider/dashboard');
      // Fetch available deliveries  
      final availableResponse = await ApiService.get('/rider/deliveries/available?limit=5');
      // Fetch active deliveries
      final activeResponse = await ApiService.get('/rider/deliveries/active');
      
      if (metricsResponse.statusCode == 200 && 
          availableResponse.statusCode == 200 && 
          activeResponse.statusCode == 200) {
        
        final metricsData = json.decode(metricsResponse.body);
        final availableData = json.decode(availableResponse.body);
        final activeData = json.decode(activeResponse.body);
        
        if (mounted) {
          setState(() {
            _metrics = RiderMetrics.fromJson(metricsData['metrics']);
            
            _availableDeliveries = (availableData['deliveries'] as List)
                .map((json) => Order.fromJson(json))
                .toList();
            _activeDeliveries = (activeData['deliveries'] as List)
                .map((json) => Order.fromJson(json))
                .toList();
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load dashboard data');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      LoggerService.error('Failed to load rider dashboard', error: e, tag: 'RiderHomeScreen');
    }
  }

  void _startLocationUpdates() {
    Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_isOnline && mounted) {
        // Update location with backend
        await _updateCurrentLocation();
      }
    });
  }

  Future<void> _updateCurrentLocation() async {
    try {
      final response = await ApiService.post('/rider/location', {
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currentLocation = data['formatted_address'] ?? 'Location updating...';
        });
      }
    } catch (e) {
      LoggerService.error('Failed to update location', error: e, tag: 'RiderHomeScreen');
    }
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
                    color: context.colors.ecoBlue,
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        _buildAppBar(user, notificationProvider),
                        _buildStatusCard(),
                        _buildEarningsCard(),
                        _buildQuickStats(),
                        _buildActiveDeliveries(),
                        _buildAvailableDeliveries(),
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
      backgroundColor: context.colors.ecoBlue,
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
              'Hello, ${user?.name?.split(' ').first ?? 'Rider'}!',
              style: context.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Ready for deliveries?',
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
          icon: const Icon(Icons.map),
          onPressed: () => NavigationService.toRiderNavigation(),
          tooltip: 'Map View',
        ),
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () => NavigationService.toRiderProfile(),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return SliverToBoxAdapter(
      child: Container(
        margin: AppSpacing.paddingMD,
        padding: AppSpacing.paddingLG,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _isOnline ? context.colors.freshGreen : Colors.grey,
              (_isOnline ? context.colors.freshGreen : Colors.grey).withValues(alpha: 0.8),
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
                _isOnline ? Icons.delivery_dining : Icons.pause_circle,
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
                    _isOnline ? 'Online - Available for deliveries' : 'Offline - Not accepting deliveries',
                    style: context.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _currentLocation,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Switch(
              value: _isOnline,
              onChanged: (value) => _toggleOnlineStatus(),
              activeColor: Colors.white,
              activeTrackColor: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard() {
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
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Today\'s Earnings',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => NavigationService.toRiderEarnings(),
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
                    child: _buildEarningsMetric(
                      'Today',
                      'KSh ${_metrics!.todaysEarnings.toStringAsFixed(0)}',
                      Icons.today,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: _buildEarningsMetric(
                      'This Month',
                      'KSh ${_metrics!.totalEarnings.toStringAsFixed(0)}',
                      Icons.calendar_month,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: _buildEarningsMetric(
                      'Rating',
                      '${_metrics!.averageRating.toStringAsFixed(1)} ⭐',
                      Icons.star,
                    ),
                  ),
                ],
              ),
            ] else
              _buildEarningsLoading(),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsMetric(String label, String value, IconData icon) {
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
              'Active',
              '${_metrics!.activeDeliveries}',
              Icons.local_shipping,
              context.colors.ecoBlue,
            ),
            _buildStatCard(
              'Today',
              '${_metrics!.todaysDeliveries}',
              Icons.check_circle,
              context.colors.freshGreen,
            ),
            _buildStatCard(
              'Total',
              '${_metrics!.totalDeliveries}',
              Icons.assignment_turned_in,
              context.colors.marketOrange,
            ),
            _buildStatCard(
              'Distance',
              '${_metrics!.distanceCovered.toStringAsFixed(0)}km',
              Icons.route,
              Colors.purple,
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

  Widget _buildActiveDeliveries() {
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
                  'Active Deliveries',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_activeDeliveries.isNotEmpty)
                  TextButton(
                    onPressed: () => NavigationService.toDeliveryList(),
                    child: Text(
                      'View All (${_activeDeliveries.length})',
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
              _buildDeliveriesLoading()
            else if (_activeDeliveries.isEmpty)
              _buildEmptyActiveDeliveries()
            else
              Column(
                children: _activeDeliveries.map((order) => 
                  _buildDeliveryCard(order, isActive: true)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableDeliveries() {
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
                  'Available Deliveries',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_availableDeliveries.isNotEmpty)
                  TextButton(
                    onPressed: () => NavigationService.toDeliveryList(showAvailable: true),
                    child: Text(
                      'View All (${_availableDeliveries.length})',
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
              _buildDeliveriesLoading()
            else if (_availableDeliveries.isEmpty)
              _buildEmptyAvailableDeliveries()
            else
              Column(
                children: _availableDeliveries.take(3).map((order) => 
                  _buildDeliveryCard(order, isActive: false)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(Order order, {required bool isActive}) {
    final statusColor = isActive ? context.colors.ecoBlue : context.colors.freshGreen;
    final deliveryFee = order.deliveryFee;
    final commission = deliveryFee * 0.95; // 95% of delivery fee (5% platform commission)
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
        child: InkWell(
          borderRadius: AppRadius.radiusLG,
          onTap: () => NavigationService.toDeliveryDetails(order),
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
                        isActive ? Icons.local_shipping : Icons.assignment,
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
                            'Delivery Fee: KSh ${order.deliveryFee.toStringAsFixed(0)}',
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
                          'KSh ${commission.toStringAsFixed(0)}',
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
                            isActive ? 'In Progress' : 'Available',
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
                        child: OutlinedButton.icon(
                          onPressed: () => _acceptDelivery(order),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Accept'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.colors.freshGreen),
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => NavigationService.toDeliveryDetails(order),
                          icon: const Icon(Icons.info, size: 16),
                          label: const Text('Details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.freshGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
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

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => NavigationService.toRiderNavigation(),
      backgroundColor: context.colors.ecoBlue,
      icon: const Icon(Icons.navigation, color: Colors.white),
      label: const Text(
        'Navigate',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
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

  Widget _buildDeliveriesLoading() {
    return Column(
      children: List.generate(2, (index) => _buildShimmerCard()),
    );
  }

  Widget _buildEarningsLoading() {
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

  // Empty states
  Widget _buildEmptyActiveDeliveries() {
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
            Icons.local_shipping_outlined,
            size: 48,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No active deliveries',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Accept available deliveries to get started',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAvailableDeliveries() {
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
            Icons.search_off,
            size: 48,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No deliveries available',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'New deliveries will appear here when available',
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
          backgroundColor: context.colors.ecoBlue,
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
            ? 'You are now online and available for deliveries'
            : 'You are now offline and won\'t receive new deliveries'),
        backgroundColor: _isOnline ? context.colors.freshGreen : Colors.grey,
      ),
    );
  }

  Future<void> _acceptDelivery(Order order) async {
    try {
      final response = await ApiService.post('/rider/deliveries/${order.id}/accept', {
        'accepted_at': DateTime.now().toIso8601String(),
      });
      
      if (response.statusCode == 200) {
        setState(() {
          _availableDeliveries.removeWhere((o) => o.id == order.id);
          _activeDeliveries.add(order);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delivery #${order.orderNumber} accepted'),
            backgroundColor: context.colors.freshGreen,
            action: SnackBarAction(
              label: 'Navigate',
              textColor: Colors.white,
              onPressed: () => NavigationService.toRiderNavigation(order: order),
            ),
          ),
        );
      } else {
        throw Exception('Failed to accept delivery: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to accept delivery', error: e, tag: 'RiderHomeScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept delivery: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 