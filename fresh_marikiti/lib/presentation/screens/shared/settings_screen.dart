import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fresh_marikiti/core/providers/theme_provider.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/providers/notification_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/models/user.dart';
import 'package:fresh_marikiti/core/models/notification_model.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class SettingsScreen extends StatefulWidget {
  final String? initialSection;

  const SettingsScreen({
    super.key,
    this.initialSection,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedSection = 'general';

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.initialSection ?? 'general';
    LoggerService.info('Settings screen initialized', tag: 'SettingsScreen');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, AuthProvider, NotificationProvider>(
      builder: (context, themeProvider, authProvider, notificationProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: _buildAppBar(context),
          body: Row(
            children: [
              // Settings navigation sidebar
              _buildNavigationSidebar(),
              
              // Settings content
              Expanded(
                child: _buildSettingsContent(themeProvider, authProvider, notificationProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.colors.freshGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Settings',
        style: context.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => NavigationService.toAbout(),
          tooltip: 'About',
        ),
      ],
    );
  }

  Widget _buildNavigationSidebar() {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: context.colors.surfaceColor,
        border: Border(
          right: BorderSide(
            color: context.colors.textSecondary.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildNavItem(
            icon: Icons.settings,
            label: 'General',
            section: 'general',
          ),
          _buildNavItem(
            icon: Icons.notifications,
            label: 'Notifications',
            section: 'notifications',
          ),
          _buildNavItem(
            icon: Icons.palette,
            label: 'Theme',
            section: 'theme',
          ),
          _buildNavItem(
            icon: Icons.security,
            label: 'Privacy',
            section: 'privacy',
          ),
          _buildNavItem(
            icon: Icons.language,
            label: 'Language',
            section: 'language',
          ),
          _buildNavItem(
            icon: Icons.storage,
            label: 'Storage',
            section: 'storage',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required String section,
  }) {
    final isSelected = _selectedSection == section;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSection = section;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? context.colors.freshGreen.withOpacity(0.1) 
              : Colors.transparent,
          borderRadius: AppRadius.radiusMD,
          border: isSelected 
              ? Border.all(color: context.colors.freshGreen, width: 1) 
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? context.colors.freshGreen 
                  : context.colors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: isSelected 
                    ? context.colors.freshGreen 
                    : context.colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsContent(
    ThemeProvider themeProvider,
    AuthProvider authProvider,
    NotificationProvider notificationProvider,
  ) {
    switch (_selectedSection) {
      case 'general':
        return _buildGeneralSettings(authProvider);
      case 'notifications':
        return _buildNotificationSettings(notificationProvider);
      case 'theme':
        return _buildThemeSettings(themeProvider);
      case 'privacy':
        return _buildPrivacySettings();
      case 'language':
        return _buildLanguageSettings();
      case 'storage':
        return _buildStorageSettings();
      default:
        return _buildGeneralSettings(authProvider);
    }
  }

  Widget _buildGeneralSettings(AuthProvider authProvider) {
    final user = authProvider.user;
    
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'General Settings',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Profile section
          if (user != null) _buildProfileCard(user),
          
          const SizedBox(height: AppSpacing.lg),
          
          // App preferences
          _buildSettingsSection(
            title: 'App Preferences',
            children: [
              _buildSwitchTile(
                title: 'Auto-refresh data',
                subtitle: 'Automatically refresh app data in background',
                value: true,
                onChanged: (value) {},
              ),
              _buildSwitchTile(
                title: 'Show delivery animations',
                subtitle: 'Display animated delivery tracking',
                value: true,
                onChanged: (value) {},
              ),
              _buildSwitchTile(
                title: 'Smart ordering suggestions',
                subtitle: 'Get personalized product recommendations',
                value: true,
                onChanged: (value) {},
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Account actions
          _buildSettingsSection(
            title: 'Account',
            children: [
              _buildActionTile(
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                icon: Icons.edit,
                onTap: () => _editProfile(user),
              ),
              _buildActionTile(
                title: 'Change Password',
                subtitle: 'Update your account password',
                icon: Icons.lock,
                onTap: () => _changePassword(),
              ),
              _buildActionTile(
                title: 'Backup & Sync',
                subtitle: 'Manage data backup and synchronization',
                icon: Icons.backup,
                onTap: () => _manageBackup(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(NotificationProvider notificationProvider) {
    final preferences = notificationProvider.preferences;
    
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Settings',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Master notification toggle
          _buildSettingsSection(
            title: 'Master Control',
            children: [
              _buildSwitchTile(
                title: 'Push Notifications',
                subtitle: 'Enable or disable all push notifications',
                value: preferences.pushNotificationsEnabled,
                onChanged: (value) {
                  notificationProvider.updatePreferences(
                    preferences.copyWith(pushNotificationsEnabled: value),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Notification categories
          _buildSettingsSection(
            title: 'Notification Types',
            children: [
              _buildSwitchTile(
                title: 'Order Updates',
                subtitle: 'Status changes, delivery notifications',
                value: preferences.orderUpdatesEnabled,
                onChanged: (value) {
                  notificationProvider.updatePreferences(
                    preferences.copyWith(orderUpdatesEnabled: value),
                  );
                },
              ),
              _buildSwitchTile(
                title: 'Chat Messages',
                subtitle: 'New messages from connectors and support',
                value: preferences.chatMessagesEnabled,
                onChanged: (value) {
                  notificationProvider.updatePreferences(
                    preferences.copyWith(chatMessagesEnabled: value),
                  );
                },
              ),
              _buildSwitchTile(
                title: 'Promotions & Offers',
                subtitle: 'Special deals and promotional content',
                value: preferences.promotionsEnabled,
                onChanged: (value) {
                  notificationProvider.updatePreferences(
                    preferences.copyWith(promotionsEnabled: value),
                  );
                },
              ),
              _buildSwitchTile(
                title: 'Waste Pickup Reminders',
                subtitle: 'Sustainability and waste collection alerts',
                value: preferences.wastePickupEnabled,
                onChanged: (value) {
                  notificationProvider.updatePreferences(
                    preferences.copyWith(wastePickupEnabled: value),
                  );
                },
              ),
              _buildSwitchTile(
                title: 'System Updates',
                subtitle: 'App updates and maintenance notifications',
                value: preferences.systemNotificationsEnabled,
                onChanged: (value) {
                  notificationProvider.updatePreferences(
                    preferences.copyWith(systemNotificationsEnabled: value),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Notification behavior
          _buildSettingsSection(
            title: 'Notification Behavior',
            children: [
              _buildSwitchTile(
                title: 'Sound',
                subtitle: 'Play notification sounds',
                value: preferences.soundEnabled,
                onChanged: (value) {
                  notificationProvider.updatePreferences(
                    preferences.copyWith(soundEnabled: value),
                  );
                },
              ),
              _buildSwitchTile(
                title: 'Vibration',
                subtitle: 'Vibrate on notification',
                value: preferences.vibrationEnabled,
                onChanged: (value) {
                  notificationProvider.updatePreferences(
                    preferences.copyWith(vibrationEnabled: value),
                  );
                },
              ),
              _buildQuietHoursTile(notificationProvider),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSettings(ThemeProvider themeProvider) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme Settings',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Theme mode selection (simplified)
          _buildSettingsSection(
            title: 'Appearance',
            children: [
              ListTile(
                contentPadding: AppSpacing.paddingMD,
                title: const Text('Theme Mode'),
                subtitle: const Text('Currently following system theme'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Theme mode selection will be implemented')),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Color scheme preview
          _buildColorSchemePreview(),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Display settings (simplified)
          _buildSettingsSection(
            title: 'Display Settings',
            children: [
              _buildSwitchTile(
                title: 'High Contrast',
                subtitle: 'Enhance readability with higher contrast',
                value: false, // Simplified - not connected to provider
                onChanged: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('High contrast mode will be implemented')),
                  );
                },
              ),
              _buildSwitchTile(
                title: 'Large Text',
                subtitle: 'Increase text size for better readability',
                value: false, // Simplified - not connected to provider
                onChanged: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Large text mode will be implemented')),
                  );
                },
              ),
              _buildSwitchTile(
                title: 'Reduce Animations',
                subtitle: 'Minimize motion for better accessibility',
                value: false, // Simplified - not connected to provider
                onChanged: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reduced motion will be implemented')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy & Security',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          _buildSettingsSection(
            title: 'Data Privacy',
            children: [
              _buildSwitchTile(
                title: 'Analytics & Tracking',
                subtitle: 'Help improve the app with usage analytics',
                value: true,
                onChanged: (value) {},
              ),
              _buildSwitchTile(
                title: 'Location Services',
                subtitle: 'Allow location access for delivery tracking',
                value: true,
                onChanged: (value) {},
              ),
              _buildActionTile(
                title: 'Data Export',
                subtitle: 'Download your personal data',
                icon: Icons.download,
                onTap: () => _exportData(),
              ),
              _buildActionTile(
                title: 'Delete Account',
                subtitle: 'Permanently delete your account and data',
                icon: Icons.delete_forever,
                onTap: () => _deleteAccount(),
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSettings() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Language & Region',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          _buildSettingsSection(
            title: 'Language Settings',
            children: [
              _buildLanguageSelector(),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          _buildSettingsSection(
            title: 'Regional Settings',
            children: [
              _buildActionTile(
                title: 'Currency',
                subtitle: 'Kenyan Shilling (KES)',
                icon: Icons.monetization_on,
                onTap: () => _changeCurrency(),
              ),
              _buildActionTile(
                title: 'Date Format',
                subtitle: 'DD/MM/YYYY',
                icon: Icons.date_range,
                onTap: () => _changeDateFormat(),
              ),
              _buildActionTile(
                title: 'Time Format',
                subtitle: '24-hour',
                icon: Icons.access_time,
                onTap: () => _changeTimeFormat(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageSettings() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Storage & Cache',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Storage usage
          _buildStorageUsageCard(),
          
          const SizedBox(height: AppSpacing.lg),
          
          _buildSettingsSection(
            title: 'Cache Management',
            children: [
              _buildActionTile(
                title: 'Clear Image Cache',
                subtitle: 'Free up space by clearing cached images',
                icon: Icons.image,
                onTap: () => _clearImageCache(),
              ),
              _buildActionTile(
                title: 'Clear App Data',
                subtitle: 'Reset app to default state',
                icon: Icons.refresh,
                onTap: () => _clearAppData(),
                isDestructive: true,
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          _buildSettingsSection(
            title: 'Download Settings',
            children: [
              _buildSwitchTile(
                title: 'Download on WiFi only',
                subtitle: 'Save mobile data by downloading only on WiFi',
                value: true,
                onChanged: (value) {},
              ),
              _buildSwitchTile(
                title: 'Auto-download updates',
                subtitle: 'Automatically download app updates',
                value: false,
                onChanged: (value) {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(User user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: context.colors.freshGreen,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: context.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.colors.freshGreen.withOpacity(0.2),
                      borderRadius: AppRadius.radiusSM,
                    ),
                    child: Text(
                      user.role.toString().split('.').last.toUpperCase(),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colors.freshGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editProfile(user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
          child: Column(
            children: children.map((child) {
              final index = children.indexOf(child);
              return Column(
                children: [
                  child,
                  if (index < children.length - 1)
                    Divider(
                      height: 1,
                      color: context.colors.textSecondary.withOpacity(0.2),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: AppSpacing.paddingMD,
      title: Text(
        title,
        style: context.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: context.colors.freshGreen,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: AppSpacing.paddingMD,
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : context.colors.freshGreen,
      ),
      title: Text(
        title,
        style: context.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildThemeModeSelector(ThemeProvider themeProvider) {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('Light Mode'),
          subtitle: const Text('Bright theme for daytime use'),
          value: 'light',
          groupValue: 'system', // Simplified
          onChanged: (value) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Theme mode selection will be implemented')),
            );
          },
          activeColor: context.colors.freshGreen,
        ),
        RadioListTile<String>(
          title: const Text('Dark Mode'),
          subtitle: const Text('Dark theme for low-light environments'),
          value: 'dark',
          groupValue: 'system', // Simplified
          onChanged: (value) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Theme mode selection will be implemented')),
            );
          },
          activeColor: context.colors.freshGreen,
        ),
        RadioListTile<String>(
          title: const Text('System Default'),
          subtitle: const Text('Follow device theme settings'),
          value: 'system',
          groupValue: 'system', // Simplified
          onChanged: (value) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Theme mode selection will be implemented')),
            );
          },
          activeColor: context.colors.freshGreen,
        ),
      ],
    );
  }

  Widget _buildColorSchemePreview() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fresh Marikiti Colors',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _buildColorCircle(context.colors.freshGreen, 'Fresh Green'),
                const SizedBox(width: AppSpacing.sm),
                _buildColorCircle(context.colors.marketOrange, 'Market Orange'),
                const SizedBox(width: AppSpacing.sm),
                _buildColorCircle(context.colors.ecoBlue, 'Eco Blue'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCircle(Color color, String name) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: context.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuietHoursTile(
    NotificationProvider notificationProvider,
  ) {
    return ListTile(
      contentPadding: AppSpacing.paddingMD,
      title: const Text('Quiet Hours'),
      subtitle: Text(
        '22:00 - 07:00', // Simplified static values
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _configureQuietHours(notificationProvider),
    );
  }

  Widget _buildLanguageSelector() {
    return ListTile(
      contentPadding: AppSpacing.paddingMD,
      title: const Text('App Language'),
      subtitle: const Text('English (US)'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _selectLanguage(),
    );
  }

  Widget _buildStorageUsageCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
      child: Padding(
        padding: AppSpacing.paddingLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage Usage',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildStorageItem('App Data', '12.5 MB', 0.3),
            const SizedBox(height: AppSpacing.sm),
            _buildStorageItem('Image Cache', '45.2 MB', 0.7),
            const SizedBox(height: AppSpacing.sm),
            _buildStorageItem('Documents', '2.1 MB', 0.1),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: 59.8 MB',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Available: 2.4 GB',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageItem(String name, String size, double percentage) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name),
            Text(
              size,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: context.colors.textSecondary.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(context.colors.freshGreen),
        ),
      ],
    );
  }

  // Action methods (placeholder implementations)
  void _editProfile(User? user) {
    NavigationService.toCustomerProfile();
  }

  void _changePassword() {
    // Implementation for password change
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change Password functionality will be implemented')),
    );
  }

  void _manageBackup() {
    // Implementation for backup management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup management will be implemented')),
    );
  }

  void _configureQuietHours(
    NotificationProvider notificationProvider,
  ) {
    // Implementation for quiet hours configuration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quiet hours configuration will be implemented')),
    );
  }

  void _exportData() {
    // Implementation for data export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data export functionality will be implemented')),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to permanently delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementation for account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion will be implemented')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _selectLanguage() {
    // Implementation for language selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Language selection will be implemented')),
    );
  }

  void _changeCurrency() {
    // Implementation for currency change
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Currency selection will be implemented')),
    );
  }

  void _changeDateFormat() {
    // Implementation for date format change
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Date format selection will be implemented')),
    );
  }

  void _changeTimeFormat() {
    // Implementation for time format change
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time format selection will be implemented')),
    );
  }

  void _clearImageCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Image Cache'),
        content: const Text('This will clear all cached images and free up storage space.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Image cache cleared'),
                  backgroundColor: context.colors.freshGreen,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _clearAppData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear App Data'),
        content: const Text('This will reset the app to its default state. You will need to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementation for clearing app data
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App data clearing will be implemented')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
} 