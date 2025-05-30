import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/config/theme.dart';
import 'package:fresh_marikiti/providers/auth_provider.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit profile
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header
          _buildProfileHeader(
            user?.name ?? 'Connector Name',
            user?.email ?? 'email@example.com',
          ),
          const SizedBox(height: 24),

          // Performance Stats Section
          _buildSection(
            title: 'Performance Stats',
            children: [
              _buildListTile(
                icon: Icons.store_outlined,
                title: 'Vendors Managed',
                trailing: const Text('45'),
              ),
              _buildListTile(
                icon: Icons.recycling_outlined,
                title: 'Waste Collected',
                trailing: const Text('1,880 kg'),
              ),
              _buildListTile(
                icon: Icons.eco_outlined,
                title: 'Recycling Rate',
                trailing: const Text('93%'),
              ),
              _buildListTile(
                icon: Icons.check_circle_outline,
                title: 'Issues Resolved',
                trailing: const Text('10/12'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Account Settings Section
          _buildSection(
            title: 'Account Settings',
            children: [
              _buildListTile(
                icon: Icons.person_outline,
                title: 'Personal Information',
                onTap: () {
                  // Navigate to personal info
                },
              ),
              _buildListTile(
                icon: Icons.location_on_outlined,
                title: 'Service Area',
                onTap: () {
                  // Navigate to service area
                },
              ),
              _buildListTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: () {
                  // Navigate to notifications
                },
              ),
              _buildListTile(
                icon: Icons.language_outlined,
                title: 'Language',
                trailing: const Text('English'),
                onTap: () {
                  // Show language picker
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Support Section
          _buildSection(
            title: 'Support',
            children: [
              _buildListTile(
                icon: Icons.help_outline,
                title: 'Help Center',
                onTap: () {
                  // Navigate to help center
                },
              ),
              _buildListTile(
                icon: Icons.chat_outlined,
                title: 'Contact Support',
                onTap: () {
                  // Navigate to support chat
                },
              ),
              _buildListTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {
                  // Show privacy policy
                },
              ),
              _buildListTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () {
                  // Show terms of service
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Logout'),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // App Version
          Center(
            child: Text(
              'Version 1.0.0',
              style: AppTextStyles.caption.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppTheme.primaryGreen,
          child: Text(
            name[0].toUpperCase(),
            style: const TextStyle(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: AppTextStyles.heading1,
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: AppTextStyles.body.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Senior Connector',
            style: AppTextStyles.caption.copyWith(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: AppTextStyles.heading2,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
} 