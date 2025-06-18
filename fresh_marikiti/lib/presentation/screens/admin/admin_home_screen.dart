import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/utils/api_endpoints.dart';
import 'package:fresh_marikiti/core/models/admin_models.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with TickerProviderStateMixin {
  SystemOverview? _systemOverview;
  List<SystemAlert> _systemAlerts = [];
  List<QuickStat> _quickStats = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _loadDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final responses = await Future.wait([
        ApiService.get(ApiEndpoints.adminOverview),
        ApiService.get(ApiEndpoints.adminAlerts),
        ApiService.get(ApiEndpoints.adminQuickStats),
      ]);

      if (responses.every((response) => response.statusCode == 200)) {
        final overviewData = json.decode(responses[0].body);
        final alertsData = json.decode(responses[1].body);
        final statsData = json.decode(responses[2].body);

        setState(() {
          _systemOverview = SystemOverview.fromJson(overviewData['overview']);
          _systemAlerts = (alertsData['alerts'] as List)
              .map((alert) => SystemAlert.fromJson(alert))
              .toList();
          _quickStats = (statsData['stats'] as List)
              .map((stat) => QuickStat.fromJson(stat))
              .toList();
          _isLoading = false;
        });
        
        _animationController.forward();
      } else {
        throw Exception('Failed to load dashboard data');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard: ${e.toString()}'),
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
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications, color: Colors.white),
                if (_systemAlerts.where((a) => a.severity == 'high').isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${_systemAlerts.where((a) => a.severity == 'high').length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showSystemAlerts(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadDashboardData(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: () => _loadDashboardData(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeHeader(),
                      const SizedBox(height: 20),
                      _buildQuickStatsGrid(),
                      const SizedBox(height: 20),
                      _buildSystemHealthCard(),
                      const SizedBox(height: 20),
                      _buildMetricsChart(),
                      const SizedBox(height: 20),
                      _buildQuickActions(),
                      const SizedBox(height: 20),
                      _buildRecentActivity(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeHeader() {
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
                    'Welcome to Fresh Marikiti',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'System Status: ${_systemOverview?.systemStatus ?? 'Loading...'}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last Updated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 48,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    if (_quickStats.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: _quickStats.length,
      itemBuilder: (context, index) {
        final stat = _quickStats[index];
        return _buildStatCard(stat);
      },
    );
  }

  Widget _buildStatCard(QuickStat stat) {
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
                Icon(
                  _getStatIcon(stat.type),
                  color: _getStatColor(stat.type),
                  size: 28,
                ),
                if (stat.changePercentage != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: stat.changePercentage > 0 ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          stat.changePercentage > 0 ? Icons.trending_up : Icons.trending_down,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${stat.changePercentage.abs().toStringAsFixed(1)}%',
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
              stat.value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stat.title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemHealthCard() {
    if (_systemOverview == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: Colors.blue[600]),
                const SizedBox(width: 12),
                const Text(
                  'System Health',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    'CPU Usage',
                    '${_systemOverview!.cpuUsage.toStringAsFixed(1)}%',
                    _systemOverview!.cpuUsage / 100,
                    _systemOverview!.cpuUsage > 80 ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildHealthMetric(
                    'Memory Usage',
                    '${_systemOverview!.memoryUsage.toStringAsFixed(1)}%',
                    _systemOverview!.memoryUsage / 100,
                    _systemOverview!.memoryUsage > 85 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    'Disk Usage',
                    '${_systemOverview!.diskUsage.toStringAsFixed(1)}%',
                    _systemOverview!.diskUsage / 100,
                    _systemOverview!.diskUsage > 90 ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildHealthMetric(
                    'Network',
                    _systemOverview!.networkStatus,
                    _systemOverview!.networkStatus == 'Healthy' ? 1.0 : 0.5,
                    _systemOverview!.networkStatus == 'Healthy' ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetric(String label, String value, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildMetricsChart() {
    if (_systemOverview?.chartData == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Platform Metrics (Last 7 Days)',
              style: TextStyle(
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
                          if (value.toInt() >= 0 && value.toInt() < _systemOverview!.chartLabels.length) {
                            return Text(_systemOverview!.chartLabels[value.toInt()]);
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
                      spots: _systemOverview!.chartData
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
                  child: _buildActionButton(
                    'User Management',
                    Icons.people,
                    Colors.blue,
                    () => _navigateToUserManagement(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'System Analytics',
                    Icons.analytics,
                    Colors.green,
                    () => _navigateToAnalytics(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Commission Mgmt',
                    Icons.account_balance,
                    Colors.purple,
                    () => _navigateToCommission(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Payment Reconciliation',
                    Icons.payment,
                    Colors.orange,
                    () => _navigateToPayments(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _viewAllActivity(),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(5, (index) {
              final activities = [
                'New user registration: John Doe (Customer)',
                'Order #12345 completed successfully',
                'System backup completed',
                'Payment reconciliation run',
                'New vendor approved: Green Valley Farm'
              ];
              final icons = [
                Icons.person_add,
                Icons.check_circle,
                Icons.backup,
                Icons.sync,
                Icons.store
              ];
              final colors = [
                Colors.blue,
                Colors.green,
                Colors.purple,
                Colors.orange,
                Colors.teal
              ];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: colors[index].withOpacity(0.2),
                      child: Icon(
                        icons[index],
                        color: colors[index],
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        activities[index],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '${index + 1}m ago',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
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

  IconData _getStatIcon(String type) {
    switch (type.toLowerCase()) {
      case 'users':
        return Icons.people;
      case 'orders':
        return Icons.shopping_cart;
      case 'revenue':
        return Icons.monetization_on;
      case 'commission':
        return Icons.account_balance;
      default:
        return Icons.analytics;
    }
  }

  Color _getStatColor(String type) {
    switch (type.toLowerCase()) {
      case 'users':
        return Colors.blue;
      case 'orders':
        return Colors.orange;
      case 'revenue':
        return Colors.green;
      case 'commission':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showSystemAlerts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Alerts'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _systemAlerts.length,
            itemBuilder: (context, index) {
              final alert = _systemAlerts[index];
              return ListTile(
                leading: Icon(
                  alert.severity == 'high' ? Icons.error : 
                  alert.severity == 'medium' ? Icons.warning : Icons.info,
                  color: alert.severity == 'high' ? Colors.red : 
                         alert.severity == 'medium' ? Colors.orange : Colors.blue,
                ),
                title: Text(alert.title),
                subtitle: Text(alert.description),
                trailing: Text(
                  DateFormat('HH:mm').format(alert.timestamp),
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToUserManagement() {
    NavigationService.toUserManagement();
  }

  void _navigateToAnalytics() {
    NavigationService.toSystemAnalytics();
  }

  void _navigateToCommission() {
    NavigationService.toCommissionManagement();
  }

  void _navigateToPayments() {
    NavigationService.toPaymentReconciliation();
  }

  void _viewAllActivity() {
    NavigationService.toSystemLogs();
  }
}

class SystemOverview {
  final String systemStatus;
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;
  final String networkStatus;
  final List<double> chartData;
  final List<String> chartLabels;

  SystemOverview({
    required this.systemStatus,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
    required this.networkStatus,
    required this.chartData,
    required this.chartLabels,
  });

  factory SystemOverview.fromJson(Map<String, dynamic> json) {
    return SystemOverview(
      systemStatus: json['systemStatus'] ?? 'Unknown',
      cpuUsage: (json['cpuUsage'] ?? 0).toDouble(),
      memoryUsage: (json['memoryUsage'] ?? 0).toDouble(),
      diskUsage: (json['diskUsage'] ?? 0).toDouble(),
      networkStatus: json['networkStatus'] ?? 'Unknown',
      chartData: List<double>.from(json['chartData'] ?? []),
      chartLabels: List<String>.from(json['chartLabels'] ?? []),
    );
  }
}

class SystemAlert {
  final String title;
  final String description;
  final String severity;
  final DateTime timestamp;

  SystemAlert({
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
  });

  factory SystemAlert.fromJson(Map<String, dynamic> json) {
    return SystemAlert(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      severity: json['severity'] ?? 'low',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class QuickStat {
  final String title;
  final String value;
  final String type;
  final double changePercentage;

  QuickStat({
    required this.title,
    required this.value,
    required this.type,
    required this.changePercentage,
  });

  factory QuickStat.fromJson(Map<String, dynamic> json) {
    return QuickStat(
      title: json['title'] ?? '',
      value: json['value'] ?? '',
      type: json['type'] ?? '',
      changePercentage: (json['changePercentage'] ?? 0).toDouble(),
    );
  }
} 