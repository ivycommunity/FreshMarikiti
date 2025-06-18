import 'package:flutter/material.dart';
import 'package:fresh_marikiti/presentation/screens/vendor_admin/vendor_admin_home_screen.dart';
import 'package:fresh_marikiti/presentation/screens/vendor_admin/stall_management_screen.dart';
import 'package:fresh_marikiti/presentation/screens/vendor_admin/vendor_management_screen.dart';
import 'package:fresh_marikiti/presentation/screens/vendor_admin/market_analytics_screen.dart';
import 'package:fresh_marikiti/presentation/screens/vendor_admin/vendor_admin_reports_screen.dart';
import 'package:fresh_marikiti/presentation/screens/vendor_admin/vendor_admin_profile_screen.dart';

class VendorAdminMainScreen extends StatefulWidget {
  const VendorAdminMainScreen({Key? key}) : super(key: key);

  @override
  State<VendorAdminMainScreen> createState() => _VendorAdminMainScreenState();
}

class _VendorAdminMainScreenState extends State<VendorAdminMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const VendorAdminHomeScreen(),
    const StallManagementScreen(),
    const VendorManagementScreen(),
    const MarketAnalyticsScreen(),
    const VendorAdminReportsScreen(),
    const VendorAdminProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.store),
      label: 'Stalls',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: 'Vendors',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.analytics),
      label: 'Analytics',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.assessment),
      label: 'Reports',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey[600],
          selectedFontSize: 12,
          unselectedFontSize: 10,
          elevation: 8,
          items: _navItems,
        ),
      ),
    );
  }
} 