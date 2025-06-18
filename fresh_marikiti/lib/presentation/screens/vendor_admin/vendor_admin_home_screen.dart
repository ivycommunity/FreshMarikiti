import 'package:flutter/material.dart';
import 'package:fresh_marikiti/core/models/vendor_admin_models.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/utils/api_endpoints.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fresh_marikiti/presentation/navigation/route_names.dart';
import 'dart:convert';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class VendorAdminHomeScreen extends StatefulWidget {
  const VendorAdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<VendorAdminHomeScreen> createState() => _VendorAdminHomeScreenState();
}

class _VendorAdminHomeScreenState extends State<VendorAdminHomeScreen>
    with TickerProviderStateMixin {
  MarketOverview? _marketOverview;
  List<StallSummary> _stalls = [];
  List<RecentActivity> _recentActivities = [];
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
    _loadMarketData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMarketData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final responses = await Future.wait([
        ApiService.get(ApiEndpoints.vendorAdminOverview),
        ApiService.get(ApiEndpoints.vendorAdminStallsSummary),
        ApiService.get(ApiEndpoints.vendorAdminActivitiesRecent),
      ]);

      if (responses.every((response) => response.statusCode == 200)) {
        final overviewData = json.decode(responses[0].body);
        final stallsData = json.decode(responses[1].body);
        final activitiesData = json.decode(responses[2].body);
        
        setState(() {
          _marketOverview = MarketOverview.fromJson(overviewData['overview']);
          _stalls = (stallsData['stalls'] as List)
              .map((s) => StallSummary.fromJson(s))
              .toList();
          _recentActivities = (activitiesData['activities'] as List)
              .map((a) => RecentActivity.fromJson(a))
              .toList();
          _isLoading = false;
        });
        
        _animationController.forward();
      } else {
        throw Exception('Failed to load market data');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Market Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () => _navigateToNotifications(),
          ),
          IconButton(
            icon: const Icon(Icons.add_business, color: Colors.white),
            onPressed: () => _navigateToAddStall(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadMarketData(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: () => _loadMarketData(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeHeader(),
                      const SizedBox(height: 20),
                      _buildQuickStatsGrid(),
                      const SizedBox(height: 20),
                      _buildPerformanceChart(),
                      const SizedBox(height: 20),
                      _buildStallsOverview(),
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
                    'Welcome to ${_marketOverview?.marketName ?? 'Your Market'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_stalls.length} Active Stalls • ${_marketOverview?.totalVendors ?? 0} Vendors',
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
              Icons.store_mall_directory,
              color: Colors.white,
              size: 48,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    if (_marketOverview == null) return const SizedBox.shrink();

    final stats = [
      StatCard(
        title: 'Total Revenue',
        value: 'KSh ${NumberFormat('#,###').format(_marketOverview!.totalRevenue)}',
        icon: Icons.monetization_on,
        color: Colors.green,
        growth: _marketOverview!.revenueGrowth,
      ),
      StatCard(
        title: 'Active Orders',
        value: _marketOverview!.activeOrders.toString(),
        icon: Icons.shopping_cart,
        color: Colors.orange,
        growth: 0.0,
      ),
      StatCard(
        title: 'Eco Points',
        value: NumberFormat('#,###').format(_marketOverview!.totalEcoPoints),
        icon: Icons.eco,
        color: Colors.teal,
        growth: _marketOverview!.ecoPointsGrowth,
      ),
      StatCard(
        title: 'Customer Satisfaction',
        value: '${_marketOverview!.avgRating.toStringAsFixed(1)} ⭐',
        icon: Icons.star,
        color: Colors.amber,
        growth: 0.0,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(stat);
      },
    );
  }

  Widget _buildStatCard(StatCard stat) {
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
                  stat.icon,
                  color: stat.color,
                  size: 28,
                ),
                if (stat.growth != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: stat.growth > 0 ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          stat.growth > 0 ? Icons.trending_up : Icons.trending_down,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${stat.growth.abs().toStringAsFixed(1)}%',
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stat.title,
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

  Widget _buildPerformanceChart() {
    if (_marketOverview?.chartData == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Market Performance (Last 7 Days)',
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
                          if (value.toInt() >= 0 && value.toInt() < _marketOverview!.chartLabels.length) {
                            return Text(_marketOverview!.chartLabels[value.toInt()]);
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
                      spots: _marketOverview!.chartData
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

  Widget _buildStallsOverview() {
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
                  'Stalls Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToStallManagement(),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _stalls.take(5).length,
                itemBuilder: (context, index) {
                  final stall = _stalls[index];
                  return _buildStallCard(stall);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStallCard(StallSummary stall) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: stall.isActive ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stall.stallName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              stall.vendorName,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              'KSh ${NumberFormat('#,###').format(stall.todayRevenue)}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              'Today',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
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
                    'Add Stall',
                    Icons.add_business,
                    Colors.blue,
                    () => _navigateToAddStall(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Manage Vendors',
                    Icons.people,
                    Colors.green,
                    () => _navigateToVendorManagement(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Analytics',
                    Icons.analytics,
                    Colors.purple,
                    () => _navigateToAnalytics(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Reports',
                    Icons.assessment,
                    Colors.orange,
                    () => _navigateToReports(),
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
            ..._recentActivities.take(5).map((activity) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _getActivityColor(activity.type).withOpacity(0.2),
                      child: Icon(
                        _getActivityIcon(activity.type),
                        color: _getActivityColor(activity.type),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        activity.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(activity.timestamp),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
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

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Icons.shopping_cart;
      case 'vendor':
        return Icons.person_add;
      case 'stall':
        return Icons.store;
      case 'payment':
        return Icons.payment;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Colors.orange;
      case 'vendor':
        return Colors.blue;
      case 'stall':
        return Colors.green;
      case 'payment':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _navigateToNotifications() {
    NavigationService.toVendorAdminNotifications();
  }

  void _navigateToAddStall() {
    NavigationService.toVendorAdminAddStall();
  }

  void _navigateToStallManagement() {
    NavigationService.toVendorAdminStalls();
  }

  void _navigateToVendorManagement() {
    NavigationService.toVendorAdminVendors();
  }

  void _navigateToAnalytics() {
    NavigationService.toVendorAdminAnalytics();
  }

  void _navigateToReports() {
    NavigationService.toVendorAdminReports();
  }

  void _viewAllActivity() {
    NavigationService.toVendorAdminActivities();
  }
}

class MarketOverview {
  final String marketName;
  final int totalVendors;
  final double totalRevenue;
  final int activeOrders;
  final int totalEcoPoints;
  final double avgRating;
  final double revenueGrowth;
  final double ecoPointsGrowth;
  final List<double> chartData;
  final List<String> chartLabels;

  MarketOverview({
    required this.marketName,
    required this.totalVendors,
    required this.totalRevenue,
    required this.activeOrders,
    required this.totalEcoPoints,
    required this.avgRating,
    required this.revenueGrowth,
    required this.ecoPointsGrowth,
    required this.chartData,
    required this.chartLabels,
  });

  factory MarketOverview.fromJson(Map<String, dynamic> json) {
    return MarketOverview(
      marketName: json['marketName'] ?? '',
      totalVendors: json['totalVendors'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      activeOrders: json['activeOrders'] ?? 0,
      totalEcoPoints: json['totalEcoPoints'] ?? 0,
      avgRating: (json['avgRating'] ?? 0).toDouble(),
      revenueGrowth: (json['revenueGrowth'] ?? 0).toDouble(),
      ecoPointsGrowth: (json['ecoPointsGrowth'] ?? 0).toDouble(),
      chartData: List<double>.from(json['chartData'] ?? []),
      chartLabels: List<String>.from(json['chartLabels'] ?? []),
    );
  }
}

class StallSummary {
  final String stallId;
  final String stallName;
  final String vendorName;
  final bool isActive;
  final double todayRevenue;

  StallSummary({
    required this.stallId,
    required this.stallName,
    required this.vendorName,
    required this.isActive,
    required this.todayRevenue,
  });

  factory StallSummary.fromJson(Map<String, dynamic> json) {
    return StallSummary(
      stallId: json['stallId'] ?? '',
      stallName: json['stallName'] ?? '',
      vendorName: json['vendorName'] ?? '',
      isActive: json['isActive'] ?? false,
      todayRevenue: (json['todayRevenue'] ?? 0).toDouble(),
    );
  }
}

class RecentActivity {
  final String type;
  final String description;
  final DateTime timestamp;

  RecentActivity({
    required this.type,
    required this.description,
    required this.timestamp,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class StatCard {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double growth;

  StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.growth,
  });
} 