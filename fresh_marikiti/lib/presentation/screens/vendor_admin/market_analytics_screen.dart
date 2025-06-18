import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fresh_marikiti/core/models/vendor_admin_models.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/utils/api_endpoints.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class MarketAnalyticsScreen extends StatefulWidget {
  const MarketAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<MarketAnalyticsScreen> createState() => _MarketAnalyticsScreenState();
}

class _MarketAnalyticsScreenState extends State<MarketAnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  MarketAnalytics? _analytics;
  List<VendorPerformance> _vendorPerformances = [];
  bool _isLoading = true;
  String _selectedPeriod = '7d';

  final List<String> _periods = ['7d', '30d', '90d', '1y'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final responses = await Future.wait([
        ApiService.get(ApiEndpoints.vendorAdminAnalytics(period: _selectedPeriod)),
        ApiService.get(ApiEndpoints.vendorAdminVendorPerformances(period: _selectedPeriod)),
      ]);

      if (responses.every((response) => response.statusCode == 200)) {
        final analyticsData = json.decode(responses[0].body);
        final performanceData = json.decode(responses[1].body);

        setState(() {
          _analytics = MarketAnalytics.fromJson(analyticsData['analytics']);
          _vendorPerformances = (performanceData['performances'] as List)
              .map((p) => VendorPerformance.fromJson(p))
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load analytics data');
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
          'Market Analytics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          DropdownButton<String>(
            value: _selectedPeriod,
            dropdownColor: const Color(0xFF2E7D32),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            underline: Container(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedPeriod = value);
                _loadAnalyticsData();
              }
            },
            items: _periods.map((period) {
              return DropdownMenuItem(
                value: period,
                child: Text(
                  _getPeriodLabel(period),
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadAnalyticsData(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Revenue', icon: Icon(Icons.monetization_on)),
            Tab(text: 'Vendors', icon: Icon(Icons.people)),
            Tab(text: 'Eco Points', icon: Icon(Icons.eco)),
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
                _buildVendorsTab(),
                _buildEcoPointsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_analytics == null) return const Center(child: Text('No data available'));

    return RefreshIndicator(
      onRefresh: () => _loadAnalyticsData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKPIGrid(),
            const SizedBox(height: 16),
            _buildPerformanceTrend(),
            const SizedBox(height: 16),
            _buildTopMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildKPICard(
          'Total Revenue',
          'KSh ${NumberFormat('#,###').format(_analytics!.totalRevenue)}',
          Icons.monetization_on,
          Colors.green,
          _analytics!.revenueGrowth,
        ),
        _buildKPICard(
          'Total Orders',
          NumberFormat('#,###').format(_analytics!.totalOrders),
          Icons.shopping_cart,
          Colors.blue,
          _analytics!.ordersGrowth,
        ),
        _buildKPICard(
          'Active Vendors',
          _analytics!.activeVendors.toString(),
          Icons.store,
          Colors.orange,
          0.0,
        ),
        _buildKPICard(
          'Eco Points',
          NumberFormat('#,###').format(_analytics!.totalEcoPoints),
          Icons.eco,
          Colors.teal,
          _analytics!.ecoPointsGrowth,
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color, double growth) {
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
                fontSize: 18,
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

  Widget _buildPerformanceTrend() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Trend (${_getPeriodLabel(_selectedPeriod)})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
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
                          if (value.toInt() >= 0 && value.toInt() < _analytics!.trendLabels.length) {
                            return Text(_analytics!.trendLabels[value.toInt()]);
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
                      spots: _analytics!.revenueData
                          .asMap()
                          .entries
                          .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                          .toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: _analytics!.ordersData
                          .asMap()
                          .entries
                          .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                          .toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
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
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Average Order Value',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'KSh ${NumberFormat('#,###').format(_analytics!.avgOrderValue)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'Per order',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Satisfaction',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_analytics!.avgRating.toStringAsFixed(1)} ⭐',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  Text(
                    'Average rating',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueTab() {
    return RefreshIndicator(
      onRefresh: () => _loadAnalyticsData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRevenueBreakdown(),
            const SizedBox(height: 16),
            _buildTopVendorsByRevenue(),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueBreakdown() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _analytics!.revenueByCategory.entries.map((entry) {
                    final index = _analytics!.revenueByCategory.keys.toList().indexOf(entry.key);
                    final colors = [Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.teal];
                    return PieChartSectionData(
                      value: entry.value,
                      title: '${((entry.value / _analytics!.totalRevenue) * 100).toStringAsFixed(1)}%',
                      color: colors[index % colors.length],
                      radius: 100,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: _analytics!.revenueByCategory.entries.map((entry) {
                final index = _analytics!.revenueByCategory.keys.toList().indexOf(entry.key);
                final colors = [Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.teal];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.key}: KSh ${NumberFormat('#,###').format(entry.value)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopVendorsByRevenue() {
    final topVendors = List<VendorPerformance>.from(_vendorPerformances)
      ..sort((a, b) => b.revenue.compareTo(a.revenue))
      ..take(10);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Vendors by Revenue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...topVendors.take(10).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final vendor = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: index < 3 ? Colors.amber : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor.vendorName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            vendor.stallName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'KSh ${NumberFormat('#,###').format(vendor.revenue)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorsTab() {
    return RefreshIndicator(
      onRefresh: () => _loadAnalyticsData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVendorMetrics(),
            const SizedBox(height: 16),
            _buildVendorPerformanceList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorMetrics() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vendor Performance Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Top Performer',
                    _vendorPerformances.isNotEmpty
                        ? _vendorPerformances.first.vendorName
                        : 'N/A',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Avg Revenue',
                    _vendorPerformances.isNotEmpty
                        ? 'KSh ${NumberFormat('#,###').format(_vendorPerformances.map((v) => v.revenue).reduce((a, b) => a + b) / _vendorPerformances.length)}'
                        : 'KSh 0',
                    Icons.monetization_on,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorPerformanceList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Vendor Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._vendorPerformances.map((vendor) => _buildVendorPerformanceCard(vendor)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorPerformanceCard(VendorPerformance vendor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  vendor.vendorName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                'KSh ${NumberFormat('#,###').format(vendor.revenue)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Orders: ${vendor.orders}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  'Rating: ${vendor.rating.toStringAsFixed(1)} ⭐',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  'Eco: ${vendor.ecoPoints}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEcoPointsTab() {
    return RefreshIndicator(
      onRefresh: () => _loadAnalyticsData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEcoPointsOverview(),
            const SizedBox(height: 16),
            _buildTopEcoPerformers(),
          ],
        ),
      ),
    );
  }

  Widget _buildEcoPointsOverview() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eco Points Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Total Points',
                    NumberFormat('#,###').format(_analytics!.totalEcoPoints),
                    Icons.eco,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Avg per Vendor',
                    _vendorPerformances.isNotEmpty
                        ? NumberFormat('#,###').format(_vendorPerformances.map((v) => v.ecoPoints).reduce((a, b) => a + b) / _vendorPerformances.length)
                        : '0',
                    Icons.person,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopEcoPerformers() {
    final topEcoVendors = List<VendorPerformance>.from(_vendorPerformances)
      ..sort((a, b) => b.ecoPoints.compareTo(a.ecoPoints))
      ..take(10);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Eco Performers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...topEcoVendors.take(10).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final vendor = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor.vendorName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            vendor.stallName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.eco, color: Colors.green[600], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          vendor.ecoPoints.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case '7d':
        return 'Last 7 Days';
      case '30d':
        return 'Last 30 Days';
      case '90d':
        return 'Last 3 Months';
      case '1y':
        return 'Last Year';
      default:
        return 'Unknown';
    }
  }
}

class MarketAnalytics {
  final double totalRevenue;
  final int totalOrders;
  final int activeVendors;
  final int totalEcoPoints;
  final double revenueGrowth;
  final double ordersGrowth;
  final double ecoPointsGrowth;
  final double avgOrderValue;
  final double avgRating;
  final Map<String, double> revenueByCategory;
  final List<double> revenueData;
  final List<double> ordersData;
  final List<String> trendLabels;

  MarketAnalytics({
    required this.totalRevenue,
    required this.totalOrders,
    required this.activeVendors,
    required this.totalEcoPoints,
    required this.revenueGrowth,
    required this.ordersGrowth,
    required this.ecoPointsGrowth,
    required this.avgOrderValue,
    required this.avgRating,
    required this.revenueByCategory,
    required this.revenueData,
    required this.ordersData,
    required this.trendLabels,
  });

  factory MarketAnalytics.fromJson(Map<String, dynamic> json) {
    return MarketAnalytics(
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      activeVendors: json['activeVendors'] ?? 0,
      totalEcoPoints: json['totalEcoPoints'] ?? 0,
      revenueGrowth: (json['revenueGrowth'] ?? 0).toDouble(),
      ordersGrowth: (json['ordersGrowth'] ?? 0).toDouble(),
      ecoPointsGrowth: (json['ecoPointsGrowth'] ?? 0).toDouble(),
      avgOrderValue: (json['avgOrderValue'] ?? 0).toDouble(),
      avgRating: (json['avgRating'] ?? 0).toDouble(),
      revenueByCategory: Map<String, double>.from(json['revenueByCategory'] ?? {}),
      revenueData: List<double>.from(json['revenueData'] ?? []),
      ordersData: List<double>.from(json['ordersData'] ?? []),
      trendLabels: List<String>.from(json['trendLabels'] ?? []),
    );
  }
}

class VendorPerformance {
  final String vendorId;
  final String vendorName;
  final String stallName;
  final double revenue;
  final int orders;
  final double rating;
  final int ecoPoints;

  VendorPerformance({
    required this.vendorId,
    required this.vendorName,
    required this.stallName,
    required this.revenue,
    required this.orders,
    required this.rating,
    required this.ecoPoints,
  });

  factory VendorPerformance.fromJson(Map<String, dynamic> json) {
    return VendorPerformance(
      vendorId: json['vendorId'] ?? '',
      vendorName: json['vendorName'] ?? '',
      stallName: json['stallName'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
      orders: json['orders'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      ecoPoints: json['ecoPoints'] ?? 0,
    );
  }
} 