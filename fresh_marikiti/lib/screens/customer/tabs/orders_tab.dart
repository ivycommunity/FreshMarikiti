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
  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _pastOrders = [];
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
      final orders = await OrderService.fetchOrders();
      setState(() {
        _activeOrders = orders.where((o) => _isActiveStatus(o['status'] ?? o['orderStatus'])).toList();
        _pastOrders = orders.where((o) => !_isActiveStatus(o['status'] ?? o['orderStatus'])).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  bool _isActiveStatus(String? status) {
    if (status == null) return false;
    final s = status.toLowerCase();
    return s == 'pending' || s == 'processing' || s == 'placed' || s == 'confirmed';
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _fetchOrders,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrdersList(_activeOrders, isActive: true),
                      _buildOrdersList(_pastOrders, isActive: false),
                    ],
                  ),
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
    final date = order['createdAt'] != null ? DateTime.tryParse(order['createdAt']) : null;
    final items = order['products'] ?? order['items'] ?? [];
    final total = order['totalAmount'] ?? order['total'] ?? order['totalPrice'] ?? 0;
    final status = order['status'] ?? order['orderStatus'] ?? 'Unknown';
    final deliveryAddress = order['deliveryAddress'] ?? '';

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
                  'Order ${order['id'] ?? order['_id'] ?? ''}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            if (date != null) ...[
              const SizedBox(height: 4),
              Text(
                '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                style: AppTextStyles.caption,
              ),
            ],
            const Divider(height: 24),
            // Order Items
            ...items.map<Widget>((item) {
              final name = item['name'] ?? item['product']?['name'] ?? 'Product';
              final quantity = item['quantity'] ?? 1;
              final unit = item['unit'] ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.body,
                    ),
                    Text(
                      '$quantity $unit',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              );
            }),
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
                if (isActive)
                  ElevatedButton(
                    onPressed: () {
                      _showOrderTrackingDialog(context, order);
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

  void _showOrderTrackingDialog(BuildContext context, Map<String, dynamic> order) {
    final status = order['status'] ?? order['orderStatus'] ?? 'Unknown';
    final items = order['products'] ?? order['items'] ?? [];
    final total = order['totalAmount'] ?? order['total'] ?? order['totalPrice'] ?? 0;
    final deliveryAddress = order['deliveryAddress'] ?? '';
    final date = order['createdAt'] != null ? DateTime.tryParse(order['createdAt']) : null;
    final connector = order['assignedConnector'];
    final rider = order['assignedRider'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Tracking'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Status: ',
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    status,
                    style: AppTextStyles.body,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (date != null)
                Text(
                  'Placed: ${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                  style: AppTextStyles.caption,
                ),
              const SizedBox(height: 12),
              if (deliveryAddress.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        deliveryAddress,
                        style: AppTextStyles.body,
                      ),
                    ),
                  ],
                ),
              if (connector != null && connector is Map && (connector['name'] != null || connector['phoneNumber'] != null)) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.handshake_outlined, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text('Connector:', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (connector['name'] != null) Text('Name: ${connector['name']}', style: AppTextStyles.body),
                      if (connector['phoneNumber'] != null) Text('Phone: ${connector['phoneNumber']}', style: AppTextStyles.body),
                    ],
                  ),
                ),
              ],
              if (rider != null && rider is Map && (rider['name'] != null || rider['phoneNumber'] != null)) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.delivery_dining_outlined, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('Rider:', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 32, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (rider['name'] != null) Text('Name: ${rider['name']}', style: AppTextStyles.body),
                      if (rider['phoneNumber'] != null) Text('Phone: ${rider['phoneNumber']}', style: AppTextStyles.body),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text('Items:', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
              ...items.map<Widget>((item) {
                final name = item['name'] ?? item['product']?['name'] ?? 'Product';
                final quantity = item['quantity'] ?? 1;
                final unit = item['unit'] ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: AppTextStyles.body),
                      Text('$quantity $unit', style: AppTextStyles.body),
                    ],
                  ),
                );
              }),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('KES $total', style: AppTextStyles.body.copyWith(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
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
      case 'pending':
        color = Colors.orange;
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