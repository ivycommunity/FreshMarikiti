import 'package:flutter/material.dart';
import 'tabs/stalls_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/staff_tab.dart';
import 'tabs/analytics_tab.dart';
import 'tabs/profile_tab.dart';

class VendorAdminHomeScreen extends StatefulWidget {
  const VendorAdminHomeScreen({super.key});

  @override
  State<VendorAdminHomeScreen> createState() => _VendorAdminHomeScreenState();
}

class _VendorAdminHomeScreenState extends State<VendorAdminHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    StallsTab(),
    OrdersTab(),
    StaffTab(),
    AnalyticsTab(),
    ProfileTab(),
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
            label: 'Stalls',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            label: 'Staff',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
} 