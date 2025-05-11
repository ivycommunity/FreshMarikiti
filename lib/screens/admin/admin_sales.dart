import 'package:flutter/material.dart';

class AdminSalesPage extends StatefulWidget {
  const AdminSalesPage({super.key});

  @override
  State<AdminSalesPage> createState() => _AdminSalesPageState();  
}

class _AdminSalesPageState extends State<AdminSalesPage> {
  String _selectedPeriod = 'This Month';
  final List<String> _periods = ['Today', 'This Week', 'This Month', 'This Year', 'All Time'];
  
  final List<Map<String, dynamic>> _salesData = [
    {
      'day': 'Mon',
      'date': '5 May',
      'amount': 42500,
      'orders': 85,
      'growth': 5.2,
    },
    {
      'day': 'Tue',
      'date': '6 May',
      'amount': 38700,
      'orders': 74,
      'growth': -2.1,
    },
    {
      'day': 'Wed',
      'date': '7 May',
      'amount': 41200,
      'orders': 81,
      'growth': 3.5,
    },
    {
      'day': 'Thu',
      'date': '8 May',
      'amount': 39600,
      'orders': 78,
      'growth': -0.8,
    },
    {
      'day': 'Fri',
      'date': '9 May',
      'amount': 45800,
      'orders': 92,
      'growth': 8.3,
    },
    {
      'day': 'Sat',
      'date': '10 May',
      'amount': 53200,
      'orders': 107,
      'growth': 12.4,
    },
    {
      'day': 'Sun',
      'date': '11 May',
      'amount': 49800,
      'orders': 98,
      'growth': 6.9,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {
              // Export sales data
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show more options
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(theme),
            const SizedBox(height: 24),
            _buildSummaryCards(theme, isDark),
            const SizedBox(height: 24),
            _buildSalesChart(theme, isDark),
            const SizedBox(height: 24),
            _buildSalesTable(theme, isDark),
            const SizedBox(height: 24),
            _buildTopProducts(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Sales Summary',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        DropdownButton<String>(
          value: _selectedPeriod,
          onChanged: (String? newValue) {
            setState(() {
              _selectedPeriod = newValue!;
            });
          },
          items: _periods.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Sales',
                'KES 250,000',
                Icons.trending_up,
                '↑ 8.5%',
                Colors.green,
                theme,
                isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Total Orders',
                '615',
                Icons.shopping_basket_outlined,
                '↑ 5.2%',
                Colors.blue,
                theme,
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Average Order',
                'KES 407',
                Icons.analytics_outlined,
                '↑ 2.3%',
                Colors.purple,
                theme,
                isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Return Rate',
                '2.4%',
                Icons.assignment_return_outlined,
                '↓ 0.5%',
                Colors.orange,
                theme,
                isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    String change,
    Color color,
    ThemeData theme,
    bool isDark,
  ) {
    final isPositiveChange = change.contains('↑');
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              change,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isPositiveChange ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart(ThemeData theme, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sales Trend',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ToggleButtons(
                  isSelected: const [true, false],
                  onPressed: (int index) {
                    // Toggle between daily/weekly view
                  },
                  borderRadius: BorderRadius.circular(8),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Daily'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Weekly'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 64,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sales chart visualization would appear here',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This would be implemented with a charting library like fl_chart',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
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

  Widget _buildSalesTable(ThemeData theme, bool isDark) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Breakdown',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // View detailed report
                  },
                  icon: const Icon(Icons.read_more),
                  label: const Text('View Report'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Day')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Sales (KES)')),
                  DataColumn(label: Text('Orders')),
                  DataColumn(label: Text('Growth')),
                ],
                rows: _salesData.map((data) {
                  final isPositiveGrowth = (data['growth'] as double) >= 0;
                  
                  return DataRow(
                    cells: [
                      DataCell(Text(data['day'])),
                      DataCell(Text(data['date'])),
                      DataCell(Text('${data['amount']}')),
                      DataCell(Text('${data['orders']}')),
                      DataCell(
                        Row(
                          children: [
                            Icon(
                              isPositiveGrowth
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: isPositiveGrowth ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${data['growth']}%',
                              style: TextStyle(
                                color: isPositiveGrowth ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts(ThemeData theme, bool isDark) {
    final topProducts = [
      {'name': 'Tomatoes', 'sales': 'KES 42,500', 'quantity': 850},
      {'name': 'Onions', 'sales': 'KES 38,750', 'quantity': 775},
      {'name': 'Potatoes', 'sales': 'KES 35,000', 'quantity': 700},
      {'name': 'Mangoes', 'sales': 'KES 28,500', 'quantity': 570},
      {'name': 'Cabbages', 'sales': 'KES 24,200', 'quantity': 484},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Selling Products',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // View all products
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topProducts.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final product = topProducts[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Text('${index + 1}', style: TextStyle(color: theme.colorScheme.primary)),
                  ),
                  title: Text(product['name'] as String),
                    subtitle: Text('${product['quantity']} units sold'),
                  trailing: Text(
                    product['sales'] as String,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}