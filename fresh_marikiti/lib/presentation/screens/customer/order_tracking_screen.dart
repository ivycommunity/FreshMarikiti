import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:fresh_marikiti/core/providers/order_provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/providers/location_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/order_model.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const OrderTrackingScreen({
    super.key,
    this.arguments,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  
  Timer? _trackingTimer;
  String? _orderId;
  bool _isLiveTracking = false;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _initializeTracking();
    _animationController.forward();
    LoggerService.info('Order tracking screen initialized', tag: 'OrderTrackingScreen');
  }

  void _initializeTracking() {
    final args = widget.arguments;
    if (args != null) {
      _orderId = args['orderId'] as String?;
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_orderId != null) {
        final orderProvider = Provider.of<OrderProvider>(context, listen: false);
        orderProvider.getOrderDetails(_orderId!).then((order) {
          if (order != null) {
            orderProvider.setCurrentOrder(order);
          }
        });
        _startLiveTracking();
      }
    });
  }

  void _startLiveTracking() {
    _isLiveTracking = true;
    _pulseController.repeat(reverse: true);
    
    _trackingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && _orderId != null) {
        final orderProvider = Provider.of<OrderProvider>(context, listen: false);
        orderProvider.getOrderDetails(_orderId!).then((order) {
          if (order != null) {
            orderProvider.setCurrentOrder(order);
          }
        });
      }
    });
  }

  void _stopLiveTracking() {
    _isLiveTracking = false;
    _trackingTimer?.cancel();
    _pulseController.stop();
  }

  @override
  void dispose() {
    _stopLiveTracking();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<OrderProvider, AuthProvider, LocationProvider>(
      builder: (context, orderProvider, authProvider, locationProvider, child) {
        final order = orderProvider.currentOrder;
        
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: _buildAppBar(context, order),
          body: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: _buildTrackingContent(orderProvider, order, locationProvider),
              );
            },
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Order? order) {
    return AppBar(
      backgroundColor: context.colors.freshGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Tracking',
            style: context.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (order != null)
            Text(
              'Order #${order.orderNumber}',
              style: context.textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
        ],
      ),
      actions: [
        if (_isLiveTracking)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Icon(
                    Icons.radio_button_checked,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
              );
            },
          ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _refreshOrder(),
        ),
      ],
    );
  }

  Widget _buildTrackingContent(OrderProvider orderProvider, Order? order, LocationProvider locationProvider) {
    if (orderProvider.isLoading && order == null) {
      return _buildLoadingState();
    }
    
    if (orderProvider.error != null && order == null) {
      return _buildErrorState(orderProvider);
    }
    
    if (order == null) {
      return _buildOrderNotFoundState();
    }
    
    return RefreshIndicator(
      onRefresh: () => _refreshOrder(),
      color: context.colors.freshGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.paddingMD,
        child: Column(
          children: [
            // Order status header
            _buildOrderStatusHeader(order),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Delivery progress
            _buildDeliveryProgress(order),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Live tracking map placeholder
            if (order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled) _buildLiveTrackingSection(order, locationProvider),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Order details
            _buildOrderDetailsCard(order),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Vendor and rider info
            _buildContactsCard(order),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Action buttons
            _buildActionButtons(order),
            
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusHeader(Order order) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Container(
        padding: AppSpacing.paddingLG,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getStatusColor(order.status),
              _getStatusColor(order.status).withOpacity(0.8),
            ],
          ),
          borderRadius: AppRadius.radiusLG,
        ),
        child: Column(
          children: [
            Icon(
              _getStatusIcon(order.status),
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _getStatusTitle(order.status),
              style: context.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              _getStatusSubtitle(order),
              style: context.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
            if (order.estimatedDeliveryTime != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: AppRadius.radiusLG,
                ),
                child: Text(
                  'Est. ${_formatEstimatedTime(order.estimatedDeliveryTime!)}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryProgress(Order order) {
    final steps = _getOrderSteps(order);
    final currentStepIndex = _getCurrentStepIndex(order.status);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Progress',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCompleted = index < currentStepIndex;
              final isCurrent = index == currentStepIndex;
              final isLast = index == steps.length - 1;
              
              return Column(
                children: [
                  Row(
                    children: [
                      // Step indicator
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCompleted 
                              ? context.colors.freshGreen 
                              : isCurrent 
                                  ? context.colors.marketOrange 
                                  : context.colors.textSecondary.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : step['icon'],
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      
                      const SizedBox(width: AppSpacing.md),
                      
                      // Step content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step['title'],
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: isCurrent 
                                    ? context.colors.textPrimary 
                                    : isCompleted 
                                        ? context.colors.freshGreen 
                                        : context.colors.textSecondary,
                              ),
                            ),
                            Text(
                              step['subtitle'],
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                            if (step['time'] != null)
                              Text(
                                step['time'],
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colors.ecoBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Connector line
                  if (!isLast)
                    Container(
                      margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                      width: 2,
                      height: 24,
                      color: isCompleted 
                          ? context.colors.freshGreen 
                          : context.colors.textSecondary.withOpacity(0.3),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTrackingSection(Order order, LocationProvider locationProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.my_location, color: context.colors.ecoBlue),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Live Tracking',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: AppRadius.radiusSM,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Map placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: context.colors.freshGreen.withOpacity(0.1),
                borderRadius: AppRadius.radiusMD,
                border: Border.all(
                  color: context.colors.freshGreen.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      size: 48,
                      color: context.colors.freshGreen,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Live Map Integration',
                      style: context.textTheme.titleMedium?.copyWith(
                        color: context.colors.freshGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Real-time delivery tracking',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Delivery info
            Row(
              children: [
                Expanded(
                  child: _buildTrackingInfo(
                    'Distance',
                    order.deliveryDistance != null 
                        ? '${order.deliveryDistance!.toStringAsFixed(1)} km'
                        : '2.5 km',
                    Icons.straighten,
                  ),
                ),
                Expanded(
                  child: _buildTrackingInfo(
                    'ETA',
                    order.estimatedDeliveryTime != null 
                        ? _formatEstimatedTime(order.estimatedDeliveryTime!)
                        : '15 min',
                    Icons.access_time,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingInfo(String label, String value, IconData icon) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: AppRadius.radiusMD,
      ),
      child: Column(
        children: [
          Icon(icon, color: context.colors.ecoBlue, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.ecoBlue,
            ),
          ),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard(Order order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Details',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            ...order.items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: context.colors.freshGreen.withOpacity(0.1),
                      borderRadius: AppRadius.radiusMD,
                    ),
                    child: Icon(
                      Icons.eco,
                      color: context.colors.freshGreen,
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: AppSpacing.md),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${item.quantity} x KSh ${item.price.toStringAsFixed(2)}',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Text(
                    'KSh ${item.subtotal.toStringAsFixed(2)}',
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.colors.freshGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
            
            const Divider(),
            
            // Order summary
            _buildOrderSummaryRow('Subtotal', 'KSh ${order.subtotal.toStringAsFixed(2)}'),
            _buildOrderSummaryRow('Delivery Fee', 'KSh ${order.deliveryFee.toStringAsFixed(2)}'),
            if (order.totalPrice - order.subtotal - order.deliveryFee > 0)
              _buildOrderSummaryRow('Discount', '-KSh ${(order.totalPrice - order.subtotal - order.deliveryFee).abs().toStringAsFixed(2)}'),
            const SizedBox(height: AppSpacing.sm),
            _buildOrderSummaryRow(
              'Total',
              'KSh ${order.totalPrice.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTotal ? context.colors.freshGreen : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsCard(Order order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contacts',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Vendor contact
            _buildContactCard(
              'Vendor',
              'Vendor ${order.vendorId.substring(0, 6)}',
              '+254XXXXXXXXX',
              Icons.store,
              context.colors.freshGreen,
              () => _contactVendor(order),
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            // Rider contact (if assigned)
            if (order.assignedRider != null)
              _buildContactCard(
                'Delivery Rider',
                'Rider ${order.assignedRider!.substring(0, 6)}',
                '+254XXXXXXXXX',
                Icons.delivery_dining,
                context.colors.ecoBlue,
                () => _contactRider(order),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    String title,
    String name,
    String phone,
    IconData icon,
    Color color,
    VoidCallback onCall,
  ) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.radiusMD,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          
          const SizedBox(width: AppSpacing.md),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                Text(
                  name,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  phone,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          IconButton(
            onPressed: onCall,
            icon: Icon(Icons.phone, color: color),
            style: IconButton.styleFrom(
              backgroundColor: color.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Order order) {
    return Column(
      children: [
        // Primary action based on order status
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _performPrimaryAction(order),
            icon: Icon(_getPrimaryActionIcon(order.status)),
            label: Text(_getPrimaryActionText(order.status)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getPrimaryActionColor(order.status),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        // Secondary actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _reorderItems(order),
                icon: const Icon(Icons.refresh),
                label: const Text('Reorder'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.colors.freshGreen),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
                ),
              ),
            ),
            
            const SizedBox(width: AppSpacing.md),
            
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _getSupport(order),
                icon: const Icon(Icons.support_agent),
                label: const Text('Support'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.colors.ecoBlue),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.lg),
          Text('Loading order details...'),
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
            color: context.colors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Failed to load order',
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
            onPressed: () => _refreshOrder(),
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

  Widget _buildOrderNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: context.colors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Order Not Found',
            style: context.textTheme.headlineSmall?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The order you\'re looking for could not be found',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/customer/order-history'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.freshGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('View Order History'),
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

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.confirmed:
        return Icons.check_circle;
      case OrderStatus.processing:
        return Icons.restaurant;
      case OrderStatus.ready:
        return Icons.shopping_bag;
      case OrderStatus.pickedUp:
      case OrderStatus.outForDelivery:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusTitle(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Order Pending';
      case OrderStatus.confirmed:
        return 'Order Confirmed';
      case OrderStatus.processing:
        return 'Being Prepared';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.outForDelivery:
        return 'On the Way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown Status';
    }
  }

  String _getStatusSubtitle(Order order) {
    switch (order.status) {
      case OrderStatus.pending:
        return 'Waiting for vendor confirmation';
      case OrderStatus.confirmed:
        return 'Your order has been confirmed';
      case OrderStatus.processing:
        return 'Fresh items being prepared';
      case OrderStatus.ready:
        return 'Ready for pickup by rider';
      case OrderStatus.pickedUp:
        return 'Rider has picked up your order';
      case OrderStatus.outForDelivery:
        return 'Your order is on the way';
      case OrderStatus.delivered:
        return 'Order delivered successfully';
      case OrderStatus.cancelled:
        return 'Order has been cancelled';
      default:
        return 'Status unknown';
    }
  }

  List<Map<String, dynamic>> _getOrderSteps(Order order) {
    return [
      {
        'title': 'Order Placed',
        'subtitle': 'Order confirmed and sent to vendor',
        'icon': Icons.receipt,
        'time': order.createdAt.toString().split(' ')[1].substring(0, 5),
      },
      {
        'title': 'Preparing',
        'subtitle': 'Fresh items being prepared',
        'icon': Icons.restaurant,
        'time': order.status == OrderStatus.processing ? 'In progress' : null,
      },
      {
        'title': 'Ready for Pickup',
        'subtitle': 'Rider assigned and en route to vendor',
        'icon': Icons.shopping_bag,
        'time': order.status == OrderStatus.ready ? 'Ready now' : null,
      },
      {
        'title': 'Out for Delivery',
        'subtitle': 'On the way to your location',
        'icon': Icons.local_shipping,
        'time': order.status == OrderStatus.outForDelivery ? 'En route' : null,
      },
      {
        'title': 'Delivered',
        'subtitle': 'Order delivered successfully',
        'icon': Icons.check_circle,
        'time': order.status == OrderStatus.delivered ? 'Completed' : null,
      },
    ];
  }

  int _getCurrentStepIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        return 0;
      case OrderStatus.processing:
        return 1;
      case OrderStatus.ready:
      case OrderStatus.pickedUp:
        return 2;
      case OrderStatus.outForDelivery:
        return 3;
      case OrderStatus.delivered:
        return 4;
      default:
        return 0;
    }
  }

  String _formatEstimatedTime(DateTime time) {
    final now = DateTime.now();
    final difference = time.difference(now);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    }
  }

  IconData _getPrimaryActionIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return Icons.rate_review;
      case OrderStatus.cancelled:
        return Icons.refresh;
      default:
        return Icons.support_agent;
    }
  }

  String _getPrimaryActionText(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return 'Rate Order';
      case OrderStatus.cancelled:
        return 'Reorder';
      default:
        return 'Contact Support';
    }
  }

  Color _getPrimaryActionColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return context.colors.marketOrange;
      case OrderStatus.cancelled:
        return context.colors.freshGreen;
      default:
        return context.colors.ecoBlue;
    }
  }

  Future<void> _refreshOrder() async {
    if (_orderId != null) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final order = await orderProvider.getOrderDetails(_orderId!);
      if (order != null) {
        orderProvider.setCurrentOrder(order);
      }
    }
  }

  void _performPrimaryAction(Order order) {
    switch (order.status) {
      case OrderStatus.delivered:
        NavigationService.toRating(
          targetId: order.id,
          ratingType: 'order',
          targetData: {
            'orderNumber': order.orderNumber,
            'vendorName': 'Vendor ${order.vendorId.substring(0, 6)}',
          },
        );
        break;
      case OrderStatus.cancelled:
        _reorderItems(order);
        break;
      default:
        _getSupport(order);
        break;
    }
  }

  void _contactVendor(Order order) {
    // Implement vendor contact functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling vendor ${order.vendorId.substring(0, 6)}...'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }

  void _contactRider(Order order) {
    // Implement rider contact functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling rider ${order.assignedRider?.substring(0, 6) ?? 'Unknown'}...'),
        backgroundColor: context.colors.ecoBlue,
      ),
    );
  }

  void _reorderItems(Order order) {
    NavigationService.toCart();
    // Implement reorder functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Items added to cart for reorder'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }

  void _getSupport(Order order) {
    NavigationService.toHelpSupport();
  }
} 