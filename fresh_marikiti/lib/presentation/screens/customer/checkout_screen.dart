import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/cart_provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/providers/order_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/cart_model.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const CheckoutScreen({
    super.key,
    this.arguments,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _paymentAnimationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _paymentAnimation;
  
  final PageController _pageController = PageController();
  final TextEditingController _mpesaPhoneController = TextEditingController();
  final TextEditingController _promoCodeController = TextEditingController();
  
  int _currentStep = 0;
  bool _isProcessingPayment = false;
  bool _orderCompleted = false;
  String? _orderId;
  
  // Payment options
  String _selectedPaymentMethod = 'mpesa';
  bool _savePaymentMethod = false;
  
  // Delivery options
  String _selectedDeliveryTime = 'asap';
  DateTime? _scheduledTime;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _paymentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _paymentAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _paymentAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
    _initializeCheckout();
    LoggerService.info('Checkout screen initialized', tag: 'CheckoutScreen');
  }

  void _initializeCheckout() {
    final args = widget.arguments;
    if (args != null) {
      // Initialize with cart data from arguments
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _paymentAnimationController.dispose();
    _pageController.dispose();
    _mpesaPhoneController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<CartProvider, AuthProvider, OrderProvider>(
      builder: (context, cartProvider, authProvider, orderProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: _buildAppBar(context),
          body: _orderCompleted 
              ? _buildOrderSuccessPage() 
              : _buildCheckoutFlow(cartProvider, authProvider, orderProvider),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.colors.freshGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        _orderCompleted ? 'Order Confirmed' : 'Checkout',
        style: context.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: _orderCompleted 
          ? null 
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
    );
  }

  Widget _buildCheckoutFlow(CartProvider cartProvider, AuthProvider authProvider, OrderProvider orderProvider) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              
              // Checkout content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildOrderReviewStep(cartProvider),
                    _buildPaymentStep(cartProvider, authProvider),
                    _buildConfirmationStep(cartProvider, authProvider),
                  ],
                ),
              ),
              
              // Navigation buttons
              _buildNavigationButtons(cartProvider, authProvider, orderProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: AppSpacing.paddingLG,
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: context.colors.textSecondary.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildStepIndicator(0, 'Review', Icons.receipt_long),
          Expanded(child: _buildStepConnector(0 < _currentStep)),
          _buildStepIndicator(1, 'Payment', Icons.payment),
          Expanded(child: _buildStepConnector(1 < _currentStep)),
          _buildStepIndicator(2, 'Confirm', Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final isActive = step <= _currentStep;
    final isCompleted = step < _currentStep;
    
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted 
                ? context.colors.freshGreen 
                : isActive 
                    ? context.colors.freshGreen 
                    : context.colors.textSecondary.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: isActive ? context.colors.textPrimary : context.colors.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isCompleted) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isCompleted 
            ? context.colors.freshGreen 
            : context.colors.textSecondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildOrderReviewStep(CartProvider cartProvider) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Your Order',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Order items
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
            child: Padding(
              padding: AppSpacing.paddingLG,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items (${cartProvider.itemCount})',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...cartProvider.items.map((item) => _buildOrderItem(item)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Delivery details
          _buildDeliveryDetailsCard(),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Promo code
          _buildPromoCodeCard(cartProvider),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Order summary
          _buildOrderSummaryCard(cartProvider),
        ],
      ),
    );
  }

  Widget _buildOrderItem(CartItem item) {
    return Container(
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
                  item.product.name,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${item.quantity} x ${item.product.formattedPrice}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          Text(
            'KSh ${item.totalPrice.toStringAsFixed(2)}',
            style: context.textTheme.titleSmall?.copyWith(
              color: context.colors.freshGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryDetailsCard() {
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
                  'Delivery Details',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Text(
              'Default Delivery Address',
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Nairobi CBD, Kenya',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Delivery time options
            Text(
              'Delivery Time',
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('ASAP'),
                    subtitle: const Text('30-45 minutes'),
                    value: 'asap',
                    groupValue: _selectedDeliveryTime,
                    onChanged: (value) {
                      setState(() {
                        _selectedDeliveryTime = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: context.colors.freshGreen,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Schedule'),
                    subtitle: const Text('Choose time'),
                    value: 'scheduled',
                    groupValue: _selectedDeliveryTime,
                    onChanged: (value) {
                      setState(() {
                        _selectedDeliveryTime = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    activeColor: context.colors.freshGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCodeCard(CartProvider cartProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Promo Code',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoCodeController,
                    decoration: InputDecoration(
                      hintText: 'Enter promo code',
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.radiusMD,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.radiusMD,
                        borderSide: BorderSide(
                          color: context.colors.freshGreen,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: () => _applyPromoCode(cartProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.freshGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(CartProvider cartProvider) {
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
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSummaryRow('Subtotal', 'KSh ${cartProvider.subtotal.toStringAsFixed(2)}'),
            _buildSummaryRow('Delivery Fee', 'KSh ${cartProvider.deliveryFee.toStringAsFixed(2)}'),
            if (cartProvider.discount > 0)
              _buildSummaryRow('Discount', '-KSh ${cartProvider.discount.toStringAsFixed(2)}'),
            const Divider(),
            _buildSummaryRow(
              'Total',
              'KSh ${cartProvider.total.toStringAsFixed(2)}',
              isTotal: true,
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

  Widget _buildPaymentStep(CartProvider cartProvider, AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // M-Pesa option
          _buildPaymentOption(
            'mpesa',
            'M-Pesa',
            'Pay with your M-Pesa mobile money',
            Icons.phone_android,
            context.colors.freshGreen,
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Card option (placeholder for future implementation)
          _buildPaymentOption(
            'card',
            'Credit/Debit Card',
            'Pay with your card (Coming soon)',
            Icons.credit_card,
            context.colors.textSecondary,
            isEnabled: false,
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // M-Pesa phone number input
          if (_selectedPaymentMethod == 'mpesa') ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
              child: Padding(
                padding: AppSpacing.paddingLG,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'M-Pesa Phone Number',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _mpesaPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '254XXXXXXXXX',
                        prefixText: '+',
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.radiusMD,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.radiusMD,
                          borderSide: BorderSide(
                            color: context.colors.freshGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CheckboxListTile(
                      title: const Text('Save this payment method'),
                      value: _savePaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _savePaymentMethod = value ?? false;
                        });
                      },
                      activeColor: context.colors.freshGreen,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.lg),
          ],
          
          // Payment security info
          Container(
            padding: AppSpacing.paddingLG,
            decoration: BoxDecoration(
              color: context.colors.ecoBlue.withOpacity(0.1),
              borderRadius: AppRadius.radiusLG,
              border: Border.all(
                color: context.colors.ecoBlue.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: context.colors.ecoBlue),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Payment',
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.ecoBlue,
                        ),
                      ),
                      Text(
                        'Your payment is protected with 256-bit SSL encryption',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.ecoBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    bool isEnabled = true,
  }) {
    return Card(
      elevation: _selectedPaymentMethod == value ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusLG,
        side: BorderSide(
          color: _selectedPaymentMethod == value 
              ? context.colors.freshGreen 
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: RadioListTile<String>(
        title: Row(
          children: [
            Icon(icon, color: isEnabled ? color : context.colors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isEnabled ? context.colors.textPrimary : context.colors.textSecondary,
              ),
            ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: context.textTheme.bodyMedium?.copyWith(
            color: isEnabled ? context.colors.textSecondary : context.colors.textSecondary,
          ),
        ),
        value: value,
        groupValue: _selectedPaymentMethod,
        onChanged: isEnabled ? (newValue) {
          setState(() {
            _selectedPaymentMethod = newValue!;
          });
        } : null,
        activeColor: context.colors.freshGreen,
      ),
    );
  }

  Widget _buildConfirmationStep(CartProvider cartProvider, AuthProvider authProvider) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm Your Order',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Final order summary
          Card(
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
                  _buildConfirmationRow('Items', '${cartProvider.itemCount} products'),
                  _buildConfirmationRow('Total Amount', 'KSh ${cartProvider.total.toStringAsFixed(2)}'),
                  _buildConfirmationRow('Payment Method', _getPaymentMethodDisplay()),
                  _buildConfirmationRow('Delivery', _selectedDeliveryTime == 'asap' ? 'ASAP (30-45 min)' : 'Scheduled'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Terms and conditions
          Container(
            padding: AppSpacing.paddingLG,
            decoration: BoxDecoration(
              color: context.colors.surfaceColor,
              borderRadius: AppRadius.radiusLG,
              border: Border.all(
                color: context.colors.textSecondary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Terms',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '• Fresh Marikiti connects you directly with local vendors\n'
                  '• 5% platform fee supports sustainable farming\n'
                  '• Orders are processed by your selected vendors\n'
                  '• Delivery times may vary based on vendor location',
                  style: context.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSuccessPage() {
    return AnimatedBuilder(
      animation: _paymentAnimation,
      builder: (context, child) {
        return Center(
          child: Padding(
            padding: AppSpacing.paddingXL,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: _paymentAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: context.colors.freshGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                Text(
                  'Order Confirmed!',
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.freshGreen,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                Text(
                  'Your order #${_orderId ?? 'FM001'} has been placed successfully',
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                Container(
                  padding: AppSpacing.paddingLG,
                  decoration: BoxDecoration(
                    color: context.colors.ecoBlue.withOpacity(0.1),
                    borderRadius: AppRadius.radiusLG,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        color: context.colors.ecoBlue,
                        size: 32,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Estimated Delivery',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.ecoBlue,
                        ),
                      ),
                      Text(
                        'Today, 2:00 PM - 4:00 PM',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colors.ecoBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          NavigationService.toCustomerHome();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.colors.freshGreen),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
                        ),
                        child: Text(
                          'Continue Shopping',
                          style: TextStyle(color: context.colors.freshGreen),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => NavigationService.toOrderTracking(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.freshGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
                        ),
                        child: const Text('Track Order'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationButtons(CartProvider cartProvider, AuthProvider authProvider, OrderProvider orderProvider) {
    if (_orderCompleted) return const SizedBox.shrink();
    
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
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.colors.freshGreen),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(color: context.colors.freshGreen),
                  ),
                ),
              ),
            
            if (_currentStep > 0) const SizedBox(width: AppSpacing.md),
            
            Expanded(
              flex: _currentStep == 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _isProcessingPayment 
                    ? null 
                    : () => _nextStep(cartProvider, authProvider, orderProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.freshGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
                ),
                child: _isProcessingPayment
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(_getNextButtonText()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getNextButtonText() {
    switch (_currentStep) {
      case 0: return 'Continue to Payment';
      case 1: return 'Review Order';
      case 2: return 'Place Order';
      default: return 'Next';
    }
  }

  String _getPaymentMethodDisplay() {
    switch (_selectedPaymentMethod) {
      case 'mpesa': return 'M-Pesa';
      case 'card': return 'Credit/Debit Card';
      default: return 'Unknown';
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextStep(CartProvider cartProvider, AuthProvider authProvider, OrderProvider orderProvider) async {
    if (_currentStep < 2) {
      if (_currentStep == 1 && !_validatePaymentDetails()) {
        return;
      }
      
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Place order
      await _placeOrder(cartProvider, authProvider, orderProvider);
    }
  }

  bool _validatePaymentDetails() {
    if (_selectedPaymentMethod == 'mpesa') {
      if (_mpesaPhoneController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enter your M-Pesa phone number'),
            backgroundColor: context.colors.marketOrange,
          ),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _placeOrder(CartProvider cartProvider, AuthProvider authProvider, OrderProvider orderProvider) async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Simulate order placement
      await Future.delayed(const Duration(seconds: 2));
      
      // Generate order ID
      _orderId = 'FM${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      
      // Clear cart
      await cartProvider.clearCart();
      
      setState(() {
        _orderCompleted = true;
        _isProcessingPayment = false;
      });
      
      _paymentAnimationController.forward();
      
      LoggerService.info('Order placed successfully: $_orderId', tag: 'CheckoutScreen');
      
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order: $e'),
          backgroundColor: context.colors.marketOrange,
        ),
      );
      
      LoggerService.error('Order placement failed', error: e, tag: 'CheckoutScreen');
    }
  }

  void _applyPromoCode(CartProvider cartProvider) {
    final code = _promoCodeController.text.trim();
    if (code.isNotEmpty) {
      // Implement promo code application
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Promo code "$code" applied!'),
          backgroundColor: context.colors.freshGreen,
        ),
      );
    }
  }
} 