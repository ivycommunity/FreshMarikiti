import 'package:flutter/material.dart';
import 'package:fresh_marikiti/config/theme.dart';
import 'package:fresh_marikiti/services/analytics_service.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String _selectedPeriod = 'This Month';
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _metrics;

  final List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
  ];

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await AnalyticsService.fetchAdminAnalytics(period: _selectedPeriod);
      setState(() {
        _metrics = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _periods.length,
                itemBuilder: (context, index) {
                  final period = _periods[index];
                  final isSelected = period == _selectedPeriod;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(period),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedPeriod = period;
                          });
                          _fetchAnalytics();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _metrics == null
                  ? const Center(child: Text('No analytics data'))
                  : RefreshIndicator(
                      onRefresh: _fetchAnalytics,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Users Section
                          _buildMetricSection(
                            title: 'Users',
                            icon: Icons.people_outline,
                            color: Colors.blue,
                            metrics: [
                              {
                                'label': 'Total Users',
                                'value': _metrics!['users']['total'].toString(),
                                'icon': Icons.people_outline,
                              },
                              {
                                'label': 'Active Users',
                                'value': _metrics!['users']['active'].toString(),
                                'icon': Icons.person_outline,
                              },
                              {
                                'label': 'New Users',
                                'value': _metrics!['users']['new'].toString(),
                                'icon': Icons.person_add_outlined,
                              },
                              {
                                'label': 'Growth',
                                'value': '${_metrics!['users']['growth']}%',
                                'icon': Icons.trending_up_outlined,
                              },
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Orders Section
                          _buildMetricSection(
                            title: 'Orders',
                            icon: Icons.shopping_cart_outlined,
                            color: AppTheme.primaryGreen,
                            metrics: [
                              {
                                'label': 'Total Orders',
                                'value': _metrics!['orders']['total'].toString(),
                                'icon': Icons.receipt_long_outlined,
                              },
                              {
                                'label': 'Completed',
                                'value': _metrics!['orders']['completed'].toString(),
                                'icon': Icons.check_circle_outline,
                              },
                              {
                                'label': 'Pending',
                                'value': _metrics!['orders']['pending'].toString(),
                                'icon': Icons.pending_outlined,
                              },
                              {
                                'label': 'Revenue',
                                'value': 'KES ${_metrics!['orders']['revenue']}',
                                'icon': Icons.payments_outlined,
                              },
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Vendors Section
                          _buildMetricSection(
                            title: 'Vendors',
                            icon: Icons.store_outlined,
                            color: Colors.orange,
                            metrics: [
                              {
                                'label': 'Total Vendors',
                                'value': _metrics!['vendors']['total'].toString(),
                                'icon': Icons.store_outlined,
                              },
                              {
                                'label': 'Active Vendors',
                                'value': _metrics!['vendors']['active'].toString(),
                                'icon': Icons.storefront_outlined,
                              },
                              {
                                'label': 'Top Performer',
                                'value': _metrics!['vendors']['topPerformer'],
                                'icon': Icons.star_outline,
                              },
                              {
                                'label': 'Average Rating',
                                'value': _metrics!['vendors']['averageRating'].toString(),
                                'icon': Icons.thumb_up_outlined,
                              },
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Waste Management Section
                          _buildMetricSection(
                            title: 'Waste Management',
                            icon: Icons.recycling_outlined,
                            color: Colors.green,
                            metrics: [
                              {
                                'label': 'Total Collected',
                                'value': '${_metrics!['waste']['collected']} kg',
                                'icon': Icons.delete_outline,
                              },
                              {
                                'label': 'Total Recycled',
                                'value': '${_metrics!['waste']['recycled']} kg',
                                'icon': Icons.recycling_outlined,
                              },
                              {
                                'label': 'Efficiency',
                                'value': '${_metrics!['waste']['efficiency']}%',
                                'icon': Icons.eco_outlined,
                              },
                              {
                                'label': 'Reduction',
                                'value': '${_metrics!['waste']['reduction']}%',
                                'icon': Icons.trending_down_outlined,
                              },
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildMetricSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Map<String, dynamic>> metrics,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.heading2,
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2,
              children: metrics.map((metric) {
                return _buildMetricCard(
                  label: metric['label'],
                  value: metric['value'],
                  icon: metric['icon'],
                  color: color,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 