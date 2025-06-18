import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/providers/order_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/connector_service.dart';
import 'package:fresh_marikiti/core/models/order_model.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class AssignmentDetailsScreen extends StatefulWidget {
  final Order order;

  const AssignmentDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  State<AssignmentDetailsScreen> createState() => _AssignmentDetailsScreenState();
}

class _AssignmentDetailsScreenState extends State<AssignmentDetailsScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  final ScrollController _scrollController = ScrollController();
  final Map<String, bool> _itemCheckList = {};
  
  double _shoppingProgress = 0.0;
  OrderStatus _currentStatus = OrderStatus.confirmed;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
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
    
    _initializeCheckList();
    _currentStatus = widget.order.status;
    _animationController.forward();
    
    LoggerService.info('Assignment details screen initialized for order ${widget.order.id}', 
                      tag: 'AssignmentDetailsScreen');
  }

  void _initializeCheckList() {
    for (int i = 0; i < widget.order.items.length; i++) {
      final itemId = 'item_$i';
      _itemCheckList[itemId] = false;
    }
    _calculateProgress();
  }

  void _calculateProgress() {
    if (_itemCheckList.isEmpty) {
      _shoppingProgress = 0.0;
      return;
    }
    
    final completedItems = _itemCheckList.values.where((checked) => checked).length;
    _shoppingProgress = completedItems / _itemCheckList.length;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, OrderProvider>(
      builder: (context, authProvider, orderProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          body: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      _buildAppBar(),
                      _buildOrderHeader(),
                      _buildProgressSection(),
                      _buildShoppingList(),
                      _buildCustomerDetails(),
                      _buildDeliveryDetails(),
                      _buildActionButtons(),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
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
              'Order #${widget.order.orderNumber}',
              style: context.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Assignment Details',
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
          icon: const Icon(Icons.chat),
          onPressed: () => _openOrderChat(),
          tooltip: 'Chat with Customer',
        ),
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () => _callCustomer(),
          tooltip: 'Call Customer',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view_map',
              child: ListTile(
                leading: Icon(Icons.map),
                title: Text('View on Map'),
              ),
            ),
            const PopupMenuItem(
              value: 'report_issue',
              child: ListTile(
                leading: Icon(Icons.report),
                title: Text('Report Issue'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderHeader() {
    return SliverToBoxAdapter(
      child: Container(
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.assignment,
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
                        'Order Value: KSh ${widget.order.totalPrice.toStringAsFixed(2)}',
                        style: context.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Items: ${widget.order.items.length} • Status: ${widget.order.statusDisplay}',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.radiusMD,
                  ),
                  child: Text(
                    _getStatusText(_currentStatus),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            Row(
              children: [
                _buildInfoCard(
                  'Order Time',
                  _formatDateTime(widget.order.createdAt),
                  Icons.access_time,
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildInfoCard(
                  'Delivery Fee',
                  'KSh ${widget.order.deliveryFee.toStringAsFixed(2)}',
                  Icons.local_shipping,
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildInfoCard(
                  'Commission',
                  'KSh ${(widget.order.totalPrice * 0.05).toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: AppSpacing.paddingMD,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: AppRadius.radiusMD,
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: context.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              title,
              style: context.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: AppSpacing.paddingMD,
        padding: AppSpacing.paddingLG,
        decoration: BoxDecoration(
          color: context.colors.surfaceColor,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(color: context.colors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: context.colors.freshGreen,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Shopping Progress',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(_shoppingProgress * 100).toInt()}%',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: context.colors.freshGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            ClipRRect(
              borderRadius: AppRadius.radiusSM,
              child: LinearProgressIndicator(
                value: _shoppingProgress,
                backgroundColor: context.colors.outline,
                valueColor: AlwaysStoppedAnimation<Color>(context.colors.freshGreen),
                minHeight: 8,
              ),
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            Text(
              '${_itemCheckList.values.where((checked) => checked).length} of ${widget.order.items.length} items collected',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShoppingList() {
    return SliverToBoxAdapter(
      child: Container(
        margin: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.list_alt,
                  color: context.colors.ecoBlue,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Shopping List',
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _toggleAllItems(),
                  icon: Icon(
                    _shoppingProgress == 1.0 ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 20,
                  ),
                  label: Text(_shoppingProgress == 1.0 ? 'Uncheck All' : 'Check All'),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.order.items.length,
              itemBuilder: (context, index) {
                final item = widget.order.items[index];
                return _buildShoppingItem(item, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShoppingItem(OrderItem item, int itemIndex) {
    final itemId = 'item_$itemIndex';
    final isChecked = _itemCheckList[itemId] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Row(
            children: [
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: isChecked,
                  onChanged: (value) => _toggleItem(itemId, value ?? false),
                  activeColor: context.colors.freshGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusSM,
                  ),
                ),
              ),
              
              const SizedBox(width: AppSpacing.sm),
              
              ClipRRect(
                borderRadius: AppRadius.radiusMD,
                child: Container(
                  width: 60,
                  height: 60,
                  color: context.colors.outline,
                  child: Center(
                    child: Text(
                      item.productName.isNotEmpty 
                          ? item.productName.substring(0, 1).toUpperCase()
                          : 'P',
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.freshGreen,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: AppSpacing.md),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: isChecked ? TextDecoration.lineThrough : null,
                        color: isChecked ? context.colors.textSecondary : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Quantity: ${item.quantity}',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    Text(
                      'Unit Price: KSh ${item.price.toStringAsFixed(2)}',
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
                    'KSh ${item.subtotal.toStringAsFixed(2)}',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.freshGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isChecked
                          ? context.colors.freshGreen.withValues(alpha: 0.2)
                          : context.colors.outline,
                      borderRadius: AppRadius.radiusSM,
                    ),
                    child: Text(
                      isChecked ? 'Collected' : 'Pending',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: isChecked
                            ? context.colors.freshGreen
                            : context.colors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerDetails() {
    return SliverToBoxAdapter(
      child: Container(
        margin: AppSpacing.paddingMD,
        padding: AppSpacing.paddingLG,
        decoration: BoxDecoration(
          color: context.colors.surfaceColor,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(color: context.colors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: context.colors.marketOrange,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Customer Information',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: context.colors.marketOrange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: context.colors.marketOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getCustomerName(widget.order),
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.order.phoneNumber,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _callCustomer(),
                      icon: Icon(
                        Icons.phone,
                        color: context.colors.freshGreen,
                      ),
                      tooltip: 'Call Customer',
                    ),
                    IconButton(
                      onPressed: () => _openOrderChat(),
                      icon: Icon(
                        Icons.chat,
                        color: context.colors.ecoBlue,
                      ),
                      tooltip: 'Chat with Customer',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDetails() {
    return SliverToBoxAdapter(
      child: Container(
        margin: AppSpacing.paddingMD,
        padding: AppSpacing.paddingLG,
        decoration: BoxDecoration(
          color: context.colors.surfaceColor,
          borderRadius: AppRadius.radiusLG,
          border: Border.all(color: context.colors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: context.colors.ecoBlue,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Delivery Information',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _openInMaps(),
                  icon: const Icon(Icons.map, size: 20),
                  label: const Text('View on Map'),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Container(
              padding: AppSpacing.paddingMD,
              decoration: BoxDecoration(
                color: context.colors.ecoBlue.withValues(alpha: 0.1),
                borderRadius: AppRadius.radiusMD,
                border: Border.all(color: context.colors.ecoBlue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.home,
                        color: context.colors.ecoBlue,
                        size: 20,
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
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.order.deliveryAddress.toString(),
                    style: context.textTheme.bodyMedium,
                  ),
                  
                  if (widget.order.specialInstructions?.isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Icon(
                          Icons.note,
                          color: context.colors.marketOrange,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Special Instructions',
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colors.marketOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: double.infinity,
                      padding: AppSpacing.paddingMD,
                      decoration: BoxDecoration(
                        color: context.colors.marketOrange.withValues(alpha: 0.1),
                        borderRadius: AppRadius.radiusMD,
                      ),
                      child: Text(
                        widget.order.specialInstructions!,
                        style: context.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return SliverToBoxAdapter(
      child: Container(
        margin: AppSpacing.paddingMD,
        child: Column(
          children: [
            if (_currentStatus == OrderStatus.confirmed) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Reject Order'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: AppSpacing.paddingMD,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptOrder(),
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Start Shopping'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.freshGreen,
                        foregroundColor: Colors.white,
                        padding: AppSpacing.paddingMD,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_currentStatus == OrderStatus.processing) ...[
              ElevatedButton.icon(
                onPressed: _shoppingProgress == 1.0 ? () => _completeShoppingAndNavigateToRider() : null,
                icon: const Icon(Icons.check_circle),
                label: Text(_shoppingProgress == 1.0
                    ? 'Complete Shopping & Assign Rider'
                    : 'Complete Shopping (${(_shoppingProgress * 100).toInt()}%)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.freshGreen,
                  foregroundColor: Colors.white,
                  padding: AppSpacing.paddingMD,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ] else if (_currentStatus == OrderStatus.ready) ...[
              ElevatedButton.icon(
                onPressed: () => _assignRider(),
                icon: const Icon(Icons.local_shipping),
                label: const Text('Assign Rider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.ecoBlue,
                  foregroundColor: Colors.white,
                  padding: AppSpacing.paddingMD,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
            
            const SizedBox(height: AppSpacing.sm),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _logWaste(),
                    icon: const Icon(Icons.eco),
                    label: const Text('Log Waste'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.marketOrange,
                      side: BorderSide(color: context.colors.marketOrange),
                      padding: AppSpacing.paddingMD,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reportIssue(),
                    icon: const Icon(Icons.report),
                    label: const Text('Report Issue'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.textSecondary,
                      side: BorderSide(color: context.colors.outline),
                      padding: AppSpacing.paddingMD,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return 'CONFIRMED';
      case OrderStatus.processing:
        return 'PROCESSING';
      case OrderStatus.ready:
        return 'READY FOR PICKUP';
      case OrderStatus.outForDelivery:
        return 'OUT FOR DELIVERY';
      case OrderStatus.delivered:
        return 'DELIVERED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
      default:
        return 'UNKNOWN';
    }
  }

  String _formatDateTime(DateTime dateTime) {
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

  void _toggleItem(String itemId, bool checked) {
    setState(() {
      _itemCheckList[itemId] = checked;
      _calculateProgress();
    });
    
    LoggerService.info('Item ${checked ? 'checked' : 'unchecked'}: $itemId', 
                      tag: 'AssignmentDetailsScreen');
  }

  void _toggleAllItems() {
    final allChecked = _shoppingProgress == 1.0;
    setState(() {
      for (var key in _itemCheckList.keys) {
        _itemCheckList[key] = !allChecked;
      }
      _calculateProgress();
    });
  }

  Future<void> _acceptOrder() async {
    try {
      final success = await ConnectorService.acceptOrder(widget.order.id);
      
      if (success && mounted) {
        setState(() {
          _currentStatus = OrderStatus.processing;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order accepted! You can now start shopping.'),
            backgroundColor: context.colors.freshGreen,
          ),
        );
      } else {
        throw Exception('Failed to accept order');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeShoppingAndNavigateToRider() async {
    try {
      final success = await ConnectorService.updateOrderStatus(widget.order.id, 'ready');
      
      if (success && mounted) {
        setState(() {
          _currentStatus = OrderStatus.ready;
        });
        
        NavigationService.toRiderHandoff(widget.order);
      } else {
        throw Exception('Failed to complete shopping');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete shopping: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _assignRider() {
    NavigationService.toRiderHandoff(widget.order);
  }

  void _callCustomer() {
    // TODO: Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calling customer...'),
      ),
    );
  }

  void _openOrderChat() {
    NavigationService.toChat();
  }

  void _openInMaps() {
    // TODO: Implement maps integration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening in maps...'),
      ),
    );
  }

  void _logWaste() {
    NavigationService.toWasteLogging();
  }

  void _reportIssue() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _buildReportIssueSheet(scrollController),
      ),
    );
  }

  Widget _buildReportIssueSheet(ScrollController scrollController) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Issue',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Describe the issue you\'re experiencing with this order:',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Describe the issue...',
              border: OutlineInputBorder(
                borderRadius: AppRadius.radiusMD,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Issue reported successfully'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.freshGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: const Text('Are you sure you want to reject this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectOrder();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectOrder() async {
    try {
      final success = await ConnectorService.updateOrderStatus(widget.order.id, 'cancelled');
      
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order rejected successfully'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        throw Exception('Failed to reject order');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'view_map':
        _openInMaps();
        break;
      case 'report_issue':
        _reportIssue();
        break;
    }
  }

  String _getCustomerName(Order order) {
    // In real implementation, this would fetch customer name
    return 'Customer ${order.customerId.substring(0, 4)}';
  }
} 