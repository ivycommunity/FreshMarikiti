import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sokoni/screens/vendor/sales/addSalePage.dart';
import 'package:sokoni/screens/vendor/sales/sales.dart';
import 'package:sokoni/screens/vendor/stalls/stallDetailPage.dart';
import '../settings.dart';
import 'categories/add_category_page.dart';
import 'categories/categories.dart';
import 'categories/products/add_product_page.dart';
import 'discounts/discountDetailPage.dart';
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


  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _fetchAttendants();
    _fetchRecentSales();
    _fetchVendorStalls();
    _fetchActiveDiscounts();
    _fetchLowStockProducts();
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
      final stalls = await getStallsForVendor(vendorId); // [{'id': ..., 'name': ...}]

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
                        Navigator.pop(context); // Close the dialog
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

            _buildVendorStallsSection(theme),
            const SizedBox(height: 24,),

            _buildRecentSalesSection(theme),
            const SizedBox(height: 24,),

            // Recent Orders Section
            _buildSectionHeader(
              theme,
              "Recent Orders",
              "View All Orders",
              () {},
            ),
            const SizedBox(height: 12),
            _buildRecentOrdersList(theme, isDark),
            const SizedBox(height: 24),

            // Attendants Section
            _buildSectionHeader(theme, "Your Attendants", "Manage", () {}),
            const SizedBox(height: 12),
            _buildAttendantsList(theme, isDark),
            const SizedBox(height: 24),

            // Discounts/Special Offers
            _buildSectionHeader(
              theme,
              "Current Discounts",
              "Manage Offers",
              () {},
            ),
            const SizedBox(height: 12),
            _buildDiscountsList(theme, isDark),
            const SizedBox(height: 24),

            // Recent Reviews
            _buildSectionHeader(theme, "Recent Reviews", "View All", () {}),
            const SizedBox(height: 12),
            _buildRecentReviews(theme, isDark),
            const SizedBox(height: 24),

            // Low Stock Alerts
            _buildSectionHeader(theme, "Low Stock Alerts", "View All", () {}),
            const SizedBox(height: 12),
            _buildLowStockList(theme, isDark),
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
    return Container(
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
                Text(
                  'Today\'s summary: 12 new orders, KES 45,200 in sales',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 8,
      childAspectRatio: 0.7,
      children: [
        _buildStatCard(
          'Sales',
          '122,300',
          Icons.attach_money_outlined,
          isDark ? Colors.teal.shade300 : Colors.teal,
          theme,
        ),
        _buildStatCard(
          'Orders',
          '27',
          Icons.shopping_cart_outlined,
          isDark ? Colors.orange.shade300 : Colors.orange,
          theme,
        ),
        _buildStatCard(
          'Products',
          '46',
          Icons.inventory_2_outlined,
          isDark ? Colors.blue.shade300 : Colors.blue,
          theme,
        ),
      ],
    );
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
            const SizedBox(width: 16),
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
          ],
        ),
      ],
    );
  }

  Widget _buildVendorStallsSection(ThemeData theme) {
    if (_loadingStalls) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vendorStalls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Your Stalls", style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ListView.builder(
          itemCount: _vendorStalls.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final stall = _vendorStalls[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: stall['imageUrl'] != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    stall['imageUrl'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
                    : const CircleAvatar(child: Icon(Icons.store)),
                title: Text(stall['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(stall['location'] ?? 'No location provided'),
                onTap: () {
                  // Navigate to Stall Detail or Management Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StallDetailPage(stallId: stall['id']),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAttendantsList(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_attendants.isEmpty) {
      return const SizedBox.shrink(); // Return empty if no attendants
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _attendants.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final attendant = _attendants[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(attendant['name']!),
          subtitle: Text(attendant['role']!),
          trailing: Chip(
            label: Text(attendant['status']!),
            backgroundColor:
            attendant['status'] == 'Active'
                ? Colors.green.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            labelStyle: TextStyle(
              color:
              attendant['status'] == 'Active' ? Colors.green : Colors.grey,
            ),
          ),
          onTap: () {},
        );
      },
    );
  }

  Widget _buildRecentSalesSection(ThemeData theme) {
    if (_loadingSales) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentSales.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Recent Sales", style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ListView.separated(
          itemCount: _recentSales.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final sale = _recentSales[index];
            final date = sale['timestamp'] != null
                ? DateFormat('MMM d, yyyy – hh:mm a').format(sale['timestamp'])
                : 'Unknown Time';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.receipt_long, color: Colors.blue),
              title: Text('Ksh ${sale['total']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('$date • ${sale['productCount']} item(s) • ${sale['paymentMethod']}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Optionally show Sale details
              },
            );
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // Navigate to all sales page
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => SalesPage(vendorId: vendorId),
              ));
            },
            child: const Text('View More'),
          ),
        ),
      ],
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

  Widget _buildDiscountsList(ThemeData theme, bool isDark) {
    if (_loadingDiscounts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeDiscounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Active Discounts", style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _activeDiscounts.length > 5 ? 5 : _activeDiscounts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final discount = _activeDiscounts[index];
            return Card(
              elevation: 1,
              color: isDark
                  ? Colors.amber.shade900.withOpacity(0.2)
                  : Colors.amber.shade50,
              child: ListTile(
                leading: const Icon(Icons.discount_outlined, color: Colors.amber),
                title: Text(discount['product'] ?? ''),
                subtitle: Text(discount['ends']),
                trailing: Chip(
                  label: Text(discount['discount']),
                  backgroundColor: Colors.amber.withOpacity(0.3),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DiscountDetailPage(product: discount),
                    ),);
                },
              ),
            );
          },
        ),
        if (_activeDiscounts.length > 5)
          TextButton(
            onPressed: () {
              // Navigate to ViewAllDiscountsPage or show a dialog
            },
            child: const Text('View More'),
          ),
      ],
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

  Widget _buildLowStockList(ThemeData theme, bool isDark) {
    if (_loadingLowStock) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_lowStockProducts.isEmpty) {
      return const SizedBox.shrink(); // Empty if nothing to show
    }

    final displayList = _showAllLowStock
        ? _lowStockProducts
        : _lowStockProducts.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Low Stock Alerts", style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = displayList[index];
            return Card(
              elevation: 1,
              color: isDark
                  ? Colors.red.shade900.withOpacity(0.2)
                  : Colors.red.shade50,
              child: ListTile(
                leading: const Icon(
                  Icons.warning_amber_outlined,
                  color: Colors.red,
                ),
                title: Text(item['product']),
                subtitle: Text('Only ${item['remaining']} left in stock'),
                trailing: TextButton(
                  onPressed: () {
                    // Navigate to restock page or handle restocking logic
                  },
                  child: const Text('Restock'),
                ),
              ),
            );
          },
        ),
        if (_lowStockProducts.length > 5)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showAllLowStock = !_showAllLowStock;
                });
              },
              child: Text(_showAllLowStock ? 'Show Less' : 'View More'),
            ),
          ),
      ],
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

