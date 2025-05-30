import 'package:flutter/material.dart';
import 'package:fresh_marikiti/config/theme.dart';
import 'package:fresh_marikiti/services/order_service.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _newOrders = [];
  List<Map<String, dynamic>> _processingOrders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final orders = await OrderService.fetchVendorOrders();
      setState(() {
        _newOrders = orders.where((o) => _isNewStatus(o['status'] ?? o['orderStatus'])).toList();
        _processingOrders = orders.where((o) => !_isNewStatus(o['status'] ?? o['orderStatus'])).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  bool _isNewStatus(String? status) {
    if (status == null) return false;
    final s = status.toLowerCase();
    return s == 'pending' || s == 'confirmed';
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _fetchOrders,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrdersList(_newOrders, isNew: true),
                      _buildOrdersList(_processingOrders, isNew: false),
                    ],
                  ),
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
    final items = (order['products'] as List?)?.map((item) {
      final product = item['product'];
      return {
        'name': product is Map ? (product['name'] ?? 'Product') : 'Product',
        'quantity': item['quantity'] ?? 1,
        'unit': '',
      };
    }).toList() ?? [];
    final customer = order['customer'] is Map ? order['customer']['name'] : order['customer']?.toString() ?? '';
    final status = order['status'] ?? order['orderStatus'] ?? '';
    final total = order['totalPrice'] ?? order['total'] ?? 0;
    final id = order['id'] ?? order['_id'] ?? '';

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
                  'Order $id',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Customer: $customer',
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
                      'KES $total',
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
            Text('Are you sure you want to reject order ${order['id'] ?? order['_id'] ?? ''}?'),
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
            onPressed: () async {
              await _updateOrderStatus(order, 'rejected');
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

  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    await _updateOrderStatus(order, 'processing');
  }

  Future<void> _markAsReady(Map<String, dynamic> order) async {
    await _updateOrderStatus(order, 'ready');
  }

  Future<void> _updateOrderStatus(Map<String, dynamic> order, String status) async {
    final id = order['id'] ?? order['_id'] ?? '';
    final success = await OrderService.updateOrderStatus(id, status);
    if (success) {
      await _fetchOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order status')),
      );
    }
  }
} 