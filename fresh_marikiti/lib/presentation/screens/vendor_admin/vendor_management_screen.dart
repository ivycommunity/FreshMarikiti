import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fresh_marikiti/core/models/vendor_admin_models.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/utils/api_endpoints.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class VendorManagementScreen extends StatefulWidget {
  const VendorManagementScreen({Key? key}) : super(key: key);

  @override
  State<VendorManagementScreen> createState() => _VendorManagementScreenState();
}

class _VendorManagementScreenState extends State<VendorManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<VendorInfo> _vendors = [];
  List<VendorInfo> _filteredVendors = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();
  final List<String> _statusFilters = ['all', 'active', 'inactive', 'pending', 'training'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVendors();
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
      _filterVendors();
    });
  }

  Future<void> _loadVendors() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.get(ApiEndpoints.vendorAdminVendors);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _vendors = (data['vendors'] as List)
              .map((vendor) => VendorInfo.fromJson(vendor))
              .toList();
          _filteredVendors = _vendors;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load vendors');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading vendors: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterVendors() {
    _filteredVendors = _vendors.where((vendor) {
      final matchesStatus = _selectedFilter == 'all' || vendor.status == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          vendor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          vendor.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          vendor.phone.contains(_searchQuery) ||
          vendor.stallName.toLowerCase().contains(_searchQuery.toLowerCase());
      
      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Vendor Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: () => _showOnboardVendorDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadVendors(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Vendors', icon: Icon(Icons.people)),
            Tab(text: 'Onboarding', icon: Icon(Icons.school)),
            Tab(text: 'Support', icon: Icon(Icons.support_agent)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVendorsTab(),
                _buildOnboardingTab(),
                _buildSupportTab(),
              ],
            ),
    );
  }

  Widget _buildVendorsTab() {
    return Column(
      children: [
        _buildFilterHeader(),
        Expanded(
          child: _buildVendorsList(),
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
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search vendors by name, email, phone, or stall...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 12),
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
                      _filterVendors();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showOnboardVendorDialog(),
                icon: const Icon(Icons.person_add),
                label: const Text('Onboard Vendor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Managing ${_filteredVendors.length} of ${_vendors.length} vendors',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorsList() {
    if (_filteredVendors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No vendors found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start onboarding vendors to your market',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadVendors(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredVendors.length,
        itemBuilder: (context, index) {
          final vendor = _filteredVendors[index];
          return _buildVendorCard(vendor);
        },
      ),
    );
  }

  Widget _buildVendorCard(VendorInfo vendor) {
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
                  backgroundColor: _getStatusColor(vendor.status).withOpacity(0.2),
                  child: Icon(
                    _getVendorIcon(vendor.status),
                    color: _getStatusColor(vendor.status),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        vendor.stallName,
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
                    color: _getStatusColor(vendor.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vendor.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleVendorAction(value, vendor),
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
                          Text('Edit Vendor'),
                        ],
                      ),
                    ),
                    if (vendor.status == 'training')
                      const PopupMenuItem(
                        value: 'complete_training',
                        child: Row(
                          children: [
                            Icon(Icons.school),
                            SizedBox(width: 8),
                            Text('Complete Training'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'support',
                      child: Row(
                        children: [
                          Icon(Icons.support_agent),
                          SizedBox(width: 8),
                          Text('Provide Support'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'performance',
                      child: Row(
                        children: [
                          Icon(Icons.trending_up),
                          SizedBox(width: 8),
                          Text('View Performance'),
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
                  child: _buildVendorDetailItem(
                    'Phone',
                    vendor.phone,
                    Icons.phone,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildVendorDetailItem(
                    'Email',
                    vendor.email,
                    Icons.email,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildVendorDetailItem(
                    'Products',
                    vendor.productCount.toString(),
                    Icons.inventory,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildVendorDetailItem(
                    'Rating',
                    '${vendor.rating.toStringAsFixed(1)} ⭐',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildVendorDetailItem(
                    'Joined',
                    DateFormat('MMM dd, yyyy').format(vendor.joinDate),
                    Icons.calendar_today,
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildVendorDetailItem(
                    'Tech Level',
                    _getTechLevelText(vendor.techSavvyLevel),
                    Icons.computer,
                    _getTechLevelColor(vendor.techSavvyLevel),
                  ),
                ),
              ],
            ),
            if (vendor.needsSupport) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.help, color: Colors.orange[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Requires additional support',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _provideSupportToVendor(vendor),
                      child: const Text('Help', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVendorDetailItem(String label, String value, IconData icon, Color color) {
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

  Widget _buildOnboardingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOnboardingStats(),
          const SizedBox(height: 16),
          _buildOnboardingProcess(),
          const SizedBox(height: 16),
          _buildTrainingModules(),
          const SizedBox(height: 16),
          _buildRecentOnboardings(),
        ],
      ),
    );
  }

  Widget _buildOnboardingStats() {
    final inTraining = _vendors.where((v) => v.status == 'training').length;
    final completed = _vendors.where((v) => v.status == 'active').length;
    final needSupport = _vendors.where((v) => v.needsSupport).length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Onboarding Overview',
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
                    'In Training',
                    inTraining.toString(),
                    Icons.school,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Completed',
                    completed.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Need Support',
                    needSupport.toString(),
                    Icons.help,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingProcess() {
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
                  'Onboarding Process',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showOnboardVendorDialog(),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Start Onboarding'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProcessStep(1, 'Registration', 'Collect vendor information', true),
            _buildProcessStep(2, 'Stall Setup', 'Create stall and add products', true),
            _buildProcessStep(3, 'Training', 'App usage and best practices', true),
            _buildProcessStep(4, 'Launch', 'Go live and start selling', true),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessStep(int step, String title, String description, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text(
                      step.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingModules() {
    final modules = [
      'Basic App Navigation',
      'Product Management',
      'Order Processing',
      'Customer Communication',
      'Payment Handling',
      'Eco-Points System',
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Training Modules',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...modules.map((module) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.play_circle_outline, color: Colors.green[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      module,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openTrainingModule(module),
                    child: const Text('View'),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOnboardings() {
    final recentVendors = _vendors.take(5).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Onboardings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...recentVendors.map((vendor) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _getStatusColor(vendor.status).withOpacity(0.2),
                    child: Icon(
                      _getVendorIcon(vendor.status),
                      color: _getStatusColor(vendor.status),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          vendor.stallName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd').format(vendor.joinDate),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSupportOverview(),
          const SizedBox(height: 16),
          _buildSupportCategories(),
          const SizedBox(height: 16),
          _buildQuickHelp(),
        ],
      ),
    );
  }

  Widget _buildSupportOverview() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Support Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Helping non tech-savvy vendors succeed on the platform',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Active Support',
                    '12',
                    Icons.support_agent,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Resolved Today',
                    '8',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCategories() {
    final categories = [
      {'title': 'App Navigation', 'icon': Icons.navigation, 'count': 5, 'color': Colors.blue},
      {'title': 'Product Management', 'icon': Icons.inventory, 'count': 3, 'color': Colors.orange},
      {'title': 'Order Processing', 'icon': Icons.shopping_cart, 'count': 4, 'color': Colors.green},
      {'title': 'Payment Issues', 'icon': Icons.payment, 'count': 2, 'color': Colors.purple},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Support Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: categories.map((category) => _buildSupportCategoryCard(category)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCategoryCard(Map<String, dynamic> category) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (category['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (category['color'] as Color).withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            category['icon'] as IconData,
            color: category['color'] as Color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            category['title'] as String,
            style: TextStyle(
              color: category['color'] as Color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '${category['count']} active',
            style: TextStyle(
              color: category['color'] as Color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickHelp() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Help Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.video_call, color: Colors.blue),
              title: const Text('Schedule Video Call'),
              subtitle: const Text('One-on-one training session'),
              trailing: ElevatedButton(
                onPressed: () => _scheduleVideoCall(),
                child: const Text('Schedule'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.green),
              title: const Text('Send Quick Message'),
              subtitle: const Text('Send help instructions via SMS'),
              trailing: ElevatedButton(
                onPressed: () => _sendQuickMessage(),
                child: const Text('Send'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.book, color: Colors.orange),
              title: const Text('Share Tutorial'),
              subtitle: const Text('Send step-by-step guide'),
              trailing: ElevatedButton(
                onPressed: () => _shareTutorial(),
                child: const Text('Share'),
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
              fontSize: 18,
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
      case 'training':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getVendorIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.store;
      case 'inactive':
        return Icons.store_mall_directory_outlined;
      case 'pending':
        return Icons.hourglass_empty;
      case 'training':
        return Icons.school;
      default:
        return Icons.person;
    }
  }

  String _getTechLevelText(int level) {
    switch (level) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Basic';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      default:
        return 'Unknown';
    }
  }

  Color _getTechLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _handleVendorAction(String action, VendorInfo vendor) {
    switch (action) {
      case 'view':
        _showVendorDetailsDialog(vendor);
        break;
      case 'edit':
        _showEditVendorDialog(vendor);
        break;
      case 'complete_training':
        _completeTraining(vendor);
        break;
      case 'support':
        _provideSupportToVendor(vendor);
        break;
      case 'performance':
        _viewPerformance(vendor);
        break;
    }
  }

  void _showVendorDetailsDialog(VendorInfo vendor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vendor Details - ${vendor.name}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: ${vendor.name}'),
              Text('Stall: ${vendor.stallName}'),
              Text('Status: ${vendor.status.toUpperCase()}'),
              Text('Email: ${vendor.email}'),
              Text('Phone: ${vendor.phone}'),
              Text('Products: ${vendor.productCount}'),
              Text('Rating: ${vendor.rating.toStringAsFixed(1)} ⭐'),
              Text('Tech Level: ${_getTechLevelText(vendor.techSavvyLevel)}'),
              Text('Needs Support: ${vendor.needsSupport ? 'Yes' : 'No'}'),
              Text('Joined: ${DateFormat('MMM dd, yyyy').format(vendor.joinDate)}'),
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

  void _showEditVendorDialog(VendorInfo vendor) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit vendor functionality would be implemented here')),
    );
  }

  void _showOnboardVendorDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Onboard vendor functionality would be implemented here')),
    );
  }

  void _completeTraining(VendorInfo vendor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Completing training for ${vendor.name}...')),
    );
  }

  void _provideSupportToVendor(VendorInfo vendor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Providing support to ${vendor.name}...')),
    );
  }

  void _viewPerformance(VendorInfo vendor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing performance for ${vendor.name}...')),
    );
  }

  void _openTrainingModule(String module) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening training module: $module')),
    );
  }

  void _scheduleVideoCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scheduling video call...')),
    );
  }

  void _sendQuickMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sending quick message...')),
    );
  }

  void _shareTutorial() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing tutorial...')),
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
            'Failed to load vendors',
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

class VendorInfo {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String category;
  final String status;
  final double rating;
  final int totalOrders;
  final double totalRevenue;
  final bool isVerified;
  final DateTime joinDate;
  final int productCount;
  final int techSavvyLevel;
  final bool needsSupport;
  final String stallName;

  VendorInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.category,
    required this.status,
    required this.rating,
    required this.totalOrders,
    required this.totalRevenue,
    required this.isVerified,
    required this.joinDate,
    required this.productCount,
    required this.techSavvyLevel,
    required this.needsSupport,
    required this.stallName,
  });

  factory VendorInfo.fromJson(Map<String, dynamic> json) {
    return VendorInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      category: json['category'] ?? '',
      status: json['status'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      isVerified: json['isVerified'] ?? false,
      joinDate: DateTime.parse(json['joinDate'] ?? DateTime.now().toIso8601String()),
      productCount: json['productCount'] ?? 0,
      techSavvyLevel: json['techSavvyLevel'] ?? 1,
      needsSupport: json['needsSupport'] ?? false,
      stallName: json['stallName'] ?? '',
    );
  }
} 