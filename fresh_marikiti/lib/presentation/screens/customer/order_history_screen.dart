import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/order_provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/order_model.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _filterAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _filterSlideAnimation;
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedFilter = 'all';
  bool _showFilterPanel = false;
  bool _isLoadingMore = false;
  
  final List<String> _statusFilters = [
    'all',
    'delivered',
    'cancelled',
    'pending',
    'confirmed',
    'processing',
    'ready',
    'outForDelivery',
  ];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _filterSlideAnimation = Tween<double>(
      begin: -300.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _setupScrollListener();
    _loadInitialData();
    _animationController.forward();
    LoggerService.info('Order history screen initialized', tag: 'OrderHistoryScreen');
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreOrders();
      }
    });
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.loadOrders(refresh: true);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _filterAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<OrderProvider, AuthProvider>(
      builder: (context, orderProvider, authProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: _buildAppBar(context, orderProvider),
          body: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Stack(
                  children: [
                    _buildOrderHistoryContent(orderProvider),
                    if (_showFilterPanel) _buildFilterPanel(orderProvider),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, OrderProvider orderProvider) {
    return AppBar(
      backgroundColor: context.colors.freshGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Order History',
        style: context.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _toggleFilterPanel(),
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearchDialog(),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _refreshOrders(orderProvider),
        ),
      ],
    );
  }

  Widget _buildOrderHistoryContent(OrderProvider orderProvider) {
    if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
      return _buildLoadingState();
    }
    
    if (orderProvider.error != null && orderProvider.orders.isEmpty) {
      return _buildErrorState(orderProvider);
    }
    
    if (orderProvider.orders.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: () => _refreshOrders(orderProvider),
      color: context.colors.freshGreen,
      child: Column(
        children: [
          // Order statistics
          _buildOrderStatistics(orderProvider),
          
          // Active filter indicator
          if (_selectedFilter != 'all') _buildActiveFilterBadge(),
          
          // Orders list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: AppSpacing.paddingMD,
              itemCount: _getFilteredOrders(orderProvider).length + 
                  (orderProvider.hasMoreOrders ? 1 : 0),
              itemBuilder: (context, index) {
                final filteredOrders = _getFilteredOrders(orderProvider);
                
                if (index >= filteredOrders.length) {
                  return _buildLoadingMoreIndicator();
                }
                
                final order = filteredOrders[index];
                return _buildOrderCard(order, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatistics(OrderProvider orderProvider) {
    final stats = orderProvider.getOrderStatistics();
    
    return Container(
      margin: AppSpacing.paddingMD,
      padding: AppSpacing.paddingLG,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.freshGreen,
            context.colors.freshGreen.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: AppRadius.radiusLG,
        boxShadow: [
          BoxShadow(
            color: context.colors.freshGreen.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total Orders',
              stats['totalOrders'].toString(),
              Icons.receipt_long,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'Completed',
              stats['completedOrders'].toString(),
              Icons.check_circle,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'Total Spent',
              'KSh ${stats['totalSpent'].toStringAsFixed(0)}',
              Icons.attach_money,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: context.textTheme.titleLarge?.copyWith(
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

  Widget _buildActiveFilterBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.marketOrange.withValues(alpha: 0.2),
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: context.colors.marketOrange),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_alt, 
               color: context.colors.marketOrange, 
               size: 16),
          const SizedBox(width: 4),
          Text(
            'Filtered by: ${_getFilterDisplayName(_selectedFilter)}',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.marketOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _clearFilter(),
            child: Icon(Icons.close, 
                 color: context.colors.marketOrange, 
                 size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.surfaceColor,
                borderRadius: AppRadius.radiusLG,
                boxShadow: [
                  BoxShadow(
                    color: context.colors.textSecondary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: AppRadius.radiusLG,
                  onTap: () => _navigateToOrderDetails(order),
                  child: Padding(
                    padding: AppSpacing.paddingLG,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8, 
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status).withValues(alpha: 0.2),
                                borderRadius: AppRadius.radiusSM,
                              ),
                              child: Text(
                                order.status.displayName,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: _getStatusColor(order.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatOrderDate(order.createdAt),
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.sm),
                        
                        // Order number and amount
                        Row(
                          children: [
                            Text(
                              'Order #${order.orderNumber ?? order.id.substring(0, 8)}',
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'KSh ${order.totalPrice.toStringAsFixed(2)}',
                              style: context.textTheme.titleMedium?.copyWith(
                                color: context.colors.freshGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.sm),
                        
                        // Items summary
                        Text(
                          '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.md),
                        
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _reorderItems(order),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Reorder'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: context.colors.freshGreen),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.radiusMD,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: AppSpacing.sm),
                            
                            if (order.status == OrderStatus.delivered && !order.isRated)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _rateOrder(order),
                                  icon: const Icon(Icons.star, size: 16),
                                  label: const Text('Rate'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.colors.marketOrange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.radiusMD,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _navigateToOrderDetails(order),
                                  icon: const Icon(Icons.visibility, size: 16),
                                  label: const Text('View'),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: context.colors.ecoBlue),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.radiusMD,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterPanel(OrderProvider orderProvider) {
    return AnimatedBuilder(
      animation: _filterSlideAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Backdrop
            GestureDetector(
              onTap: () => _toggleFilterPanel(),
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
            
            // Filter panel
            Positioned(
              top: 0,
              bottom: 0,
              right: _filterSlideAnimation.value,
              child: Container(
                width: 300,
                decoration: BoxDecoration(
                  color: context.colors.surfaceColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(-2, 0),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: AppSpacing.paddingLG,
                        decoration: BoxDecoration(
                          color: context.colors.freshGreen,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Filter Orders',
                              style: context.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => _toggleFilterPanel(),
                              icon: const Icon(Icons.close, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      
                      // Filter options
                      Expanded(
                        child: ListView(
                          padding: AppSpacing.paddingMD,
                          children: [
                            Text(
                              'Order Status',
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            const SizedBox(height: AppSpacing.md),
                            
                            ..._statusFilters.map((filter) => 
                              _buildFilterOption(filter, orderProvider)),
                            
                            const SizedBox(height: AppSpacing.xl),
                            
                            // Clear filters button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => _clearFilter(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: context.colors.marketOrange),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.radiusMD,
                                  ),
                                ),
                                child: const Text('Clear Filters'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterOption(String filter, OrderProvider orderProvider) {
    final isSelected = _selectedFilter == filter;
    final count = _getFilteredOrderCount(filter, orderProvider);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.radiusMD,
          onTap: () => _applyFilter(filter),
          child: Container(
            padding: AppSpacing.paddingMD,
            decoration: BoxDecoration(
              color: isSelected 
                  ? context.colors.freshGreen.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: AppRadius.radiusMD,
              border: Border.all(
                color: isSelected 
                    ? context.colors.freshGreen 
                    : context.colors.textSecondary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getFilterIcon(filter),
                  color: isSelected 
                      ? context.colors.freshGreen 
                      : context.colors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _getFilterDisplayName(filter),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: isSelected 
                          ? context.colors.freshGreen 
                          : context.colors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? context.colors.freshGreen 
                        : context.colors.textSecondary.withValues(alpha: 0.2),
                    borderRadius: AppRadius.radiusSM,
                  ),
                  child: Text(
                    count.toString(),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: isSelected ? Colors.white : context.colors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.lg),
          Text('Loading order history...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(OrderProvider orderProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Failed to load orders',
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            orderProvider.error ?? 'Something went wrong',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: () => _refreshOrders(orderProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.freshGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 120,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'No orders yet',
            style: context.textTheme.headlineMedium?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your order history will appear here',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: () {
              NavigationService.toCustomerHome();
            },
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Start Shopping'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.freshGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: AppSpacing.paddingLG,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  // Helper methods
  List<Order> _getFilteredOrders(OrderProvider orderProvider) {
    if (_selectedFilter == 'all') {
      return orderProvider.orders;
    }
    return orderProvider.getOrdersByStatus(_selectedFilter);
  }

  int _getFilteredOrderCount(String filter, OrderProvider orderProvider) {
    if (filter == 'all') {
      return orderProvider.orders.length;
    }
    return orderProvider.getOrdersByStatus(filter).length;
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return context.colors.marketOrange;
      case OrderStatus.confirmed:
      case OrderStatus.processing:
        return context.colors.ecoBlue;
      case OrderStatus.ready:
      case OrderStatus.pickedUp:
      case OrderStatus.outForDelivery:
        return context.colors.freshGreen;
      case OrderStatus.delivered:
        return context.colors.freshGreen;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return context.colors.textSecondary;
    }
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'all':
        return Icons.list_alt;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.verified;
      case 'processing':
        return Icons.restaurant;
      case 'ready':
        return Icons.shopping_bag;
      case 'outForDelivery':
        return Icons.local_shipping;
      default:
        return Icons.filter_list;
    }
  }

  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'all':
        return 'All Orders';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'processing':
        return 'Processing';
      case 'ready':
        return 'Ready';
      case 'outForDelivery':
        return 'Out for Delivery';
      default:
        return filter;
    }
  }

  String _formatOrderDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _toggleFilterPanel() {
    setState(() {
      _showFilterPanel = !_showFilterPanel;
    });
    
    if (_showFilterPanel) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _toggleFilterPanel();
  }

  void _clearFilter() {
    setState(() {
      _selectedFilter = 'all';
    });
    if (_showFilterPanel) {
      _toggleFilterPanel();
    }
  }

  Future<void> _refreshOrders(OrderProvider orderProvider) async {
    await orderProvider.refresh();
  }

  Future<void> _loadMoreOrders() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await orderProvider.loadMoreOrders();
    
    setState(() {
      _isLoadingMore = false;
    });
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Orders'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter order number or item name...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement search functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Searching for "${_searchController.text}"...'),
                  backgroundColor: context.colors.ecoBlue,
                ),
              );
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _navigateToOrderDetails(Order order) {
    NavigationService.toOrderTracking();
  }

  void _reorderItems(Order order) {
    // Navigate to cart and add items
    NavigationService.toCart();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Items added to cart for reorder'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }

  void _rateOrder(Order order) {
    NavigationService.toRating(
      targetId: order.id,
      ratingType: 'order',
      targetData: {
        'orderNumber': order.orderNumber,
        'vendorName': 'Vendor ${order.vendorId.substring(0, 6)}',
      },
    );
  }
} 