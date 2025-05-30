import 'package:flutter/material.dart';
import 'package:fresh_marikiti/config/theme.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  String _selectedPeriod = 'This Month';
  String _selectedType = 'All';

  final List<String> _periods = [
    'This Week',
    'This Month',
    'Last Month',
    'This Year',
  ];

  final List<String> _reportTypes = [
    'All',
    'Vendor Performance',
    'Waste Management',
    'Issues',
  ];

  // Dummy data - replace with actual reports
  final List<Map<String, dynamic>> _reports = [
    {
      'id': 'REP001',
      'title': 'Monthly Vendor Performance',
      'type': 'Vendor Performance',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'status': 'Generated',
      'summary': {
        'totalVendors': 45,
        'activeVendors': 42,
        'averageEcoPoints': 725,
        'topPerformer': 'Green Market Stall',
      },
    },
    {
      'id': 'REP002',
      'title': 'Weekly Waste Collection Report',
      'type': 'Waste Management',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'status': 'Generated',
      'summary': {
        'totalCollected': '1,880 kg',
        'recyclingRate': '93%',
        'organicWaste': '1,250 kg',
        'nonOrganicWaste': '630 kg',
      },
    },
    {
      'id': 'REP003',
      'title': 'Issues Resolution Report',
      'type': 'Issues',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'status': 'Generated',
      'summary': {
        'totalIssues': 12,
        'resolvedIssues': 10,
        'pendingIssues': 2,
        'averageResolutionTime': '2.5 days',
      },
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Generate new report
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Filter
                Text(
                  'Period',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
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
                const SizedBox(height: 16),
                // Report Type Filter
                Text(
                  'Report Type',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _reportTypes.length,
                    itemBuilder: (context, index) {
                      final type = _reportTypes[index];
                      final isSelected = type == _selectedType;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedType = type;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Reports List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                final report = _reports[index];
                if (_selectedType != 'All' && report['type'] != _selectedType) {
                  return const SizedBox.shrink();
                }
                return _buildReportCard(report);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          _showReportDetails(report);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report['title'],
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(report['date']),
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(report['status']),
                ],
              ),
              const Divider(height: 24),
              // Summary
              Text(
                'Summary',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              _buildSummaryGrid(report['summary']),
              const SizedBox(height: 16),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // Share report
                    },
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      // Download report
                    },
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Download'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(Map<String, dynamic> summary) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: summary.entries.map((entry) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 64) / 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatKey(entry.key),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.value.toString(),
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (Match match) => ' ${match.group(0)}',
        )
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'generated':
        color = AppTheme.primaryGreen;
        break;
      case 'generating':
        color = Colors.blue;
        break;
      case 'failed':
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _showReportDetails(Map<String, dynamic> report) async {
    // Show detailed report view
  }
} 