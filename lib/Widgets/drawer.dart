import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:marikiti/Homepage.dart';
import 'package:marikiti/Widgets/pages/About.dart';
import 'package:marikiti/Widgets/pages/Mycart.dart';
import 'package:marikiti/Widgets/pages/Profile.dart';
import 'package:marikiti/Widgets/pages/Settings.dart';
import 'package:marikiti/Widgets/pages/Subscription.dart';
import 'package:marikiti/Widgets/pages/Support.dart';
import 'package:marikiti/core/constants/providers/Themeprovders.dart';
import 'package:provider/provider.dart';

class FreshMarikitiDrawer extends StatefulWidget {
  const FreshMarikitiDrawer({super.key});

  @override
  State<FreshMarikitiDrawer> createState() => _FreshMarikitiDrawerState();
}

class _FreshMarikitiDrawerState extends State<FreshMarikitiDrawer> {
  @override
  Widget build(BuildContext context) {
    final themeprovider = Provider.of<ThemeProvider>(context);

    //final googleprovider = Provider.of<AuthProvider>(context);
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7,
      // height: MediaQuery.of(context).size.height *0.9,
      child: Drawer(
        // backgroundColor: Colors.transparent,
        child: Column(
          children: [
            SizedBox(height: 200),
            drawerItem(
                icon: Icons.home,
                text: "Home",
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HomePage()))),
            drawerItem(
                icon: Icons.subscriptions,
                text: "Subscription",
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Subscription()))),
            drawerItem(
                icon: Icons.shopping_cart,
                text: "My Cart",
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => CartPage()))),
            drawerItem(
                icon: Icons.person,
                text: "Profile",
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Profile()))),
            drawerItem(
                icon: Icons.info,
                text: "About Us",
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (context) => About()))),
            Divider(),
            drawerItem(
                icon: Icons.support,
                text: "Support",
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Support()))),
            /* drawerItem(
                icon: Icons.logout_outlined,
                text: "Log Out",
                onTap: () {
                  googleprovider.Logout();
                }), */

            drawerItem(
                icon: Icons.settings,
                text: "Settings",
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Settings()))),
            ListTile(
              leading: const Icon(
                Icons.dark_mode,
                color: Colors.green,
              ),
              title: const Text('Dark Mode'),
              trailing: Switch(
                  value: themeprovider.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeprovider.toggleTheme();
                  }),
            )
          ],
        ),
      ),
    );
  }
}

// Drawer Menu Item Widget
Widget drawerItem({
  required IconData icon,
  required String text,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Icon(icon, color: Colors.green[700]),
    title: Text(
      text,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    ),
    onTap: onTap,
  );
}
