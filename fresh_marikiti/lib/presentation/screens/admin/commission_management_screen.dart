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

class CommissionManagementScreen extends StatefulWidget {
  const CommissionManagementScreen({Key? key}) : super(key: key);

  @override
  State<CommissionManagementScreen> createState() => _CommissionManagementScreenState();
}

class _CommissionManagementScreenState extends State<CommissionManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  CommissionData? _commissionData;
  List<RiderCommission> _riderCommissions = [];
  List<PayoutRecord> _payouts = [];
  bool _isLoading = true;
  String _selectedPeriod = '30d';
  String _statusFilter = 'all';

  final List<String> _periods = ['7d', '30d', '90d', '1y'];
  final List<String> _periodLabels = ['7 Days', '30 Days', '90 Days', '1 Year'];
  final List<String> _statusFilters = ['all', 'pending', 'completed', 'failed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCommissionData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCommissionData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final responses = await Future.wait([
        ApiService.get(ApiEndpoints.adminCommissionOverview(period: _selectedPeriod)),
        ApiService.get(ApiEndpoints.adminCommissionRiders(period: _selectedPeriod)),
        ApiService.get(ApiEndpoints.adminCommissionPayouts(status: _statusFilter)),
      ]);

      if (responses.every((response) => response.statusCode == 200)) {
        final overviewData = json.decode(responses[0].body);
        final ridersData = json.decode(responses[1].body);
        final payoutsData = json.decode(responses[2].body);
        
        setState(() {
          _commissionData = CommissionData.fromJson(overviewData['data']);
          _riderCommissions = (ridersData['riders'] as List)
              .map((r) => RiderCommission.fromJson(r))
              .toList();
          _payouts = (payoutsData['payouts'] as List)
              .map((p) => PayoutRecord.fromJson(p))
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load commission data');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processPayouts() async {
    final pendingRiders = _riderCommissions.where((r) => r.pendingCommission > 0).toList();
    
    if (pendingRiders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending commissions to process'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Payouts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Process payouts for ${pendingRiders.length} riders?'),
            const SizedBox(height: 8),
            Text(
              'Total amount: KSh ${NumberFormat('#,###').format(pendingRiders.fold<double>(0, (sum, r) => sum + r.pendingCommission))}',
              style: const TextStyle(fontWeight: FontWeight.bold),
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
              Navigator.pop(context);
              _executeBulkPayout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: const Text('Process', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeBulkPayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.post(
        ApiEndpoints.adminCommissionBulkPayout,
        {
          'period': _selectedPeriod,
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bulk payout initiated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCommissionData();
        }
      } else {
        throw Exception('Failed to process bulk payout');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payout: ${e.toString()}'),
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
          'Commission Management',
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
              _loadCommissionData();
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
            onPressed: () => _loadCommissionData(),
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
            Tab(text: 'Riders', icon: Icon(Icons.delivery_dining)),
            Tab(text: 'Payouts', icon: Icon(Icons.account_balance)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildRidersTab(),
                _buildPayoutsTab(),
                _buildAnalyticsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: () => _loadCommissionData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCommissionSummary(),
            const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 16),
            _buildRecentActivity(),
            const SizedBox(height: 16),
            _buildTopPerformers(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionSummary() {
    if (_commissionData == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Commission Overview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '5% commission rate on all deliveries',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Earned',
                    'KSh ${NumberFormat('#,###').format(_commissionData!.totalEarned)}',
                    Colors.white,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Pending Payouts',
                    'KSh ${NumberFormat('#,###').format(_commissionData!.pendingPayouts)}',
                    Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'This Month',
                    'KSh ${NumberFormat('#,###').format(_commissionData!.thisMonth)}',
                    Colors.white,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Growth',
                    '${_commissionData!.growth >= 0 ? '+' : ''}${_commissionData!.growth.toStringAsFixed(1)}%',
                    Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _processPayouts,
                    icon: const Icon(Icons.payment),
                    label: const Text('Process Payouts'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCommissionSettings(),
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      foregroundColor: const Color(0xFF2E7D32),
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

  Widget _buildRidersTab() {
    return RefreshIndicator(
      onRefresh: () => _loadCommissionData(),
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Rider Commission (${_riderCommissions.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _showRiderFilters(),
                  icon: const Icon(Icons.filter_list),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _riderCommissions.length,
              itemBuilder: (context, index) {
                final rider = _riderCommissions[index];
                return _buildRiderCommissionCard(rider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderCommissionCard(RiderCommission rider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
                  child: const Icon(Icons.delivery_dining, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rider.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${rider.riderId}',
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
                    color: rider.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rider.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRiderMetric(
                    'Deliveries',
                    rider.totalDeliveries.toString(),
                    Icons.local_shipping,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildRiderMetric(
                    'Total Earned',
                    'KSh ${NumberFormat('#,###').format(rider.totalCommission)}',
                    Icons.monetization_on,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildRiderMetric(
                    'Pending',
                    'KSh ${NumberFormat('#,###').format(rider.pendingCommission)}',
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildRiderMetric(
                    'Rating',
                    '${rider.rating.toStringAsFixed(1)} ⭐',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
            if (rider.pendingCommission > 0) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _processIndividualPayout(rider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Pay KSh ${NumberFormat('#,###').format(rider.pendingCommission)}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRiderMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutsTab() {
    return RefreshIndicator(
      onRefresh: () => _loadCommissionData(),
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Payout History (${_payouts.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DropdownButton<String>(
                  value: _statusFilter,
                  items: _statusFilters.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _statusFilter = value!;
                    });
                    _loadCommissionData();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _payouts.length,
              itemBuilder: (context, index) {
                final payout = _payouts[index];
                return _buildPayoutCard(payout);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutCard(PayoutRecord payout) {
    Color statusColor;
    IconData statusIcon;
    
    switch (payout.status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          payout.riderName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: KSh ${NumberFormat('#,###').format(payout.amount)}'),
            Text('Date: ${DateFormat('MMM dd, yyyy').format(payout.payoutDate)}'),
            if (payout.transactionId.isNotEmpty)
              Text('Ref: ${payout.transactionId}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            payout.status.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_commissionData == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () => _loadCommissionData(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCommissionChart(),
            const SizedBox(height: 16),
            _buildPerformanceMetrics(),
            const SizedBox(height: 16),
            _buildTrendAnalysis(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionChart() {
    if (_commissionData?.chartData == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Commission Trends',
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
                          if (value.toInt() >= 0 && value.toInt() < _commissionData!.chartLabels.length) {
                            return Text(_commissionData!.chartLabels[value.toInt()]);
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
                      spots: _commissionData!.chartData
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

  Widget _buildPerformanceMetrics() {
    if (_commissionData == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
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
                    'Avg Commission/Rider',
                    'KSh ${_commissionData!.avgCommissionPerRider.toStringAsFixed(0)}',
                    Icons.person,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Commission Rate',
                    '5.0%',
                    Icons.percent,
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
                    'Active Riders',
                    _commissionData!.activeRiders.toString(),
                    Icons.delivery_dining,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Total Deliveries',
                    NumberFormat('#,###').format(_commissionData!.totalDeliveries),
                    Icons.local_shipping,
                    Colors.orange,
                  ),
                ),
              ],
            ),
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

  Widget _buildTrendAnalysis() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trend Analysis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '• Commission earnings have increased by 15% this month\n'
              '• 8 new riders joined the platform\n'
              '• Average delivery commission: KSh 45\n'
              '• Peak commission hours: 6PM - 9PM\n'
              '• Top performing area: Nairobi CBD',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(3, (index) {
              final activities = [
                'John Doe completed 5 deliveries - KSh 225 commission',
                'Weekly payout processed for 15 riders - KSh 12,500',
                'Mary Smith joined as new rider'
              ];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.grey[400]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        activities[index],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformers() {
    final topRiders = _riderCommissions.take(3).toList();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Performers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...topRiders.asMap().entries.map((entry) {
              final index = entry.key;
              final rider = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: index == 0 ? Colors.amber : 
                               index == 1 ? Colors.grey[400] : 
                               Colors.brown[300],
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
                            rider.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${rider.totalDeliveries} deliveries • KSh ${NumberFormat('#,###').format(rider.totalCommission)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
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

  Future<void> _processIndividualPayout(RiderCommission rider) async {
    // Implementation for individual payout
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Processing payout for ${rider.name}...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showCommissionSettings() {
    // Implementation for commission settings
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Commission Settings'),
        content: const Text('Commission rate: 5%\nPayout frequency: Weekly\nMinimum payout: KSh 100'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRiderFilters() {
    // Implementation for rider filters
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Riders'),
        content: const Text('Filter options will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class CommissionData {
  final double totalEarned;
  final double pendingPayouts;
  final double thisMonth;
  final double growth;
  final double avgCommissionPerRider;
  final int activeRiders;
  final int totalDeliveries;
  final List<double> chartData;
  final List<String> chartLabels;

  CommissionData({
    required this.totalEarned,
    required this.pendingPayouts,
    required this.thisMonth,
    required this.growth,
    required this.avgCommissionPerRider,
    required this.activeRiders,
    required this.totalDeliveries,
    required this.chartData,
    required this.chartLabels,
  });

  factory CommissionData.fromJson(Map<String, dynamic> json) {
    return CommissionData(
      totalEarned: (json['totalEarned'] ?? 0).toDouble(),
      pendingPayouts: (json['pendingPayouts'] ?? 0).toDouble(),
      thisMonth: (json['thisMonth'] ?? 0).toDouble(),
      growth: (json['growth'] ?? 0).toDouble(),
      avgCommissionPerRider: (json['avgCommissionPerRider'] ?? 0).toDouble(),
      activeRiders: json['activeRiders'] ?? 0,
      totalDeliveries: json['totalDeliveries'] ?? 0,
      chartData: List<double>.from(json['chartData'] ?? []),
      chartLabels: List<String>.from(json['chartLabels'] ?? []),
    );
  }
}

class RiderCommission {
  final String riderId;
  final String name;
  final bool isActive;
  final int totalDeliveries;
  final double totalCommission;
  final double pendingCommission;
  final double rating;

  RiderCommission({
    required this.riderId,
    required this.name,
    required this.isActive,
    required this.totalDeliveries,
    required this.totalCommission,
    required this.pendingCommission,
    required this.rating,
  });

  factory RiderCommission.fromJson(Map<String, dynamic> json) {
    return RiderCommission(
      riderId: json['riderId'] ?? '',
      name: json['name'] ?? '',
      isActive: json['isActive'] ?? false,
      totalDeliveries: json['totalDeliveries'] ?? 0,
      totalCommission: (json['totalCommission'] ?? 0).toDouble(),
      pendingCommission: (json['pendingCommission'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
    );
  }
}

class PayoutRecord {
  final String payoutId;
  final String riderName;
  final double amount;
  final String status;
  final DateTime payoutDate;
  final String transactionId;

  PayoutRecord({
    required this.payoutId,
    required this.riderName,
    required this.amount,
    required this.status,
    required this.payoutDate,
    required this.transactionId,
  });

  factory PayoutRecord.fromJson(Map<String, dynamic> json) {
    return PayoutRecord(
      payoutId: json['payoutId'] ?? '',
      riderName: json['riderName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      payoutDate: DateTime.parse(json['payoutDate'] ?? DateTime.now().toIso8601String()),
      transactionId: json['transactionId'] ?? '',
    );
  }
} 