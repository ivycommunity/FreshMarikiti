import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fresh_marikiti/core/models/vendor_models.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/utils/api_endpoints.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({Key? key}) : super(key: key);

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen>
    with TickerProviderStateMixin {
  List<VendorOrder> _orders = [];
  List<VendorOrder> _filteredOrders = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterOptions = [
    'all',
    'pending',
    'accepted',
    'preparing',
    'ready',
    'completed',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterOptions.length, vsync: this);
    _loadOrders();
    _setupPeriodicRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _setupPeriodicRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadOrders(showLoading: false);
        _setupPeriodicRefresh();
      }
    });
  }

  Future<void> _loadOrders({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.get(ApiEndpoints.vendorOrders);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> ordersJson = data['orders'] ?? [];
        
        setState(() {
          _orders = ordersJson.map((json) => VendorOrder.fromJson(json)).toList();
          _filterOrders();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading orders: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterOrders() {
    List<VendorOrder> filtered = _orders;

    // Filter by status
    if (_selectedFilter != 'all') {
      filtered = filtered.where((order) => 
        order.status.toLowerCase() == _selectedFilter.toLowerCase()).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) =>
        order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        order.connectorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        order.customerName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _filteredOrders = filtered;
    });
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.put(
        ApiEndpoints.vendorOrderStatus(orderId),
        {'status': status},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order status updated to $status'),
              backgroundColor: Colors.green,
            ),
          );
          _loadOrders();
        }
      } else {
        throw Exception('Failed to update order status');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Orders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadOrders(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredOrders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => _loadOrders(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      return _buildOrderCard(order);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Orders will appear here when customers place them',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(VendorOrder order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id}',
                          style: const TextStyle(
                          fontSize: 16,
                            fontWeight: FontWeight.bold,
                        ),
                      ),
                        Text(
                        'Customer: ${order.customerName}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                          color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(12),
                        ),
                  child: Text(
                          order.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                            fontWeight: FontWeight.bold,
                    ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
                        Text(
              'Total: KSh ${NumberFormat('#,###').format(order.totalAmount)}',
                          style: const TextStyle(
                fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      const SizedBox(height: 8),
                            Text(
              'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(order.createdAt)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                            fontSize: 12,
              ),
            ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                    onPressed: () => _showOrderDetails(order),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                if (order.status == 'pending')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateOrderStatus(order.id, 'accepted'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                        ),
                        child: const Text('Accept', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                if (order.status == 'accepted')
                  Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateOrderStatus(order.id, 'preparing'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                    ),
                    child: const Text('Start Preparing', style: TextStyle(color: Colors.white)),
                  ),
                ),
                if (order.status == 'preparing')
                  Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateOrderStatus(order.id, 'ready'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text('Mark Ready', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            ],
        ),
      ),
    );
  }

  void _showOrderDetails(VendorOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
        child: Padding(
          padding: const EdgeInsets.all(20),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Row(
              children: [
                  Expanded(
                    child: Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                      ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
              const SizedBox(height: 16),
              Text('Customer: ${order.customerName}'),
              Text('Connector: ${order.connectorName}'),
              Text('Total: KSh ${NumberFormat('#,###').format(order.totalAmount)}'),
              Text('Status: ${order.status.toUpperCase()}'),
              Text('Date: ${DateFormat('MMM dd, yyyy HH:mm').format(order.createdAt)}'),
              // Add more order details here
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Placeholder VendorOrder model - this should be defined in vendor_models.dart
class VendorOrder {
  final String id;
  final String customerName;
  final String connectorName;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  VendorOrder({
    required this.id,
    required this.customerName,
    required this.connectorName,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory VendorOrder.fromJson(Map<String, dynamic> json) {
    return VendorOrder(
      id: json['id'] ?? '',
      customerName: json['customerName'] ?? '',
      connectorName: json['connectorName'] ?? '',
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
} 