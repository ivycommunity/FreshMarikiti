import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:fresh_marikiti/core/models/vendor_models.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/utils/api_endpoints.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:intl/intl.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({Key? key}) : super(key: key);

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  VendorProfile? _profile;
  bool _isLoading = true;
  bool _isUpdating = false;

  // Form controllers and keys
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  String _selectedCategory = 'fruits';
  Map<String, Map<String, String>> _operatingHours = {};

  final List<String> _categories = [
    'fruits',
    'vegetables',
    'grains',
    'dairy',
    'meat',
    'beverages',
    'spices',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVendorProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadVendorProfile() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.get(ApiEndpoints.vendorProfile);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _profile = VendorProfile.fromJson(data['profile']);
          _populateControllers();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load vendor profile');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _populateControllers() {
    if (_profile != null) {
      _nameController.text = _profile!.name;
      _emailController.text = _profile!.email;
      _phoneController.text = _profile!.phone;
      _addressController.text = _profile!.address;
      _selectedCategory = _profile!.category;
      _operatingHours = Map.from(_profile!.operatingHours);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.put(
        ApiEndpoints.vendorProfile,
        {
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
          'category': _selectedCategory,
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadVendorProfile();
        }
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _updateOperatingHours(Map<String, OperatingHours> newHours) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.put(
        ApiEndpoints.vendorOperatingHours,
        {
          'operatingHours': newHours.map((day, hours) => MapEntry(
            day,
            {
              'open': hours.openTime,
              'close': hours.closeTime,
              'isOpen': hours.isOpen,
            },
          )),
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Operating hours updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadVendorProfile();
        }
      } else {
        throw Exception('Failed to update operating hours');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating hours: ${e.toString()}'),
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
          'Vendor Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          if (_profile != null)
            IconButton(
              icon: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              onPressed: _isUpdating ? null : _updateProfile,
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadVendorProfile(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Profile', icon: Icon(Icons.person)),
            Tab(text: 'Business', icon: Icon(Icons.business)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Failed to load profile'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProfileTab(),
                    _buildBusinessTab(),
                    _buildSettingsTab(),
                  ],
                ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 16),
            _buildPersonalInfoCard(),
            const SizedBox(height: 16),
            _buildContactInfoCard(),
            const SizedBox(height: 16),
            _buildCategoryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2E7D32),
              const Color(0xFF2E7D32).withOpacity(0.8),
            ],
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                _profile!.name.isNotEmpty ? _profile!.name[0].toUpperCase() : 'V',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
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
                    _profile!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _profile!.category.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _profile!.isVerified ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _profile!.isVerified ? 'VERIFIED' : 'PENDING',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Business Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Address is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Email is required';
                }
                if (!value!.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Phone number is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBusinessStatsCard(),
          const SizedBox(height: 16),
          _buildOperatingHoursCard(),
          const SizedBox(height: 16),
          _buildBusinessMetricsCard(),
        ],
      ),
    );
  }

  Widget _buildBusinessStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Orders',
                    _profile!.totalOrders.toString(),
                    Icons.shopping_cart,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Revenue',
                    'KSh ${NumberFormat('#,###').format(_profile!.totalRevenue)}',
                    Icons.monetization_on,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Rating',
                    '${_profile!.rating.toStringAsFixed(1)} ⭐',
                    Icons.star,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Active Products',
                    _profile!.activeProducts.toString(),
                    Icons.inventory,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
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
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOperatingHoursCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Operating Hours',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _showOperatingHoursDialog,
                  icon: const Icon(Icons.edit),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...(_profile!.operatingHours.entries.map((entry) {
              final day = entry.key;
              final hours = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      day.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      hours.isOpen
                          ? '${hours.openTime} - ${hours.closeTime}'
                          : 'Closed',
                      style: TextStyle(
                        color: hours.isOpen ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            }).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessMetricsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Completion Rate', '${(_profile!.completionRate * 100).toStringAsFixed(1)}%'),
            _buildMetricRow('Response Time', '${_profile!.responseTime} mins'),
            _buildMetricRow('Customer Satisfaction', '${(_profile!.satisfaction * 100).toStringAsFixed(1)}%'),
            _buildMetricRow('Member Since', DateFormat('MMM yyyy').format(_profile!.joinDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return const Center(
      child: Text('Settings tab content will be implemented here'),
    );
  }

  void _showOperatingHoursDialog() {
    showDialog(
      context: context,
      builder: (context) => OperatingHoursDialog(
        currentHours: _profile!.operatingHours,
        onSave: _updateOperatingHours,
      ),
    );
  }
}

// Operating Hours Dialog Widget
class OperatingHoursDialog extends StatefulWidget {
  final Map<String, OperatingHours> currentHours;
  final Function(Map<String, OperatingHours>) onSave;

  const OperatingHoursDialog({
    Key? key,
    required this.currentHours,
    required this.onSave,
  }) : super(key: key);

  @override
  State<OperatingHoursDialog> createState() => _OperatingHoursDialogState();
}

class _OperatingHoursDialogState extends State<OperatingHoursDialog> {
  late Map<String, OperatingHours> _hours;

  @override
  void initState() {
    super.initState();
    _hours = Map.from(widget.currentHours);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Operating Hours'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: _hours.entries.map((entry) {
            final day = entry.key;
            final hours = entry.value;
            return ListTile(
              title: Text(day.toUpperCase()),
              subtitle: hours.isOpen
                  ? Text('${hours.openTime} - ${hours.closeTime}')
                  : const Text('Closed'),
              trailing: Switch(
                value: hours.isOpen,
                onChanged: (value) {
                  setState(() {
                    _hours[day] = OperatingHours(
                      openTime: hours.openTime,
                      closeTime: hours.closeTime,
                      isOpen: value,
                    );
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_hours);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Data Models
class VendorProfile {
  final String id;
  final String name;
  final String description;
  final String phone;
  final String email;
  final String address;
  final String? website;
  final String? profileImage;
  final double rating;
  final int reviewCount;
  final bool isStoreOpen;
  final bool isCurrentlyOpen;
  final String? nextOpenTime;
  final int totalOrders;
  final int totalProducts;
  final double totalRevenue;
  final int totalCustomers;
  final Map<String, OperatingHours> operatingHours;
  final String category;
  final bool isVerified;
  final double completionRate;
  final double responseTime;
  final double satisfaction;
  final DateTime joinDate;
  final int activeProducts;

  VendorProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.phone,
    required this.email,
    required this.address,
    this.website,
    this.profileImage,
    required this.rating,
    required this.reviewCount,
    required this.isStoreOpen,
    required this.isCurrentlyOpen,
    this.nextOpenTime,
    required this.totalOrders,
    required this.totalProducts,
    required this.totalRevenue,
    required this.totalCustomers,
    required this.operatingHours,
    required this.category,
    required this.isVerified,
    required this.completionRate,
    required this.responseTime,
    required this.satisfaction,
    required this.joinDate,
    required this.activeProducts,
  });

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    final operatingHoursJson = json['operatingHours'] as Map<String, dynamic>? ?? {};
    final operatingHours = operatingHoursJson.map((day, hours) => 
      MapEntry(day, OperatingHours.fromJson(hours)));

    return VendorProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      website: json['website'],
      profileImage: json['profileImage'],
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      isStoreOpen: json['isStoreOpen'] ?? false,
      isCurrentlyOpen: json['isCurrentlyOpen'] ?? false,
      nextOpenTime: json['nextOpenTime'],
      totalOrders: json['totalOrders'] ?? 0,
      totalProducts: json['totalProducts'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalCustomers: json['totalCustomers'] ?? 0,
      operatingHours: operatingHours,
      category: json['category'] ?? '',
      isVerified: json['isVerified'] ?? false,
      completionRate: (json['completionRate'] ?? 0).toDouble(),
      responseTime: (json['responseTime'] ?? 0).toDouble(),
      satisfaction: (json['satisfaction'] ?? 0).toDouble(),
      joinDate: DateTime.parse(json['joinDate'] ?? DateTime.now().toIso8601String()),
      activeProducts: json['activeProducts'] ?? 0,
    );
  }
}

class OperatingHours {
  final bool isOpen;
  final String openTime;
  final String closeTime;

  OperatingHours({
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  factory OperatingHours.fromJson(Map<String, dynamic> json) {
    return OperatingHours(
      isOpen: json['isOpen'] ?? false,
      openTime: json['openTime'] ?? '09:00',
      closeTime: json['closeTime'] ?? '17:00',
    );
  }
} 