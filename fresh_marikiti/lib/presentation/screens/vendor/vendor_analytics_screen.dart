import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/utils/api_endpoints.dart';
import 'package:fresh_marikiti/core/models/vendor_models.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class VendorAnalyticsScreen extends StatefulWidget {
  const VendorAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<VendorAnalyticsScreen> createState() => _VendorAnalyticsScreenState();
}

class _VendorAnalyticsScreenState extends State<VendorAnalyticsScreen>
    with TickerProviderStateMixin {
  AnalyticsData? _analyticsData;
  bool _isLoading = true;
  String _selectedPeriod = '7d';
  late TabController _tabController;

  final List<String> _periodOptions = ['7d', '30d', '90d', '1y'];
  final Map<String, String> _periodLabels = {
    '7d': 'Last 7 Days',
    '30d': 'Last 30 Days',
    '90d': 'Last 3 Months',
    '1y': 'Last Year',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.get(
        ApiEndpoints.vendorAnalytics(period: _selectedPeriod)
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _analyticsData = AnalyticsData.fromJson(data);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load analytics');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onSelected: (period) {
              setState(() {
                _selectedPeriod = period;
              });
              _loadAnalytics();
            },
            itemBuilder: (context) => _periodOptions.map((period) {
              return PopupMenuItem(
                value: period,
                child: Row(
                  children: [
                    Icon(
                      _selectedPeriod == period ? Icons.check : Icons.calendar_today,
                      size: 16,
                      color: _selectedPeriod == period ? const Color(0xFF2E7D32) : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(_periodLabels[period]!),
                  ],
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAnalytics,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Sales'),
            Tab(text: 'Products'),
            Tab(text: 'Customers'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analyticsData == null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildSalesTab(),
                      _buildProductsTab(),
                      _buildCustomersTab(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load analytics',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAnalytics,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2E7D32).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: const Color(0xFF2E7D32),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Analytics for ${_periodLabels[_selectedPeriod]}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Key Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildMetricCard(
                'Total Revenue',
                'KSh ${_analyticsData!.totalRevenue.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
                _analyticsData!.revenueGrowth,
              ),
              _buildMetricCard(
                'Total Orders',
                '${_analyticsData!.totalOrders}',
                Icons.shopping_cart,
                Colors.blue,
                _analyticsData!.ordersGrowth,
              ),
              _buildMetricCard(
                'Average Order',
                'KSh ${_analyticsData!.averageOrderValue.toStringAsFixed(2)}',
                Icons.receipt,
                Colors.purple,
                _analyticsData!.aovGrowth,
              ),
              _buildMetricCard(
                'Products Sold',
                '${_analyticsData!.totalProductsSold}',
                Icons.inventory,
                Colors.orange,
                _analyticsData!.productsSoldGrowth,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Revenue Chart
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Revenue Trend',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  'KSh ${(value / 1000).toStringAsFixed(0)}K',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < _analyticsData!.dailyRevenue.length) {
                                  final date = _analyticsData!.dailyRevenue[index].date;
                                  return Text(
                                    DateFormat('MM/dd').format(date),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _analyticsData!.dailyRevenue.asMap().entries.map((entry) {
                              return FlSpot(entry.key.toDouble(), entry.value.amount);
                            }).toList(),
                            isCurved: true,
                            color: const Color(0xFF2E7D32),
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF2E7D32).withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Stats
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Stats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickStat(
                        'Conversion Rate',
                        '${_analyticsData!.conversionRate.toStringAsFixed(1)}%',
                        Icons.trending_up,
                      ),
                      _buildQuickStat(
                        'Return Rate',
                        '${_analyticsData!.returnRate.toStringAsFixed(1)}%',
                        Icons.keyboard_return,
                      ),
                      _buildQuickStat(
                        'Avg Rating',
                        '${_analyticsData!.averageRating.toStringAsFixed(1)}',
                        Icons.star,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sales by Day Chart
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Sales',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < _analyticsData!.dailyOrders.length) {
                                  final date = _analyticsData!.dailyOrders[index].date;
                                  return Text(
                                    DateFormat('MM/dd').format(date),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        barGroups: _analyticsData!.dailyOrders.asMap().entries.map((entry) {
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(
                                toY: entry.value.count.toDouble(),
                                color: const Color(0xFF2E7D32),
                                width: 16,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Sales by Hour
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sales by Hour',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._analyticsData!.hourlyStats.map((stat) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text(
                            '${stat.hour}:00',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: stat.orders / _analyticsData!.hourlyStats.map((s) => s.orders).reduce((a, b) => a > b ? a : b),
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${stat.orders}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Payment Methods
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Methods',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: _analyticsData!.paymentMethods.map((method) {
                          final colors = [
                            const Color(0xFF2E7D32),
                            Colors.blue,
                            Colors.orange,
                            Colors.purple,
                          ];
                          final colorIndex = _analyticsData!.paymentMethods.indexOf(method) % colors.length;
                          
                          return PieChartSectionData(
                            value: method.percentage,
                            title: '${method.percentage.toStringAsFixed(1)}%',
                            color: colors[colorIndex],
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._analyticsData!.paymentMethods.map((method) {
                    final colors = [
                      const Color(0xFF2E7D32),
                      Colors.blue,
                      Colors.orange,
                      Colors.purple,
                    ];
                    final colorIndex = _analyticsData!.paymentMethods.indexOf(method) % colors.length;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: colors[colorIndex],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(method.method),
                          ),
                          Text(
                            '${method.percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Products
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Selling Products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._analyticsData!.topProducts.take(5).map((product) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: product.image != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    product.image!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(Icons.image, color: Colors.grey[400]),
                                  ),
                                )
                              : Icon(Icons.image, color: Colors.grey[400]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${product.quantitySold} sold • KSh ${product.revenue.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '#${_analyticsData!.topProducts.indexOf(product) + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Category Performance
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category Performance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._analyticsData!.categoryStats.map((category) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              category.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'KSh ${category.revenue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: category.revenue / _analyticsData!.categoryStats.map((c) => c.revenue).reduce((a, b) => a > b ? a : b),
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${category.productsSold} products sold',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Stats
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildMetricCard(
                'Total Customers',
                '${_analyticsData!.totalCustomers}',
                Icons.people,
                Colors.blue,
                _analyticsData!.customersGrowth,
              ),
              _buildMetricCard(
                'New Customers',
                '${_analyticsData!.newCustomers}',
                Icons.person_add,
                Colors.green,
                null,
              ),
              _buildMetricCard(
                'Repeat Customers',
                '${_analyticsData!.repeatCustomers}',
                Icons.repeat,
                Colors.purple,
                null,
              ),
              _buildMetricCard(
                'Customer LTV',
                'KSh ${_analyticsData!.customerLifetimeValue.toStringAsFixed(2)}',
                Icons.monetization_on,
                Colors.orange,
                null,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Top Customers
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Customers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._analyticsData!.topCustomers.take(5).map((customer) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF2E7D32),
                          child: Text(
                            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${customer.totalOrders} orders • KSh ${customer.totalSpent.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '#${_analyticsData!.topCustomers.indexOf(customer) + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, double? growth) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                if (growth != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: growth >= 0 ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// Data Models
class AnalyticsData {
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final int totalProductsSold;
  final double revenueGrowth;
  final double ordersGrowth;
  final double aovGrowth;
  final double productsSoldGrowth;
  final double conversionRate;
  final double returnRate;
  final double averageRating;
  final int totalCustomers;
  final int newCustomers;
  final int repeatCustomers;
  final double customersGrowth;
  final double customerLifetimeValue;
  final List<DailyData> dailyRevenue;
  final List<DailyData> dailyOrders;
  final List<HourlyStats> hourlyStats;
  final List<PaymentMethodStats> paymentMethods;
  final List<ProductStats> topProducts;
  final List<CategoryStats> categoryStats;
  final List<CustomerStats> topCustomers;

  AnalyticsData({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.totalProductsSold,
    required this.revenueGrowth,
    required this.ordersGrowth,
    required this.aovGrowth,
    required this.productsSoldGrowth,
    required this.conversionRate,
    required this.returnRate,
    required this.averageRating,
    required this.totalCustomers,
    required this.newCustomers,
    required this.repeatCustomers,
    required this.customersGrowth,
    required this.customerLifetimeValue,
    required this.dailyRevenue,
    required this.dailyOrders,
    required this.hourlyStats,
    required this.paymentMethods,
    required this.topProducts,
    required this.categoryStats,
    required this.topCustomers,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      averageOrderValue: (json['averageOrderValue'] ?? 0).toDouble(),
      totalProductsSold: json['totalProductsSold'] ?? 0,
      revenueGrowth: (json['revenueGrowth'] ?? 0).toDouble(),
      ordersGrowth: (json['ordersGrowth'] ?? 0).toDouble(),
      aovGrowth: (json['aovGrowth'] ?? 0).toDouble(),
      productsSoldGrowth: (json['productsSoldGrowth'] ?? 0).toDouble(),
      conversionRate: (json['conversionRate'] ?? 0).toDouble(),
      returnRate: (json['returnRate'] ?? 0).toDouble(),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalCustomers: json['totalCustomers'] ?? 0,
      newCustomers: json['newCustomers'] ?? 0,
      repeatCustomers: json['repeatCustomers'] ?? 0,
      customersGrowth: (json['customersGrowth'] ?? 0).toDouble(),
      customerLifetimeValue: (json['customerLifetimeValue'] ?? 0).toDouble(),
      dailyRevenue: (json['dailyRevenue'] as List<dynamic>? ?? [])
          .map((item) => DailyData.fromJson(item))
          .toList(),
      dailyOrders: (json['dailyOrders'] as List<dynamic>? ?? [])
          .map((item) => DailyData.fromJson(item))
          .toList(),
      hourlyStats: (json['hourlyStats'] as List<dynamic>? ?? [])
          .map((item) => HourlyStats.fromJson(item))
          .toList(),
      paymentMethods: (json['paymentMethods'] as List<dynamic>? ?? [])
          .map((item) => PaymentMethodStats.fromJson(item))
          .toList(),
      topProducts: (json['topProducts'] as List<dynamic>? ?? [])
          .map((item) => ProductStats.fromJson(item))
          .toList(),
      categoryStats: (json['categoryStats'] as List<dynamic>? ?? [])
          .map((item) => CategoryStats.fromJson(item))
          .toList(),
      topCustomers: (json['topCustomers'] as List<dynamic>? ?? [])
          .map((item) => CustomerStats.fromJson(item))
          .toList(),
    );
  }
}

class DailyData {
  final DateTime date;
  final double amount;
  final int count;

  DailyData({
    required this.date,
    required this.amount,
    required this.count,
  });

  factory DailyData.fromJson(Map<String, dynamic> json) {
    return DailyData(
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      amount: (json['amount'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class HourlyStats {
  final int hour;
  final int orders;
  final double revenue;

  HourlyStats({
    required this.hour,
    required this.orders,
    required this.revenue,
  });

  factory HourlyStats.fromJson(Map<String, dynamic> json) {
    return HourlyStats(
      hour: json['hour'] ?? 0,
      orders: json['orders'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class PaymentMethodStats {
  final String method;
  final double percentage;
  final int count;

  PaymentMethodStats({
    required this.method,
    required this.percentage,
    required this.count,
  });

  factory PaymentMethodStats.fromJson(Map<String, dynamic> json) {
    return PaymentMethodStats(
      method: json['method'] ?? 'Unknown',
      percentage: (json['percentage'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class ProductStats {
  final String id;
  final String name;
  final String? image;
  final int quantitySold;
  final double revenue;

  ProductStats({
    required this.id,
    required this.name,
    this.image,
    required this.quantitySold,
    required this.revenue,
  });

  factory ProductStats.fromJson(Map<String, dynamic> json) {
    return ProductStats(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Product',
      image: json['image'],
      quantitySold: json['quantitySold'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class CategoryStats {
  final String name;
  final int productsSold;
  final double revenue;

  CategoryStats({
    required this.name,
    required this.productsSold,
    required this.revenue,
  });

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      name: json['name'] ?? 'Unknown Category',
      productsSold: json['productsSold'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class CustomerStats {
  final String id;
  final String name;
  final int totalOrders;
  final double totalSpent;

  CustomerStats({
    required this.id,
    required this.name,
    required this.totalOrders,
    required this.totalSpent,
  });

  factory CustomerStats.fromJson(Map<String, dynamic> json) {
    return CustomerStats(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Customer',
      totalOrders: json['totalOrders'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
    );
  }
} 