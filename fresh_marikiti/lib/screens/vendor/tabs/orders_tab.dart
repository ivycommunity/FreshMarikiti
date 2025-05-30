import 'package:flutter/material.dart';
import 'package:fresh_marikiti/config/theme.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dummy data - replace with actual orders
  final List<Map<String, dynamic>> _newOrders = [
    {
      'id': 'ORD001',
      'customer': 'John Doe',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'Pending',
      'total': 450.0,
      'items': [
        {'name': 'Fresh Tomatoes', 'quantity': 2, 'unit': 'kg'},
        {'name': 'Red Onions', 'quantity': 1, 'unit': 'kg'},
      ],
    },
  ];

  final List<Map<String, dynamic>> _processingOrders = [
    {
      'id': 'ORD000',
      'customer': 'Jane Smith',
      'date': DateTime.now().subtract(const Duration(hours: 4)),
      'status': 'Processing',
      'total': 850.0,
      'items': [
        {'name': 'Potatoes', 'quantity': 5, 'unit': 'kg'},
        {'name': 'Carrots', 'quantity': 2, 'unit': 'kg'},
      ],
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
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'New Orders'),
            Tab(text: 'Processing'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(_newOrders, isNew: true),
          _buildOrdersList(_processingOrders, isNew: false),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders, {required bool isNew}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isNew ? 'No new orders' : 'No orders in progress',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 8),
            Text(
              isNew
                  ? 'New orders will appear here'
                  : 'Orders in progress will appear here',
              style: AppTextStyles.body.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order, isNew);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isNew) {
    final items = order['items'] as List<Map<String, dynamic>>;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ${order['id']}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(order['status']),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Customer: ${order['customer']}',
              style: AppTextStyles.body,
            ),
            const Divider(height: 24),
            // Order Items
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['name'],
                    style: AppTextStyles.body,
                  ),
                  Text(
                    '${item['quantity']} ${item['unit']}',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
            )),
            const Divider(height: 24),
            // Order Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: AppTextStyles.caption,
                    ),
                    Text(
                      'KES ${order['total']}',
                      style: AppTextStyles.body.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (isNew)
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          _showRejectDialog(order);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.errorRed,
                        ),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          _acceptOrder(order);
                        },
                        child: const Text('Accept'),
                      ),
                    ],
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      _markAsReady(order);
                    },
                    child: const Text('Mark as Ready'),
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
      case 'pending':
        color = Colors.orange;
        break;
      case 'processing':
        color = Colors.blue;
        break;
      case 'ready':
        color = AppTheme.primaryGreen;
        break;
      case 'rejected':
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

  Future<void> _showRejectDialog(Map<String, dynamic> order) async {
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject order ${order['id']}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection (optional)',
                hintText: 'Enter reason...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement reject functionality
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _acceptOrder(Map<String, dynamic> order) {
    // TODO: Implement accept functionality
  }

  void _markAsReady(Map<String, dynamic> order) {
    // TODO: Implement mark as ready functionality
  }
} 