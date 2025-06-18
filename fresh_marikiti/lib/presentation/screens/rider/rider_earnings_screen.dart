import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'dart:convert';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

enum EarningsPeriod { today, week, month, year }

class EarningsData {
  final double totalEarnings;
  final double deliveryFees;
  final double platformCommission;
  final double bonuses;
  final double tips;
  final int totalDeliveries;
  final int totalHours;
  final double avgEarningsPerDelivery;
  final double avgEarningsPerHour;
  final DateTime lastUpdated;

  EarningsData({
    required this.totalEarnings,
    required this.deliveryFees,
    required this.platformCommission,
    required this.bonuses,
    required this.tips,
    required this.totalDeliveries,
    required this.totalHours,
    required this.avgEarningsPerDelivery,
    required this.avgEarningsPerHour,
    required this.lastUpdated,
  });

  factory EarningsData.fromJson(Map<String, dynamic> json) {
    return EarningsData(
      totalEarnings: (json['total_earnings'] ?? 0).toDouble(),
      deliveryFees: (json['delivery_fees'] ?? 0).toDouble(),
      platformCommission: (json['platform_commission'] ?? 0).toDouble(),
      bonuses: (json['bonuses'] ?? 0).toDouble(),
      tips: (json['tips'] ?? 0).toDouble(),
      totalDeliveries: json['total_deliveries'] ?? 0,
      totalHours: json['total_hours'] ?? 0,
      avgEarningsPerDelivery: (json['avg_earnings_per_delivery'] ?? 0).toDouble(),
      avgEarningsPerHour: (json['avg_earnings_per_hour'] ?? 0).toDouble(),
      lastUpdated: DateTime.parse(json['last_updated'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class PaymentHistory {
  final String id;
  final double amount;
  final String status;
  final String paymentMethod;
  final DateTime processedAt;
  final String reference;
  final Map<String, dynamic> breakdown;

  PaymentHistory({
    required this.id,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.processedAt,
    required this.reference,
    required this.breakdown,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      id: json['id'],
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentMethod: json['payment_method'] ?? 'bank_transfer',
      processedAt: DateTime.parse(json['processed_at']),
      reference: json['reference'] ?? '',
      breakdown: json['breakdown'] ?? {},
    );
  }
}

class RiderEarningsScreen extends StatefulWidget {
  const RiderEarningsScreen({super.key});

  @override
  State<RiderEarningsScreen> createState() => _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends State<RiderEarningsScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final ScrollController _scrollController = ScrollController();
  
  EarningsPeriod _selectedPeriod = EarningsPeriod.week;
  EarningsData? _earningsData;
  List<PaymentHistory> _paymentHistory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: 3, vsync: this);
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
    
    _loadEarningsData();
    _animationController.forward();
    
    LoggerService.info('Rider earnings screen initialized', tag: 'RiderEarningsScreen');
  }

  Future<void> _loadEarningsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final periodParam = _selectedPeriod.toString().split('.').last;
      
      // Load earnings data
      final earningsResponse = await ApiService.get('/rider/earnings?period=$periodParam');
      
      if (earningsResponse.statusCode == 200) {
        final earningsJson = json.decode(earningsResponse.body);
        
        // Load payment history
        final paymentsResponse = await ApiService.get('/rider/payments?limit=50');
        
        if (paymentsResponse.statusCode == 200) {
          final paymentsJson = json.decode(paymentsResponse.body);
          
          if (mounted) {
            setState(() {
              _earningsData = EarningsData.fromJson(earningsJson['data']);
              _paymentHistory = (paymentsJson['data'] as List)
                  .map((payment) => PaymentHistory.fromJson(payment))
                  .toList();
              _isLoading = false;
            });
          }
        } else {
          throw Exception('Failed to load payment history: ${paymentsResponse.statusCode}');
        }
      } else {
        throw Exception('Failed to load earnings: ${earningsResponse.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to load earnings data', error: e, tag: 'RiderEarningsScreen');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _requestPayout() async {
    try {
      final response = await ApiService.post('/rider/request-payout', {
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Payout request submitted successfully'),
              backgroundColor: context.colors.freshGreen,
            ),
          );
          _loadEarningsData(); // Refresh data
        }
      } else {
        throw Exception('Failed to request payout: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request payout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          appBar: _buildAppBar(),
          body: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: _isLoading
                    ? _buildLoadingState()
                    : _error != null
                        ? _buildErrorState()
                        : Column(
                            children: [
                              _buildPeriodSelector(),
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
        'Earnings & Payments',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _loadEarningsData(),
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.account_balance_wallet),
          onPressed: _requestPayout,
          tooltip: 'Request Payout',
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
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
      child: Row(
        children: EarningsPeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
                _loadEarningsData();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? context.colors.ecoBlue : Colors.transparent,
                  borderRadius: AppRadius.radiusMD,
                  border: Border.all(
                    color: isSelected ? context.colors.ecoBlue : context.colors.outline,
                  ),
                ),
                child: Text(
                  _getPeriodLabel(period),
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: isSelected ? Colors.white : context.colors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
        tabs: const [
          Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 20)),
          Tab(text: 'Breakdown', icon: Icon(Icons.pie_chart, size: 20)),
          Tab(text: 'Payments', icon: Icon(Icons.payment, size: 20)),
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
        _buildOverviewTab(),
        _buildBreakdownTab(),
        _buildPaymentsTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    if (_earningsData == null) return const SizedBox.shrink();
    
    return RefreshIndicator(
      onRefresh: _loadEarningsData,
      color: context.colors.ecoBlue,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: AppSpacing.paddingMD,
        child: Column(
          children: [
            _buildEarningsSummaryCard(),
            const SizedBox(height: AppSpacing.md),
            _buildPerformanceMetrics(),
            const SizedBox(height: AppSpacing.md),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsSummaryCard() {
    return Container(
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
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Earnings',
                      style: context.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    Text(
                      'KSh ${_earningsData!.totalEarnings.toStringAsFixed(0)}',
                      style: context.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
                  _getPeriodLabel(_selectedPeriod),
                  style: const TextStyle(
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
              _buildEarningsMetric(
                'Deliveries',
                '${_earningsData!.totalDeliveries}',
                Icons.local_shipping,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildEarningsMetric(
                'Avg/Delivery',
                'KSh ${_earningsData!.avgEarningsPerDelivery.toStringAsFixed(0)}',
                Icons.attach_money,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildEarningsMetric(
                'Hours',
                '${_earningsData!.totalHours}h',
                Icons.access_time,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildEarningsMetric(
                'Avg/Hour',
                'KSh ${_earningsData!.avgEarningsPerHour.toStringAsFixed(0)}',
                Icons.trending_up,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsMetric(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
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
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Acceptance Rate',
                    '95%',
                    Icons.check_circle,
                    context.colors.freshGreen,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildMetricCard(
                    'On-Time Rate',
                    '92%',
                    Icons.schedule,
                    context.colors.ecoBlue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.sm),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Customer Rating',
                    '4.8 ⭐',
                    Icons.star,
                    context.colors.marketOrange,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildMetricCard(
                    'Completion Rate',
                    '98%',
                    Icons.assignment_turned_in,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.radiusMD,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: context.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _requestPayout,
                    icon: const Icon(Icons.payment),
                    label: const Text('Request Payout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.freshGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => NavigationService.toRiderAnalytics(),
                    icon: const Icon(Icons.analytics),
                    label: const Text('View Analytics'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.colors.ecoBlue),
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

  Widget _buildBreakdownTab() {
    if (_earningsData == null) return const SizedBox.shrink();
    
    return SingleChildScrollView(
      padding: AppSpacing.paddingMD,
      child: Column(
        children: [
          _buildEarningsBreakdownCard(),
          const SizedBox(height: AppSpacing.md),
          _buildCommissionTransparency(),
        ],
      ),
    );
  }

  Widget _buildEarningsBreakdownCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings Breakdown',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            _buildBreakdownItem(
              'Delivery Fees',
              _earningsData!.deliveryFees,
              context.colors.ecoBlue,
              isPositive: true,
            ),
            _buildBreakdownItem(
              'Bonuses',
              _earningsData!.bonuses,
              context.colors.freshGreen,
              isPositive: true,
            ),
            _buildBreakdownItem(
              'Tips',
              _earningsData!.tips,
              context.colors.marketOrange,
              isPositive: true,
            ),
            _buildBreakdownItem(
              'Platform Commission (5%)',
              _earningsData!.platformCommission,
              Colors.red,
              isPositive: false,
            ),
            
            const Divider(),
            
            _buildBreakdownItem(
              'Total Earnings',
              _earningsData!.totalEarnings,
              context.colors.freshGreen,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(String label, double amount, Color color, {bool isPositive = true, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '${isPositive ? '+' : '-'} KSh ${amount.toStringAsFixed(0)}',
            style: context.textTheme.bodyMedium?.copyWith(
              color: isTotal ? context.colors.freshGreen : color,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionTransparency() {
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
                Icon(
                  Icons.info_outline,
                  color: context.colors.ecoBlue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Commission Transparency',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.ecoBlue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            Container(
              padding: AppSpacing.paddingMD,
              decoration: BoxDecoration(
                color: context.colors.ecoBlue.withValues(alpha: 0.1),
                borderRadius: AppRadius.radiusMD,
              ),
              child: Column(
                children: [
                  Text(
                    'Fresh Marikiti takes only 5% commission from delivery fees to maintain our platform and provide you with:',
                    style: context.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Column(
                    children: [
                      '• 24/7 customer support',
                      '• Insurance coverage',
                      '• App maintenance & updates',
                      '• Marketing & customer acquisition',
                      '• Payment processing',
                    ].map((benefit) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check,
                            size: 16,
                            color: context.colors.freshGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              benefit.substring(2),
                              style: context.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return RefreshIndicator(
      onRefresh: _loadEarningsData,
      color: context.colors.ecoBlue,
      child: _paymentHistory.isEmpty
          ? _buildEmptyPayments()
          : ListView.builder(
              padding: AppSpacing.paddingMD,
              itemCount: _paymentHistory.length,
              itemBuilder: (context, index) {
                final payment = _paymentHistory[index];
                return _buildPaymentCard(payment);
              },
            ),
    );
  }

  Widget _buildPaymentCard(PaymentHistory payment) {
    Color statusColor = payment.status == 'completed' 
        ? context.colors.freshGreen
        : payment.status == 'pending'
            ? context.colors.marketOrange
            : Colors.red;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
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
                    payment.status == 'completed' 
                        ? Icons.check_circle
                        : payment.status == 'pending'
                            ? Icons.schedule
                            : Icons.error,
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
                        'KSh ${payment.amount.toStringAsFixed(0)}',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ref: ${payment.reference}',
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: AppRadius.radiusSM,
                      ),
                      child: Text(
                        payment.status.toUpperCase(),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(payment.processedAt),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
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

  Widget _buildEmptyPayments() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment,
            size: 64,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No payments yet',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textSecondary,
            ),
          ),
          Text(
            'Complete deliveries to start earning',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Failed to load earnings',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          Text(
            _error ?? 'Unknown error occurred',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: _loadEarningsData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel(EarningsPeriod period) {
    switch (period) {
      case EarningsPeriod.today:
        return 'Today';
      case EarningsPeriod.week:
        return 'This Week';
      case EarningsPeriod.month:
        return 'This Month';
      case EarningsPeriod.year:
        return 'This Year';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Recent';
    }
  }
} 