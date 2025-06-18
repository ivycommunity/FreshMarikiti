import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fresh_marikiti/core/models/vendor_admin_models.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/utils/api_endpoints.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class StallManagementScreen extends StatefulWidget {
  const StallManagementScreen({Key? key}) : super(key: key);

  @override
  State<StallManagementScreen> createState() => _StallManagementScreenState();
}

class _StallManagementScreenState extends State<StallManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<MarketStall> _stalls = [];
  List<MarketStall> _filteredStalls = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();
  final List<String> _statusFilters = ['all', 'active', 'inactive', 'pending'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStalls();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterStalls();
    });
  }

  Future<void> _loadStalls() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.get(ApiEndpoints.vendorAdminStalls);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _stalls = (data['stalls'] as List)
              .map((stall) => MarketStall.fromJson(stall))
              .toList();
          _filteredStalls = _stalls;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load stalls');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading stalls: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterStalls() {
    _filteredStalls = _stalls.where((stall) {
      final matchesStatus = _selectedFilter == 'all' || stall.status == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          stall.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          stall.vendorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          stall.location.toLowerCase().contains(_searchQuery.toLowerCase());
      
      return matchesStatus && matchesSearch;
    }).toList();
  }

  Future<void> _updateStallStatus(String stallId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.put(
        ApiEndpoints.vendorAdminStallStatus(stallId),
        {'status': status},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stall status updated to $status'),
              backgroundColor: Colors.green,
            ),
          );
          _loadStalls();
        }
      } else {
        throw Exception('Failed to update stall status');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating stall: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteStall(String stallId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.delete(ApiEndpoints.vendorAdminStall(stallId));

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stall deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadStalls();
        }
      } else {
        throw Exception('Failed to delete stall');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting stall: ${e.toString()}'),
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
          'Stall Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddStallDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadStalls(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Stalls', icon: Icon(Icons.store)),
            Tab(text: 'Performance', icon: Icon(Icons.trending_up)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStallsTab(),
                _buildPerformanceTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildStallsTab() {
    return Column(
      children: [
        _buildFilterHeader(),
        Expanded(
          child: _buildStallsList(),
        ),
      ],
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search stalls by name, vendor, or location...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 12),
          
          // Filters
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _statusFilters.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                      _filterStalls();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showAddStallDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Stall'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Results Count
          Text(
            'Showing ${_filteredStalls.length} of ${_stalls.length} stalls',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStallsList() {
    if (_filteredStalls.isEmpty) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadStalls(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredStalls.length,
        itemBuilder: (context, index) {
          final stall = _filteredStalls[index];
          return _buildStallCard(stall);
        },
      ),
    );
  }

  Widget _buildStallCard(MarketStall stall) {
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
                CircleAvatar(
                  backgroundColor: _getStatusColor(stall.status).withOpacity(0.2),
                  child: Icon(
                    Icons.store,
                    color: _getStatusColor(stall.status),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stall.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${stall.id}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(stall.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    stall.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleStallAction(value, stall),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit Stall'),
                        ],
                      ),
                    ),
                    if (stall.status == 'active')
                      const PopupMenuItem(
                        value: 'deactivate',
                        child: Row(
                          children: [
                            Icon(Icons.pause),
                            SizedBox(width: 8),
                            Text('Deactivate'),
                          ],
                        ),
                      ),
                    if (stall.status == 'inactive')
                      const PopupMenuItem(
                        value: 'activate',
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow),
                            SizedBox(width: 8),
                            Text('Activate'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStallDetailItem(
                    'Vendor',
                    stall.vendorName,
                    Icons.person,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStallDetailItem(
                    'Location',
                    stall.location,
                    Icons.location_on,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStallDetailItem(
                    'Today Revenue',
                    'KSh ${NumberFormat('#,###').format(stall.todayRevenue)}',
                    Icons.monetization_on,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStallDetailItem(
                    'Products',
                    stall.productCount.toString(),
                    Icons.inventory,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStallDetailItem(
                    'Created',
                    DateFormat('MMM dd, yyyy').format(stall.assignedDate),
                    Icons.calendar_today,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildStallDetailItem(
                    'Rating',
                    '${stall.rating.toStringAsFixed(1)} ⭐',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStallDetailItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return RefreshIndicator(
      onRefresh: () => _loadStalls(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPerformanceOverview(),
            const SizedBox(height: 16),
            _buildTopPerformingStalls(),
            const SizedBox(height: 16),
            _buildRevenueComparison(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceOverview() {
    final totalRevenue = _stalls.fold<double>(0, (sum, stall) => sum + stall.todayRevenue);
    final avgRating = _stalls.isEmpty ? 0.0 : _stalls.fold<double>(0, (sum, stall) => sum + stall.rating) / _stalls.length;
    final activeStalls = _stalls.where((s) => s.status == 'active').length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Total Revenue',
                    'KSh ${NumberFormat('#,###').format(totalRevenue)}',
                    Icons.monetization_on,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Active Stalls',
                    '$activeStalls/${_stalls.length}',
                    Icons.store,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Avg Rating',
                    '${avgRating.toStringAsFixed(1)} ⭐',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Total Products',
                    _stalls.fold<int>(0, (sum, stall) => sum + stall.productCount).toString(),
                    Icons.inventory,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformingStalls() {
    final topStalls = List<MarketStall>.from(_stalls)
      ..sort((a, b) => b.todayRevenue.compareTo(a.todayRevenue))
      ..take(5);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Performing Stalls',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...topStalls.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final stall = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: index == 0 ? Colors.amber : 
                               index == 1 ? Colors.grey[400] : 
                               Colors.brown[300],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stall.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            stall.vendorName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'KSh ${NumberFormat('#,###').format(stall.todayRevenue)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueComparison() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Comparison',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Revenue distribution across stalls for today',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _stalls.length,
                itemBuilder: (context, index) {
                  final stall = _stalls[index];
                  final maxRevenue = _stalls.isEmpty ? 1.0 : _stalls.map((s) => s.todayRevenue).reduce((a, b) => a > b ? a : b);
                  final percentage = maxRevenue == 0 ? 0.0 : (stall.todayRevenue / maxRevenue);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            stall.name,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green.withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'KSh ${NumberFormat('#,###').format(stall.todayRevenue)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGeneralSettings(),
          const SizedBox(height: 16),
          _buildStallCategories(),
          const SizedBox(height: 16),
          _buildNotificationSettings(),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'General Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Auto-approve new stalls'),
              subtitle: const Text('Automatically approve stall registration'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: const Text('Real-time notifications'),
              subtitle: const Text('Get notified of stall activities'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Performance tracking'),
              subtitle: const Text('Track stall performance metrics'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStallCategories() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Stall Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _showAddCategoryDialog(),
                  child: const Text('Add Category'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Manage categories for organizing stalls'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Vegetables',
                'Fruits',
                'Grains',
                'Dairy',
                'Meat',
                'Spices',
              ].map((category) => Chip(
                label: Text(category),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {},
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.store_mall_directory),
              title: const Text('New stall registration'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
            ListTile(
              leading: const Icon(Icons.warning),
              title: const Text('Stall performance alerts'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Payment notifications'),
              trailing: Switch(
                value: false,
                onChanged: (value) {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _handleStallAction(String action, MarketStall stall) {
    switch (action) {
      case 'view':
        _showStallDetailsDialog(stall);
        break;
      case 'edit':
        _showEditStallDialog(stall);
        break;
      case 'activate':
        _updateStallStatus(stall.id, 'active');
        break;
      case 'deactivate':
        _updateStallStatus(stall.id, 'inactive');
        break;
      case 'delete':
        _deleteStall(stall.id);
        break;
    }
  }

  void _showStallDetailsDialog(MarketStall stall) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stall Details - ${stall.name}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${stall.id}'),
              Text('Vendor: ${stall.vendorName}'),
              Text('Status: ${stall.status.toUpperCase()}'),
              Text('Location: ${stall.location}'),
              Text('Today Revenue: KSh ${NumberFormat('#,###').format(stall.todayRevenue)}'),
              Text('Products: ${stall.productCount}'),
              Text('Rating: ${stall.rating.toStringAsFixed(1)} ⭐'),
              Text('Created: ${DateFormat('MMM dd, yyyy').format(stall.assignedDate)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEditStallDialog(MarketStall stall) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit stall functionality would be implemented here')),
    );
  }

  void _showAddStallDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add stall functionality would be implemented here')),
    );
  }

  void _showAddCategoryDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add category functionality would be implemented here')),
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          SizedBox(height: 16),
          Text(
            'Failed to load stalls',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          Text(
            'Please try again later',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class MarketStall {
  final String id;
  final String name;
  final String vendorName;
  final String vendorId;
  final String location;
  final String status;
  final double size;
  final double monthlyRent;
  final DateTime assignedDate;
  final bool isPaid;
  final String category;
  final double todayRevenue;
  final int productCount;
  final double rating;

  MarketStall({
    required this.id,
    required this.name,
    required this.vendorName,
    required this.vendorId,
    required this.location,
    required this.status,
    required this.size,
    required this.monthlyRent,
    required this.assignedDate,
    required this.isPaid,
    required this.category,
    required this.todayRevenue,
    required this.productCount,
    required this.rating,
  });

  factory MarketStall.fromJson(Map<String, dynamic> json) {
    return MarketStall(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      vendorName: json['vendorName'] ?? '',
      vendorId: json['vendorId'] ?? '',
      location: json['location'] ?? '',
      status: json['status'] ?? '',
      size: (json['size'] ?? 0).toDouble(),
      monthlyRent: (json['monthlyRent'] ?? 0).toDouble(),
      assignedDate: DateTime.parse(json['assignedDate'] ?? DateTime.now().toIso8601String()),
      isPaid: json['isPaid'] ?? false,
      category: json['category'] ?? '',
      todayRevenue: (json['todayRevenue'] ?? 0).toDouble(),
      productCount: json['productCount'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
    );
  }
} 