import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/cart_provider.dart';
import 'package:fresh_marikiti/core/providers/location_provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';
import 'package:fresh_marikiti/core/models/cart_model.dart';
import 'package:fresh_marikiti/core/models/product.dart';
import 'package:fresh_marikiti/core/models/user.dart';
import 'dart:async';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _checkoutAnimationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _checkoutAnimation;
  
  bool _isCheckingOut = false;
  String? _selectedDeliveryAddress;
  DateTime? _preferredDeliveryTime;
  String _specialInstructions = '';
  
  final TextEditingController _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _checkoutAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _checkoutAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _checkoutAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    LoggerService.info('Cart screen initialized', tag: 'CartScreen');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _checkoutAnimationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<CartProvider, LocationProvider, AuthProvider>(
      builder: (context, cartProvider, locationProvider, authProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: _buildAppBar(context, cartProvider),
          body: cartProvider.isEmpty 
              ? _buildEmptyCart()
              : Column(
                  children: [
                    // Cart items
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _slideAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: _buildCartContent(cartProvider, locationProvider),
                          );
                        },
                      ),
                    ),
                    
                    // Checkout section
                    _buildCheckoutSection(cartProvider, locationProvider),
                  ],
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, CartProvider cartProvider) {
    return AppBar(
      backgroundColor: context.colors.freshGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Your Cart',
        style: context.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (cartProvider.isNotEmpty)
          TextButton(
            onPressed: () => _showClearCartDialog(cartProvider),
            child: Text(
              'Clear All',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 120,
            color: context.colors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Your cart is empty',
            style: context.textTheme.headlineMedium?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add some fresh products to get started',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/customer/product-browse'),
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Browse Products'),
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

  Widget _buildCartContent(CartProvider cartProvider, LocationProvider locationProvider) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingMD,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delivery location section
          _buildDeliveryLocationSection(locationProvider),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Cart items header
          Text(
            'Cart Items (${cartProvider.itemCount})',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Cart items list
          ...cartProvider.items.map((item) => _buildCartItemCard(item, cartProvider)),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Special instructions
          _buildSpecialInstructions(),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Order summary
          _buildOrderSummary(cartProvider),
          
          const SizedBox(height: 100), // Space for checkout button
        ],
      ),
    );
  }

  Widget _buildDeliveryLocationSection(LocationProvider locationProvider) {
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
                Icon(Icons.location_on, color: context.colors.freshGreen),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Delivery Location',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Container(
              padding: AppSpacing.paddingMD,
              decoration: BoxDecoration(
                color: context.colors.freshGreen.withOpacity(0.1),
                borderRadius: AppRadius.radiusMD,
                border: Border.all(
                  color: context.colors.freshGreen.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locationProvider.currentAddress ?? 'No location selected',
                          style: context.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (locationProvider.currentAddress != null)
                          Text(
                            'Fresh Marikiti Location',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => NavigationService.toAddresses(),
                    child: Text(
                      'Change',
                      style: TextStyle(
                        color: context.colors.freshGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Delivery time
            Row(
              children: [
                Icon(Icons.schedule, color: context.colors.ecoBlue, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Estimated delivery: Today, 2-4 PM',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.ecoBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item, CartProvider cartProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: AppRadius.radiusLG,
        boxShadow: [
          BoxShadow(
            color: context.colors.textSecondary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Row(
          children: [
            // Product image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.colors.freshGreen.withOpacity(0.1),
                borderRadius: AppRadius.radiusMD,
              ),
              child: Icon(
                Icons.eco,
                color: context.colors.freshGreen,
                size: 32,
              ),
            ),
            
            const SizedBox(width: AppSpacing.md),
            
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    item.product.formattedPrice,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.colors.freshGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Quantity controls
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: context.colors.textSecondary.withOpacity(0.3),
                          ),
                          borderRadius: AppRadius.radiusSM,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _decreaseQuantity(item, cartProvider),
                              icon: const Icon(Icons.remove, size: 16),
                              iconSize: 16,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                item.quantity.toString(),
                                style: context.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _increaseQuantity(item, cartProvider),
                              icon: const Icon(Icons.add, size: 16),
                              iconSize: 16,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Subtotal
                      Text(
                        'KSh ${item.totalPrice.toStringAsFixed(2)}',
                        style: context.textTheme.titleMedium?.copyWith(
                          color: context.colors.freshGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Remove button
            IconButton(
              onPressed: () => _removeItem(item, cartProvider),
              icon: Icon(
                Icons.close,
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialInstructions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Special Instructions',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            TextField(
              controller: _instructionsController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any special delivery instructions or preferences...',
                border: OutlineInputBorder(
                  borderRadius: AppRadius.radiusMD,
                  borderSide: BorderSide(
                    color: context.colors.textSecondary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.radiusMD,
                  borderSide: BorderSide(
                    color: context.colors.freshGreen,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _specialInstructions = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cartProvider) {
    final subtotal = cartProvider.subtotal;
    final deliveryFee = cartProvider.deliveryFee;
    final total = cartProvider.total;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            _buildSummaryRow('Subtotal', 'KSh ${subtotal.toStringAsFixed(2)}'),
            _buildSummaryRow('Delivery Fee', 'KSh ${deliveryFee.toStringAsFixed(2)}'),
            _buildSummaryRow('Commission (5%)', 'KSh ${(subtotal * 0.05).toStringAsFixed(2)}'),
            
            const Divider(height: AppSpacing.lg),
            
            _buildSummaryRow(
              'Total',
              'KSh ${total.toStringAsFixed(2)}',
              isTotal: true,
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Container(
              padding: AppSpacing.paddingMD,
              decoration: BoxDecoration(
                color: context.colors.ecoBlue.withOpacity(0.1),
                borderRadius: AppRadius.radiusMD,
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: context.colors.ecoBlue, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Fresh Marikiti keeps only 5% commission to support local vendors',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.ecoBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? context.colors.textPrimary : context.colors.textSecondary,
            ),
          ),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTotal ? context.colors.freshGreen : context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(CartProvider cartProvider, LocationProvider locationProvider) {
    return Container(
      padding: AppSpacing.paddingLG,
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.textSecondary.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total and item count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cartProvider.itemCount} items',
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                    Text(
                      'KSh ${cartProvider.total.toStringAsFixed(2)}',
                      style: context.textTheme.headlineSmall?.copyWith(
                        color: context.colors.freshGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                // Checkout button
                AnimatedBuilder(
                  animation: _checkoutAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _checkoutAnimation.value,
                      child: ElevatedButton.icon(
                        onPressed: _isCheckingOut ? null : () => _proceedToCheckout(cartProvider, locationProvider),
                        icon: _isCheckingOut 
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.payment),
                        label: Text(_isCheckingOut ? 'Processing...' : 'Checkout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.freshGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  void _increaseQuantity(CartItem item, CartProvider cartProvider) {
    cartProvider.updateQuantity(item.product.id, item.quantity + 1);
  }

  void _decreaseQuantity(CartItem item, CartProvider cartProvider) {
    if (item.quantity > 1) {
      cartProvider.updateQuantity(item.product.id, item.quantity - 1);
    } else {
      _removeItem(item, cartProvider);
    }
  }

  void _removeItem(CartItem item, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove ${item.product.name} from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cartProvider.removeFromCart(item.product.id);
              Navigator.pop(context);
            },
            child: Text(
              'Remove',
              style: TextStyle(color: context.colors.marketOrange),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cartProvider.clearCart();
              Navigator.pop(context);
            },
            child: Text(
              'Clear All',
              style: TextStyle(color: context.colors.marketOrange),
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout(CartProvider cartProvider, LocationProvider locationProvider) async {
    if (locationProvider.currentAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a delivery address'),
          backgroundColor: context.colors.marketOrange,
          action: SnackBarAction(
            label: 'Select',
            textColor: Colors.white,
            onPressed: () => NavigationService.toAddresses(),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isCheckingOut = true;
    });
    
    _checkoutAnimationController.forward().then((_) {
      _checkoutAnimationController.reverse();
    });

    // Navigate to checkout screen
    await NavigationService.toCheckout();

    setState(() {
      _isCheckingOut = false;
    });
  }
} 