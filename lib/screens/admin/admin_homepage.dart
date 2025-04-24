import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sokoni/screens/admin/admin_profile.dart';
import 'package:sokoni/screens/admin/register_vendor.dart';
import 'package:sokoni/screens/settings.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  bool _isDarkMode = false;
  String userName = 'you here';
  String? userImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    print("Function called: LOADING USER DETAILS");
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.email).get();
      if (doc.exists) {
        final data = doc.data();
        print("USER document FOUND");

        setState(() {
          userName = data!.containsKey('name') ? data['name'] : 'you here';
          userImageUrl = data.containsKey('profileImageUrl') ? data['profileImageUrl'] : null;
        });

        print("USERNAME HERE: $userName");
      } else {
        print("USER document NOT FOUND");
      }
    } else {
      print("USER NOT FOUND");
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;


    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeBanner(theme, isDark),
            const SizedBox(height: 24),

            // Overview Cards
            _buildSectionHeader(theme, "Platform Overview", "View All", () {}),
            const SizedBox(height: 12),
            _buildOverviewCards(theme, isDark),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(theme, primaryColor),
            const SizedBox(height: 24),

            // Vendors Section
            _buildSectionHeader(theme, "Vendors", "View All", () {}),
            const SizedBox(height: 12),
            _buildVendorList(theme, isDark),
            const SizedBox(height: 24),

            // Stalls Section
            _buildSectionHeader(theme, "Stalls", "View All", () {}),
            const SizedBox(height: 12),
            _buildStallsList(theme, isDark),
            const SizedBox(height: 24),

            // Flash Sales
            _buildSectionHeader(theme, "Flash Sales", "View All", () {}),
            const SizedBox(height: 12),
            _buildFlashSales(theme, isDark),
            const SizedBox(height: 24),

            // Reviews
            _buildSectionHeader(theme, "Recent Reviews", "View All", () {}),
            const SizedBox(height: 12),
            _buildReviews(theme, isDark),
            const SizedBox(height: 24),

            // Recent Activity
            _buildSectionHeader(theme, "Recent Activity", "View All", () {}),
            const SizedBox(height: 12),
            _buildActivityFeed(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, String actionText, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(actionText),
        ),
      ],
    );
  }

  Widget _buildWelcomeBanner(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.blue.shade800, Colors.blue.shade600]
                : [Colors.blue.shade600, Colors.blue.shade300],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: userImageUrl != null
                  ? NetworkImage(userImageUrl!)
                  : const AssetImage("assets/images/mama-1.jpg") as ImageProvider,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome $userName!",
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Here's your platform overview",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildOverviewCards(ThemeData theme, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1, // reduced from 1.5 to fix overflow
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _overviewCard(
          "Vendors",
          "12",
          Icons.store_outlined,
          isDark ? Colors.green.shade300 : Colors.green,
          theme,
          isDark,
        ),
        _overviewCard(
          "Sales",
          "KES 250k",
          Icons.attach_money_outlined,
          isDark ? Colors.orange.shade300 : Colors.orange,
          theme,
          isDark,
        ),
        _overviewCard(
          "Orders",
          "300+",
          Icons.shopping_bag_outlined,
          isDark ? Colors.purple.shade300 : Colors.purple,
          theme,
          isDark,
        ),
        _overviewCard(
          "Products",
          "600",
          Icons.category_outlined,
          isDark ? Colors.red.shade300 : Colors.redAccent,
          theme,
          isDark,
        ),
      ],
    );
  }


  Widget _overviewCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ThemeData theme,
      bool isDark,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(12),

          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // allows height to adjust
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 26, color: color),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }




  Widget _buildQuickActions(ThemeData theme, Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => AddVendorPage()));
            },
            icon: const Icon(Icons.person_add_outlined),
            label: const Text("Add Vendor"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.bar_chart_outlined),
            label: const Text("Reports"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVendorList(ThemeData theme, bool isDark) {
    final vendors = [
      {'name': 'Vendor Samuel', 'sales': 'KES 32,000', 'products': '45 items'},
      {'name': 'Vendor Mary', 'sales': 'KES 21,500', 'products': '32 items'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vendors.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final vendor = vendors[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.blue.shade900 : Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.store_outlined,
                color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
              ),
            ),
            title: Text(
              vendor['name']!,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Sales: ${vendor['sales']}'),
                Text('Products: ${vendor['products']}'),
              ],
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildStallsList(ThemeData theme, bool isDark) {
    final stalls = [
      {'name': 'Fruit Stall', 'location': 'Section A', 'vendor': 'Samuel'},
      {'name': 'Vegetable Stall', 'location': 'Section B', 'vendor': 'Mary'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stalls.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final stall = stalls[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.green.shade900 : Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.storefront_outlined,
                color: isDark ? Colors.green.shade200 : Colors.green.shade700,
              ),
            ),
            title: Text(
              stall['name']!,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Location: ${stall['location']}'),
                Text('Vendor: ${stall['vendor']}'),
              ],
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildFlashSales(ThemeData theme, bool isDark) {
    final sales = [
      {'product': 'Tomatoes', 'discount': '20% OFF', 'ends': 'Ends in 2 days'},
      {'product': 'Mangoes', 'discount': '15% OFF', 'ends': 'Ends tomorrow'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sales.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final sale = sales[index];
        return Card(
          elevation: 1,
          color: isDark ? Colors.amber.shade900.withOpacity(0.2) : Colors.amber.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.amber.shade900 : Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flash_on_outlined,
                color: isDark ? Colors.amber.shade200 : Colors.amber.shade700,
              ),
            ),
            title: Text(
              sale['product']!,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(sale['ends']!),
            trailing: Chip(
              label: Text(sale['discount']!),
              backgroundColor: Colors.amber.withOpacity(0.3),
            ),
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildReviews(ThemeData theme, bool isDark) {
    final reviews = [
      {'name': 'Brian K.', 'rating': 4, 'comment': 'Great quality produce!'},
      {'name': 'Anne M.', 'rating': 5, 'comment': 'Excellent service and fresh fruits'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final review = reviews[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.person_outline)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${review['name']}"),
                          Row(
                            children: List.generate(5, (i) => Icon(
                              i < (review['rating'] as int)
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            )),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text("${review['comment']}"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityFeed(ThemeData theme, bool isDark) {
    final activities = [
      {'event': 'New Vendor Registered', 'time': '10 min ago', 'icon': Icons.person_add_outlined},
      {'event': 'Samuel added a product', 'time': '1 hr ago', 'icon': Icons.add_box_outlined},
      {'event': 'Mary updated prices', 'time': '2 hrs ago', 'icon': Icons.price_change_outlined},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final activity = activities[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.purple.shade900 : Colors.purple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                activity['icon'] as IconData,
                color: isDark ? Colors.purple.shade200 : Colors.purple.shade700,
              ),
            ),
            title: Text(
              "${activity['event']}",
              style: theme.textTheme.bodyLarge,
            ),
            subtitle: Text("${activity['time']}"),
          ),
        );
      },
    );
  }
}