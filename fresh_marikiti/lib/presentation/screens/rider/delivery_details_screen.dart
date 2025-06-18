import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/order_model.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'dart:convert';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class DeliveryDetailsScreen extends StatefulWidget {
  final Order order;

  const DeliveryDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  bool _hasPickedUp = false;
  String _estimatedTime = '15-20 min';
  double _distanceToCustomer = 2.5;

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
    
    _hasPickedUp = widget.order.status == OrderStatus.outForDelivery;
    _animationController.forward();
    
    LoggerService.info('Delivery details screen initialized for order ${widget.order.id}', 
                      tag: 'DeliveryDetailsScreen');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
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
                      _buildDeliveryHeader(),
                      _buildCustomerDetails(),
                      _buildOrderItems(),
                      _buildDeliveryInstructions(),
                      _buildEarningsBreakdown(),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),
              );
            },
          ),
          bottomNavigationBar: _buildBottomControls(),
        );
      },
    );
  }

  Widget _buildAppBar() {
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
              'Order #${widget.order.orderNumber}',
              style: context.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Delivery Details',
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
          icon: const Icon(Icons.phone),
          onPressed: () => _callCustomer(),
          tooltip: 'Call Customer',
        ),
        IconButton(
          icon: const Icon(Icons.navigation),
          onPressed: () => NavigationService.toRiderNavigation(),
          tooltip: 'Navigate',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'report_issue',
              child: ListTile(
                leading: Icon(Icons.report),
                title: Text('Report Issue'),
              ),
            ),
            const PopupMenuItem(
              value: 'view_map',
              child: ListTile(
                leading: Icon(Icons.map),
                title: Text('View on Map'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeliveryHeader() {
    final deliveryFee = widget.order.deliveryFee;
    final commission = deliveryFee * 0.95; // 95% of delivery fee
    
    return SliverToBoxAdapter(
      child: Container(
        margin: AppSpacing.paddingMD,
        padding: AppSpacing.paddingLG,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colors.ecoBlue,
              context.colors.ecoBlue.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: AppRadius.radiusLG,
        ),
        child: Column(
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
                    _hasPickedUp ? Icons.local_shipping : Icons.store,
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
                        _hasPickedUp ? 'Out for Delivery' : 'Ready for Pickup',
                        style: context.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Earn KSh ${commission.toStringAsFixed(0)} for this delivery',
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
                    _hasPickedUp ? 'DELIVERING' : 'PICKUP',
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
                _buildHeaderMetric(
                  'Distance',
                  '${_distanceToCustomer.toStringAsFixed(1)} km',
                  Icons.route,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _buildHeaderMetric(
                  'Est. Time',
                  _estimatedTime,
                  Icons.access_time,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _buildHeaderMetric(
                  'Order Value',
                  'KSh ${widget.order.totalPrice.toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderMetric(String label, String value, IconData icon) {
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
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
                  'Customer Details',
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
                        _getCustomerName(),
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
                      onPressed: () => _sendMessage(),
                      icon: Icon(
                        Icons.message,
                        color: context.colors.ecoBlue,
                      ),
                      tooltip: 'Send Message',
                    ),
                  ],
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
                        Icons.location_on,
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
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => NavigationService.toRiderNavigation(),
                        icon: const Icon(Icons.navigation, size: 16),
                        label: const Text('Navigate'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.order.deliveryAddress.fullAddress,
                    style: context.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems() {
    if (widget.order.products.isEmpty) {
      return _buildNoOrderItems();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Items',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Column(
              children: widget.order.products.map((product) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: context.colors.ecoBlue.withValues(alpha: 0.1),
                          borderRadius: AppRadius.radiusMD,
                        ),
                        child: Icon(
                          Icons.shopping_bag,
                          color: context.colors.ecoBlue,
                        ),
                      ),
                      
                      const SizedBox(width: AppSpacing.sm),
                      
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.productName,
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Qty: ${product.quantity}',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Text(
                        'KSh ${product.subtotal.toStringAsFixed(0)}',
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.freshGreen,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoOrderItems() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: context.colors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Order items not loaded',
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            Text(
              'Contact support if this persists',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInstructions() {
    return SliverToBoxAdapter(
      child: Container(
        margin: AppSpacing.paddingMD,
        padding: AppSpacing.paddingLG,
        decoration: BoxDecoration(
          color: context.colors.marketOrange.withValues(alpha: 0.1),
          borderRadius: AppRadius.radiusLG,
          border: Border.all(color: context.colors.marketOrange.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.note,
                  color: context.colors.marketOrange,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Delivery Instructions',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.marketOrange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Container(
              padding: AppSpacing.paddingMD,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.radiusMD,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.order.specialInstructions?.isNotEmpty == true) ...[
                    Text(
                      'Special Instructions:',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      widget.order.specialInstructions!,
                      style: context.textTheme.bodyMedium,
                    ),
                    
                    const SizedBox(height: AppSpacing.md),
                  ],
                  
                  Text(
                    'General Instructions:',
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '• Call customer upon arrival\n• Handle items with care\n• Verify customer identity\n• Collect payment if cash on delivery',
                    style: context.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsBreakdown() {
    final deliveryFee = widget.order.deliveryFee;
    final platformFee = deliveryFee * 0.05; // 5% platform commission
    final earnings = deliveryFee - platformFee;
    
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
                  Icons.account_balance_wallet,
                  color: context.colors.freshGreen,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Earnings Breakdown',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Container(
              padding: AppSpacing.paddingMD,
              decoration: BoxDecoration(
                color: context.colors.freshGreen.withValues(alpha: 0.1),
                borderRadius: AppRadius.radiusMD,
              ),
              child: Column(
                children: [
                  _buildEarningsRow('Delivery Fee', 'KSh ${deliveryFee.toStringAsFixed(0)}'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildEarningsRow('Platform Fee (5%)', '- KSh ${platformFee.toStringAsFixed(0)}', isDeduction: true),
                  const Divider(),
                  _buildEarningsRow('Your Earnings', 'KSh ${earnings.toStringAsFixed(0)}', isTotal: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsRow(String label, String amount, {bool isDeduction = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isDeduction ? Colors.red : 
                   isTotal ? context.colors.freshGreen : null,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: AppSpacing.paddingLG,
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_hasPickedUp) ...[
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _confirmPickup,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(_isLoading ? 'Confirming...' : 'Confirm Pickup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.freshGreen,
                  foregroundColor: Colors.white,
                  padding: AppSpacing.paddingMD,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _confirmDelivery,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delivery_dining),
                label: Text(_isLoading ? 'Confirming...' : 'Confirm Delivery'),
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
                    onPressed: () => NavigationService.toRiderNavigation(),
                    icon: const Icon(Icons.navigation),
                    label: const Text('Navigate'),
                    style: OutlinedButton.styleFrom(
                      padding: AppSpacing.paddingMD,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callCustomer(),
                    icon: const Icon(Icons.phone),
                    label: const Text('Call Customer'),
                    style: OutlinedButton.styleFrom(
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

  String _getCustomerName() {
    // Get customer name from order or fetch from backend if needed
    return 'Customer'; // Default fallback - in production would fetch customer details
  }

  Future<void> _confirmPickup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.post('/rider/orders/${widget.order.id}/pickup', {
        'pickup_time': DateTime.now().toIso8601String(),
        'rider_location': {
          'latitude': 0.0, // Would get from location service
          'longitude': 0.0,
        },
      });
      
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _hasPickedUp = true;
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Pickup confirmed! Start delivery.'),
              backgroundColor: context.colors.freshGreen,
              action: SnackBarAction(
                label: 'Navigate',
                textColor: Colors.white,
                onPressed: () => NavigationService.toRiderNavigation(),
              ),
            ),
          );
        }
      } else {
        throw Exception('Failed to confirm pickup: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to confirm pickup', error: e, tag: 'DeliveryDetailsScreen');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm pickup: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelivery() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.post('/rider/orders/${widget.order.id}/deliver', {
        'delivery_time': DateTime.now().toIso8601String(),
        'delivery_location': {
          'latitude': 0.0, // Would get from location service
          'longitude': 0.0,
        },
      });
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (mounted) {
          NavigationService.toRiderHome();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delivery completed! Earned KSh ${data['earnings']?.toStringAsFixed(0) ?? '0'}'),
              backgroundColor: context.colors.freshGreen,
            ),
          );
        }
      } else {
        throw Exception('Failed to confirm delivery: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to confirm delivery', error: e, tag: 'DeliveryDetailsScreen');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm delivery: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _callCustomer() {
    // TODO: Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${widget.order.phoneNumber}...'),
      ),
    );
  }

  void _sendMessage() {
    // TODO: Implement messaging functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening message...'),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'report_issue':
        _reportIssue();
        break;
      case 'view_map':
        NavigationService.toRiderNavigation();
        break;
    }
  }

  void _reportIssue() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: const TextField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Describe the issue...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Issue reported successfully'),
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
} 