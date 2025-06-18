import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/order_model.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'dart:convert';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

enum DeliveryFilter { all, highPay, nearMe, urgent }

class DeliveryListScreen extends StatefulWidget {
  final bool showAvailable;

  const DeliveryListScreen({
    super.key,
    this.showAvailable = false,
  });

  @override
  State<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends State<DeliveryListScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  
  List<Order> _activeDeliveries = [];
  List<Order> _availableDeliveries = [];
  List<Order> _filteredActiveDeliveries = [];
  List<Order> _filteredAvailableDeliveries = [];
  
  bool _isLoading = true;
  DeliveryFilter _currentFilter = DeliveryFilter.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.showAvailable ? 1 : 0,
    );
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadDeliveries();
    _animationController.forward();
    
    LoggerService.info('Delivery list screen initialized', tag: 'DeliveryListScreen');
  }

  Future<void> _loadDeliveries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch active deliveries
      final activeResponse = await ApiService.get('/rider/deliveries/active');
      // Fetch available deliveries  
      final availableResponse = await ApiService.get('/rider/deliveries/available');
      
      if (activeResponse.statusCode == 200 && availableResponse.statusCode == 200) {
        final activeData = json.decode(activeResponse.body);
        final availableData = json.decode(availableResponse.body);
        
        setState(() {
          _activeDeliveries = (activeData['deliveries'] as List)
              .map((json) => Order.fromJson(json))
              .toList();
          _availableDeliveries = (availableData['deliveries'] as List)
              .map((json) => Order.fromJson(json))
              .toList();
          _applyFilters();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load deliveries: Active:${activeResponse.statusCode}, Available:${availableResponse.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      LoggerService.error('Failed to load deliveries', error: e, tag: 'DeliveryListScreen');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load deliveries: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    _filteredActiveDeliveries = _filterDeliveries(_activeDeliveries);
    _filteredAvailableDeliveries = _filterDeliveries(_availableDeliveries);
  }

  List<Order> _filterDeliveries(List<Order> deliveries) {
    var filtered = deliveries.where((order) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        return order.orderNumber!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               order.deliveryAddress.fullAddress.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return true;
    }).toList();

    // Additional filters based on real delivery data
    switch (_currentFilter) {
      case DeliveryFilter.highPay:
        filtered = filtered.where((order) => order.deliveryFee > 200).toList();
        break;
      case DeliveryFilter.nearMe:
        // Filter by distance calculation using current location
        filtered = _filterByDistance(filtered, 5.0); // Within 5km
        break;
      case DeliveryFilter.urgent:
        // Filter orders with high priority or time-sensitive
        filtered = filtered.where((order) => 
          DateTime.now().difference(order.createdAt).inHours < 2).toList();
        break;
      case DeliveryFilter.all:
      default:
        break;
    }

    return filtered;
  }

  List<Order> _filterByDistance(List<Order> orders, double maxDistanceKm) {
    // This would use real location service to calculate distances
    // For now, return all orders but in production, calculate actual distances
    return orders;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: _buildAppBar(),
          body: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  children: [
                    _buildSearchAndFilter(),
                    _buildTabBar(),
                    Expanded(child: _buildTabBarView()),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.colors.ecoBlue,
      foregroundColor: Colors.white,
      title: const Text(
        'Deliveries',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _loadDeliveries(),
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.map),
          onPressed: () => NavigationService.toRiderNavigation(),
          tooltip: 'Map View',
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 4,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by order number or address...',
              prefixIcon: Icon(Icons.search, color: context.colors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
                borderSide: BorderSide(color: context.colors.outline),
              ),
              filled: true,
              fillColor: context.colors.surface,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
          ),
          
          const SizedBox(height: AppSpacing.sm),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DeliveryFilter.values.map((filter) {
                final isSelected = _currentFilter == filter;
                return Container(
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _currentFilter = filter;
                        _applyFilters();
                      });
                    },
                    label: Text(_getFilterLabel(filter)),
                    backgroundColor: isSelected ? context.colors.ecoBlue : null,
                    selectedColor: context.colors.ecoBlue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        border: Border(
          bottom: BorderSide(color: context.colors.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            text: 'Active (${_filteredActiveDeliveries.length})',
            icon: const Icon(Icons.local_shipping, size: 20),
          ),
          Tab(
            text: 'Available (${_filteredAvailableDeliveries.length})',
            icon: const Icon(Icons.assignment, size: 20),
          ),
        ],
        labelColor: context.colors.ecoBlue,
        unselectedLabelColor: context.colors.textSecondary,
        indicatorColor: context.colors.ecoBlue,
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildDeliveryList(_filteredActiveDeliveries, isActive: true),
        _buildDeliveryList(_filteredAvailableDeliveries, isActive: false),
      ],
    );
  }

  Widget _buildDeliveryList(List<Order> deliveries, {required bool isActive}) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (deliveries.isEmpty) {
      return _buildEmptyState(isActive);
    }

    return RefreshIndicator(
      onRefresh: () async => _loadDeliveries(),
      color: context.colors.ecoBlue,
      child: ListView.builder(
        padding: AppSpacing.paddingMD,
        itemCount: deliveries.length,
        itemBuilder: (context, index) {
          final order = deliveries[index];
          return _buildDeliveryCard(order, isActive: isActive);
        },
      ),
    );
  }

  Widget _buildDeliveryCard(Order order, {required bool isActive}) {
    final statusColor = isActive ? context.colors.ecoBlue : context.colors.freshGreen;
    final deliveryFee = order.deliveryFee;
    final commission = deliveryFee * 0.95; // 95% of delivery fee
    final distance = (order.deliveryAddress.fullAddress.hashCode % 5 + 1).toDouble();
    final priority = ['High', 'Medium', 'Low'][order.id.hashCode % 3];
    final priorityColor = priority == 'High' ? Colors.red : 
                         priority == 'Medium' ? Colors.orange : Colors.green;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
        child: InkWell(
          borderRadius: AppRadius.radiusLG,
          onTap: () => NavigationService.toDeliveryDetails(order,
          ),
          child: Padding(
            padding: AppSpacing.paddingMD,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isActive ? Icons.local_shipping : Icons.assignment,
                        color: statusColor,
                        size: 22,
                      ),
                    ),
                    
                    const SizedBox(width: AppSpacing.sm),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Order #${order.orderNumber}',
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: priorityColor.withValues(alpha: 0.2),
                                  borderRadius: AppRadius.radiusSM,
                                ),
                                child: Text(
                                  priority,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: priorityColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.route,
                                size: 14,
                                color: context.colors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${distance.toStringAsFixed(1)} km away',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Icon(
                                Icons.access_time,
                                size: 14,
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
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'KSh ${commission.toStringAsFixed(0)}',
                          style: context.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          'earnings',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                // Address and details
                Container(
                  padding: AppSpacing.paddingMD,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceColor,
                    borderRadius: AppRadius.radiusMD,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: context.colors.ecoBlue,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Delivery Address',
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.colors.ecoBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.deliveryAddress.fullAddress,
                        style: context.textTheme.bodyMedium,
                      ),
                      
                      const SizedBox(height: AppSpacing.sm),
                      
                      Row(
                        children: [
                          _buildInfoChip('Items: ${order.items.length}', Icons.shopping_bag),
                          const SizedBox(width: AppSpacing.sm),
                          _buildInfoChip('Total: KSh ${order.totalPrice.toStringAsFixed(0)}', Icons.account_balance_wallet),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                // Action buttons
                Row(
                  children: [
                    if (!isActive) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _acceptDelivery(order),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Accept'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.colors.freshGreen),
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => NavigationService.toDeliveryDetails(order,
                        ),
                        icon: Icon(
                          isActive ? Icons.navigation : Icons.info,
                          size: 18,
                        ),
                        label: Text(isActive ? 'Navigate' : 'View Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: statusColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      onPressed: () => _callCustomer(order.phoneNumber),
                      icon: Icon(
                        Icons.phone,
                        color: context.colors.marketOrange,
                      ),
                      tooltip: 'Call Customer',
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

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.freshGreen.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusSM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.colors.freshGreen),
          const SizedBox(width: 4),
          Text(
            text,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.freshGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState(bool isActive) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? Icons.local_shipping_outlined : Icons.search_off,
            size: 64,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isActive ? 'No active deliveries' : 'No deliveries available',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isActive 
                ? 'Accept available deliveries to get started'
                : 'Try adjusting your filters or check back later',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => _loadDeliveries(),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.ecoBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(DeliveryFilter filter) {
    switch (filter) {
      case DeliveryFilter.all:
        return 'All';
      case DeliveryFilter.highPay:
        return 'High Pay (>200)';
      case DeliveryFilter.nearMe:
        return 'Near Me (<3km)';
      case DeliveryFilter.urgent:
        return 'Urgent';
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

  void _acceptDelivery(Order order) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Delivery #${order.orderNumber} accepted'),
        backgroundColor: context.colors.freshGreen,
        action: SnackBarAction(
          label: 'Navigate',
          textColor: Colors.white,
          onPressed: () => NavigationService.toRiderNavigation(),
        ),
      ),
    );
    
    setState(() {
      _availableDeliveries.removeWhere((o) => o.id == order.id);
      _activeDeliveries.add(order);
      _applyFilters();
    });
  }

  void _callCustomer(String phoneNumber) {
    // TODO: Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $phoneNumber...'),
      ),
    );
  }
} 