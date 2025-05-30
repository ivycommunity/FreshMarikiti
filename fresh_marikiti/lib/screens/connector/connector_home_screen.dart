import 'package:flutter/material.dart';
import 'package:fresh_marikiti/config/theme.dart';
import 'package:fresh_marikiti/screens/connector/tabs/vendors_tab.dart';
import 'package:fresh_marikiti/screens/connector/tabs/waste_tab.dart';
import 'package:fresh_marikiti/screens/connector/tabs/reports_tab.dart';
import 'package:fresh_marikiti/screens/connector/tabs/profile_tab.dart';

class ConnectorHomeScreen extends StatefulWidget {
  const ConnectorHomeScreen({super.key});

  @override
  State<ConnectorHomeScreen> createState() => _ConnectorHomeScreenState();
}

class _ConnectorHomeScreenState extends State<ConnectorHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const VendorsTab(),
    const WasteTab(),
    const ReportsTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store),
            label: 'Vendors',
          ),
          NavigationDestination(
            icon: Icon(Icons.recycling_outlined),
            selectedIcon: Icon(Icons.recycling),
            label: 'Waste',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
} 