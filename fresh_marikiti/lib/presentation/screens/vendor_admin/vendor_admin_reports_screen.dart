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

class VendorAdminReportsScreen extends StatefulWidget {
  const VendorAdminReportsScreen({Key? key}) : super(key: key);

  @override
  State<VendorAdminReportsScreen> createState() => _VendorAdminReportsScreenState();
}

class _VendorAdminReportsScreenState extends State<VendorAdminReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  MarketReport? _report;
  bool _isLoading = true;
  String _selectedPeriod = '30d';
  DateTimeRange? _customDateRange;
  bool _isGenerating = false;
  bool _isExporting = false;

  final List<String> _periods = ['7d', '30d', '90d', '1y', 'custom'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadReport();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReport({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.get(
        ApiEndpoints.vendorAdminReports(period: _selectedPeriod)
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        setState(() {
          _report = MarketReport.fromJson(data['report']);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load report');
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

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.get(
        ApiEndpoints.vendorAdminReports(period: _selectedPeriod)
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _report = MarketReport.fromJson(data['report']);
          _isGenerating = false;
        });
      } else {
        throw Exception('Failed to generate report');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportReport(String format) async {
    setState(() => _isExporting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.get(
        ApiEndpoints.vendorAdminReportsExport(format: format, period: _selectedPeriod)
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report exported as $format successfully. Download URL: ${data['downloadUrl']}'),
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
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Market Reports',
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
            onSelected: _exportReport,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Export as PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Export as Excel'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.description, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Export as CSV'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadReport(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
                  Tab(text: 'Financial', icon: Icon(Icons.monetization_on)),
                  Tab(text: 'Operational', icon: Icon(Icons.business)),
                  Tab(text: 'Detailed', icon: Icon(Icons.list_alt)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPeriod,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _periods.map((period) {
                          return DropdownMenuItem(
                            value: period,
                            child: Text(_getPeriodLabel(period)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPeriod = value);
                            if (value == 'custom') {
                              _selectDateRange();
                            } else {
                              _loadReport();
                            }
                          }
                        },
                      ),
                    ),
                    if (_selectedPeriod == 'custom' && _customDateRange != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Text(
                            '${DateFormat('MMM dd').format(_customDateRange!.start)} - ${DateFormat('MMM dd').format(_customDateRange!.end)}',
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildFinancialTab(),
                _buildOperationalTab(),
                _buildDetailedTab(),
              ],
            ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange,
    );
    
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
      });
      _loadReport();
    }
  }

  Widget _buildOverviewTab() {
    if (_report == null) return const Center(child: Text('No data available'));

    return RefreshIndicator(
      onRefresh: () => _loadReport(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportHeader(),
            const SizedBox(height: 16),
            _buildKPICards(),
            const SizedBox(height: 16),
            _buildTrendChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHeader() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2E7D32),
              const Color(0xFF4CAF50),
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Market Report',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getPeriodLabel(_selectedPeriod),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.assessment,
              color: Colors.white,
              size: 48,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICards() {
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
          'KSh ${NumberFormat('#,###').format(_report!.totalRevenue)}',
          Icons.monetization_on,
          Colors.green,
          _report!.revenueGrowth,
        ),
        _buildKPICard(
          'Total Orders',
          NumberFormat('#,###').format(_report!.totalOrders),
          Icons.shopping_cart,
          Colors.blue,
          _report!.ordersGrowth,
        ),
        _buildKPICard(
          'Active Vendors',
          _report!.activeVendors.toString(),
          Icons.store,
          Colors.orange,
          0.0,
        ),
        _buildKPICard(
          'Customer Satisfaction',
          '${_report!.avgRating.toStringAsFixed(1)} ⭐',
          Icons.star,
          Colors.amber,
          0.0,
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

  Widget _buildTrendChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Trend (${_getPeriodLabel(_selectedPeriod)})',
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
                          if (value.toInt() >= 0 && value.toInt() < _report!.trendLabels.length) {
                            return Text(_report!.trendLabels[value.toInt()]);
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
                      spots: _report!.revenueData
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

  Widget _buildFinancialTab() {
    return RefreshIndicator(
      onRefresh: () => _loadReport(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFinancialSummary(),
            const SizedBox(height: 16),
            _buildRevenueBreakdown(),
            const SizedBox(height: 16),
            _buildPaymentMethods(),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financial Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFinancialItem('Gross Revenue', _report!.totalRevenue, Colors.green),
            _buildFinancialItem('Commission (5%)', _report!.totalRevenue * 0.05, Colors.orange),
            _buildFinancialItem('Net Revenue', _report!.totalRevenue * 0.95, Colors.blue),
            const Divider(height: 32),
            _buildFinancialItem('Average Order Value', _report!.avgOrderValue, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialItem(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'KSh ${NumberFormat('#,###').format(amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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
              'Revenue by Category',
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
                  sections: _report!.revenueByCategory.entries.map((entry) {
                    final index = _report!.revenueByCategory.keys.toList().indexOf(entry.key);
                    final colors = [Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.teal];
                    return PieChartSectionData(
                      value: entry.value,
                      title: '${((entry.value / _report!.totalRevenue) * 100).toStringAsFixed(1)}%',
                      color: colors[index % colors.length],
                      radius: 100,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            ..._report!.paymentMethods.entries.map((entry) => _buildPaymentMethodItem(entry.key, entry.value)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodItem(String method, double amount) {
    final percentage = (amount / _report!.totalRevenue) * 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                method,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'KSh ${NumberFormat('#,###').format(amount)} (${percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalTab() {
    return RefreshIndicator(
      onRefresh: () => _loadReport(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOperationalMetrics(),
            const SizedBox(height: 16),
            _buildVendorPerformance(),
            const SizedBox(height: 16),
            _buildCustomerMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationalMetrics() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Operational Metrics',
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
                    'Total Orders',
                    _report!.totalOrders.toString(),
                    Icons.shopping_cart,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Completed',
                    _report!.completedOrders.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Cancelled',
                    _report!.cancelledOrders.toString(),
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Success Rate',
                    '${((_report!.completedOrders / _report!.totalOrders) * 100).toStringAsFixed(1)}%',
                    Icons.trending_up,
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

  Widget _buildVendorPerformance() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vendor Performance',
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
                    'Active Vendors',
                    _report!.activeVendors.toString(),
                    Icons.store,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Avg Rating',
                    '${_report!.avgRating.toStringAsFixed(1)} ⭐',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerMetrics() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Metrics',
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
                    'Total Customers',
                    _report!.totalCustomers.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'New Customers',
                    _report!.newCustomers.toString(),
                    Icons.person_add,
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

  Widget _buildDetailedTab() {
    return RefreshIndicator(
      onRefresh: () => _loadReport(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopVendors(),
            const SizedBox(height: 16),
            _buildTopProducts(),
            const SizedBox(height: 16),
            _buildRecentOrders(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopVendors() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Performing Vendors',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._report!.topVendors.asMap().entries.map((entry) {
              final index = entry.key;
              final vendor = entry.value;
              return _buildRankingItem(
                index + 1,
                vendor['name'],
                'KSh ${NumberFormat('#,###').format(vendor['revenue'])}',
                vendor['orders'].toString(),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            ..._report!.topProducts.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return _buildRankingItem(
                index + 1,
                product['name'],
                '${product['quantity']} sold',
                'KSh ${NumberFormat('#,###').format(product['revenue'])}',
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._report!.recentOrders.map((order) => _buildOrderItem(order)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingItem(int rank, String name, String primary, String secondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3 ? Colors.amber : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank.toString(),
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
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  secondary,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            primary,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.withOpacity(0.2),
            child: Icon(
              Icons.shopping_cart,
              color: Colors.blue,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order['id']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  order['customerName'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'KSh ${NumberFormat('#,###').format(order['amount'])}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                DateFormat('MMM dd, HH:mm').format(DateTime.parse(order['date'])),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
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
      case 'custom':
        return 'Custom Range';
      default:
        return 'Unknown';
    }
  }
}

class MarketReport {
  final double totalRevenue;
  final int totalOrders;
  final int activeVendors;
  final double avgRating;
  final double revenueGrowth;
  final double ordersGrowth;
  final double avgOrderValue;
  final int completedOrders;
  final int cancelledOrders;
  final int totalCustomers;
  final int newCustomers;
  final Map<String, double> revenueByCategory;
  final Map<String, double> paymentMethods;
  final List<Map<String, dynamic>> topVendors;
  final List<Map<String, dynamic>> topProducts;
  final List<Map<String, dynamic>> recentOrders;
  final List<double> revenueData;
  final List<String> trendLabels;

  MarketReport({
    required this.totalRevenue,
    required this.totalOrders,
    required this.activeVendors,
    required this.avgRating,
    required this.revenueGrowth,
    required this.ordersGrowth,
    required this.avgOrderValue,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.totalCustomers,
    required this.newCustomers,
    required this.revenueByCategory,
    required this.paymentMethods,
    required this.topVendors,
    required this.topProducts,
    required this.recentOrders,
    required this.revenueData,
    required this.trendLabels,
  });

  factory MarketReport.fromJson(Map<String, dynamic> json) {
    return MarketReport(
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      activeVendors: json['activeVendors'] ?? 0,
      avgRating: (json['avgRating'] ?? 0).toDouble(),
      revenueGrowth: (json['revenueGrowth'] ?? 0).toDouble(),
      ordersGrowth: (json['ordersGrowth'] ?? 0).toDouble(),
      avgOrderValue: (json['avgOrderValue'] ?? 0).toDouble(),
      completedOrders: json['completedOrders'] ?? 0,
      cancelledOrders: json['cancelledOrders'] ?? 0,
      totalCustomers: json['totalCustomers'] ?? 0,
      newCustomers: json['newCustomers'] ?? 0,
      revenueByCategory: Map<String, double>.from(json['revenueByCategory'] ?? {}),
      paymentMethods: Map<String, double>.from(json['paymentMethods'] ?? {}),
      topVendors: List<Map<String, dynamic>>.from(json['topVendors'] ?? []),
      topProducts: List<Map<String, dynamic>>.from(json['topProducts'] ?? []),
      recentOrders: List<Map<String, dynamic>>.from(json['recentOrders'] ?? []),
      revenueData: List<double>.from(json['revenueData'] ?? []),
      trendLabels: List<String>.from(json['trendLabels'] ?? []),
    );
  }
} 