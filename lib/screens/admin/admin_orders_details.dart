import 'package:flutter/material.dart';

class AdminOrdersDetails extends StatefulWidget {
  const AdminOrdersDetails({super.key});

  @override
  State<AdminOrdersDetails> createState() => _AdminOrdersDetailsState();
}

class _AdminOrdersDetailsState extends State<AdminOrdersDetails> {
  // Dummy orders data
  final List<Map<String, dynamic>> ordersData = [
    {
      'id': 'ORD-001',
      'date': '11 May 2025',
      'clientName': 'John Doe',
      'vendorName': 'Samuel Kamau',
      'stallLocation': 'Fruit Stall (Section A)',
      'destinationLocation': 'Westlands, Nairobi',
      'items': [
        {'name': 'Mangoes', 'quantity': '3 kg', 'price': 'KES 450'},
        {'name': 'Bananas', 'quantity': '2 bunches', 'price': 'KES 300'},
        {'name': 'Avocados', 'quantity': '4 pcs', 'price': 'KES 600'},
      ],
      'productsTotal': 'KES 1,350',
      'deliveryFee': 'KES 250',
      'totalAmount': 'KES 1,600',
      'status': 'Delivered',
      'paymentMethod': 'M-Pesa',
      'paymentStatus': 'Paid'
    },
    {
      'id': 'ORD-002',
      'date': '11 May 2025',
      'clientName': 'Jane Smith',
      'vendorName': 'Mary Njeri',
      'stallLocation': 'Vegetable Stall (Section B)',
      'destinationLocation': 'Kilimani, Nairobi',
      'items': [
        {'name': 'Tomatoes', 'quantity': '2 kg', 'price': 'KES 300'},
        {'name': 'Kale (Sukuma Wiki)', 'quantity': '3 bundles', 'price': 'KES 150'},
        {'name': 'Onions', 'quantity': '1 kg', 'price': 'KES 150'},
        {'name': 'Carrots', 'quantity': '1 kg', 'price': 'KES 150'},
      ],
      'productsTotal': 'KES 750',
      'deliveryFee': 'KES 200',
      'totalAmount': 'KES 950',
      'status': 'In Transit',
      'paymentMethod': 'Cash on Delivery',
      'paymentStatus': 'Pending'
    },
    {
      'id': 'ORD-003',
      'date': '10 May 2025',
      'clientName': 'David Mwangi',
      'vendorName': 'John Omondi',
      'stallLocation': 'Grain Stall (Section C)',
      'destinationLocation': 'South B, Nairobi',
      'items': [
        {'name': 'Rice', 'quantity': '5 kg', 'price': 'KES 750'},
        {'name': 'Beans', 'quantity': '3 kg', 'price': 'KES 600'},
        {'name': 'Maize Flour', 'quantity': '2 kg', 'price': 'KES 300'},
      ],
      'productsTotal': 'KES 1,650',
      'deliveryFee': 'KES 300',
      'totalAmount': 'KES 1,950',
      'status': 'Processing',
      'paymentMethod': 'M-Pesa',
      'paymentStatus': 'Paid'
    },
    {
      'id': 'ORD-004',
      'date': '9 May 2025',
      'clientName': 'Sarah Kamau',
      'vendorName': 'Alice Wambui',
      'stallLocation': 'Dairy Stall (Section D)',
      'destinationLocation': 'Lavington, Nairobi',
      'items': [
        {'name': 'Milk', 'quantity': '3 liters', 'price': 'KES 450'},
        {'name': 'Yogurt', 'quantity': '4 containers', 'price': 'KES 600'},
        {'name': 'Cheese', 'quantity': '1 kg', 'price': 'KES 600'},
      ],
      'productsTotal': 'KES 1,650',
      'deliveryFee': 'KES 350',
      'totalAmount': 'KES 2,000',
      'status': 'Delivered',
      'paymentMethod': 'Card Payment',
      'paymentStatus': 'Paid'
    },
    {
      'id': 'ORD-005',
      'date': '8 May 2025',
      'clientName': 'Michael Njoroge',
      'vendorName': 'Samuel Kamau',
      'stallLocation': 'Fruit Stall (Section A)',
      'destinationLocation': 'Karen, Nairobi',
      'items': [
        {'name': 'Pineapples', 'quantity': '2 pcs', 'price': 'KES 500'},
        {'name': 'Watermelon', 'quantity': '1 pc', 'price': 'KES 350'},
        {'name': 'Passion Fruits', 'quantity': '1 kg', 'price': 'KES 300'},
      ],
      'productsTotal': 'KES 1,150',
      'deliveryFee': 'KES 400',
      'totalAmount': 'KES 1,550',
      'status': 'Cancelled',
      'paymentMethod': 'M-Pesa',
      'paymentStatus': 'Refunded'
    },
  ];

  // Filter variables
  String _selectedStatusFilter = 'All';
  String _searchQuery = '';
  
  List<Map<String, dynamic>> get filteredOrders {
    return ordersData.where((order) {
      // Apply search filter
      final matchesSearch = order['clientName'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order['id'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order['vendorName'].toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Apply status filter
      if (_selectedStatusFilter == 'All') {
        return matchesSearch;
      } else {
        return matchesSearch && order['status'] == _selectedStatusFilter;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Management'),
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
          // Orders Summary Cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    'Total Orders',
                    '5',
                    Icons.shopping_bag_outlined,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    'Delivered',
                    '2',
                    Icons.check_circle_outline,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    'In Progress',
                    '2',
                    Icons.pending_outlined,
                    Colors.orange,
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
                hintText: 'Search orders by client, vendor or ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildStatusFilterChip('All', theme),
                const SizedBox(width: 8),
                _buildStatusFilterChip('Delivered', theme),
                const SizedBox(width: 8),
                _buildStatusFilterChip('In Transit', theme),
                const SizedBox(width: 8),
                _buildStatusFilterChip('Processing', theme),
                const SizedBox(width: 8),
                _buildStatusFilterChip('Cancelled', theme),
              ],
            ),
          ),
          
          // Orders List
          Expanded(
            child: filteredOrders.isEmpty
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
                          'No orders found',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _buildOrderCard(context, order, isDark);
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

  Widget _buildStatusFilterChip(String label, ThemeData theme) {
    final isSelected = _selectedStatusFilter == label;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatusFilter = selected ? label : 'All';
        });
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order, bool isDark) {
    final theme = Theme.of(context);
    
    // Determine status color
    Color statusColor;
    IconData statusIcon;
    
    switch (order['status']) {
      case 'Delivered':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'In Transit':
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping_outlined;
        break;
      case 'Processing':
        statusColor = Colors.orange;
        statusIcon = Icons.pending_outlined;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showOrderDetailsDialog(context, order),
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
                          color: isDark ? Colors.purple.shade900 : Colors.purple.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          color: isDark ? Colors.purple.shade200 : Colors.purple.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['id'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            order['date'],
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Chip(
                    avatar: Icon(
                      statusIcon,
                      size: 16,
                      color: statusColor,
                    ),
                    label: Text(
                      order['status'],
                      style: TextStyle(
                        //color: isDark ? statusColor.shade200 : statusColor.shade700,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: isDark ? statusColor.withOpacity(0.2) : statusColor.withOpacity(0.1),
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
                        'Client',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        order['clientName'],
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
                        order['totalAmount'],
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
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vendor',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          order['vendorName'],
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stall',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          order['stallLocation'].split(' (')[0],
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Destination',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          order['destinationLocation'],
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment',
                        style: theme.textTheme.bodySmall,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: order['paymentStatus'] == 'Paid' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          order['paymentStatus'],
                          style: TextStyle(
                            color: order['paymentStatus'] == 'Paid' ? Colors.green : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${(order['items'] as List).length} items',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < (order['items'] as List).length && i < 3; i++)
                    Chip(
                      label: Text(
                        order['items'][i]['name'],
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: isDark
                          ? theme.colorScheme.surface
                          : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  if ((order['items'] as List).length > 3)
                    Chip(
                      label: Text(
                        '+${(order['items'] as List).length - 3} more',
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
        title: const Text('Filter Orders'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Coming soon: More detailed filters for orders'),
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

  void _showOrderDetailsDialog(BuildContext context, Map<String, dynamic> order) {
    final theme = Theme.of(context);
    
    // Determine status color for styling
    Color statusColor;
    switch (order['status']) {
      case 'Delivered':
        statusColor = Colors.green;
        break;
      case 'In Transit':
        statusColor = Colors.blue;
        break;
      case 'Processing':
        statusColor = Colors.orange;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
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
                      'Order Details',
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
                
                // Order status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(order['status']),
                        color: statusColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order['status'],
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Order info
                _buildInfoRow('Order ID:', order['id']),
                _buildInfoRow('Date:', order['date']),
                _buildInfoRow('Client:', order['clientName']),
                _buildInfoRow('Vendor:', order['vendorName']),
                _buildInfoRow('Stall Location:', order['stallLocation']),
                _buildInfoRow('Destination:', order['destinationLocation']),
                _buildInfoRow('Payment Method:', order['paymentMethod']),
                _buildInfoRow('Payment Status:', order['paymentStatus']),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Items
                Text(
                  'Items',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Item headers
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
                
                // Item list
                ...order['items'].map<Widget>((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(item['name']),
                        ),
                        Expanded(
                          child: Text(
                            item['quantity'],
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item['price'],
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
                
                // Order summary
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Products Subtotal:',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        order['productsTotal'],
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
                        'Delivery Fee:',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        order['deliveryFee'],
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
                        order['totalAmount'],
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
                          const SnackBar(content: Text('Contact feature coming soon!')),
                        );
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Contact'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Track order feature coming soon!')),
                        );
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Track Order'),
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Delivered':
        return Icons.check_circle_outline;
      case 'In Transit':
        return Icons.local_shipping_outlined;
      case 'Processing':
        return Icons.pending_outlined;
      case 'Cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
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