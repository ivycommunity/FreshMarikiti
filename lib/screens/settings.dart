import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sokoni/screens/auth/login.dart';
import '../main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppThemeMode _currentTheme;
  bool _notificationsEnabled = true;
  String _currentLanguage = 'English';
  final _auth = FirebaseAuth.instance;

  static const List<String> _languages = [
    'English',
    'Swahili',
    'French',
  ];

  @override
  void initState() {
    super.initState();
    _loadNotificationPref();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe place to access ThemeSwitcher
    final themeSwitcher = ThemeSwitcher.of(context);
    _currentTheme = themeSwitcher.appThemeMode;
  }

  Future<void> _loadNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _setNotificationPref(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeSwitcher = ThemeSwitcher.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Theme'),
            trailing: DropdownButton<AppThemeMode>(
              value: _currentTheme,
              onChanged: (mode) {
                if (mode != null) {
                  themeSwitcher.changeTheme(mode);
                  setState(() => _currentTheme = mode);
                }
              },
              items: AppThemeMode.values.map((mode) {
                return DropdownMenuItem(
                  value: mode,
                  child: Text(mode.toString().split('.').last.capitalize()),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          Text('Notifications', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Enable push notifications'),
            value: _notificationsEnabled,
            onChanged: _setNotificationPref,
          ),
          const Divider(),
          Text('Language', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('App Language'),
            trailing: DropdownButton<String>(
              value: _currentLanguage,
              onChanged: (lang) {
                if (lang != null) {
                  setState(() => _currentLanguage = lang);
                }
              },
              items: _languages.map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(lang),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          Text('Account', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Logout'),
            leading: const Icon(Icons.logout),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();

              // Clear saved login details
              await prefs.remove('email');
              await prefs.remove('password');

              // Sign out from Firebase Auth
              await FirebaseAuth.instance.signOut();

              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false, // Removes all previous routes
                );

              }
            },
          ),

          const Divider(),
          Text('About', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Version'),
            subtitle: const Text('v1.0.0'),
            leading: const Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }
}


// Extension to capitalize enum names
extension on String {
  String capitalize() => isEmpty ? '' : this[0].toUpperCase() + substring(1);
}
