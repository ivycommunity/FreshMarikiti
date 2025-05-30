import 'package:flutter/material.dart';
import 'package:fresh_marikiti/config/theme.dart';

class WasteTab extends StatefulWidget {
  const WasteTab({super.key});

  @override
  State<WasteTab> createState() => _WasteTabState();
}

class _WasteTabState extends State<WasteTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'Today';

  final List<String> _periods = [
    'Today',
    'Tomorrow',
    'This Week',
  ];

  // Dummy data - replace with actual collections
  final List<Map<String, dynamic>> _collections = [
    {
      'id': 'COL001',
      'vendor': 'Green Market Stall',
      'location': 'Block A, Stall #12',
      'time': '09:00 AM',
      'status': 'Pending',
      'wasteTypes': [
        {'type': 'Organic', 'amount': '25kg'},
        {'type': 'Plastic', 'amount': '5kg'},
      ],
    },
    {
      'id': 'COL002',
      'vendor': 'Fresh Produce Corner',
      'location': 'Block B, Stall #5',
      'time': '10:30 AM',
      'status': 'Completed',
      'wasteTypes': [
        {'type': 'Organic', 'amount': '18kg'},
        {'type': 'Paper', 'amount': '3kg'},
      ],
    },
  ];

  final List<Map<String, dynamic>> _recyclingStats = [
    {
      'type': 'Organic',
      'collected': 1250.0,
      'recycled': 1150.0,
      'unit': 'kg',
      'color': Colors.green,
    },
    {
      'type': 'Plastic',
      'collected': 350.0,
      'recycled': 320.0,
      'unit': 'kg',
      'color': Colors.blue,
    },
    {
      'type': 'Paper',
      'collected': 280.0,
      'recycled': 275.0,
      'unit': 'kg',
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Collections'),
            Tab(text: 'Recycling'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCollectionsTab(),
          _buildRecyclingTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new collection
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCollectionsTab() {
    return Column(
      children: [
        // Period Filter
        Container(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 40,
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

        // Collections List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _collections.length,
            itemBuilder: (context, index) {
              final collection = _collections[index];
              return _buildCollectionCard(collection);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionCard(Map<String, dynamic> collection) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection['vendor'],
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      collection['location'],
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                _buildStatusChip(collection['status']),
              ],
            ),
            const Divider(height: 24),
            // Waste Types
            Text(
              'Waste Types',
              style: AppTextStyles.caption.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: (collection['wasteTypes'] as List<Map<String, dynamic>>)
                  .map((waste) => Chip(
                        label: Text('${waste['type']}: ${waste['amount']}'),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            // Actions
            Row(
              children: [
                Text(
                  collection['time'],
                  style: AppTextStyles.body.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // View details
                  },
                  child: const Text('View Details'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // Start collection
                  },
                  child: const Text('Start Collection'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecyclingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall Stats Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Recycling Rate',
                  style: AppTextStyles.heading2,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOverallStat(
                      'Total Collected',
                      '1,880 kg',
                      Icons.delete_outline,
                      Colors.blue,
                    ),
                    _buildOverallStat(
                      'Total Recycled',
                      '1,745 kg',
                      Icons.recycling,
                      AppTheme.primaryGreen,
                    ),
                    _buildOverallStat(
                      'Efficiency',
                      '93%',
                      Icons.eco_outlined,
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Waste Type Stats
        Text(
          'By Waste Type',
          style: AppTextStyles.heading2,
        ),
        const SizedBox(height: 16),
        ..._recyclingStats.map((stat) => _buildWasteTypeCard(stat)),
      ],
    );
  }

  Widget _buildOverallStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWasteTypeCard(Map<String, dynamic> stat) {
    final efficiency =
        (stat['recycled'] / stat['collected'] * 100).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stat['type'],
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Collected',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stat['collected']} ${stat['unit']}',
                        style: AppTextStyles.body.copyWith(
                          color: stat['color'],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recycled',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stat['recycled']} ${stat['unit']}',
                        style: AppTextStyles.body.copyWith(
                          color: stat['color'],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Efficiency',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$efficiency%',
                        style: AppTextStyles.body.copyWith(
                          color: stat['color'],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = AppTheme.primaryGreen;
        break;
      case 'in progress':
        color = Colors.blue;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = AppTheme.errorRed;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 