import 'dart:async';

import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sokoni/screens/vendor/sales/addSalePage.dart';
import 'package:sokoni/screens/vendor/sales/saleDetailPage.dart';
import 'package:sokoni/screens/vendor/sales/sales.dart';
import 'package:sokoni/screens/vendor/stalls/stallDetailPage.dart';
import '../admin/admin_profile.dart';
import '../settings.dart';
import 'categories/add_category_page.dart';
import 'categories/categories.dart';
import 'categories/products/add_product_page.dart';
import 'discounts/addDiscountPage.dart';
import 'discounts/discountDetailPage.dart';
import 'discounts/discountsPage.dart';
import 'flash sales/add_flashSale.dart';
import 'flash sales/flashSaleDetail.dart';
import 'flash sales/flashSales.dart';
import 'stalls/add_stall_page.dart';


class VendorHomePage extends StatefulWidget {
  const VendorHomePage({super.key});

  @override
  State<VendorHomePage> createState() => _VendorHomePageState();
}

class _VendorHomePageState extends State<VendorHomePage> {
  String userName = 'you here';
  String? userImageUrl;
  String vendorId = '';
  List<Map<String, dynamic>> _attendants = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentSales = [];
  bool _loadingSales = true;
  List<Map<String, dynamic>> _vendorStalls = [];
  bool _loadingStalls = true;
  List<Map<String, dynamic>> _activeDiscounts = [];
  bool _loadingDiscounts = true;
  List<Map<String, dynamic>> _lowStockProducts = [];
  bool _loadingLowStock = true;
  bool _showAllLowStock = false;
  Map<String, String> _stallMap = {};
  num _totalSales = 0;
  int _totalOrders = 0;
  int _totalProducts = 0;
  bool _statsLoading = false;



  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _fetchAttendants();
    _fetchRecentSales();
    _fetchVendorStalls();
    _fetchActiveDiscounts();
    _fetchLowStockProducts();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    await _loadUserDetails();
    setState(() => _statsLoading = true);

    final stalls = await getStallsForVendor(vendorId); // Get all vendor stalls
    num totalSales = 0;
    int totalOrders = 0;
    int totalProducts = 0;

    for (var stall in stalls) {
      final stallId = stall['id'];
      try {
        // Fetch sales
        final salesSnapshot = await FirebaseFirestore.instance
            .collection('stalls')
            .doc(stallId)
            .collection('sales')
            .get();

        totalSales += salesSnapshot.docs.length;

        // Fetch orders
        final ordersSnapshot = await FirebaseFirestore.instance
            .collection('stalls')
            .doc(stallId)
            .collection('orders')
            .get();

        totalOrders += ordersSnapshot.docs.length;

        // Fetch products count
        final categoriesSnapshot = await FirebaseFirestore.instance
            .collection('stalls')
            .doc(stallId)
            .collection('categories')
            .get();

        for (var categoryDoc in categoriesSnapshot.docs) {
          final categoryId = categoryDoc.id;

          // Products directly in category
          final categoryProductsSnapshot = await FirebaseFirestore.instance
              .collection('stalls')
              .doc(stallId)
              .collection('categories')
              .doc(categoryId)
              .collection('products')
              .get();

          totalProducts += categoryProductsSnapshot.docs.length;
          // for (var productDoc in categoryProductsSnapshot.docs) {
          //   totalProducts += ((productDoc['quantity'] ?? 0) as num).round();
          // }

          // Products inside subcategories
          final subcategoriesSnapshot = await FirebaseFirestore.instance
              .collection('stalls')
              .doc(stallId)
              .collection('categories')
              .doc(categoryId)
              .collection('subcategories')
              .get();

          for (var subcategoryDoc in subcategoriesSnapshot.docs) {
            final subcategoryId = subcategoryDoc.id;

            final subProductsSnapshot = await FirebaseFirestore.instance
                .collection('stalls')
                .doc(stallId)
                .collection('categories')
                .doc(categoryId)
                .collection('subcategories')
                .doc(subcategoryId)
                .collection('products')
                .get();

            totalProducts += subProductsSnapshot.docs.length;

            // for (var productDoc in subProductsSnapshot.docs) {
            //   totalProducts += ((productDoc['quantity'] ?? 0) as num).round();
            // }
          }
        }
      } catch (e) {
        debugPrint('Error fetching stats: $e');
      }
    }

    if (mounted) {
      setState(() {
        _totalSales = totalSales;
        _totalOrders = totalOrders;
        _totalProducts = totalProducts;
        _statsLoading = false;
      });
    }
  }

  Future<void> _fetchLowStockProducts() async {
    setState(() => _loadingLowStock = true);

    try {
      final stalls = await getStallsForVendor(vendorId); // Get all vendor stalls

      List<Map<String, dynamic>> allProducts = [];

      for (var stall in stalls) {
        final stallId = stall['id'];

        final categorySnapshots = await FirebaseFirestore.instance
            .collection('stalls')
            .doc(stallId)
            .collection('categories')
            .get();

        for (var categoryDoc in categorySnapshots.docs) {
          final productsSnapshot = await categoryDoc.reference
              .collection('products')
              .where('quantity', isLessThanOrEqualTo: 5)
              .get();

          for (var productDoc in productsSnapshot.docs) {
            final data = productDoc.data();
            allProducts.add({
              'product': data['name'],
              'remaining': data['quantity'],
              'id': productDoc.id,
              'stallId': stallId,
            });
          }
        }
      }

      setState(() {
        _lowStockProducts = allProducts;
        _loadingLowStock = false;
      });
    } catch (e) {
      debugPrint('Error fetching low stock products: $e');
      setState(() {
        _lowStockProducts = [];
        _loadingLowStock = false;
      });
    }
  }

  Future<void> _fetchActiveDiscounts() async {
    setState(() => _loadingDiscounts = true);

    try {
      final stalls = await getStallsForVendor(vendorId); // Get all vendor stalls

      final now = DateTime.now();
      List<Map<String, dynamic>> discounts = [];

      for (var stall in stalls) {
        final stallId = stall['id'];

        final categorySnapshots = await FirebaseFirestore.instance
            .collection('stalls')
            .doc(stallId)
            .collection('categories')
            .get();

        for (var categoryDoc in categorySnapshots.docs) {
          final productsSnapshot = await categoryDoc.reference
              .collection('products')
              .where('discountPercent', isGreaterThan: 0)
              .get();

          for (var productDoc in productsSnapshot.docs) {
            final data = productDoc.data();
            final end = (data['discountEnd'] as Timestamp?)?.toDate();
            final start = (data['discountStart'] as Timestamp?)?.toDate();

            discounts.add({
              'product': data['name'],
              'discount': '${data['discountPercent']}% OFF',
              'ends': _formatDiscountEndTime(now, end),
              'start': start,
              'end': end,
              'stallId': stallId,
            });
          }
        }
      }

      setState(() {
        _activeDiscounts = discounts;
        _loadingDiscounts = false;
      });
    } catch (e) {
      debugPrint('Error fetching discounts: $e');
      setState(() {
        _activeDiscounts = [];
        _loadingDiscounts = false;
      });
    }
  }

  String _formatDiscountEndTime(DateTime now, DateTime? end) {
    if (end == null) return 'No end date';
    final diff = end.difference(now);
    if (diff.inDays > 1) return 'Ends in ${diff.inDays} days';
    if (diff.inDays == 1) return 'Ends tomorrow';
    if (diff.inHours > 0) return 'Ends in ${diff.inHours} hours';
    return 'Ends soon';
  }

  Future<void> _fetchRecentSales() async {
    setState(() => _loadingSales = true);

    try {
      final vendorStalls = await getStallsForVendor(vendorId); // [{'id': ..., 'name': ...}]

      // Ensure type safety
      final Map<String, String> stallMap = {
        for (var stall in vendorStalls)
          stall['id'] as String: stall['name'] as String? ?? 'Unnamed Stall',
      };

      List<Map<String, dynamic>> allSales = [];

      for (var stall in vendorStalls) {
        final salesSnapshot = await FirebaseFirestore.instance
            .collection('stalls')
            .doc(stall['id'])
            .collection('sales')
            .orderBy('timestamp', descending: true)
            .limit(5)
            .get();

        for (var doc in salesSnapshot.docs) {
          final data = doc.data();
          allSales.add({
            'total': data['total'],
            'timestamp': (data['timestamp'] as Timestamp?)?.toDate(),
            'productCount': (data['products'] as List).length,
            'paymentMethod': data['paymentMethod'],
            'stallId': stall['id'],
          });
        }
      }

      // Sort all collected sales by most recent
      allSales.sort((a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      setState(() {
        _recentSales = allSales.take(5).toList(); // Limit to 5 most recent sales across stalls
        _stallMap = stallMap; // Map of stallId -> stallName
        _loadingSales = false;
      });
    } catch (e) {
      debugPrint("Error fetching recent sales: $e");
      setState(() {
        _recentSales = [];
        _loadingSales = false;
      });
    }
  }

  Future<void> _fetchAttendants() async {
    try {
      final vendorId = FirebaseAuth.instance.currentUser!.email;

      // Get all stalls for the vendor
      final stallSnapshot = await FirebaseFirestore.instance
          .collection('stalls')
          .where('vendorId', isEqualTo: vendorId)
          .get();

      final attendantIds = <String>{}; // Use set to avoid duplicates

      for (var doc in stallSnapshot.docs) {
        final data = doc.data();
        final attendants = List<String>.from(data['attendants'] ?? []);
        attendantIds.addAll(attendants);
      }

      if (attendantIds.isEmpty) {
        setState(() {
          _attendants = [];
          _isLoading = false;
        });
        return;
      }

      // Fetch attendant details
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: attendantIds.toList())
          .get();

      final attendants = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'name': "${data['name']}",
          'role': data['role'],
          'status': data['status'] ?? 'Active',
        };
      }).toList();

      setState(() {
        _attendants = attendants;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching attendants: $e');
      setState(() {
        _attendants = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAddProduct() async {
    final vendorId = FirebaseAuth.instance.currentUser!.email;

    final stallSnapshot =
        await FirebaseFirestore.instance
            .collection('stalls')
            .where('vendorId', isEqualTo: vendorId)
            .get();

    if (stallSnapshot.docs.isEmpty) {
      _showPrompt(
        'No stalls found',
        'Please add a stall before adding products.',
      );
      return;
    }

    // Navigate to stall selector
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectStallPage(stalls: stallSnapshot.docs),
      ),
    );
  }

  void _showPrompt(String title, String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  Future<void> _loadUserDetails() async {
    print("Function called: LOADING USER DETAILS");
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.email)
              .get();
      if (doc.exists) {
        final data = doc.data();
        print("USER document FOUND");

        setState(() {
          userName = data!.containsKey('name') ? data['name'] : 'you here';
          userImageUrl =
              data.containsKey('profileImageUrl')
                  ? data['profileImageUrl']
                  : null;
          vendorId = data.containsKey('email') ? data['email'] : null;
        });

        print("USERNAME HERE: $userName");
      } else {
        print("USER document NOT FOUND");
      }
    } else {
      print("USER NOT FOUND");
    }
  }

  Future<List<Map<String, dynamic>>> getStallsForVendor(String vendorId) async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('stalls')
            .where('vendorId', isEqualTo: vendorId)
            .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // This ensures we have the Firestore doc ID too
      return data;
    }).toList();
  }

  Future<void> _fetchVendorStalls() async {
    try {
      final stalls = await getStallsForVendor(vendorId);
      setState(() {
        _vendorStalls = stalls;
        _loadingStalls = false;
      });
    } catch (e) {
      debugPrint("Error fetching stalls: $e");
      setState(() {
        _vendorStalls = [];
        _loadingStalls = false;
      });
    }
  }

  void _handleMakeSale(BuildContext context) async {
    try {
      final stalls = await getStallsForVendor(vendorId);

      if (stalls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You don’t have any stalls yet.')),
        );
        return;
      }

      if (stalls.length == 1) {
        // If only one stall, navigate directly
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MakeSalePage(stallId: stalls[0]['id']),
          ),
        );
      } else {
        // Show a dialog to select the stall
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Select Stall'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: stalls.length,
                  itemBuilder: (context, index) {
                    final stall = stalls[index];
                    return ListTile(
                      title: Text(stall['name'] ?? 'Unnamed Stall'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MakeSalePage(stallId: stall['id']),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Error loading stalls for sale: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load stalls. Try again later.')),
      );
    }
  }

  void _handleFlashSale(BuildContext context) async {
    try {
      final stalls = await getStallsForVendor(vendorId);

      if (stalls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You don’t have any stalls yet.')),
        );
        return;
      }

      if (stalls.length == 1) {
        // If only one stall, navigate directly
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddFlashSalePage(stallId: stalls[0]['id']),
          ),
        );
      } else {
        // Show a dialog to select the stall
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Select Stall'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: stalls.length,
                  itemBuilder: (context, index) {
                    final stall = stalls[index];
                    return ListTile(
                      title: Text(stall['name'] ?? 'Unnamed Stall'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddFlashSalePage(stallId: stall['id']),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Error loading stalls for sale: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load stalls. Try again later.')),
      );
    }
  }

  void _handleDiscount(BuildContext context) async {
    try {
      final stalls = await getStallsForVendor(vendorId);

      if (stalls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You don’t have any stalls yet.')),
        );
        return;
      }

      if (stalls.length == 1) {
        // If only one stall, navigate directly
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddDiscountsPage(stallId: stalls[0]['id']),
          ),
        );
      } else {
        // Show a dialog to select the stall
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Select Stall'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: stalls.length,
                  itemBuilder: (context, index) {
                    final stall = stalls[index];
                    return ListTile(
                      title: Text(stall['name'] ?? 'Unnamed Stall'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddDiscountsPage(stallId: stall['id']),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Error loading stalls for sale: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load stalls. Try again later.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeBanner(theme, isDark),
            const SizedBox(height: 24),

            // Stats Overview
            Text("Check out your stats:", style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            _buildStatsRow(theme, isDark),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(theme, primaryColor),
            const SizedBox(height: 24),

            // _buildVendorStallsSection(theme),
            // const SizedBox(height: 24,),

            _buildRecentSalesSection(theme, vendorId),

            // ToDo: implement Orders
            // Recent Orders Section
            // _buildSectionHeader(
            //   theme,
            //   "Recent Orders",
            //   "View All Orders",
            //   () {},
            // ),
            // const SizedBox(height: 12),
            // _buildRecentOrdersList(theme, isDark),
            // const SizedBox(height: 24),

            // Attendants Section
            // _buildSectionHeader(theme, "Your Attendants", "Manage", () {}),
            // const SizedBox(height: 12),
            // _buildAttendantsList(theme, isDark),
            // const SizedBox(height: 24),

            // Discounts/Special Offers


            // FlashSalesSection(),
            // const SizedBox(height: 12),

            DiscountsSection(vendorId: vendorId),
            const SizedBox(height: 24),



            // ToDo: Implement Reviews
            // Recent Reviews
            // _buildSectionHeader(theme, "Recent Reviews", "View All", () {}),
            // const SizedBox(height: 12),
            // _buildRecentReviews(theme, isDark),
            // const SizedBox(height: 24),

            // Low Stock Alerts
            LowStockAlertsSection(vendorId: vendorId,),
          ],
        ),
      ),
    );
  }

  // Common Section Header Widget
  Widget _buildSectionHeader(
    ThemeData theme,
    String title,
    String actionText,
    VoidCallback onAction,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(onPressed: onAction, child: Text(actionText)),
      ],
    );
  }

  Widget _buildWelcomeBanner(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_)=> ProfilePage())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isDark
                    ? [Colors.green.shade800, Colors.green.shade600]
                    : [Colors.green.shade600, Colors.green.shade300],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage:
                  userImageUrl != null
                      ? NetworkImage(userImageUrl!)
                      : const AssetImage("assets/images/mama-1.jpg")
                          as ImageProvider,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $userName!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Text(
                  //   'Today\'s summary: 12 new orders, KES 45,200 in sales',
                  //   style: theme.textTheme.bodySmall?.copyWith(
                  //     color: Colors.white.withOpacity(0.9),
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, bool isDark) {
    return _statsLoading
        ? const Center(child: CircularProgressIndicator())
        : GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 8,
      childAspectRatio: 0.7,
      children: [
        _buildStatCard(
          'Sales',
          _formatCurrency(_totalSales),
          Icons.attach_money_outlined,
          isDark ? Colors.teal.shade300 : Colors.teal,
          theme,
        ),
        _buildStatCard(
          'Orders',
          '$_totalOrders',
          Icons.shopping_cart_outlined,
          isDark ? Colors.orange.shade300 : Colors.orange,
          theme,
        ),
        _buildStatCard(
          'Products',
          '$_totalProducts',
          Icons.inventory_2_outlined,
          isDark ? Colors.blue.shade300 : Colors.blue,
          theme,
        ),
      ],
    );
  }

  String _formatCurrency(num value) {
    return value >= 1000
        ? '${(value / 1000).toStringAsFixed(1)}K'
        : value.toStringAsFixed(0);
  }


  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme, Color primaryColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleMakeSale(context),
                icon: const Icon(Icons.sell),
                label: const Text('Sell'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _handleAddProduct,
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final stalls = await getStallsForVendor(vendorId);

                    if (stalls.isEmpty) {
                      showDialog(
                        context: context,
                        builder:
                            (_) => AlertDialog(
                          title: const Text('No Stalls Found'),
                          content: const Text(
                            'Please add stalls and items to continue.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    } else if (stalls.length == 1) {
                      final stallId =
                      stalls[0]['id']; // or stalls[0].id depending on how you structure it
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoriesPage(stallId: stallId),
                        ),
                      );
                    } else {
                      // Multiple stalls: show selection
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        builder:
                            (_) => ListView.builder(
                          itemCount: stalls.length,
                          itemBuilder: (_, index) {
                            final stall = stalls[index];
                            return ListTile(
                              title: Text(stall['name']),
                              onTap: () {
                                Navigator.pop(context); // close the sheet
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => CategoriesPage(
                                      stallId: stall['id'],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error fetching stalls: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Something went wrong. Please try again.',
                        ),
                      ),
                    );
                  }
                },
                // Inventory logic here
                icon: const Icon(Icons.inventory_outlined),
                label: const Text('Inventory'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddStallPage(vendorId: vendorId),
                    ),
                  );
                },
                icon: const Icon(Icons.store_mall_directory),
                label: const Text('Add Stall'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _handleFlashSale(context),
                icon: const Icon(Icons.sell),
                label: const Text('flash sale'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: ()=> _handleDiscount(context),
                icon: const Icon(Icons.add),
                label: const Text('Add discount'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

          ],
        ),
      ],
    );
  }

  // Widget _buildVendorStallsSection(ThemeData theme) {
  //   if (_loadingStalls) {
  //     return const Center(child: CircularProgressIndicator());
  //   }
  //
  //   if (_vendorStalls.isEmpty) {
  //     return const SizedBox.shrink();
  //   }
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text("Your Stalls", style: theme.textTheme.titleMedium),
  //       const SizedBox(height: 8),
  //       ListView.builder(
  //         itemCount: _vendorStalls.length,
  //         shrinkWrap: true,
  //         physics: const NeverScrollableScrollPhysics(),
  //         itemBuilder: (context, index) {
  //           final stall = _vendorStalls[index];
  //           return Card(
  //             elevation: 2,
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //             child: ListTile(
  //               leading: stall['imageUrl'] != null
  //                   ? ClipRRect(
  //                 borderRadius: BorderRadius.circular(8),
  //                 child: Image.network(
  //                   stall['imageUrl'],
  //                   width: 50,
  //                   height: 50,
  //                   fit: BoxFit.cover,
  //                 ),
  //               )
  //                   : const CircleAvatar(child: Icon(Icons.store)),
  //               title: Text(stall['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
  //               subtitle: Text(stall['location'] ?? 'No location provided'),
  //               onTap: () {
  //                 // Navigate to Stall Detail or Management Page
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                     builder: (_) => StallDetailPage(stallId: stall['id']),
  //                   ),
  //                 );
  //               },
  //             ),
  //           );
  //         },
  //       ),
  //     ],
  //   );
  // }
  //
  // Widget _buildAttendantsList(ThemeData theme, bool isDark) {
  //   if (_isLoading) {
  //     return const Center(child: CircularProgressIndicator());
  //   }
  //
  //   if (_attendants.isEmpty) {
  //     return const SizedBox.shrink(); // Return empty if no attendants
  //   }
  //
  //   return ListView.separated(
  //     shrinkWrap: true,
  //     physics: const NeverScrollableScrollPhysics(),
  //     itemCount: _attendants.length,
  //     separatorBuilder: (_, __) => const SizedBox(height: 8),
  //     itemBuilder: (context, index) {
  //       final attendant = _attendants[index];
  //       return ListTile(
  //         leading: const CircleAvatar(child: Icon(Icons.person)),
  //         title: Text(attendant['name']!),
  //         subtitle: Text(attendant['role']!),
  //         trailing: Chip(
  //           label: Text(attendant['status']!),
  //           backgroundColor:
  //           attendant['status'] == 'Active'
  //               ? Colors.green.withOpacity(0.2)
  //               : Colors.grey.withOpacity(0.2),
  //           labelStyle: TextStyle(
  //             color:
  //             attendant['status'] == 'Active' ? Colors.green : Colors.grey,
  //           ),
  //         ),
  //         onTap: () {},
  //       );
  //     },
  //   );
  // }

  Widget _buildRecentSalesSection(ThemeData theme, String vendorId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stalls')
          .where('vendorId', isEqualTo: vendorId)
          .snapshots(),
      builder: (context, stallsSnapshot) {
        if (stallsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!stallsSnapshot.hasData || stallsSnapshot.data!.docs.isEmpty) {
          // No stalls => show nothing
          return const SizedBox.shrink();
        }

        final stalls = stallsSnapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              theme,
              "Recent Sales",
              "View All Sales",
                  () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SalesPage(vendorId: vendorId)));

              },
            ),
            const SizedBox(height: 12),

            // For each stall
            ...stalls.map((stallDoc) {
              final stallId = stallDoc['id'];
              final stallName = stallDoc['name'];

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('stalls')
                    .doc(stallId)
                    .collection('sales')
                    .orderBy('timestamp', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (context, salesSnapshot) {
                  if (salesSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!salesSnapshot.hasData || salesSnapshot.data!.docs.isEmpty) {
                    // No sales for this stall => skip showing
                    return const SizedBox.shrink();
                  }

                  final salesDocs = salesSnapshot.data!.docs;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stall Name header
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          stallName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Sales list
                      ListView.builder(
                        itemCount: salesDocs.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final sale = salesDocs[index];
                          final amount = sale['total'] ?? 0;
                          final timestamp = (sale['timestamp'] as Timestamp?)?.toDate();
                          final customerPhone = sale['customerPhone'] ?? 'Unknown';
                          final products = sale['products'] as List<dynamic>? ?? [];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SaleDetailsPage(
                                    sale: sale,
                                    stallName: stallName,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ksh ${amount.toStringAsFixed(2)}',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 4),
                                    Text(
                                      'Items sold: ${products.length}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    if (timestamp != null)
                                      Text(
                                        'Date: ${DateFormat.yMMMd().add_jm().format(timestamp)}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildRecentOrdersList(ThemeData theme, bool isDark) {
    final orders = [
      {
        'name': 'Jane Doe',
        'item': 'Tomatoes',
        'time': '2 hrs ago',
        'status': 'Processing',
      },
      {
        'name': 'Alex M.',
        'item': 'Mangoes',
        'time': '5 hrs ago',
        'status': 'Shipped',
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 5,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.green.shade900 : Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: isDark ? Colors.green.shade200 : Colors.green.shade700,
              ),
            ),
            title: Text(
              '${order['name']}',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${order['item']}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            order['status'] == 'Shipped'
                                ? (isDark
                                    ? Colors.blue.shade900
                                    : Colors.blue.shade50)
                                : (isDark
                                    ? Colors.orange.shade900
                                    : Colors.orange.shade50),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${order['status']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              order['status'] == 'Shipped'
                                  ? (isDark
                                      ? Colors.blue.shade200
                                      : Colors.blue.shade700)
                                  : (isDark
                                      ? Colors.orange.shade200
                                      : Colors.orange.shade700),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${order['time']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.6,
                        ),
                      ),
                    ),
                  ],
                ),
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

  Widget _buildRecentReviews(ThemeData theme, bool isDark) {
    final reviews = [
      {'name': 'Brian K.', 'rating': 4, 'comment': 'Great quality produce!'},
      {
        'name': 'Anne M.',
        'rating': 5,
        'comment': 'Excellent service and fresh fruits',
      },
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${review['name']}"),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < (review['rating'] as int)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ),
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

}

class SelectStallPage extends StatelessWidget {
  final List<DocumentSnapshot> stalls;

  const SelectStallPage({required this.stalls, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Stall')),
      body: ListView.builder(
        itemCount: stalls.length,
        itemBuilder: (_, index) {
          final stall = stalls[index];
          return ListTile(
            title: Text(stall['name']),
            subtitle: Text(stall['location']),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SelectCategoryPage(stallId: stall.id),
                  ),
                ),
          );
        },
      ),
    );
  }
}

class SelectCategoryPage extends StatefulWidget {
  final String stallId;

  const SelectCategoryPage({required this.stallId, super.key});

  @override
  State<SelectCategoryPage> createState() => _SelectCategoryPageState();
}

class _SelectCategoryPageState extends State<SelectCategoryPage> {
  List<DocumentSnapshot> _categories = [];
  Map<String, List<DocumentSnapshot>> _subcategories = {};

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('stalls')
        .doc(widget.stallId)
        .collection('categories')
        .get();

    setState(() {
      _categories = snapshot.docs;
    });

    if (_categories.isEmpty) {
      _showAddCategoryPrompt();
    } else {
      for (var category in _categories) {
        final subsnap = await category.reference.collection('subcategories').get();
        setState(() {
          _subcategories[category.id] = subsnap.docs;
        });
      }
    }
  }

  void _showAddCategoryPrompt() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('No categories found'),
        content: const Text('Please add a category before adding a product.'),
        actions: [
          TextButton(
            child: const Text('Add Category'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddCategoryPage(stallId: widget.stallId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _goToAddProduct(String categoryId, [String? subcategoryId]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductPage(
          stallId: widget.stallId,
          categoryId: categoryId,
          subcategoryId: subcategoryId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Category')),
      body: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (_, index) {
          final cat = _categories[index];
          final subs = _subcategories[cat.id] ?? [];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
              title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
              children: [
                if (subs.isEmpty)
                  ListTile(
                    title: const Text('No subcategories'),
                    subtitle: const Text('Tap to add to this category'),
                    onTap: () => _goToAddProduct(cat.id),
                  ),
                ...subs.map(
                      (sub) => ListTile(
                    title: Text(sub['name']),
                    leading: const Icon(Icons.chevron_right),
                    onTap: () => _goToAddProduct(cat.id, sub.id),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FlashSaleCard extends StatefulWidget {
  final String stallId;
  final String flashSaleId;
  final String productName;
  final String productImage;
  final double productPrice;
  final int discountPercent;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool active;

  const FlashSaleCard({
    Key? key,
    required this.stallId,
    required this.flashSaleId,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.discountPercent,
    this.startTime,
    this.endTime,
    required this.active,
  }) : super(key: key);

  @override
  State<FlashSaleCard> createState() => _FlashSaleCardState();
}

class _FlashSaleCardState extends State<FlashSaleCard> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

  void _calculateTimeLeft() {
    if (widget.endTime != null) {
      final now = DateTime.now();
      setState(() {
        _timeLeft = widget.endTime!.difference(now);
        if (_timeLeft.isNegative) {
          _timeLeft = Duration.zero;
        }
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final discountedPrice = widget.productPrice * (1 - widget.discountPercent / 100);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FlashSaleDetailPage(
              stallId: widget.stallId,
              flashSaleId: widget.flashSaleId,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(right: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: widget.active
                  ? [Colors.orange.shade200, Colors.deepOrange.shade400]
                  : [Colors.grey.shade300, Colors.grey.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.productImage,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),

              // Product Name
              Text(
                widget.productName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Price & Discount
              Row(
                children: [
                  Text(
                    "\$${discountedPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "\$${widget.productPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Countdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Active badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.active ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.active ? "Active" : "Inactive",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  // Countdown timer
                  Text(
                    _formatDuration(_timeLeft),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }
}

class FlashSalesSection extends StatefulWidget {
  const FlashSalesSection({Key? key}) : super(key: key);

  @override
  State<FlashSalesSection> createState() => _FlashSalesSectionState();
}

class _FlashSalesSectionState extends State<FlashSalesSection> {
  List<QueryDocumentSnapshot>? _flashSales;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchFlashSales();
  }

  Future<void> _fetchFlashSales() async {
    if (!mounted) return; // Ensure widget is still mounted
    setState(() {
      _isLoading = true;
    });

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final stallSnapshot = await FirebaseFirestore.instance
        .collection('stalls')
        .where('vendorId', isEqualTo: currentUser.email)
        .get();

    if (stallSnapshot.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No stalls found for this vendor')),
        );
        print("No stalls Found");
        setState(() {
          _flashSales = [];
          _isLoading = false;
        });
      }
      return;
    }

    final stallIds = stallSnapshot.docs.map((doc) => doc['id'] as String).toList();
    print("STALL IDS: $stallIds");

    List<QueryDocumentSnapshot> allSales = [];

    for (String stallId in stallIds) {
      final salesSnapshot = await FirebaseFirestore.instance
          .collection('stalls')
          .doc(stallId)
          .collection('flash_sales')
          .orderBy('createdAt', descending: true)
          .get();

      allSales.addAll(salesSnapshot.docs);
      print("Sales added");
    }

    allSales.sort((a, b) {
      final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      return bTime.compareTo(aTime);
    });

    final topSales = allSales.take(5).toList();
    print("TOP SALES: $topSales");

    if (mounted) {
      setState(() {
        _flashSales = topSales;
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return _flashSalesSection(context);
  }

  Widget _flashSalesSection(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_flashSales == null || _flashSales!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Flash Sales",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchFlashSales,  // Refresh on tap
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FlashSalesPage(stallId: ''), // You can pass stallId if needed
                        ),
                      );
                    },
                    child: const Text("View All"),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _flashSales!.length,
            itemBuilder: (context, index) {
              final sale = _flashSales![index];
              final saleId = sale.id;

              final stallRef = sale.reference.parent.parent;
              final stallId = stallRef?.id ?? '';

              final discountPercent = sale['discountPercent'];
              final active = sale['active'] ?? true;
              final productId = sale['productId'];

              final startTime = (sale['startTime'] as Timestamp?)?.toDate();
              final endTime = (sale['endTime'] as Timestamp?)?.toDate();

              // Now instead of nested StreamBuilder, just use FutureBuilder
              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collectionGroup('products')
                    .where('productId', isEqualTo: productId)
                    .limit(1)
                    .get(),
                builder: (context, productSnapshot) {
                  if (!productSnapshot.hasData || productSnapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final product = productSnapshot.data!.docs.first;
                  final productData = product.data() as Map<String, dynamic>;

                  final productName = productData['name'] ?? 'Unnamed';
                  final productImage = productData['imageUrl'] ?? '';
                  final productPrice = productData['price'] ?? 0.0;

                  return FlashSaleCard(
                    stallId: stallId,
                    flashSaleId: saleId,
                    productName: productName,
                    productImage: productImage,
                    productPrice: productPrice,
                    discountPercent: discountPercent,
                    startTime: startTime,
                    endTime: endTime,
                    active: active,
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }
}

class DiscountsSection extends StatefulWidget {
  final String vendorId; // 🔥 vendorId passed in
  const DiscountsSection({Key? key, required this.vendorId}) : super(key: key);

  @override
  State<DiscountsSection> createState() => _DiscountsSectionState();
}

class _DiscountsSectionState extends State<DiscountsSection> {
  List<QueryDocumentSnapshot>? _discountedProducts;
  bool _isLoading = false;
  List<String> _stallIds = [];

  @override
  void initState() {
    super.initState();
    _fetchStallsAndDiscounts();
  }

  Future<void> _fetchStallsAndDiscounts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Step 1: Get all stall IDs belonging to this vendor
      final stallsSnapshot = await FirebaseFirestore.instance
          .collection('stalls')
          .where('vendorId', isEqualTo: widget.vendorId)
          .get();

      final stallIds = stallsSnapshot.docs.map((doc) => doc.id).toList();
      print("Got Stalls: $stallIds");

      if (stallIds.isEmpty) {
        if (mounted) {
          setState(() {
            _discountedProducts = [];
            _isLoading = false;
          });
        }
        return;
      }

      _stallIds = stallIds;

      // Step 2: Fetch products with discounts across those stalls
      final productsSnapshot = await FirebaseFirestore.instance
          .collectionGroup('products')
          .where('stallId', whereIn: stallIds.length > 10 ? stallIds.sublist(0, 10) : stallIds)
          .where('discountPercent', isGreaterThan: 0)
          .get();

      final allProducts = productsSnapshot.docs.where((doc) {
        final start = (doc['discountStart'] as Timestamp?)?.toDate();
        final end = (doc['discountEnd'] as Timestamp?)?.toDate();
        final now = DateTime.now();

        return start != null && end != null && start.isBefore(now) && end.isAfter(now);
      }).toList();

      allProducts.sort((a, b) {
        final aEnd = (a['discountEnd'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bEnd = (b['discountEnd'] as Timestamp?)?.toDate() ?? DateTime.now();
        return aEnd.compareTo(bEnd);
      });

      if (mounted) {
        setState(() {
          _discountedProducts = allProducts.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching discounts: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _discountsSection(context);
  }

  Widget _discountsSection(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_discountedProducts == null || _discountedProducts!.isEmpty) {
      return const SizedBox.shrink(); // Show nothing if no discounts
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Discounts",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchStallsAndDiscounts,
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (_) => DiscountsPage(stallIds: _stallIds, stallId: '',),
                      //   ),
                      // );
                    },
                    child: const Text("View All"),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 300,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _discountedProducts!.length,
            itemBuilder: (context, index) {
              final product = _discountedProducts![index];
              final productData = product.data() as Map<String, dynamic>;

              return DiscountCard(
                productData: productData,
                onTap: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (_) => DiscountDetailPage(productData: productData),
                  //   ),
                  // );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class DiscountCard extends StatefulWidget {
  final Map<String, dynamic> productData;
  final VoidCallback onTap;

  const DiscountCard({Key? key, required this.productData, required this.onTap}) : super(key: key);

  @override
  State<DiscountCard> createState() => _DiscountCardState();
}

class _DiscountCardState extends State<DiscountCard> {
  late Timer _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    final end = (widget.productData['discountEnd'] as Timestamp?)?.toDate();
    _timeLeft = end != null ? end.difference(DateTime.now()) : Duration.zero;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final end = (widget.productData['discountEnd'] as Timestamp?)?.toDate();
      if (end == null) return;
      final now = DateTime.now();
      final newTimeLeft = end.difference(now);

      if (newTimeLeft.isNegative) {
        _timer.cancel();
        return;
      }

      setState(() {
        _timeLeft = newTimeLeft;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.productData['name'] ?? 'Unnamed';
    final imageUrl = widget.productData['imageUrl'] ?? '';
    final price = widget.productData['price'] ?? 0;
    final discountPercent = widget.productData['discountPercent'] ?? 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imageUrl.isNotEmpty
                ? ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 130,
                fit: BoxFit.cover,
              ),
            )
                : Container(
              height: 130,
              decoration: const BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Center(child: Icon(Icons.image)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text("\$${price.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "$discountPercent% OFF",
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Ends in: ${_formatDuration(_timeLeft)}",
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LowStockAlertsSection extends StatefulWidget {
  final String vendorId;
  const LowStockAlertsSection({Key? key, required this.vendorId}) : super(key: key);

  @override
  State<LowStockAlertsSection> createState() => _LowStockAlertsSectionState();
}

class _LowStockAlertsSectionState extends State<LowStockAlertsSection> {
  List<QueryDocumentSnapshot>? _lowStockProducts;
  bool _isLoading = false;
  List<String> _stallIds = [];

  @override
  void initState() {
    super.initState();
    _fetchStallsAndLowStockProducts();
  }

  Future<void> _fetchStallsAndLowStockProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Step 1: Get all stalls for this vendor
      final stallsSnapshot = await FirebaseFirestore.instance
          .collection('stalls')
          .where('vendorId', isEqualTo: widget.vendorId)
          .get();

      final stallIds = stallsSnapshot.docs.map((doc) => doc.id).toList();

      if (stallIds.isEmpty) {
        if (mounted) {
          setState(() {
            _lowStockProducts = [];
            _isLoading = false;
          });
        }
        return;
      }

      _stallIds = stallIds;

      // Step 2: Fetch low stock products (quantity <= 5)
      final productsSnapshot = await FirebaseFirestore.instance
          .collectionGroup('products')
          .where('stallId', whereIn: stallIds.length > 10 ? stallIds.sublist(0, 10) : stallIds)
          .where('quantity', isLessThanOrEqualTo: 5)
          .get();

      final products = productsSnapshot.docs;

      if (mounted) {
        setState(() {
          _lowStockProducts = products.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching low stock products: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _lowStockSection(context);
  }

  Widget _lowStockSection(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_lowStockProducts == null || _lowStockProducts!.isEmpty) {
      return const SizedBox.shrink(); // Show nothing if no low stock
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Low Stock Alerts",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchStallsAndLowStockProducts,
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (_) => LowStockPage(stallIds: _stallIds),
                      //   ),
                      // );
                    },
                    child: const Text("View All"),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 300,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _lowStockProducts!.length,
            itemBuilder: (context, index) {
              final product = _lowStockProducts![index];
              final productData = product.data() as Map<String, dynamic>;

              return LowStockCard(
                productData: productData,
                onTap: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (_) => ProductDetailPage(productData: productData),
                  //   ),
                  // );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class LowStockCard extends StatelessWidget {
  final Map<String, dynamic> productData;
  final VoidCallback onTap;

  const LowStockCard({Key? key, required this.productData, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = productData['imageUrl'] ?? '';
    final name = productData['name'] ?? 'No Name';
    final quantity = productData['quantity'] ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "Stock left: $quantity",
                style: TextStyle(
                  color: quantity <= 2 ? Colors.red : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text("Restock"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




