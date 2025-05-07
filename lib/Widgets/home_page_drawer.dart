import 'package:flutter/material.dart';

class HomePageDrawer extends StatelessWidget {
  const HomePageDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage("assets/profile_image.png"),
                ),
                SizedBox(height: 10),
                Text(
                  "Fresh Marikiti",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Using DrawerItem widgets instead of ListTile
          DrawerItem(
            icon: Icons.home,
            title: "Reviews",
            onTap: () {
              Navigator.pop(context);
              // Add navigation logic here
            },
          ),
          
          DrawerItem(
            icon: Icons.shopping_cart,
            title: "sales/Analytics",
            onTap: () {
              Navigator.pop(context);
              // Add navigation logic here
            },
          ),
          
          DrawerItem(
            icon: Icons.account_circle,
            title: "Goals",
            onTap: () {
              Navigator.pop(context);
              // Add navigation logic here
            },
          ),
          
          DrawerItem(
            icon: Icons.settings,
            title: "Support",
            onTap: () {
              Navigator.pop(context);
              // Add navigation logic here
            },
          ),
          
          const Divider(),
          
          DrawerItem(
            icon: Icons.exit_to_app,
            title: "Logout",
            onTap: () {
              Navigator.pop(context);
              // Add logout logic here
            },
          ),
        ],
      ),
    );
  }
}

// Custom DrawerItem widget
class DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showBadge;
  final int badgeCount;

  const DrawerItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.showBadge = false,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(icon, size: 24.0, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (showBadge)
                  Container(
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
