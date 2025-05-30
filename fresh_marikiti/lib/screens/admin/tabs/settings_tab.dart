import 'package:flutter/material.dart';
import 'package:fresh_marikiti/config/theme.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  // Dummy data - replace with actual settings
  final Map<String, dynamic> _settings = {
    'general': {
      'appName': 'Fresh Marikiti',
      'currency': 'KES',
      'timezone': 'Africa/Nairobi',
      'language': 'English',
    },
    'fees': {
      'platformFee': 5.0,
      'deliveryBaseFee': 100.0,
      'deliveryPerKm': 30.0,
      'connectorCommission': 10.0,
    },
    'notifications': {
      'enablePush': true,
      'enableEmail': true,
      'enableSMS': true,
      'maintenanceMode': false,
    },
    'security': {
      'requireEmailVerification': true,
      'requirePhoneVerification': true,
      'passwordMinLength': 8,
      'sessionTimeout': 30,
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Save settings
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // General Settings
          _buildSection(
            title: 'General Settings',
            icon: Icons.settings_outlined,
            color: Colors.blue,
            children: [
              _buildTextSetting(
                label: 'App Name',
                value: _settings['general']['appName'],
                onChanged: (value) {
                  setState(() {
                    _settings['general']['appName'] = value;
                  });
                },
              ),
              _buildDropdownSetting(
                label: 'Currency',
                value: _settings['general']['currency'],
                items: const ['KES', 'USD', 'EUR', 'GBP'],
                onChanged: (value) {
                  setState(() {
                    _settings['general']['currency'] = value;
                  });
                },
              ),
              _buildDropdownSetting(
                label: 'Timezone',
                value: _settings['general']['timezone'],
                items: const [
                  'Africa/Nairobi',
                  'UTC',
                  'Europe/London',
                  'America/New_York'
                ],
                onChanged: (value) {
                  setState(() {
                    _settings['general']['timezone'] = value;
                  });
                },
              ),
              _buildDropdownSetting(
                label: 'Language',
                value: _settings['general']['language'],
                items: const ['English', 'Swahili', 'French', 'Arabic'],
                onChanged: (value) {
                  setState(() {
                    _settings['general']['language'] = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Fees & Commissions
          _buildSection(
            title: 'Fees & Commissions',
            icon: Icons.payments_outlined,
            color: AppTheme.primaryGreen,
            children: [
              _buildNumberSetting(
                label: 'Platform Fee (%)',
                value: _settings['fees']['platformFee'],
                onChanged: (value) {
                  setState(() {
                    _settings['fees']['platformFee'] = value;
                  });
                },
              ),
              _buildNumberSetting(
                label: 'Delivery Base Fee',
                value: _settings['fees']['deliveryBaseFee'],
                onChanged: (value) {
                  setState(() {
                    _settings['fees']['deliveryBaseFee'] = value;
                  });
                },
              ),
              _buildNumberSetting(
                label: 'Delivery Fee per KM',
                value: _settings['fees']['deliveryPerKm'],
                onChanged: (value) {
                  setState(() {
                    _settings['fees']['deliveryPerKm'] = value;
                  });
                },
              ),
              _buildNumberSetting(
                label: 'Connector Commission (%)',
                value: _settings['fees']['connectorCommission'],
                onChanged: (value) {
                  setState(() {
                    _settings['fees']['connectorCommission'] = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Notifications
          _buildSection(
            title: 'Notifications',
            icon: Icons.notifications_outlined,
            color: Colors.orange,
            children: [
              _buildSwitchSetting(
                label: 'Enable Push Notifications',
                value: _settings['notifications']['enablePush'],
                onChanged: (value) {
                  setState(() {
                    _settings['notifications']['enablePush'] = value;
                  });
                },
              ),
              _buildSwitchSetting(
                label: 'Enable Email Notifications',
                value: _settings['notifications']['enableEmail'],
                onChanged: (value) {
                  setState(() {
                    _settings['notifications']['enableEmail'] = value;
                  });
                },
              ),
              _buildSwitchSetting(
                label: 'Enable SMS Notifications',
                value: _settings['notifications']['enableSMS'],
                onChanged: (value) {
                  setState(() {
                    _settings['notifications']['enableSMS'] = value;
                  });
                },
              ),
              _buildSwitchSetting(
                label: 'Maintenance Mode',
                value: _settings['notifications']['maintenanceMode'],
                onChanged: (value) {
                  setState(() {
                    _settings['notifications']['maintenanceMode'] = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Security
          _buildSection(
            title: 'Security',
            icon: Icons.security_outlined,
            color: Colors.red,
            children: [
              _buildSwitchSetting(
                label: 'Require Email Verification',
                value: _settings['security']['requireEmailVerification'],
                onChanged: (value) {
                  setState(() {
                    _settings['security']['requireEmailVerification'] = value;
                  });
                },
              ),
              _buildSwitchSetting(
                label: 'Require Phone Verification',
                value: _settings['security']['requirePhoneVerification'],
                onChanged: (value) {
                  setState(() {
                    _settings['security']['requirePhoneVerification'] = value;
                  });
                },
              ),
              _buildNumberSetting(
                label: 'Minimum Password Length',
                value: _settings['security']['passwordMinLength'].toDouble(),
                onChanged: (value) {
                  setState(() {
                    _settings['security']['passwordMinLength'] = value.toInt();
                  });
                },
                isInteger: true,
              ),
              _buildNumberSetting(
                label: 'Session Timeout (minutes)',
                value: _settings['security']['sessionTimeout'].toDouble(),
                onChanged: (value) {
                  setState(() {
                    _settings['security']['sessionTimeout'] = value.toInt();
                  });
                },
                isInteger: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTextStyles.heading2,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextSetting({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: value),
            onChanged: onChanged,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ))
                .toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberSetting({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    bool isInteger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: 0,
                  max: isInteger ? 100 : 1000,
                  divisions: isInteger ? 100 : 1000,
                  label: isInteger
                      ? value.toInt().toString()
                      : value.toStringAsFixed(1),
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 64,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isInteger
                      ? value.toInt().toString()
                      : value.toStringAsFixed(1),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body,
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
} 