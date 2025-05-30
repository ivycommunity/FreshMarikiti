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
  final List<Map<String, dynamic>> _activeOrders = [
    {
      'id': 'ORD001',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'Processing',
      'total': 450.0,
      'items': [
        {'name': 'Fresh Tomatoes', 'quantity': 2, 'unit': 'kg'},
        {'name': 'Red Onions', 'quantity': 1, 'unit': 'kg'},
      ],
    },
  ];

  final List<Map<String, dynamic>> _pastOrders = [
    {
      'id': 'ORD000',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'status': 'Delivered',
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
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active Orders'),
            Tab(text: 'Past Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(_activeOrders, isActive: true),
          _buildOrdersList(_pastOrders, isActive: false),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders, {required bool isActive}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.local_shipping_outlined : Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active orders' : 'No order history',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 8),
            Text(
              isActive ? 'Your active orders will appear here' : 'Your past orders will appear here',
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
        return _buildOrderCard(order, isActive);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isActive) {
    final date = order['date'] as DateTime;
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
                if (isActive)
                  ElevatedButton(
                    onPressed: () {
                      // Track order
                    },
                    child: const Text('Track Order'),
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
      case 'processing':
        color = Colors.blue;
        break;
      case 'delivered':
        color = AppTheme.primaryGreen;
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