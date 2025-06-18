import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fresh_marikiti/core/models/admin_models.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/utils/api_endpoints.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  BusinessReport? _businessReport;
  bool _isLoading = true;
  String _selectedPeriod = '30d';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  final List<String> _periods = ['7d', '30d', '90d', '1y', 'custom'];
  final List<String> _periodLabels = ['7 Days', '30 Days', '90 Days', '1 Year', 'Custom'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadBusinessReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessReport({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      String dateRange = _selectedPeriod;
      if (_selectedPeriod == 'custom') {
        dateRange = '${DateFormat('yyyy-MM-dd').format(_startDate)}_${DateFormat('yyyy-MM-dd').format(_endDate)}';
      }

      final response = await ApiService.get(
        ApiEndpoints.adminReportsBusiness(period: dateRange)
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        setState(() {
          _businessReport = BusinessReport.fromJson(data['report']);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load business report');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportReport(String format) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      String dateRange = _selectedPeriod;
      if (_selectedPeriod == 'custom') {
        dateRange = '${DateFormat('yyyy-MM-dd').format(_startDate)}_${DateFormat('yyyy-MM-dd').format(_endDate)}';
      }

      final response = await ApiService.post(
        ApiEndpoints.adminReportsExport,
        {
          'period': dateRange,
          'format': format,
          'type': 'business',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report exported as $format successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to export report');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting report: ${e.toString()}'),
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
          'Business Reports',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download, color: Colors.white),
            onSelected: (format) => _exportReport(format),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf),
                    SizedBox(width: 8),
                    Text('Export as PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 8),
                    Text('Export as Excel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.description),
                    SizedBox(width: 8),
                    Text('Export as CSV'),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onSelected: (period) {
              if (period == 'custom') {
                _showCustomDatePicker();
              } else {
                setState(() {
                  _selectedPeriod = period;
                });
                _loadBusinessReport();
              }
            },
            itemBuilder: (context) => _periods.map((period) {
              final index = _periods.indexOf(period);
              return PopupMenuItem(
                value: period,
                child: Row(
                  children: [
                    if (_selectedPeriod == period)
                      const Icon(Icons.check, color: Colors.green),
                    if (_selectedPeriod == period)
                      const SizedBox(width: 8),
                    Text(_periodLabels[index]),
                  ],
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadBusinessReport(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Revenue', icon: Icon(Icons.monetization_on)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Orders', icon: Icon(Icons.shopping_cart)),
            Tab(text: 'Performance', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildRevenueTab(),
                _buildUsersTab(),
                _buildOrdersTab(),
                _buildPerformanceTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_businessReport == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () => _loadBusinessReport(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodHeader(),
            const SizedBox(height: 16),
            _buildKPIGrid(),
            const SizedBox(height: 16),
            _buildRevenueTrend(),
            const SizedBox(height: 16),
            _buildTopMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodHeader() {
    String periodText = _selectedPeriod == 'custom'
        ? '${DateFormat('MMM dd').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}'
        : _periodLabels[_periods.indexOf(_selectedPeriod)];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2E7D32),
              const Color(0xFF2E7D32).withOpacity(0.8),
            ],
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.assessment, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Business Intelligence Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Period: $periodText',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
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

  Widget _buildKPIGrid() {
    if (_businessReport == null) return const SizedBox.shrink();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildKPICard(
          'Total Revenue',
          'KSh ${NumberFormat('#,###').format(_businessReport!.totalRevenue)}',
          _businessReport!.revenueGrowth,
          Icons.monetization_on,
          Colors.green,
        ),
        _buildKPICard(
          'Total Orders',
          NumberFormat('#,###').format(_businessReport!.totalOrders),
          _businessReport!.ordersGrowth,
          Icons.shopping_cart,
          Colors.blue,
        ),
        _buildKPICard(
          'Active Users',
          NumberFormat('#,###').format(_businessReport!.activeUsers),
          _businessReport!.usersGrowth,
          Icons.people,
          Colors.purple,
        ),
        _buildKPICard(
          'Avg Order Value',
          'KSh ${_businessReport!.avgOrderValue.toStringAsFixed(0)}',
          _businessReport!.aovGrowth,
          Icons.trending_up,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, double growth, IconData icon, Color color) {
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
                Icon(icon, color: color, size: 28),
                if (growth != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: growth > 0 ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          growth > 0 ? Icons.trending_up : Icons.trending_down,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${growth.abs().toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Spacer(),
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

  Widget _buildRevenueTrend() {
    if (_businessReport?.revenueChart == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < _businessReport!.chartLabels.length) {
                            return Text(_businessReport!.chartLabels[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _businessReport!.revenueChart
                          .asMap()
                          .entries
                          .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                          .toList(),
                      isCurved: true,
                      color: const Color(0xFF2E7D32),
                      barWidth: 3,
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
    );
  }

  Widget _buildTopMetrics() {
    if (_businessReport == null) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTopVendorsCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildTopProductsCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTopCustomersCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildTopRidersCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildTopVendorsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Vendors',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...(_businessReport!.topVendors.take(3).map((vendor) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vendor.name,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'KSh ${NumberFormat('#,###').format(vendor.revenue)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Products',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...(_businessReport!.topProducts.take(3).map((product) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${product.sales} sold',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCustomersCard() {
    return Card(
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
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...(_businessReport!.topCustomers.take(3).map((customer) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customer.name,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${customer.orders} orders',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRidersCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Riders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...(_businessReport!.topRiders.take(3).map((rider) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rider.name,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${rider.deliveries} trips',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueTab() {
    return const Center(
      child: Text('Revenue Analytics Tab - Implementation in progress'),
    );
  }

  Widget _buildUsersTab() {
    return const Center(
      child: Text('Users Analytics Tab - Implementation in progress'),
    );
  }

  Widget _buildOrdersTab() {
    return const Center(
      child: Text('Orders Analytics Tab - Implementation in progress'),
    );
  }

  Widget _buildPerformanceTab() {
    return const Center(
      child: Text('Performance Analytics Tab - Implementation in progress'),
    );
  }

  void _showCustomDatePicker() {
    showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    ).then((range) {
      if (range != null) {
        setState(() {
          _selectedPeriod = 'custom';
          _startDate = range.start;
          _endDate = range.end;
        });
        _loadBusinessReport();
      }
    });
  }
}

class BusinessReport {
  final double totalRevenue;
  final int totalOrders;
  final int activeUsers;
  final double avgOrderValue;
  final double revenueGrowth;
  final double ordersGrowth;
  final double usersGrowth;
  final double aovGrowth;
  final List<double> revenueChart;
  final List<String> chartLabels;
  final List<TopVendor> topVendors;
  final List<TopProduct> topProducts;
  final List<TopCustomer> topCustomers;
  final List<TopRider> topRiders;

  BusinessReport({
    required this.totalRevenue,
    required this.totalOrders,
    required this.activeUsers,
    required this.avgOrderValue,
    required this.revenueGrowth,
    required this.ordersGrowth,
    required this.usersGrowth,
    required this.aovGrowth,
    required this.revenueChart,
    required this.chartLabels,
    required this.topVendors,
    required this.topProducts,
    required this.topCustomers,
    required this.topRiders,
  });

  factory BusinessReport.fromJson(Map<String, dynamic> json) {
    return BusinessReport(
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      avgOrderValue: (json['avgOrderValue'] ?? 0).toDouble(),
      revenueGrowth: (json['revenueGrowth'] ?? 0).toDouble(),
      ordersGrowth: (json['ordersGrowth'] ?? 0).toDouble(),
      usersGrowth: (json['usersGrowth'] ?? 0).toDouble(),
      aovGrowth: (json['aovGrowth'] ?? 0).toDouble(),
      revenueChart: List<double>.from(json['revenueChart'] ?? []),
      chartLabels: List<String>.from(json['chartLabels'] ?? []),
      topVendors: (json['topVendors'] as List? ?? [])
          .map((v) => TopVendor.fromJson(v))
          .toList(),
      topProducts: (json['topProducts'] as List? ?? [])
          .map((p) => TopProduct.fromJson(p))
          .toList(),
      topCustomers: (json['topCustomers'] as List? ?? [])
          .map((c) => TopCustomer.fromJson(c))
          .toList(),
      topRiders: (json['topRiders'] as List? ?? [])
          .map((r) => TopRider.fromJson(r))
          .toList(),
    );
  }
}

class TopVendor {
  final String name;
  final double revenue;

  TopVendor({required this.name, required this.revenue});

  factory TopVendor.fromJson(Map<String, dynamic> json) {
    return TopVendor(
      name: json['name'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class TopProduct {
  final String name;
  final int sales;

  TopProduct({required this.name, required this.sales});

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      name: json['name'] ?? '',
      sales: json['sales'] ?? 0,
    );
  }
}

class TopCustomer {
  final String name;
  final int orders;

  TopCustomer({required this.name, required this.orders});

  factory TopCustomer.fromJson(Map<String, dynamic> json) {
    return TopCustomer(
      name: json['name'] ?? '',
      orders: json['orders'] ?? 0,
    );
  }
}

class TopRider {
  final String name;
  final int deliveries;

  TopRider({required this.name, required this.deliveries});

  factory TopRider.fromJson(Map<String, dynamic> json) {
    return TopRider(
      name: json['name'] ?? '',
      deliveries: json['deliveries'] ?? 0,
    );
  }
} 