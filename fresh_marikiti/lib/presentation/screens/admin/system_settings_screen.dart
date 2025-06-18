import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fresh_marikiti/core/models/admin_models.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/utils/api_endpoints.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({Key? key}) : super(key: key);

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  SystemSettings? _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSystemSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSystemSettings() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.get(ApiEndpoints.adminSystemSettings);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _settings = SystemSettings.fromJson(data['settings']);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load system settings');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await ApiService.put(
        ApiEndpoints.adminSystemSettings,
        _settings!.toJson(),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to save settings');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'System Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          if (_settings != null)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white),
              onPressed: _isSaving ? null : _saveSettings,
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadSystemSettings(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'General', icon: Icon(Icons.settings)),
            Tab(text: 'Features', icon: Icon(Icons.toggle_on)),
            Tab(text: 'Payments', icon: Icon(Icons.payment)),
            Tab(text: 'Notifications', icon: Icon(Icons.notifications)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _settings == null
              ? const Center(child: Text('Failed to load settings'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGeneralTab(),
                    _buildFeaturesTab(),
                    _buildPaymentsTab(),
                    _buildNotificationsTab(),
                  ],
                ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlatformInfoCard(),
          const SizedBox(height: 16),
          _buildBusinessHoursCard(),
          const SizedBox(height: 16),
          _buildMaintenanceCard(),
          const SizedBox(height: 16),
          _buildSecurityCard(),
        ],
      ),
    );
  }

  Widget _buildPlatformInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Platform Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'Platform Name',
              TextField(
                controller: TextEditingController(text: _settings!.platformName),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter platform name',
                ),
                onChanged: (value) {
                  _settings!.platformName = value;
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'Support Email',
              TextField(
                controller: TextEditingController(text: _settings!.supportEmail),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter support email',
                ),
                onChanged: (value) {
                  _settings!.supportEmail = value;
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'Support Phone',
              TextField(
                controller: TextEditingController(text: _settings!.supportPhone),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter support phone',
                ),
                onChanged: (value) {
                  _settings!.supportPhone = value;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessHoursCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Hours',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSettingItem(
                    'Opening Time',
                    TextField(
                      controller: TextEditingController(text: _settings!.businessHours.openTime),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '08:00',
                      ),
                      onChanged: (value) {
                        _settings!.businessHours.openTime = value;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSettingItem(
                    'Closing Time',
                    TextField(
                      controller: TextEditingController(text: _settings!.businessHours.closeTime),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '22:00',
                      ),
                      onChanged: (value) {
                        _settings!.businessHours.closeTime = value;
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('24/7 Operations'),
              subtitle: const Text('Enable round-the-clock operations'),
              value: _settings!.businessHours.is24Hours,
              onChanged: (value) {
                setState(() {
                  _settings!.businessHours.is24Hours = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Maintenance Mode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Maintenance Mode'),
              subtitle: const Text('Users will see a maintenance message'),
              value: _settings!.maintenanceMode.enabled,
              onChanged: (value) {
                setState(() {
                  _settings!.maintenanceMode.enabled = value;
                });
              },
            ),
            if (_settings!.maintenanceMode.enabled) ...[
              const SizedBox(height: 16),
              _buildSettingItem(
                'Maintenance Message',
                TextField(
                  controller: TextEditingController(text: _settings!.maintenanceMode.message),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter maintenance message',
                  ),
                  onChanged: (value) {
                    _settings!.maintenanceMode.message = value;
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Require Email Verification'),
              subtitle: const Text('Users must verify email before access'),
              value: _settings!.security.requireEmailVerification,
              onChanged: (value) {
                setState(() {
                  _settings!.security.requireEmailVerification = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Two-Factor Authentication'),
              subtitle: const Text('Enable 2FA for admin accounts'),
              value: _settings!.security.enableTwoFactor,
              onChanged: (value) {
                setState(() {
                  _settings!.security.enableTwoFactor = value;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'Session Timeout (minutes)',
              TextField(
                controller: TextEditingController(text: _settings!.security.sessionTimeout.toString()),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '30',
                ),
                onChanged: (value) {
                  _settings!.security.sessionTimeout = int.tryParse(value) ?? 30;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserFeaturesCard(),
          const SizedBox(height: 16),
          _buildOrderFeaturesCard(),
          const SizedBox(height: 16),
          _buildIntegrationFeaturesCard(),
        ],
      ),
    );
  }

  Widget _buildUserFeaturesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('User Registration'),
              subtitle: const Text('Allow new user registrations'),
              value: _settings!.features.allowUserRegistration,
              onChanged: (value) {
                setState(() {
                  _settings!.features.allowUserRegistration = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Guest Orders'),
              subtitle: const Text('Allow orders without registration'),
              value: _settings!.features.allowGuestOrders,
              onChanged: (value) {
                setState(() {
                  _settings!.features.allowGuestOrders = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Customer Reviews'),
              subtitle: const Text('Enable product and service reviews'),
              value: _settings!.features.enableReviews,
              onChanged: (value) {
                setState(() {
                  _settings!.features.enableReviews = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderFeaturesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Real-time Tracking'),
              subtitle: const Text('Enable GPS tracking for orders'),
              value: _settings!.features.enableRealTimeTracking,
              onChanged: (value) {
                setState(() {
                  _settings!.features.enableRealTimeTracking = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Scheduled Delivery'),
              subtitle: const Text('Allow customers to schedule deliveries'),
              value: _settings!.features.enableScheduledDelivery,
              onChanged: (value) {
                setState(() {
                  _settings!.features.enableScheduledDelivery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'Minimum Order Amount (KSh)',
              TextField(
                controller: TextEditingController(text: _settings!.features.minimumOrderAmount.toString()),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '100',
                ),
                onChanged: (value) {
                  _settings!.features.minimumOrderAmount = double.tryParse(value) ?? 0.0;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrationFeaturesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Integration Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('SMS Notifications'),
              subtitle: const Text('Send SMS updates to users'),
              value: _settings!.features.enableSMS,
              onChanged: (value) {
                setState(() {
                  _settings!.features.enableSMS = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Send email updates to users'),
              value: _settings!.features.enableEmail,
              onChanged: (value) {
                setState(() {
                  _settings!.features.enableEmail = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Send push notifications to mobile apps'),
              value: _settings!.features.enablePushNotifications,
              onChanged: (value) {
                setState(() {
                  _settings!.features.enablePushNotifications = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPaymentMethodsCard(),
          const SizedBox(height: 16),
          _buildMpesaSettingsCard(),
          const SizedBox(height: 16),
          _buildCommissionCard(),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Methods',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('M-Pesa'),
              subtitle: const Text('Mobile money payments'),
              value: _settings!.payments.enableMpesa,
              onChanged: (value) {
                setState(() {
                  _settings!.payments.enableMpesa = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Credit/Debit Cards'),
              subtitle: const Text('Visa, Mastercard payments'),
              value: _settings!.payments.enableCards,
              onChanged: (value) {
                setState(() {
                  _settings!.payments.enableCards = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Cash on Delivery'),
              subtitle: const Text('Pay upon delivery'),
              value: _settings!.payments.enableCash,
              onChanged: (value) {
                setState(() {
                  _settings!.payments.enableCash = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMpesaSettingsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'M-Pesa Configuration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'Business Short Code',
              TextField(
                controller: TextEditingController(text: _settings!.payments.mpesaShortCode),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter short code',
                ),
                onChanged: (value) {
                  _settings!.payments.mpesaShortCode = value;
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'Passkey',
              TextField(
                controller: TextEditingController(text: _settings!.payments.mpesaPasskey),
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter passkey',
                ),
                onChanged: (value) {
                  _settings!.payments.mpesaPasskey = value;
                },
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Sandbox Mode'),
              subtitle: const Text('Use test environment'),
              value: _settings!.payments.mpesaSandbox,
              onChanged: (value) {
                setState(() {
                  _settings!.payments.mpesaSandbox = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionCard() {
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
            _buildSettingItem(
              'Delivery Commission (%)',
              TextField(
                controller: TextEditingController(text: _settings!.payments.deliveryCommission.toString()),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '5.0',
                  suffix: Text('%'),
                ),
                onChanged: (value) {
                  _settings!.payments.deliveryCommission = double.tryParse(value) ?? 5.0;
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'Platform Fee (%)',
              TextField(
                controller: TextEditingController(text: _settings!.payments.platformFee.toString()),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '2.5',
                  suffix: Text('%'),
                ),
                onChanged: (value) {
                  _settings!.payments.platformFee = double.tryParse(value) ?? 2.5;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotificationSettingsCard(),
          const SizedBox(height: 16),
          _buildEmailSettingsCard(),
          const SizedBox(height: 16),
          _buildSMSSettingsCard(),
        ],
      ),
    );
  }

  Widget _buildNotificationSettingsCard() {
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
              title: const Text('Order Notifications'),
              subtitle: const Text('Notify users about order updates'),
              value: _settings!.notifications.orderNotifications,
              onChanged: (value) {
                setState(() {
                  _settings!.notifications.orderNotifications = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Payment Notifications'),
              subtitle: const Text('Notify about payment confirmations'),
              value: _settings!.notifications.paymentNotifications,
              onChanged: (value) {
                setState(() {
                  _settings!.notifications.paymentNotifications = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Marketing Notifications'),
              subtitle: const Text('Send promotional messages'),
              value: _settings!.notifications.marketingNotifications,
              onChanged: (value) {
                setState(() {
                  _settings!.notifications.marketingNotifications = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailSettingsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Email Configuration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'SMTP Server',
              TextField(
                controller: TextEditingController(text: _settings!.notifications.smtpServer),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'smtp.gmail.com',
                ),
                onChanged: (value) {
                  _settings!.notifications.smtpServer = value;
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'SMTP Port',
              TextField(
                controller: TextEditingController(text: _settings!.notifications.smtpPort.toString()),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '587',
                ),
                onChanged: (value) {
                  _settings!.notifications.smtpPort = int.tryParse(value) ?? 587;
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'From Email',
              TextField(
                controller: TextEditingController(text: _settings!.notifications.fromEmail),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'noreply@freshmarikiti.com',
                ),
                onChanged: (value) {
                  _settings!.notifications.fromEmail = value;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSMSSettingsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SMS Configuration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'SMS Provider',
              DropdownButtonFormField<String>(
                value: _settings!.notifications.smsProvider,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'africastalking', child: Text('Africa\'s Talking')),
                  DropdownMenuItem(value: 'twilio', child: Text('Twilio')),
                  DropdownMenuItem(value: 'safaricom', child: Text('Safaricom')),
                ],
                onChanged: (value) {
                  setState(() {
                    _settings!.notifications.smsProvider = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'SMS API Key',
              TextField(
                controller: TextEditingController(text: _settings!.notifications.smsApiKey),
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter API key',
                ),
                onChanged: (value) {
                  _settings!.notifications.smsApiKey = value;
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'Sender ID',
              TextField(
                controller: TextEditingController(text: _settings!.notifications.smsSenderId),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'FreshMarikiti',
                ),
                onChanged: (value) {
                  _settings!.notifications.smsSenderId = value;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class SystemSettings {
  String platformName;
  String supportEmail;
  String supportPhone;
  BusinessHours businessHours;
  MaintenanceMode maintenanceMode;
  SecuritySettings security;
  FeatureSettings features;
  PaymentSettings payments;
  NotificationSettings notifications;

  SystemSettings({
    required this.platformName,
    required this.supportEmail,
    required this.supportPhone,
    required this.businessHours,
    required this.maintenanceMode,
    required this.security,
    required this.features,
    required this.payments,
    required this.notifications,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) {
    return SystemSettings(
      platformName: json['platformName'] ?? '',
      supportEmail: json['supportEmail'] ?? '',
      supportPhone: json['supportPhone'] ?? '',
      businessHours: BusinessHours.fromJson(json['businessHours'] ?? {}),
      maintenanceMode: MaintenanceMode.fromJson(json['maintenanceMode'] ?? {}),
      security: SecuritySettings.fromJson(json['security'] ?? {}),
      features: FeatureSettings.fromJson(json['features'] ?? {}),
      payments: PaymentSettings.fromJson(json['payments'] ?? {}),
      notifications: NotificationSettings.fromJson(json['notifications'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platformName': platformName,
      'supportEmail': supportEmail,
      'supportPhone': supportPhone,
      'businessHours': businessHours.toJson(),
      'maintenanceMode': maintenanceMode.toJson(),
      'security': security.toJson(),
      'features': features.toJson(),
      'payments': payments.toJson(),
      'notifications': notifications.toJson(),
    };
  }
}

class BusinessHours {
  String openTime;
  String closeTime;
  bool is24Hours;

  BusinessHours({
    required this.openTime,
    required this.closeTime,
    required this.is24Hours,
  });

  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    return BusinessHours(
      openTime: json['openTime'] ?? '08:00',
      closeTime: json['closeTime'] ?? '22:00',
      is24Hours: json['is24Hours'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'openTime': openTime,
      'closeTime': closeTime,
      'is24Hours': is24Hours,
    };
  }
}

class MaintenanceMode {
  bool enabled;
  String message;

  MaintenanceMode({required this.enabled, required this.message});

  factory MaintenanceMode.fromJson(Map<String, dynamic> json) {
    return MaintenanceMode(
      enabled: json['enabled'] ?? false,
      message: json['message'] ?? 'System is under maintenance. Please try again later.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'message': message,
    };
  }
}

class SecuritySettings {
  bool requireEmailVerification;
  bool enableTwoFactor;
  int sessionTimeout;

  SecuritySettings({
    required this.requireEmailVerification,
    required this.enableTwoFactor,
    required this.sessionTimeout,
  });

  factory SecuritySettings.fromJson(Map<String, dynamic> json) {
    return SecuritySettings(
      requireEmailVerification: json['requireEmailVerification'] ?? true,
      enableTwoFactor: json['enableTwoFactor'] ?? false,
      sessionTimeout: json['sessionTimeout'] ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requireEmailVerification': requireEmailVerification,
      'enableTwoFactor': enableTwoFactor,
      'sessionTimeout': sessionTimeout,
    };
  }
}

class FeatureSettings {
  bool allowUserRegistration;
  bool allowGuestOrders;
  bool enableReviews;
  bool enableRealTimeTracking;
  bool enableScheduledDelivery;
  bool enableSMS;
  bool enableEmail;
  bool enablePushNotifications;
  double minimumOrderAmount;

  FeatureSettings({
    required this.allowUserRegistration,
    required this.allowGuestOrders,
    required this.enableReviews,
    required this.enableRealTimeTracking,
    required this.enableScheduledDelivery,
    required this.enableSMS,
    required this.enableEmail,
    required this.enablePushNotifications,
    required this.minimumOrderAmount,
  });

  factory FeatureSettings.fromJson(Map<String, dynamic> json) {
    return FeatureSettings(
      allowUserRegistration: json['allowUserRegistration'] ?? true,
      allowGuestOrders: json['allowGuestOrders'] ?? false,
      enableReviews: json['enableReviews'] ?? true,
      enableRealTimeTracking: json['enableRealTimeTracking'] ?? true,
      enableScheduledDelivery: json['enableScheduledDelivery'] ?? true,
      enableSMS: json['enableSMS'] ?? true,
      enableEmail: json['enableEmail'] ?? true,
      enablePushNotifications: json['enablePushNotifications'] ?? true,
      minimumOrderAmount: (json['minimumOrderAmount'] ?? 100).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowUserRegistration': allowUserRegistration,
      'allowGuestOrders': allowGuestOrders,
      'enableReviews': enableReviews,
      'enableRealTimeTracking': enableRealTimeTracking,
      'enableScheduledDelivery': enableScheduledDelivery,
      'enableSMS': enableSMS,
      'enableEmail': enableEmail,
      'enablePushNotifications': enablePushNotifications,
      'minimumOrderAmount': minimumOrderAmount,
    };
  }
}

class PaymentSettings {
  bool enableMpesa;
  bool enableCards;
  bool enableCash;
  String mpesaShortCode;
  String mpesaPasskey;
  bool mpesaSandbox;
  double deliveryCommission;
  double platformFee;

  PaymentSettings({
    required this.enableMpesa,
    required this.enableCards,
    required this.enableCash,
    required this.mpesaShortCode,
    required this.mpesaPasskey,
    required this.mpesaSandbox,
    required this.deliveryCommission,
    required this.platformFee,
  });

  factory PaymentSettings.fromJson(Map<String, dynamic> json) {
    return PaymentSettings(
      enableMpesa: json['enableMpesa'] ?? true,
      enableCards: json['enableCards'] ?? true,
      enableCash: json['enableCash'] ?? true,
      mpesaShortCode: json['mpesaShortCode'] ?? '',
      mpesaPasskey: json['mpesaPasskey'] ?? '',
      mpesaSandbox: json['mpesaSandbox'] ?? true,
      deliveryCommission: (json['deliveryCommission'] ?? 5.0).toDouble(),
      platformFee: (json['platformFee'] ?? 2.5).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableMpesa': enableMpesa,
      'enableCards': enableCards,
      'enableCash': enableCash,
      'mpesaShortCode': mpesaShortCode,
      'mpesaPasskey': mpesaPasskey,
      'mpesaSandbox': mpesaSandbox,
      'deliveryCommission': deliveryCommission,
      'platformFee': platformFee,
    };
  }
}

class NotificationSettings {
  bool orderNotifications;
  bool paymentNotifications;
  bool marketingNotifications;
  String smtpServer;
  int smtpPort;
  String fromEmail;
  String smsProvider;
  String smsApiKey;
  String smsSenderId;

  NotificationSettings({
    required this.orderNotifications,
    required this.paymentNotifications,
    required this.marketingNotifications,
    required this.smtpServer,
    required this.smtpPort,
    required this.fromEmail,
    required this.smsProvider,
    required this.smsApiKey,
    required this.smsSenderId,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      orderNotifications: json['orderNotifications'] ?? true,
      paymentNotifications: json['paymentNotifications'] ?? true,
      marketingNotifications: json['marketingNotifications'] ?? false,
      smtpServer: json['smtpServer'] ?? '',
      smtpPort: json['smtpPort'] ?? 587,
      fromEmail: json['fromEmail'] ?? '',
      smsProvider: json['smsProvider'] ?? 'africastalking',
      smsApiKey: json['smsApiKey'] ?? '',
      smsSenderId: json['smsSenderId'] ?? 'FreshMarikiti',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderNotifications': orderNotifications,
      'paymentNotifications': paymentNotifications,
      'marketingNotifications': marketingNotifications,
      'smtpServer': smtpServer,
      'smtpPort': smtpPort,
      'fromEmail': fromEmail,
      'smsProvider': smsProvider,
      'smsApiKey': smsApiKey,
      'smsSenderId': smsSenderId,
    };
  }
} 