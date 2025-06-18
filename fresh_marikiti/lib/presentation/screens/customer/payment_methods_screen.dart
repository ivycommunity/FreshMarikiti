import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/providers/order_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fabAnimation;
  
  bool _isLoading = false;
  String _selectedTab = 'methods';
  
  // Demo payment methods
  List<Map<String, dynamic>> _paymentMethods = [];
  List<Map<String, dynamic>> _paymentHistory = [];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
    
    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _loadData();
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _fabAnimationController.forward();
    });
    LoggerService.info('Payment methods screen initialized', tag: 'PaymentMethodsScreen');
  }

  void _loadData() {
    _loadPaymentMethods();
    _loadPaymentHistory();
  }

  void _loadPaymentMethods() {
    // Demo payment methods
    _paymentMethods = [
      {
        'id': 'mpesa_001',
        'type': 'mpesa',
        'label': 'M-Pesa Primary',
        'phoneNumber': '+254712345678',
        'isDefault': true,
        'lastUsed': DateTime.now().subtract(const Duration(days: 1)),
        'isActive': true,
      },
      {
        'id': 'mpesa_002',
        'type': 'mpesa',
        'label': 'M-Pesa Business',
        'phoneNumber': '+254798765432',
        'isDefault': false,
        'lastUsed': DateTime.now().subtract(const Duration(days: 7)),
        'isActive': true,
      },
    ];
  }

  void _loadPaymentHistory() {
    // Demo payment history
    _paymentHistory = [
      {
        'id': 'txn_001',
        'orderId': 'ORD_001',
        'amount': 1250.00,
        'method': 'M-Pesa',
        'methodDetails': '+254712345678',
        'status': 'completed',
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'transactionCode': 'QF47X8Y2Z1',
      },
      {
        'id': 'txn_002',
        'orderId': 'ORD_002',
        'amount': 875.50,
        'method': 'M-Pesa',
        'methodDetails': '+254712345678',
        'status': 'completed',
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'transactionCode': 'QF44Y2X8Z9',
      },
      {
        'id': 'txn_003',
        'orderId': 'ORD_003',
        'amount': 2150.00,
        'method': 'M-Pesa',
        'methodDetails': '+254798765432',
        'status': 'failed',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'transactionCode': 'QF41Z8X2Y7',
      },
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, OrderProvider>(
      builder: (context, authProvider, orderProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: _buildAppBar(context),
          body: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Column(
                    children: [
                      _buildTabBar(),
                      Expanded(
                        child: _selectedTab == 'methods' 
                            ? _buildPaymentMethodsTab()
                            : _buildPaymentHistoryTab(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          floatingActionButton: _selectedTab == 'methods' ? _buildFloatingActionButton() : null,
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
        'Payment Methods',
        style: context.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        borderRadius: AppRadius.radiusLG,
        border: Border.all(color: context.colors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('methods', 'Payment Methods', Icons.payment),
          ),
          Expanded(
            child: _buildTabButton('history', 'Transaction History', Icons.history),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabId, String title, IconData icon) {
    final isSelected = _selectedTab == tabId;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tabId),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.freshGreen : Colors.transparent,
          borderRadius: AppRadius.radiusLG,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : context.colors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: context.textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : context.colors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsTab() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_paymentMethods.isEmpty) {
      return _buildEmptyMethodsState();
    }
    
    return SingleChildScrollView(
      padding: AppSpacing.paddingMD,
      child: Column(
        children: [
          // Payment statistics
          _buildPaymentStatistics(),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Payment methods header
          Row(
            children: [
              Text(
                'Saved Payment Methods',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_paymentMethods.length} methods',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.md),
          
          // Payment methods list
          ..._paymentMethods.asMap().entries.map((entry) {
            final index = entry.key;
            final method = entry.value;
            return _buildPaymentMethodCard(method, index);
          }),
          
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryTab() {
    if (_paymentHistory.isEmpty) {
      return _buildEmptyHistoryState();
    }
    
    return SingleChildScrollView(
      padding: AppSpacing.paddingMD,
      child: Column(
        children: [
          // Filter options
          _buildHistoryFilters(),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Transaction history
          ..._paymentHistory.asMap().entries.map((entry) {
            final index = entry.key;
            final transaction = entry.value;
            return _buildTransactionCard(transaction, index);
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentStatistics() {
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
                Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Payment Overview',
                  style: context.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Spent',
                    'KSh 4,275',
                    Icons.attach_money,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Transactions',
                    '${_paymentHistory.length}',
                    Icons.receipt,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Success Rate',
                    '95%',
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
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

  Widget _buildPaymentMethodCard(Map<String, dynamic> method, int index) {
    final isDefault = method['isDefault'] ?? false;
    final isActive = method['isActive'] ?? true;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Card(
                elevation: isDefault ? 6 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.radiusLG,
                  side: BorderSide(
                    color: isDefault 
                        ? context.colors.freshGreen 
                        : Colors.transparent,
                    width: isDefault ? 2 : 0,
                  ),
                ),
                child: Padding(
                  padding: AppSpacing.paddingLG,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Method header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getMethodColor(method['type']).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getMethodIcon(method['type']),
                              color: _getMethodColor(method['type']),
                              size: 24,
                            ),
                          ),
                          
                          const SizedBox(width: AppSpacing.md),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      method['label'] ?? 'Payment Method',
                                      style: context.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isDefault) ...[
                                      const SizedBox(width: AppSpacing.sm),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: context.colors.freshGreen,
                                          borderRadius: AppRadius.radiusSM,
                                        ),
                                        child: Text(
                                          'Default',
                                          style: context.textTheme.bodySmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  _getMaskedMethodDetails(method),
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              color: context.colors.textSecondary,
                            ),
                            onSelected: (action) => _handleMethodAction(action, method),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              if (!isDefault)
                                const PopupMenuItem(
                                  value: 'setDefault',
                                  child: Row(
                                    children: [
                                      Icon(Icons.star),
                                      SizedBox(width: 8),
                                      Text('Set as Default'),
                                    ],
                                  ),
                                ),
                              PopupMenuItem(
                                value: isActive ? 'disable' : 'enable',
                                child: Row(
                                  children: [
                                    Icon(isActive ? Icons.visibility_off : Icons.visibility),
                                    const SizedBox(width: 8),
                                    Text(isActive ? 'Disable' : 'Enable'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // Method details
                      Row(
                        children: [
                          _buildMethodDetail(
                            'Last Used',
                            _formatLastUsed(method['lastUsed']),
                            Icons.access_time,
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          _buildMethodDetail(
                            'Status',
                            isActive ? 'Active' : 'Disabled',
                            isActive ? Icons.check_circle : Icons.cancel,
                            color: isActive ? context.colors.freshGreen : Colors.red,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // Action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isActive ? () => _usePaymentMethod(method) : null,
                          icon: const Icon(Icons.payment, size: 16),
                          label: const Text('Use This Method'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.freshGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMethodDetail(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color ?? context.colors.textSecondary,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            Text(
              value,
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryFilters() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Row(
          children: [
            Icon(Icons.filter_list, color: context.colors.freshGreen),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Filter transactions',
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Chip(
              label: const Text('All Time'),
              backgroundColor: context.colors.freshGreen.withValues(alpha: 0.2),
              labelStyle: TextStyle(color: context.colors.freshGreen),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction, int index) {
    final status = transaction['status'] as String;
    final isSuccess = status == 'completed';
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
                child: Padding(
                  padding: AppSpacing.paddingLG,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transaction header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isSuccess 
                                  ? context.colors.freshGreen 
                                  : Colors.red).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSuccess ? Icons.check : Icons.close,
                              color: isSuccess ? context.colors.freshGreen : Colors.red,
                              size: 16,
                            ),
                          ),
                          
                          const SizedBox(width: AppSpacing.sm),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order ${transaction['orderId']}',
                                  style: context.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _formatTransactionDate(transaction['date']),
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
                                'KSh ${transaction['amount'].toStringAsFixed(2)}',
                                style: context.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSuccess ? context.colors.freshGreen : Colors.red,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isSuccess 
                                      ? context.colors.freshGreen 
                                      : Colors.red).withValues(alpha: 0.2),
                                  borderRadius: AppRadius.radiusSM,
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: isSuccess ? context.colors.freshGreen : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppSpacing.sm),
                      
                      // Transaction details
                      Row(
                        children: [
                          Icon(
                            Icons.phone_android,
                            size: 16,
                            color: context.colors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${transaction['method']} - ${transaction['methodDetails']}',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Ref: ${transaction['transactionCode']}',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                              fontFamily: 'monospace',
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
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: () => _addPaymentMethod(),
            backgroundColor: context.colors.freshGreen,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add Method',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.lg),
          Text('Loading payment methods...'),
        ],
      ),
    );
  }

  Widget _buildEmptyMethodsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment_outlined,
            size: 120,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'No payment methods',
            style: context.textTheme.headlineMedium?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add your M-Pesa or card details for faster checkout',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: () => _addPaymentMethod(),
            icon: const Icon(Icons.add),
            label: const Text('Add Payment Method'),
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

  Widget _buildEmptyHistoryState() {
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
            'No transaction history',
            style: context.textTheme.headlineMedium?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your payment history will appear here',
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getMethodIcon(String type) {
    switch (type.toLowerCase()) {
      case 'mpesa':
        return Icons.phone_android;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  Color _getMethodColor(String type) {
    switch (type.toLowerCase()) {
      case 'mpesa':
        return context.colors.freshGreen;
      case 'card':
        return context.colors.ecoBlue;
      default:
        return context.colors.textSecondary;
    }
  }

  String _getMaskedMethodDetails(Map<String, dynamic> method) {
    final type = method['type'] as String;
    switch (type.toLowerCase()) {
      case 'mpesa':
        final phone = method['phoneNumber'] as String;
        return '${phone.substring(0, 7)}***${phone.substring(phone.length - 2)}';
      case 'card':
        final cardNumber = method['cardNumber'] as String? ?? '****';
        return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
      default:
        return 'Unknown method';
    }
  }

  String _formatLastUsed(DateTime date) {
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

  String _formatTransactionDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _handleMethodAction(String action, Map<String, dynamic> method) {
    switch (action) {
      case 'edit':
        _editPaymentMethod(method);
        break;
      case 'setDefault':
        _setDefaultMethod(method);
        break;
      case 'disable':
      case 'enable':
        _toggleMethodStatus(method);
        break;
      case 'delete':
        _showDeleteConfirmation(method);
        break;
    }
  }

  void _addPaymentMethod() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAddPaymentMethodBottomSheet(),
    );
  }

  Widget _buildAddPaymentMethodBottomSheet() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add Payment Method',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.freshGreen.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.phone_android, color: context.colors.freshGreen),
            ),
            title: const Text('M-Pesa'),
            subtitle: const Text('Mobile money payment'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              _showAddMpesaDialog();
            },
          ),
          
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.textSecondary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.credit_card, color: context.colors.textSecondary),
            ),
            title: const Text('Credit/Debit Card'),
            subtitle: const Text('Coming soon'),
            trailing: const Icon(Icons.lock_outline),
            onTap: null, // Disabled for now
          ),
        ],
      ),
    );
  }

  void _showAddMpesaDialog() {
    final phoneController = TextEditingController();
    final labelController = TextEditingController();
    bool setAsDefault = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add M-Pesa Number'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'Label (e.g., Primary, Business)',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'M-Pesa Phone Number',
                  hintText: '254XXXXXXXXX',
                  prefixText: '+',
                  border: OutlineInputBorder(),
                ),
              ),
              
              CheckboxListTile(
                title: const Text('Set as default payment method'),
                value: setAsDefault,
                onChanged: (value) {
                  setState(() {
                    setAsDefault = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (phoneController.text.isNotEmpty && labelController.text.isNotEmpty) {
                  Navigator.pop(context);
                  _saveMpesaMethod(labelController.text, phoneController.text, setAsDefault);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.freshGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveMpesaMethod(String label, String phone, bool isDefault) {
    if (isDefault) {
      for (var method in _paymentMethods) {
        method['isDefault'] = false;
      }
    }
    
    final newMethod = {
      'id': 'mpesa_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'mpesa',
      'label': label,
      'phoneNumber': '+$phone',
      'isDefault': isDefault,
      'lastUsed': DateTime.now(),
      'isActive': true,
    };
    
    setState(() {
      _paymentMethods.add(newMethod);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label M-Pesa number added successfully'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }

  void _editPaymentMethod(Map<String, dynamic> method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit ${method['label']} functionality coming soon'),
        backgroundColor: context.colors.ecoBlue,
      ),
    );
  }

  void _setDefaultMethod(Map<String, dynamic> method) {
    setState(() {
      for (var m in _paymentMethods) {
        m['isDefault'] = m['id'] == method['id'];
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${method['label']} set as default payment method'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }

  void _toggleMethodStatus(Map<String, dynamic> method) {
    setState(() {
      method['isActive'] = !(method['isActive'] ?? true);
    });
    
    final status = method['isActive'] ? 'enabled' : 'disabled';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${method['label']} $status'),
        backgroundColor: context.colors.ecoBlue,
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text('Are you sure you want to delete "${method['label']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMethod(method);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteMethod(Map<String, dynamic> method) {
    setState(() {
      _paymentMethods.removeWhere((m) => m['id'] == method['id']);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${method['label']} deleted successfully'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }

  void _usePaymentMethod(Map<String, dynamic> method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${method['label']} selected for next payment'),
        backgroundColor: context.colors.freshGreen,
      ),
    );
  }
} 