import 'package:flutter/material.dart';
import 'package:fresh_marikiti/config/theme.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  String _selectedPeriod = 'This Week';
  final List<String> _periods = [
    'Today',
    'This Week',
    'This Month',
    'This Year',
  ];

  // Dummy data - replace with actual analytics
  final Map<String, dynamic> _analytics = {
    'totalSales': 45850.0,
    'totalOrders': 124,
    'averageOrderValue': 369.75,
    'ecoPoints': 850,
    'topProducts': [
      {
        'name': 'Fresh Tomatoes',
        'quantity': 250,
        'unit': 'kg',
        'revenue': 30000.0,
      },
      {
        'name': 'Red Onions',
        'quantity': 180,
        'unit': 'kg',
        'revenue': 14400.0,
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
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
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Key Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Sales',
                  'KES ${_analytics['totalSales']}',
                  Icons.payments_outlined,
                  AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Total Orders',
                  _analytics['totalOrders'].toString(),
                  Icons.shopping_bag_outlined,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Average Order',
                  'KES ${_analytics['averageOrderValue']}',
                  Icons.analytics_outlined,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Eco Points',
                  _analytics['ecoPoints'].toString(),
                  Icons.eco_outlined,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Top Products
          Text(
            'Top Products',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 16),
          ..._analytics['topProducts'].map<Widget>((product) {
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'],
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${product['quantity']} ${product['unit']} sold',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'KES ${product['revenue']}',
                        style: AppTextStyles.body.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          // Eco Points Details
          const SizedBox(height: 24),
          Text(
            'Eco Points Details',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.eco, color: Colors.green),
                    title: const Text('Current Level'),
                    trailing: Text(
                      'Gold',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.amber[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.recycling, color: Colors.blue),
                    title: const Text('Waste Reduction'),
                    trailing: const Text('95%'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.local_shipping, color: Colors.orange),
                    title: const Text('Eco Deliveries'),
                    trailing: const Text('85%'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.caption.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.heading2.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 