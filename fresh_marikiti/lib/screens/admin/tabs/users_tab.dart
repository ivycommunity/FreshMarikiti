import 'package:flutter/material.dart';
import 'package:fresh_marikiti/config/theme.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Active',
    'Inactive',
    'Blocked',
  ];

  // Dummy data - replace with actual users
  final List<Map<String, dynamic>> _users = [
    {
      'id': 'USR001',
      'name': 'John Doe',
      'email': 'john.doe@example.com',
      'phone': '+254 712 345 678',
      'role': 'Customer',
      'status': 'Active',
      'joinDate': DateTime.now().subtract(const Duration(days: 30)),
      'lastActive': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'id': 'USR002',
      'name': 'Jane Smith',
      'email': 'jane.smith@example.com',
      'phone': '+254 723 456 789',
      'role': 'Vendor',
      'status': 'Active',
      'joinDate': DateTime.now().subtract(const Duration(days: 60)),
      'lastActive': DateTime.now().subtract(const Duration(minutes: 30)),
    },
    {
      'id': 'USR003',
      'name': 'Mike Johnson',
      'email': 'mike.johnson@example.com',
      'phone': '+254 734 567 890',
      'role': 'Rider',
      'status': 'Inactive',
      'joinDate': DateTime.now().subtract(const Duration(days: 45)),
      'lastActive': DateTime.now().subtract(const Duration(days: 5)),
    },
    {
      'id': 'USR004',
      'name': 'Sarah Wilson',
      'email': 'sarah.wilson@example.com',
      'phone': '+254 745 678 901',
      'role': 'Connector',
      'status': 'Active',
      'joinDate': DateTime.now().subtract(const Duration(days: 90)),
      'lastActive': DateTime.now().subtract(const Duration(hours: 1)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All Users'),
            Tab(text: 'Customers'),
            Tab(text: 'Vendors'),
            Tab(text: 'Riders'),
            Tab(text: 'Connectors'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Add new user
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 16),
                // Filters
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = filter == _selectedFilter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersList(null), // All Users
                _buildUsersList('Customer'),
                _buildUsersList('Vendor'),
                _buildUsersList('Rider'),
                _buildUsersList('Connector'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(String? roleFilter) {
    final filteredUsers = _users.where((user) {
      // Apply role filter
      if (roleFilter != null && user['role'] != roleFilter) {
        return false;
      }
      // Apply status filter
      if (_selectedFilter != 'All' &&
          user['status'].toString().toLowerCase() !=
              _selectedFilter.toLowerCase()) {
        return false;
      }
      // Apply search filter
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        return user['name'].toString().toLowerCase().contains(searchTerm) ||
            user['email'].toString().toLowerCase().contains(searchTerm) ||
            user['phone'].toString().toLowerCase().contains(searchTerm);
      }
      return true;
    }).toList();

    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
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
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          _showUserDetails(user);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen,
                    child: Text(
                      user['name'][0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'],
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user['email'],
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(user['status']),
                ],
              ),
              const Divider(height: 24),
              // Details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Role',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user['role'],
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join Date',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(user['joinDate']),
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Active',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(user['lastActive']),
                          style: AppTextStyles.body,
                        ),
                      ],
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

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = AppTheme.primaryGreen;
        break;
      case 'inactive':
        color = Colors.grey;
        break;
      case 'blocked':
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _showUserDetails(Map<String, dynamic> user) async {
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
                'User Details',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 24),
              // User Info
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Name'),
                subtitle: Text(user['name']),
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(user['email']),
              ),
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Phone'),
                subtitle: Text(user['phone']),
              ),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Role'),
                subtitle: Text(user['role']),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Join Date'),
                subtitle: Text(_formatDate(user['joinDate'])),
              ),
              const Spacer(),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Edit user
                      },
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Block/Unblock user
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: user['status'] == 'Blocked'
                            ? AppTheme.primaryGreen
                            : AppTheme.errorRed,
                      ),
                      child: Text(
                        user['status'] == 'Blocked' ? 'Unblock' : 'Block',
                      ),
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