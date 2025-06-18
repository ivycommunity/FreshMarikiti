import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fresh_marikiti/core/models/vendor_admin_models.dart';
import 'package:fresh_marikiti/core/config/app_config.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class VendorAdminProfileScreen extends StatefulWidget {
  const VendorAdminProfileScreen({Key? key}) : super(key: key);

  @override
  State<VendorAdminProfileScreen> createState() => _VendorAdminProfileScreenState();
}

class _VendorAdminProfileScreenState extends State<VendorAdminProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  VendorAdminProfile? _profile;
  MarketSettings? _settings;
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _marketNameController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _marketNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final responses = await Future.wait([
        ApiService.get('/vendor-admin/profile'),
        ApiService.get('/vendor-admin/settings'),
      ]);

      if (responses.every((response) => response.statusCode == 200)) {
        final profileData = json.decode(responses[0].body);
        final settingsData = json.decode(responses[1].body);

        setState(() {
          _profile = VendorAdminProfile.fromJson(profileData['profile']);
          _settings = MarketSettings.fromJson(settingsData['settings']);
          _populateControllers();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load profile data');
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
      _marketNameController.text = _profile!.marketName;
      _addressController.text = _profile!.address;
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.put(
        '/vendor-admin/profile',
        {
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'marketName': _marketNameController.text,
          'address': _addressController.text,
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
          _loadProfileData(showLoading: false);
        }
      } else {
        throw Exception('Failed to update profile');
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
    }
  }

  Future<void> _updateSettings(Map<String, dynamic> settingsUpdate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.put(
        '/vendor-admin/settings',
        settingsUpdate,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadProfileData(showLoading: false);
        }
      } else {
        throw Exception('Failed to update settings');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating settings: ${e.toString()}'),
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
          'Profile & Settings',
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
            onPressed: () => _loadProfileData(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Profile', icon: Icon(Icons.person)),
            Tab(text: 'Market Settings', icon: Icon(Icons.settings)),
            Tab(text: 'Preferences', icon: Icon(Icons.tune)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildMarketSettingsTab(),
                _buildPreferencesTab(),
              ],
            ),
    );
  }

  Widget _buildProfileTab() {
    if (_profile == null) return const Center(child: Text('No profile data available'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildPersonalInfoCard(),
            const SizedBox(height: 16),
            _buildMarketInfoCard(),
            const SizedBox(height: 16),
            _buildStatsCard(),
            const SizedBox(height: 24),
            _buildUpdateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2E7D32),
              const Color(0xFF4CAF50),
            ],
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
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
                  const SizedBox(height: 4),
                  Text(
                    'Market Administrator',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Member since ${DateFormat('MMM yyyy').format(_profile!.joinedDate)}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
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
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Market Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _marketNameController,
              decoration: const InputDecoration(
                labelText: 'Market Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store_mall_directory),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the market name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Market Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the market address';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Market Stats',
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
                    'Total Stalls',
                    _profile!.totalStalls.toString(),
                    Icons.store,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Active Vendors',
                    _profile!.activeVendors.toString(),
                    Icons.people,
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
                    'Monthly Revenue',
                    'KSh ${NumberFormat('#,###').format(_profile!.monthlyRevenue)}',
                    Icons.monetization_on,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Rating',
                    '${_profile!.rating.toStringAsFixed(1)} ⭐',
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

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
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
            textAlign: TextAlign.center,
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

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Update Profile',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMarketSettingsTab() {
    if (_settings == null) return const Center(child: Text('No settings data available'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOperationalSettings(),
          const SizedBox(height: 16),
          _buildVendorSettings(),
          const SizedBox(height: 16),
          _buildCommissionSettings(),
        ],
      ),
    );
  }

  Widget _buildOperationalSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Operational Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-approve new vendors'),
              subtitle: const Text('Automatically approve vendor registrations'),
              value: _settings!.autoApproveVendors,
              onChanged: (value) {
                _updateSettings({'autoApproveVendors': value});
              },
            ),
            SwitchListTile(
              title: const Text('Real-time notifications'),
              subtitle: const Text('Receive instant notifications for market activities'),
              value: _settings!.realTimeNotifications,
              onChanged: (value) {
                _updateSettings({'realTimeNotifications': value});
              },
            ),
            SwitchListTile(
              title: const Text('Performance tracking'),
              subtitle: const Text('Track detailed performance metrics'),
              value: _settings!.performanceTracking,
              onChanged: (value) {
                _updateSettings({'performanceTracking': value});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vendor Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Require vendor training'),
              subtitle: const Text('All vendors must complete training before going live'),
              value: _settings!.requireVendorTraining,
              onChanged: (value) {
                _updateSettings({'requireVendorTraining': value});
              },
            ),
            SwitchListTile(
              title: const Text('Allow vendor self-registration'),
              subtitle: const Text('Vendors can register without admin approval'),
              value: _settings!.allowVendorSelfRegistration,
              onChanged: (value) {
                _updateSettings({'allowVendorSelfRegistration': value});
              },
            ),
            ListTile(
              title: const Text('Maximum vendors per admin'),
              subtitle: Text('Current limit: ${_settings!.maxVendorsPerAdmin}'),
              trailing: TextButton(
                onPressed: () => _showMaxVendorsDialog(),
                child: const Text('Change'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Commission Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Platform commission rate'),
              subtitle: Text('${_settings!.commissionRate}% per transaction'),
              trailing: const Icon(Icons.info_outline, color: Colors.blue),
            ),
            ListTile(
              title: const Text('Payment schedule'),
              subtitle: Text(_settings!.paymentSchedule),
              trailing: TextButton(
                onPressed: () => _showPaymentScheduleDialog(),
                child: const Text('Change'),
              ),
            ),
            SwitchListTile(
              title: const Text('Automatic payouts'),
              subtitle: const Text('Automatically process vendor payouts'),
              value: _settings!.automaticPayouts,
              onChanged: (value) {
                _updateSettings({'automaticPayouts': value});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotificationPreferences(),
          const SizedBox(height: 16),
          _buildPrivacySettings(),
          const SizedBox(height: 16),
          _buildSystemPreferences(),
          const SizedBox(height: 16),
          _buildAccountActions(),
        ],
      ),
    );
  }

  Widget _buildNotificationPreferences() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Email notifications'),
              subtitle: const Text('Receive notifications via email'),
              value: _settings?.emailNotifications ?? true,
              onChanged: (value) {
                _updateSettings({'emailNotifications': value});
              },
            ),
            SwitchListTile(
              title: const Text('SMS notifications'),
              subtitle: const Text('Receive notifications via SMS'),
              value: _settings?.smsNotifications ?? false,
              onChanged: (value) {
                _updateSettings({'smsNotifications': value});
              },
            ),
            SwitchListTile(
              title: const Text('Push notifications'),
              subtitle: const Text('Receive push notifications on mobile'),
              value: _settings?.pushNotifications ?? true,
              onChanged: (value) {
                _updateSettings({'pushNotifications': value});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Profile visibility'),
              subtitle: const Text('Allow vendors to see your profile'),
              value: _settings?.profileVisibility ?? true,
              onChanged: (value) {
                _updateSettings({'profileVisibility': value});
              },
            ),
            SwitchListTile(
              title: const Text('Analytics sharing'),
              subtitle: const Text('Share anonymized analytics data'),
              value: _settings?.analyticsSharing ?? false,
              onChanged: (value) {
                _updateSettings({'analyticsSharing': value});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemPreferences() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Language'),
              subtitle: const Text('English'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showLanguageDialog(),
            ),
            ListTile(
              title: const Text('Currency'),
              subtitle: const Text('Kenyan Shilling (KSh)'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showCurrencyDialog(),
            ),
            ListTile(
              title: const Text('Time zone'),
              subtitle: const Text('East Africa Time (EAT)'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showTimezoneDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.blue),
              title: const Text('Change Password'),
              subtitle: const Text('Update your account password'),
              onTap: () => _showChangePasswordDialog(),
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.green),
              title: const Text('Export Data'),
              subtitle: const Text('Download your market data'),
              onTap: () => _exportMarketData(),
            ),
            ListTile(
              leading: const Icon(Icons.help, color: Colors.orange),
              title: const Text('Help & Support'),
              subtitle: const Text('Get help with market management'),
              onTap: () => _openSupport(),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out'),
              subtitle: const Text('Sign out of your account'),
              onTap: () => _signOut(),
            ),
          ],
        ),
      ),
    );
  }

  void _showMaxVendorsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Maximum Vendors'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Maximum vendors per admin',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vendor limit updated')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showPaymentScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Weekly'),
              value: 'weekly',
              groupValue: _settings?.paymentSchedule.toLowerCase(),
              onChanged: (value) {
                Navigator.pop(context);
                _updateSettings({'paymentSchedule': value});
              },
            ),
            RadioListTile<String>(
              title: const Text('Bi-weekly'),
              value: 'bi-weekly',
              groupValue: _settings?.paymentSchedule.toLowerCase(),
              onChanged: (value) {
                Navigator.pop(context);
                _updateSettings({'paymentSchedule': value});
              },
            ),
            RadioListTile<String>(
              title: const Text('Monthly'),
              value: 'monthly',
              groupValue: _settings?.paymentSchedule.toLowerCase(),
              onChanged: (value) {
                Navigator.pop(context);
                _updateSettings({'paymentSchedule': value});
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Language settings would be implemented here')),
    );
  }

  void _showCurrencyDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Currency settings would be implemented here')),
    );
  }

  void _showTimezoneDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Timezone settings would be implemented here')),
    );
  }

  void _showChangePasswordDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change password functionality would be implemented here')),
    );
  }

  void _exportMarketData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting market data...')),
    );
  }

  void _openSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening support center...')),
    );
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement sign out logic here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signed out successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class VendorAdminProfile {
  final String name;
  final String email;
  final String phone;
  final String marketName;
  final String address;
  final int totalStalls;
  final int activeVendors;
  final double monthlyRevenue;
  final double rating;
  final DateTime joinedDate;

  VendorAdminProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.marketName,
    required this.address,
    required this.totalStalls,
    required this.activeVendors,
    required this.monthlyRevenue,
    required this.rating,
    required this.joinedDate,
  });

  factory VendorAdminProfile.fromJson(Map<String, dynamic> json) {
    return VendorAdminProfile(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      marketName: json['marketName'] ?? '',
      address: json['address'] ?? '',
      totalStalls: json['totalStalls'] ?? 0,
      activeVendors: json['activeVendors'] ?? 0,
      monthlyRevenue: (json['monthlyRevenue'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      joinedDate: DateTime.parse(json['joinedDate'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class MarketSettings {
  final bool autoApproveVendors;
  final bool realTimeNotifications;
  final bool performanceTracking;
  final bool requireVendorTraining;
  final bool allowVendorSelfRegistration;
  final int maxVendorsPerAdmin;
  final double commissionRate;
  final String paymentSchedule;
  final bool automaticPayouts;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool pushNotifications;
  final bool profileVisibility;
  final bool analyticsSharing;

  MarketSettings({
    required this.autoApproveVendors,
    required this.realTimeNotifications,
    required this.performanceTracking,
    required this.requireVendorTraining,
    required this.allowVendorSelfRegistration,
    required this.maxVendorsPerAdmin,
    required this.commissionRate,
    required this.paymentSchedule,
    required this.automaticPayouts,
    required this.emailNotifications,
    required this.smsNotifications,
    required this.pushNotifications,
    required this.profileVisibility,
    required this.analyticsSharing,
  });

  factory MarketSettings.fromJson(Map<String, dynamic> json) {
    return MarketSettings(
      autoApproveVendors: json['autoApproveVendors'] ?? false,
      realTimeNotifications: json['realTimeNotifications'] ?? true,
      performanceTracking: json['performanceTracking'] ?? true,
      requireVendorTraining: json['requireVendorTraining'] ?? true,
      allowVendorSelfRegistration: json['allowVendorSelfRegistration'] ?? false,
      maxVendorsPerAdmin: json['maxVendorsPerAdmin'] ?? 50,
      commissionRate: (json['commissionRate'] ?? 5.0).toDouble(),
      paymentSchedule: json['paymentSchedule'] ?? 'Weekly',
      automaticPayouts: json['automaticPayouts'] ?? false,
      emailNotifications: json['emailNotifications'] ?? true,
      smsNotifications: json['smsNotifications'] ?? false,
      pushNotifications: json['pushNotifications'] ?? true,
      profileVisibility: json['profileVisibility'] ?? true,
      analyticsSharing: json['analyticsSharing'] ?? false,
    );
  }
} 