import 'package:flutter/material.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({Key? key}) : super(key: key);

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  String _filterStatus = 'All';
  final List<String> _statusOptions = ['All', 'Pending', 'Processing', 'Completed', 'Cancelled'];
  
  // Dummy data for orders
  final List<Map<String, dynamic>> _orders = [
    {
      'id': 'ORD-2025-001',
      'client': 'John Doe',
      'vendor': 'Samuel',
      'stall': 'Fruit Stall',
      'date': '10 May 2025',
      'amount': 'KES 1,200',
      'status': 'Completed',
      'items': [
        {'name': 'Mangoes', 'quantity': 2, 'price': 'KES 300'},
        {'name': 'Apples', 'quantity': 3, 'price': 'KES 600'},
      ],
    },
    {
      'id': 'ORD-2025-002',
      'client': 'Jane Smith',
      'vendor': 'Mary',
      'stall': 'Vegetable Stall',
      'date': '11 May 2025',
      'amount': 'KES 850',
      'status': 'Processing',
      'items': [
        {'name': 'Tomatoes', 'quantity': 1, 'price': 'KES 350'},
        {'name': 'Onions', 'quantity': 2, 'price': 'KES 200'},
        {'name': 'Spinach', 'quantity': 1, 'price': 'KES 300'},
      ],
    },
    {
      'id': 'ORD-2025-003',
      'client': 'Robert Johnson',
      'vendor': 'Samuel',
      'stall': 'Fruit Stall',
      'date': '09 May 2025',
      'amount': 'KES 2,200',
      'status': 'Completed',
      'items': [
        {'name': 'Watermelon', 'quantity': 1, 'price': 'KES 800'},
        {'name': 'Bananas', 'quantity': 2, 'price': 'KES 400'},
        {'name': 'Oranges', 'quantity': 5, 'price': 'KES 1,000'},
      ],
    },
    {
      'id': 'ORD-2025-004',
      'client': 'Emily Williams',
      'vendor': 'Mary',
      'stall': 'Vegetable Stall',
      'date': '11 May 2025',
      'amount': 'KES 450',
      'status': 'Pending',
      'items': [
        {'name': 'Carrots', 'quantity': 1, 'price': 'KES 150'},
        {'name': 'Potatoes', 'quantity': 2, 'price': 'KES 300'},
      ],
    },
    {
      'id': 'ORD-2025-005',
      'client': 'David Brown',
      'vendor': 'Samuel',
      'stall': 'Fruit Stall',
      'date': '08 May 2025',
      'amount': 'KES 1,800',
      'status': 'Cancelled',
      'items': [
        {'name': 'Grapes', 'quantity': 2, 'price': 'KES 800'},
        {'name': 'Pineapples', 'quantity': 2, 'price': 'KES 1,000'},
      ],
    },
  ];

  List<Map<String, dynamic>> get filteredOrders {
    if (_filterStatus == 'All') {
      return _orders;
    } else {
      return _orders.where((order) => order['status'] == _filterStatus).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Orders"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterChips(theme, isDark),
          Expanded(
            child: _buildOrdersList(theme, isDark),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action for generating reports or adding orders
        },
        child: const Icon(Icons.assignment_outlined),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusOptions.map((status) {
            final isSelected = _filterStatus == status;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    _filterStatus = status;
                  });
                },
                backgroundColor: isDark ? theme.cardColor : theme.scaffoldBackgroundColor,
                selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                checkmarkColor: theme.colorScheme.primary,
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.dividerColor,
                  width: 1,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrdersList(ThemeData theme, bool isDark) {
    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              "No orders found",
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderCard(order, theme, isDark);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, ThemeData theme, bool isDark) {
    Color statusColor;
    IconData statusIcon;

    switch (order['status']) {
      case 'Completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Processing':
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
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
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showOrderDetails(order);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order['id'],
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    label: Text(
                      order['status'],
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: statusColor.withOpacity(0.1),
                    avatar: Icon(statusIcon, color: statusColor, size: 16),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      Icons.person_outline,
                      'Client',
                      order['client'],
                      theme,
                      isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoRow(
                      Icons.store_outlined,
                      'Vendor',
                      order['vendor'],
                      theme,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      Icons.calendar_today_outlined,
                      'Date',
                      order['date'],
                      theme,
                      isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoRow(
                      Icons.attach_money_outlined,
                      'Amount',
                      order['amount'],
                      theme,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${order['items'].length} items",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text("View Details"),
                    onPressed: () {
                      _showOrderDetails(order);
                    },
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, ThemeData theme, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        Color statusColor;
        switch (order['status']) {
          case 'Completed':
            statusColor = Colors.green;
            break;
          case 'Processing':
            statusColor = Colors.blue;
            break;
          case 'Pending':
            statusColor = Colors.orange;
            break;
          case 'Cancelled':
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.grey;
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Order Details",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            order['status'],
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Order Information",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow("Order ID", order['id'], theme),
                    _buildDetailRow("Date", order['date'], theme),
                    _buildDetailRow("Total Amount", order['amount'], theme),
                    const SizedBox(height: 24),
                    Text(
                      "Customer & Vendor",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow("Client", order['client'], theme),
                    _buildDetailRow("Vendor", order['vendor'], theme),
                    _buildDetailRow("Stall", order['stall'], theme),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Order Items",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${order['items'].length} items",
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(
                      order['items'].length,
                      (index) => _buildOrderItemCard(
                          order['items'][index], theme, isDark),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle appropriate action based on status
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          order['status'] == 'Completed' || order['status'] == 'Cancelled'
                              ? "Close"
                              : order['status'] == 'Processing'
                                  ? "Mark as Completed"
                                  : "Process Order",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(
      Map<String, dynamic> item, ThemeData theme, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark
          ? theme.cardColor.withOpacity(0.5)
          : theme.colorScheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.shopping_basket_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Quantity: ${item['quantity']}",
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Text(
              item['price'],
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}