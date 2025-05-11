import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sokoni/screens/customer/product_detail.dart';
import '../../main.dart';
import '../settings.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({Key? key}) : super(key: key);

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _selectedIndex = 0;
  String location = 'Langata, Nairobi';

  final List<String> categories = [
    'Fruits', 'Vegetables', 'Spices', 'Grains', 'Dairy', 'All'
  ];
  final List<Map<String, dynamic>> vendors = [
    {'name': 'Mama Amina', 'image': 'assets/images/mama.jpg', 'rating': 4.7},
    {'name': 'FreshFarm', 'image': 'assets/images/stall-1.jpg', 'rating': 4.5},
    {'name': 'Organic Valley', 'image': 'assets/images/stall-2.jpg', 'rating': 4.8},
    {'name': 'Green Harvest', 'image': 'assets/images/stall-3.jpg', 'rating': 4.6},
  ];

  final List<Map<String, dynamic>> products = [
    {'name': 'Tomatoes', 'image': 'assets/images/tomatoes.jpg', 'price': 50, 'rating': 4.5, 'unit': 'kg'},
    {'name': 'Kales', 'image': 'assets/images/kales.jpg', 'price': 30, 'rating': 4.0, 'unit': 'bunch'},
    {'name': 'Mangoes', 'image': 'assets/images/mangoes.jpg', 'price': 60, 'rating': 4.8, 'unit': 'piece'},
    {'name': 'Coriander', 'image': 'assets/images/coriander.jpg', 'price': 20, 'rating': 3.9, 'unit': 'bunch'},
    {'name': 'Avocados', 'image': 'assets/images/kales.jpg', 'price': 40, 'rating': 4.7, 'unit': 'piece'},
    {'name': 'Carrots', 'image': 'assets/images/tomatoes.jpg', 'price': 35, 'rating': 4.2, 'unit': 'kg'},
  ];

  void _onTabChanged(int index) => setState(() => _selectedIndex = index);

  void _goToChat() {
    // TODO: Implement chat
  }

  void _goToCart() {
    // TODO: Implement cart
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.location_on_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery to',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    location,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(smallSize: 10, child: const Icon(Icons.chat_outlined)),
            onPressed: _goToChat,
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
          ),
          IconButton(
            icon: Badge(label: const Text('2'), child: const Icon(Icons.shopping_cart_outlined)),
            onPressed: _goToCart,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(theme),
            const SizedBox(height: 20),
            _buildCategoriesSection(theme),
            const SizedBox(height: 24),
            _buildSectionHeader('Popular Vendors', 'See all', theme),
            const SizedBox(height: 12),
            _buildVendorsList(),
            const SizedBox(height: 24),
            // _buildFlashSalesBanner(theme),
            // const SizedBox(height: 24),
            _buildSectionHeader('Featured Products', 'View all', theme),
            const SizedBox(height: 12),
            _buildProductsGrid(theme),
            const SizedBox(height: 24),
            _buildSectionHeader('Customer Reviews', '', theme),
            const SizedBox(height: 12),
            _buildReviewsList(theme),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(theme),
    );
  }


  Widget _buildSearchBar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return TextField(
      decoration: InputDecoration(
        hintText: "Search for mangoes, spinach...",
        prefixIcon: Icon(Icons.search, color: theme.hintColor),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildCategoriesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collectionGroup('categories') // 🔥 fetch across all stalls
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text("No categories found");
              }

              final docs = snapshot.data!.docs;

              // 🔥 Get unique categories by name (to avoid duplicates)
              final uniqueNames = docs
                  .map((doc) => doc['name'] as String)
                  .toSet()
                  .toList();

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: uniqueNames.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final name = uniqueNames[index];
                  final isSelected = index == 0; // default selected

                  return ChoiceChip(
                    label: Text(name),
                    selected: isSelected,
                    onSelected: (_) {
                      // TODO: Implement category filtering here
                    },
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : null,
                    ),
                    selectedColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }



  Widget _buildSectionHeader(String title, String action, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (action.isNotEmpty)
          TextButton(
            onPressed: () {},
            child: Text(
              action,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVendorsList() {
    return SizedBox(
      height: 140, // Increased to prevent overflow
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'vendor')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Text("No vendors available");
          }

          final vendors = snapshot.data!.docs;

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: vendors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final vendor = vendors[index];
              final data = vendor.data() as Map<String, dynamic>;

              final name = data['name'] ?? 'No Name';
              final imageUrl = data['profileImageUrl'] ?? '';

              // Safely read rating
              final rating = data['rating'];
              final double ratingValue = rating is num ? rating.toDouble() : 4.2;

              return SizedBox(
                width: 100,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        imageUrl.isNotEmpty
                            ? CircleAvatar(
                          backgroundImage: NetworkImage(imageUrl),
                          radius: 40,
                          backgroundColor: Colors.grey[200],
                        )
                            : const CircleAvatar(
                          child: Icon(Icons.person),
                          radius: 40,
                          backgroundColor: Colors.grey,
                        ),
                        Positioned(
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, size: 14, color: Colors.white),
                                const SizedBox(width: 2),
                                Text(
                                  ratingValue.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 12, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }



  // Widget _buildFlashSalesBanner(ThemeData theme) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         colors: [
  //           theme.colorScheme.primary.withOpacity(0.8),
  //           theme.colorScheme.secondary,
  //         ],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Row(
  //       children: [
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'Flash Sale!',
  //                 style: theme.textTheme.titleLarge?.copyWith(
  //                   color: Colors.white,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //               const SizedBox(height: 8),
  //               Text(
  //                 'Get 20% off on all fruits today only',
  //                 style: theme.textTheme.bodyMedium?.copyWith(
  //                   color: Colors.white.withOpacity(0.9),
  //                 ),
  //               ),
  //               const SizedBox(height: 12),
  //               ElevatedButton(
  //                 onPressed: () {},
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: Colors.white,
  //                   foregroundColor: theme.colorScheme.primary,
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(20),
  //                   ),
  //                 ),
  //                 child: const Text('Shop Now'),
  //               ),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(width: 16),
  //         Image.asset(
  //           'assets/images/stall-3.jpg',
  //           width: 100,
  //           height: 100,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildProductsGrid(ThemeData theme) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      // padding: const EdgeInsets.symmetric(horizontal: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 8,
        childAspectRatio: 0.7, // Adjusted to give more vertical space
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return LayoutBuilder(
          builder: (context, constraints) {
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailPage(product: product),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      SizedBox(
                        height: constraints.maxHeight * 0.45, // 45% of card height
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                product['image'],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.favorite_border),
                                onPressed: () {},
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.8),
                                  padding: const EdgeInsets.all(4),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      product['rating'].toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product['name'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'KES ${product['price']} / ${product['unit']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add_shopping_cart, size: 16),
                          label: const Text('Add'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildReviewsList(ThemeData theme) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Brian',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                                  (i) => Icon(
                                i < 4 ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '2 days ago',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Great quality produce and fast delivery! The tomatoes were fresh and perfectly ripe.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anne',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: List.generate(
                              5,
                                  (i) => Icon(
                                i < 5 ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '1 week ago',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Affordable prices and very fresh fruits. The mangoes were sweet and juicy!',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar(ThemeData theme) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onTabChanged,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Badge(
            label: Text('2'),
            child: Icon(Icons.shopping_cart_outlined),
          ),
          selectedIcon: Badge(
            label: Text('2'),
            child: Icon(Icons.shopping_cart),
          ),
          label: 'Cart',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}