import 'package:flutter/material.dart';
import 'package:fresh_marikiti/config/theme.dart';
import 'package:fresh_marikiti/services/user_service.dart';

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
  ];
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchUsers();
  }

  Future<void> _fetchUsers({String? role}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final users = await UserService.fetchUsers(role: role);
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
          onTap: (index) {
            String? role;
            switch (index) {
              case 1:
                role = 'customer';
                break;
              case 2:
                role = 'vendor';
                break;
              case 3:
                role = 'rider';
                break;
              case 4:
                role = 'connector';
                break;
              default:
                role = null;
            }
            _fetchUsers(role: role);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchUsers(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
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
                            onChanged: (_) => setState(() {}),
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
                      child: _buildUsersList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildUsersList() {
    final filteredUsers = _users.where((user) {
      // Apply status filter
      if (_selectedFilter != 'All') {
        final isActive = user['isActive'] == true;
        if (_selectedFilter == 'Active' && !isActive) return false;
        if (_selectedFilter == 'Inactive' && isActive) return false;
      }
      // Apply search filter
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        return user['name'].toString().toLowerCase().contains(searchTerm) ||
            user['email'].toString().toLowerCase().contains(searchTerm) ||
            user['phone']?.toString().toLowerCase().contains(searchTerm) == true;
      }
      return true;
    }).toList();

    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text('No users found'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(user['name']?[0]?.toUpperCase() ?? '?'),
            ),
            title: Text(user['name'] ?? ''),
            subtitle: Text('${user['email'] ?? ''}\n${user['phone'] ?? ''}'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'activate') {
                  await _updateUser(user, isActive: true);
                } else if (value == 'deactivate') {
                  await _updateUser(user, isActive: false);
                } else if (value.startsWith('role:')) {
                  final newRole = value.split(':')[1];
                  await _updateUser(user, role: newRole);
                }
              },
              itemBuilder: (context) => [
                if (user['isActive'] == true)
                  const PopupMenuItem(value: 'deactivate', child: Text('Deactivate'))
                else
                  const PopupMenuItem(value: 'activate', child: Text('Activate')),
                const PopupMenuDivider(),
                ...['customer', 'vendor', 'connector', 'rider', 'admin', 'vendorAdmin']
                    .where((r) => r != user['role'])
                    .map((role) => PopupMenuItem(
                          value: 'role:$role',
                          child: Text('Set role: $role'),
                        )),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Future<void> _updateUser(Map<String, dynamic> user, {bool? isActive, String? role}) async {
    final userId = user['id'] ?? user['_id'] ?? '';
    final success = await UserService.updateUser(userId, isActive: isActive, role: role);
    if (success) {
      await _fetchUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update user')),
      );
    }
  }
} 