import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/order_model.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class RiderInfo {
  final String id;
  final String name;
  final String phone;
  final double rating;
  final int completedDeliveries;
  final bool isAvailable;
  final String location;
  final String vehicleType;

  RiderInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.rating,
    required this.completedDeliveries,
    required this.isAvailable,
    required this.location,
    required this.vehicleType,
  });
}

class RiderHandoffScreen extends StatefulWidget {
  final Order order;

  const RiderHandoffScreen({
    super.key,
    required this.order,
  });

  @override
  State<RiderHandoffScreen> createState() => _RiderHandoffScreenState();
}

class _RiderHandoffScreenState extends State<RiderHandoffScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _instructionsController = TextEditingController();
  
  List<RiderInfo> _availableRiders = [];
  RiderInfo? _selectedRider;
  bool _isLoading = false;
  bool _isAssigning = false;

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
    
    _loadAvailableRiders();
    _animationController.forward();
    
    LoggerService.info('Rider handoff screen initialized for order ${widget.order.id}', 
                      tag: 'RiderHandoffScreen');
  }

  Future<void> _loadAvailableRiders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mock data - would fetch from actual service
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _availableRiders = [
          RiderInfo(
            id: '1',
            name: 'John Kamau',
            phone: '+254712345678',
            rating: 4.8,
            completedDeliveries: 245,
            isAvailable: true,
            location: '2.5km away',
            vehicleType: 'Motorcycle',
          ),
          RiderInfo(
            id: '2',
            name: 'Mary Wanjiku',
            phone: '+254723456789',
            rating: 4.9,
            completedDeliveries: 189,
            isAvailable: true,
            location: '1.8km away',
            vehicleType: 'Bicycle',
          ),
          RiderInfo(
            id: '3',
            name: 'Peter Mwangi',
            phone: '+254734567890',
            rating: 4.7,
            completedDeliveries: 312,
            isAvailable: true,
            location: '3.2km away',
            vehicleType: 'Car',
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      LoggerService.error('Failed to load available riders', error: e, tag: 'RiderHandoffScreen');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _instructionsController.dispose();
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
                    _buildOrderSummary(),
                    Expanded(child: _buildRiderSelection()),
                  ],
                ),
              );
            },
          ),
          bottomNavigationBar: _buildBottomControls(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.colors.ecoBlue,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assign Rider',
            style: context.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Order #${widget.order.orderNumber}',
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _loadAvailableRiders(),
          tooltip: 'Refresh Riders',
        ),
        IconButton(
          icon: const Icon(Icons.map),
          onPressed: () => _viewOnMap(),
          tooltip: 'View on Map',
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Container(
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
                  Icons.local_shipping,
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
                      'Ready for Delivery',
                      style: context.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Shopping completed - assign rider for delivery',
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
                  'READY',
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
              Expanded(
                child: _buildOrderInfoCard(
                  'Order Value',
                  'KSh ${widget.order.totalPrice.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildOrderInfoCard(
                  'Items',
                  '${widget.order.items.length}',
                  Icons.shopping_bag,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildOrderInfoCard(
                  'Distance',
                  '2.5 km', // Would calculate actual distance
                  Icons.location_on,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard(String label, String value, IconData icon) {
    return Container(
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

  Widget _buildRiderSelection() {
    return Container(
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: context.colors.textPrimary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Available Riders',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_availableRiders.isNotEmpty)
                Text(
                  '${_availableRiders.length} available',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.freshGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          if (_isLoading)
            _buildLoadingState()
          else if (_availableRiders.isEmpty)
            _buildEmptyState()
          else
            Expanded(
              child: ListView.builder(
                itemCount: _availableRiders.length,
                itemBuilder: (context, index) {
                  final rider = _availableRiders[index];
                  return _buildRiderCard(rider);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRiderCard(RiderInfo rider) {
    final isSelected = _selectedRider?.id == rider.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        elevation: isSelected ? 4 : 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
        child: InkWell(
          borderRadius: AppRadius.radiusLG,
          onTap: () => _selectRider(rider),
          child: Container(
            padding: AppSpacing.paddingMD,
            decoration: BoxDecoration(
              borderRadius: AppRadius.radiusLG,
              border: isSelected 
                  ? Border.all(color: context.colors.ecoBlue, width: 2)
                  : null,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: context.colors.ecoBlue.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: context.colors.ecoBlue,
                        size: 30,
                      ),
                    ),
                    
                    const SizedBox(width: AppSpacing.md),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rider.name,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${rider.rating}',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '• ${rider.completedDeliveries} deliveries',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: context.colors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rider.location,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Icon(
                                _getVehicleIcon(rider.vehicleType),
                                size: 14,
                                color: context.colors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rider.vehicleType,
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
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.colors.freshGreen.withValues(alpha: 0.2),
                            borderRadius: AppRadius.radiusSM,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 12,
                                color: context.colors.freshGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Available',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colors.freshGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: context.colors.ecoBlue,
                            size: 20,
                          )
                        else
                          Icon(
                            Icons.radio_button_unchecked,
                            color: context.colors.textSecondary,
                            size: 20,
                          ),
                      ],
                    ),
                  ],
                ),
                
                if (isSelected) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: AppSpacing.paddingMD,
                    decoration: BoxDecoration(
                      color: context.colors.ecoBlue.withValues(alpha: 0.1),
                      borderRadius: AppRadius.radiusMD,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Information',
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 16,
                              color: context.colors.ecoBlue,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              rider.phone,
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => _callRider(rider),
                              icon: Icon(
                                Icons.call,
                                color: context.colors.freshGreen,
                                size: 20,
                              ),
                              tooltip: 'Call Rider',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: context.colors.ecoBlue,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Loading available riders...',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: context.colors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No riders available',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textSecondary,
              ),
            ),
            Text(
              'Try refreshing or check back later',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => _loadAvailableRiders(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.ecoBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
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
            if (_selectedRider != null) ...[
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
                    Text(
                      'Handoff Instructions (Optional)',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _instructionsController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Add any special instructions for the rider...',
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.radiusMD,
                        ),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              ElevatedButton.icon(
                onPressed: _isAssigning ? null : _assignRider,
                icon: _isAssigning 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.local_shipping),
                label: Text(_isAssigning ? 'Assigning...' : 'Assign ${_selectedRider!.name}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.ecoBlue,
                  foregroundColor: Colors.white,
                  padding: AppSpacing.paddingMD,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ] else ...[
              Container(
                padding: AppSpacing.paddingMD,
                decoration: BoxDecoration(
                  color: context.colors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.radiusMD,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: context.colors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Select a rider to assign this delivery',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: AppSpacing.sm),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Shopping'),
                    style: OutlinedButton.styleFrom(
                      padding: AppSpacing.paddingMD,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewOrderDetails(),
                    icon: const Icon(Icons.receipt),
                    label: const Text('Order Details'),
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

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'bicycle':
        return Icons.pedal_bike;
      case 'car':
        return Icons.directions_car;
      default:
        return Icons.local_shipping;
    }
  }

  void _selectRider(RiderInfo rider) {
    setState(() {
      _selectedRider = rider;
    });
  }

  Future<void> _assignRider() async {
    if (_selectedRider == null) return;

    setState(() {
      _isAssigning = true;
    });

    try {
      // Would call actual service to assign rider
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        NavigationService.toConnectorHome();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order assigned to ${_selectedRider!.name}'),
            backgroundColor: context.colors.ecoBlue,
            action: SnackBarAction(
              label: 'Track',
              textColor: Colors.white,
              onPressed: () => _trackOrder(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAssigning = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign rider: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _callRider(RiderInfo rider) {
    // TODO: Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${rider.name}...'),
      ),
    );
  }

  void _viewOnMap() {
    // TODO: Implement map view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening map view...'),
      ),
    );
  }

  void _viewOrderDetails() {
    NavigationService.toAssignmentDetails(widget.order,
    );
  }

  void _trackOrder() {
    NavigationService.toOrderTracking();
  }
} 