import 'package:flutter/material.dart';

class AdminSalesDetails extends StatefulWidget {
  const AdminSalesDetails({super.key});

  @override
  State<AdminSalesDetails> createState() => _AdminSalesDetailsState();
}

class _AdminSalesDetailsState extends State<AdminSalesDetails> {
  // Dummy sales data
  final List<Map<String, dynamic>> salesData = [
    {
      'id': 'S001',
      'date': '11 May 2025',
      'vendor': 'Samuel Kamau',
      'stall': 'Fruit Stall (Section A)',
      'totalAmount': 'KES 3,500',
      'status': 'Completed',
      'products': [
        {'name': 'Mangoes', 'quantity': '5 kg', 'price': 'KES 750'},
        {'name': 'Bananas', 'quantity': '3 bunches', 'price': 'KES 450'},
        {'name': 'Apples', 'quantity': '2 kg', 'price': 'KES 800'},
        {'name': 'Oranges', 'quantity': '4 kg', 'price': 'KES 600'},
        {'name': 'Avocados', 'quantity': '6 pcs', 'price': 'KES 900'},
      ],
      'paymentMethod': 'M-Pesa'
    },
    {
      'id': 'S002',
      'date': '10 May 2025',
      'vendor': 'Mary Njeri',
      'stall': 'Vegetable Stall (Section B)',
      'totalAmount': 'KES 2,800',
      'status': 'Completed',
      'products': [
        {'name': 'Tomatoes', 'quantity': '3 kg', 'price': 'KES 450'},
        {'name': 'Kale (Sukuma Wiki)', 'quantity': '4 bundles', 'price': 'KES 200'},
        {'name': 'Onions', 'quantity': '2 kg', 'price': 'KES 300'},
        {'name': 'Carrots', 'quantity': '1.5 kg', 'price': 'KES 225'},
        {'name': 'Potatoes', 'quantity': '5 kg', 'price': 'KES 750'},
        {'name': 'Garlic', 'quantity': '0.5 kg', 'price': 'KES 375'},
        {'name': 'Ginger', 'quantity': '0.5 kg', 'price': 'KES 500'},
      ],
      'paymentMethod': 'Cash'
    },
    {
      'id': 'S003',
      'date': '10 May 2025',
      'vendor': 'John Omondi',
      'stall': 'Grain Stall (Section C)',
      'totalAmount': 'KES 5,200',
      'status': 'Completed',
      'products': [
        {'name': 'Rice', 'quantity': '10 kg', 'price': 'KES 1,500'},
        {'name': 'Beans', 'quantity': '5 kg', 'price': 'KES 1,200'},
        {'name': 'Maize Flour', 'quantity': '6 kg', 'price': 'KES 900'},
        {'name': 'Green Grams', 'quantity': '3 kg', 'price': 'KES 750'},
        {'name': 'Wheat Flour', 'quantity': '2 kg', 'price': 'KES 350'},
        {'name': 'Peanuts', 'quantity': '1 kg', 'price': 'KES 500'},
      ],
      'paymentMethod': 'Bank Transfer'
    },
    {
      'id': 'S004',
      'date': '9 May 2025',
      'vendor': 'Alice Wambui',
      'stall': 'Dairy Stall (Section D)',
      'totalAmount': 'KES 3,150',
      'status': 'Completed',
      'products': [
        {'name': 'Milk', 'quantity': '5 liters', 'price': 'KES 750'},
        {'name': 'Yogurt', 'quantity': '6 containers', 'price': 'KES 900'},
        {'name': 'Cheese', 'quantity': '2 kg', 'price': 'KES 1,200'},
        {'name': 'Eggs', 'quantity': '2 trays', 'price': 'KES 300'},
      ],
      'paymentMethod': 'M-Pesa'
    },
    {
      'id': 'S005',
      'date': '8 May 2025',
      'vendor': 'Samuel Kamau',
      'stall': 'Fruit Stall (Section A)',
      'totalAmount': 'KES 2,900',
      'status': 'Completed',
      'products': [
        {'name': 'Pineapples', 'quantity': '2 pcs', 'price': 'KES 500'},
        {'name': 'Watermelon', 'quantity': '1 pc', 'price': 'KES 350'},
        {'name': 'Passion Fruits', 'quantity': '1.5 kg', 'price': 'KES 450'},
        {'name': 'Strawberries', 'quantity': '1 kg', 'price': 'KES 800'},
        {'name': 'Avocados', 'quantity': '4 pcs', 'price': 'KES 600'},
        {'name': 'Lemons', 'quantity': '1 kg', 'price': 'KES 200'},
      ],
      'paymentMethod': 'Cash'
    },
  ];

  // Filter variables
  String _selectedFilter = 'All';
  String _searchQuery = '';
  
  List<Map<String, dynamic>> get filteredSales {
    return salesData.where((sale) {
      // Apply search filter
      final matchesSearch = sale['vendor'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          sale['id'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          sale['stall'].toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Apply category filter
      if (_selectedFilter == 'All') {
        return matchesSearch;
      } else {
        return matchesSearch && sale['paymentMethod'] == _selectedFilter;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              // Show date range picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Date range picker coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Sales Summary Cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    'Total Sales',
                    'KES 17,550',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    'This Week',
                    'KES 14,350',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search sales by vendor or ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildFilterChip('All', theme),
                const SizedBox(width: 8),
                _buildFilterChip('M-Pesa', theme),
                const SizedBox(width: 8),
                _buildFilterChip('Cash', theme),
                const SizedBox(width: 8),
                _buildFilterChip('Bank Transfer', theme),
              ],
            ),
          ),
          
          // Sales List
          Expanded(
            child: filteredSales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No sales found',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredSales.length,
                    itemBuilder: (context, index) {
                      final sale = filteredSales[index];
                      return _buildSaleCard(context, sale, isDark);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Download or export functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export feature coming soon!')),
          );
        },
        child: const Icon(Icons.download),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.more_horiz,
                  color: theme.disabledColor,
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
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, ThemeData theme) {
    final isSelected = _selectedFilter == label;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? label : 'All';
        });
      },
    );
  }

  Widget _buildSaleCard(BuildContext context, Map<String, dynamic> sale, bool isDark) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showSaleDetailsDialog(context, sale),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.blue.shade900 : Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_outlined,
                          color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sale #${sale['id']}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${sale['date']}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Chip(
                    label: Text(
                      sale['status'],
                      style: TextStyle(
                        color: isDark ? Colors.green.shade200 : Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: isDark ? Colors.green.shade900.withOpacity(0.2) : Colors.green.shade50,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vendor',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        sale['vendor'],
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Amount',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        sale['totalAmount'],
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stall',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          sale['stall'],
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Payment',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        sale['paymentMethod'],
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${(sale['products'] as List).length} items',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < (sale['products'] as List).length && i < 3; i++)
                    Chip(
                      label: Text(
                        sale['products'][i]['name'],
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: isDark
                          ? theme.colorScheme.surface
                          : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  if ((sale['products'] as List).length > 3)
                    Chip(
                      label: Text(
                        '+${(sale['products'] as List).length - 3} more',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: isDark
                          ? theme.colorScheme.surface
                          : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Sales'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Coming soon: More detailed filters for sales reports'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSaleDetailsDialog(BuildContext context, Map<String, dynamic> sale) {
    final theme = Theme.of(context);
    
    // Calculate subtotal and set it in a variable for easy access
    double subtotal = 0;
    for (final product in sale['products']) {
      String priceStr = product['price'].toString().replaceAll('KES ', '').replaceAll(',', '');
      subtotal += double.parse(priceStr);
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sale Details',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Sale info
                _buildInfoRow('Sale ID:', '#${sale['id']}'),
                _buildInfoRow('Date:', sale['date']),
                _buildInfoRow('Status:', sale['status']),
                _buildInfoRow('Vendor:', sale['vendor']),
                _buildInfoRow('Stall:', sale['stall']),
                _buildInfoRow('Payment Method:', sale['paymentMethod']),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Products
                Text(
                  'Products',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Product headers
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Item',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Quantity',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Price',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Product list
                ...sale['products'].map<Widget>((product) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(product['name']),
                        ),
                        Expanded(
                          child: Text(
                            product['quantity'],
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            product['price'],
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                
                // Total
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal:',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'KES ${subtotal.toStringAsFixed(0)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        sale['totalAmount'],
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Print feature coming soon!')),
                        );
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Print'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Export feature coming soon!')),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Export'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}