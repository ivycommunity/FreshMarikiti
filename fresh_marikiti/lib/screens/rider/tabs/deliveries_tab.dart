import 'package:flutter/material.dart';
import 'package:fresh_marikiti/config/theme.dart';

class DeliveriesTab extends StatefulWidget {
  const DeliveriesTab({super.key});

  @override
  State<DeliveriesTab> createState() => _DeliveriesTabState();
}

class _DeliveriesTabState extends State<DeliveriesTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isOnline = false;

  // Dummy data - replace with actual deliveries
  final List<Map<String, dynamic>> _activeDeliveries = [
    {
      'id': 'DEL001',
      'customer': 'John Doe',
      'pickup': 'Green Market Stall #12',
      'dropoff': '123 Main St, Apartment 4B',
      'status': 'Picking Up',
      'items': [
        {'name': 'Fresh Tomatoes', 'quantity': 2, 'unit': 'kg'},
        {'name': 'Red Onions', 'quantity': 1, 'unit': 'kg'},
      ],
      'total': 450.0,
      'distance': 3.5,
      'earnings': 250.0,
    },
  ];

  final List<Map<String, dynamic>> _deliveryHistory = [
    {
      'id': 'DEL000',
      'customer': 'Jane Smith',
      'pickup': 'Central Market Stall #5',
      'dropoff': '456 Oak Ave',
      'status': 'Delivered',
      'items': [
        {'name': 'Potatoes', 'quantity': 5, 'unit': 'kg'},
        {'name': 'Carrots', 'quantity': 2, 'unit': 'kg'},
      ],
      'total': 850.0,
      'distance': 5.2,
      'earnings': 350.0,
      'date': DateTime.now().subtract(const Duration(days: 1)),
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
        title: const Text('Deliveries'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Online/Offline Switch
          Container(
            padding: const EdgeInsets.all(16),
            color: _isOnline ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isOnline ? 'You are Online' : 'You are Offline',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _isOnline ? AppTheme.primaryGreen : Colors.grey[600],
                      ),
                    ),
                    Text(
                      _isOnline
                          ? 'You can receive delivery requests'
                          : 'Go online to start receiving requests',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _isOnline,
                  onChanged: (value) {
                    setState(() {
                      _isOnline = value;
                    });
                  },
                  activeColor: AppTheme.primaryGreen,
                ),
              ],
            ),
          ),
          // Deliveries List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDeliveriesList(_activeDeliveries, isActive: true),
                _buildDeliveriesList(_deliveryHistory, isActive: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveriesList(List<Map<String, dynamic>> deliveries, {required bool isActive}) {
    if (deliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delivery_dining_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active deliveries' : 'No delivery history',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 8),
            Text(
              isActive
                  ? 'New delivery requests will appear here'
                  : 'Your completed deliveries will appear here',
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
      itemCount: deliveries.length,
      itemBuilder: (context, index) {
        final delivery = deliveries[index];
        return _buildDeliveryCard(delivery, isActive);
      },
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery, bool isActive) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ${delivery['id']}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(delivery['status']),
              ],
            ),
            const Divider(height: 24),
            // Pickup Location
            _buildLocationInfo(
              'Pickup',
              delivery['pickup'],
              Icons.store_outlined,
            ),
            const SizedBox(height: 16),
            // Dropoff Location
            _buildLocationInfo(
              'Dropoff',
              delivery['dropoff'],
              Icons.location_on_outlined,
            ),
            const Divider(height: 24),
            // Delivery Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distance',
                      style: AppTextStyles.caption,
                    ),
                    Text(
                      '${delivery['distance']} km',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Earnings',
                      style: AppTextStyles.caption,
                    ),
                    Text(
                      'KES ${delivery['earnings']}',
                      style: AppTextStyles.body.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showDeliveryDetails(delivery);
                  },
                  child: const Text('View Details'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(String title, String address, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Text(
                address,
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'picking up':
        color = Colors.blue;
        break;
      case 'delivering':
        color = Colors.orange;
        break;
      case 'delivered':
        color = AppTheme.primaryGreen;
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

  Future<void> _showDeliveryDetails(Map<String, dynamic> delivery) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Delivery Details',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 24),
              // Customer Info
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Customer'),
                subtitle: Text(delivery['customer']),
              ),
              // Items List
              const SizedBox(height: 16),
              Text(
                'Items',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...(delivery['items'] as List<Map<String, dynamic>>).map(
                (item) => ListTile(
                  title: Text(item['name']),
                  trailing: Text('${item['quantity']} ${item['unit']}'),
                ),
              ),
              const Spacer(),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Open navigation
                      },
                      child: const Text('Navigate'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Update delivery status
                      },
                      child: const Text('Mark as Delivered'),
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
} 