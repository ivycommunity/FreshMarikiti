// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   final List<String> categories = ['All', 'Fruits', 'Vegetables', 'Spices'];
//   String selectedCategory = 'All';
//   int limit = 10;
//   bool isLoadingMore = false;
//
//   Stream<QuerySnapshot> getFeaturedStream() {
//     return FirebaseFirestore.instance
//         .collection('products')
//         .orderBy('orders', descending: true)
//         .limit(10)
//         .snapshots();
//   }
//
//   Future<List<DocumentSnapshot>> fetchAllProducts() async {
//     Query baseQuery = FirebaseFirestore.instance.collection('products');
//     if (selectedCategory != 'All') {
//       baseQuery = baseQuery.where('category', isEqualTo: selectedCategory);
//     }
//     baseQuery = baseQuery.orderBy('createdAt', descending: true).limit(limit);
//     final snapshot = await baseQuery.get();
//     return snapshot.docs;
//   }
//
//   void loadMore() async {
//     setState(() => isLoadingMore = true);
//     await Future.delayed(const Duration(seconds: 1));
//     setState(() {
//       limit += 10;
//       isLoadingMore = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       appBar: AppBar(title: const Text("Market Home")),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 20),
//             _sectionTitle('Most Popular 🔥', theme),
//             StreamBuilder<QuerySnapshot>(
//               stream: getFeaturedStream(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) return _buildShimmerLoader();
//                 final products = snapshot.data!.docs;
//                 return _buildFeaturedProducts(products, theme);
//               },
//             ),
//             const SizedBox(height: 24),
//             _sectionTitle('Browse All 🛍️', theme),
//             _categoryChips(),
//             FutureBuilder<List<DocumentSnapshot>>(
//               future: fetchAllProducts(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) return _buildShimmerLoader();
//                 final products = snapshot.data!;
//                 return Column(
//                   children: [
//                     _buildAllProducts(products, theme),
//                     const SizedBox(height: 10),
//                     _buildViewMoreButton(isLoadingMore, loadMore),
//                     const SizedBox(height: 20),
//                   ],
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _sectionTitle(String text, ThemeData theme) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
//       child: Text(
//         text,
//         style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//       ),
//     );
//   }
//
//   Widget _categoryChips() {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Row(
//         children: categories.map((cat) {
//           final isSelected = cat == selectedCategory;
//           return Padding(
//             padding: const EdgeInsets.only(right: 8),
//             child: ChoiceChip(
//               label: Text(cat),
//               selected: isSelected,
//               onSelected: (_) => setState(() => selectedCategory = cat),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
//
//   Widget _buildFeaturedProducts(List<DocumentSnapshot> products, ThemeData theme) {
//     return SizedBox(
//       height: 280,
//       child: ListView.separated(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         itemCount: products.length,
//         separatorBuilder: (_, __) => const SizedBox(width: 12),
//         itemBuilder: (context, index) {
//           final data = products[index].data() as Map<String, dynamic>;
//           return _productCard(data, theme, width: 180);
//         },
//       ),
//     );
//   }
//
//   Widget _buildAllProducts(List<DocumentSnapshot> products, ThemeData theme) {
//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       itemCount: products.length,
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         mainAxisSpacing: 16,
//         crossAxisSpacing: 12,
//         childAspectRatio: 0.7,
//       ),
//       itemBuilder: (context, index) {
//         final data = products[index].data() as Map<String, dynamic>;
//         return _productCard(data, theme);
//       },
//     );
//   }
//
//   Widget _productCard(Map<String, dynamic> data, ThemeData theme, {double? width}) {
//     return Container(
//       width: width,
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           AspectRatio(
//             aspectRatio: 1,
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(10),
//               child: Image.network(data['image'], fit: BoxFit.cover),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(data['name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
//           Text('Ksh ${data['price']} / ${data['unit']}', style: theme.textTheme.labelMedium?.copyWith(color: Colors.green)),
//           const Spacer(),
//           Align(
//             alignment: Alignment.bottomRight,
//             child: ElevatedButton(
//               onPressed: () {},
//               child: const Text("Add"),
//               style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildViewMoreButton(bool loading, VoidCallback onTap) {
//     return Center(
//       child: ElevatedButton(
//         onPressed: loading ? null : onTap,
//         child: loading
//             ? const SizedBox(
//             width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
//             : const Text('View More'),
//       ),
//     );
//   }
//
//   Widget _buildShimmerLoader() {
//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: 6,
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         mainAxisSpacing: 16,
//         crossAxisSpacing: 12,
//         childAspectRatio: 0.7,
//       ),
//       itemBuilder: (context, index) {
//         return Shimmer.fromColors(
//           baseColor: Colors.grey.shade300,
//           highlightColor: Colors.grey.shade100,
//           child: Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
