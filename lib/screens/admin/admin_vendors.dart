import 'package:flutter/material.dart';

class AdminVendorsPage extends StatefulWidget {
  const AdminVendorsPage({super.key});

  @override
  State<AdminVendorsPage> createState() => _AdminVendorsPageState();
}

class _AdminVendorsPageState extends State<AdminVendorsPage> {
  final List<Map<String, dynamic>> vendors = [
    {
      'name': 'Vendor Samuel',
      'joinDate': '12 Jan 2023',
      'sales': 'KES 32,000',
      'products': 45,
      'rating': 4.5,
      'status': 'Active',
    },
    {
      'name': 'Vendor Mary',
      'joinDate': '05 Feb 2023',
      'sales': 'KES 21,500',
      'products': 32,
      'rating': 4.2,
      'status': 'Active',
    },
    {
      'name': 'Vendor John',
      'joinDate': '21 Mar 2023',
      'sales': 'KES 15,200',
      'products': 28,
      'rating': 3.8,
      'status': 'Active',
    },
    {
      'name': 'Vendor Sarah',
      'joinDate': '17 Apr 2023',
      'sales': 'KES 8,500',
      'products': 15,
      'rating': 4.0,
      'status': 'Inactive',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Show search
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    color: isDark ? Colors.blue.shade900 : Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Vendors',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '12',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: isDark ? Colors.green.shade900 : Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Vendors',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '10',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vendor List',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to add vendor page
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Vendor'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vendors.length,
              itemBuilder: (context, index) {
                final vendor = vendors[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              child: Text(vendor['name'].toString().substring(0, 1)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vendor['name'],
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Joined: ${vendor['joinDate']}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(vendor['status']),
                              backgroundColor: vendor['status'] == 'Active'
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: vendor['status'] == 'Active'
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildVendorStat(
                              'Products',
                              vendor['products'].toString(),
                              Icons.category_outlined,
                              theme,
                            ),
                            _buildVendorStat(
                              'Sales',
                              vendor['sales'],
                              Icons.monetization_on_outlined,
                              theme,
                            ),
                            _buildVendorStat(
                              'Rating',
                              '${vendor['rating']}',
                              Icons.star_outline,
                              theme,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                // View vendor details
                              },
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('View'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () {
                                // Edit vendor
                              },
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new vendor
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildVendorStat(String title, String value, IconData icon, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, color: theme.primaryColor),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium),
        Text(title, style: theme.textTheme.bodySmall),
      ],
    );
  }
}