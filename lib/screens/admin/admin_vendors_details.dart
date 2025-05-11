import 'package:flutter/material.dart';
import 'package:sokoni/screens/admin/admin_vendor_profile.dart';
import 'package:sokoni/screens/admin/register_vendor.dart';

class AdminVendorsDetails extends StatefulWidget {
  const AdminVendorsDetails({super.key});

  @override
  State<AdminVendorsDetails> createState() => _AdminVendorsDetailsState();
}

class _AdminVendorsDetailsState extends State<AdminVendorsDetails> {
  late List<Map<String, dynamic>> vendors;

  @override
  void initState() {
    super.initState();
    // Initialize vendors data
    vendors = [
      {
        'name': 'Vendor Samuel',
        'joinDate': '12 Jan 2023',
        'sales': 'KES 32,000',
        'products': 45,
        'rating': 4.5,
        'status': 'Active',
        'email': 'samuel@example.com',
        'phone': '+254 712 345678',
        'address': 'Nairobi, Kenya',
        'stallName': 'Fresh Fruits',
        'stallLocation': 'Section A',
        'role': 'Main Vendor',
      },
      {
        'name': 'Vendor Mary',
        'joinDate': '05 Feb 2023',
        'sales': 'KES 21,500',
        'products': 32,
        'rating': 4.2,
        'status': 'Active',
        'email': 'mary@example.com',
        'phone': '+254 723 456789',
        'address': 'Mombasa, Kenya',
        'stallName': 'Mary\'s Vegetables',
        'stallLocation': 'Section B',
        'role': 'Premium Vendor',
      },
      {
        'name': 'Vendor John',
        'joinDate': '21 Mar 2023',
        'sales': 'KES 15,200',
        'products': 28,
        'rating': 3.8,
        'status': 'Active',
        'email': 'john@example.com',
        'phone': '+254 734 567890',
        'address': 'Kisumu, Kenya',
        'stallName': 'Grain Corner',
        'stallLocation': 'Section C',
        'role': 'Associate Vendor',
      },
      {
        'name': 'Vendor Sarah',
        'joinDate': '17 Apr 2023',
        'sales': 'KES 8,500',
        'products': 15,
        'rating': 4.0,
        'status': 'Inactive',
        'email': 'sarah@example.com',
        'phone': '+254 745 678901',
        'address': 'Nakuru, Kenya',
        'stallName': 'Dairy Products',
        'stallLocation': 'Section D',
        'role': 'Junior Vendor',
      },
    ];
  }

  // Function to update a vendor's details
  void _updateVendor(int index, Map<String, dynamic> updatedVendor) {
    setState(() {
      vendors[index] = updatedVendor;
    });
  }

  // Function to delete a vendor
  void _deleteVendor(int index) {
    setState(() {
      vendors.removeAt(index);
    });
  }

  // Navigate to the vendor profile page
  void _navigateToVendorProfile(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminVendorProfile(
          vendorData: vendors[index],
          onVendorUpdated: (updatedVendor) => _updateVendor(index, updatedVendor),
          onVendorDeleted: () => _deleteVendor(index),
        ),
      ),
    );
  }

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
                            '${vendors.length}',
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
                            '${vendors.where((v) => v['status'] == 'Active').length}',
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
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddVendorPage(),
                    ),
                  ),
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
                return GestureDetector(
                  //onTap: () => _navigateToVendorProfile(index), // Uncomment to navigate to vendor details page when card is tapped
                  child: Card(
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
                                onPressed: () => _showDeleteConfirmation(context, index),
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                label: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () => _navigateToVendorProfile(index),
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('View Profile'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddVendorPage(),
                    ),
        //child: const Icon(Icons.add),
      ),
      child: const Icon(Icons.add),
      ),
    );
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Vendor'),
          content: Text('Are you sure you want to delete ${vendors[index]['name']}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _deleteVendor(index);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vendor deleted successfully')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
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