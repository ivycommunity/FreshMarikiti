import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sokoni/screens/vendor/categories/add_category_page.dart';
import 'package:sokoni/screens/vendor/categories/edit_category.dart';
import 'package:sokoni/screens/vendor/categories/products/products.dart';


class CategoriesPage extends StatelessWidget {
  final String stallId;
  const CategoriesPage({super.key, required this.stallId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Categories")),
      floatingActionButton: FloatingActionButton.extended(onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (_)=> AddCategoryPage(stallId: stallId)));  }, label: Text("Add Category"),),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stalls')
            .doc(stallId)
            .collection('categories')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }

          final categories = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final doc = categories[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unnamed';
              final imageUrl = data['imageUrl'] ?? '';

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 16, top: 12),
                elevation: 3,
                child: ExpansionTile(
                  tilePadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  leading: imageUrl.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                    ),
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                  title: Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => EditCategoryPage(stallId: stallId, categoryId: doc.id)));
                      } else if (value == 'delete') {
                        _confirmDelete(context, stallId, doc.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  children: [
                    // Click to view category-level products
                    ListTile(
                      title: const Text('View Products'),
                      leading: const Icon(Icons.shopping_bag),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductsPage(
                              stallId: stallId,
                              categoryId: doc.id,
                            ),
                          ),
                        );
                      },
                    ),

                    // Subcategories list
                    StreamBuilder<QuerySnapshot>(
                      stream: doc.reference.collection('subcategories').snapshots(),
                      builder: (context, subSnap) {
                        if (!subSnap.hasData || subSnap.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("No subcategories"),
                          );
                        }

                        final subcategories = subSnap.data!.docs;

                        return Column(
                          children: subcategories.map((subDoc) {
                            final subData = subDoc.data() as Map<String, dynamic>;
                            final subName = subData['name'] ?? 'Unnamed Subcategory';
                            final subImageUrl = subData['imageUrl'] ?? '';

                            return ListTile(

                              leading: subImageUrl.isNotEmpty
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  subImageUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[300],
                                ),
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                              title: Text(subName),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductsPage(
                                      stallId: stallId,
                                      categoryId: doc.id,
                                      subcategoryId: subDoc.id,
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String stallId, String categoryId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('stalls')
                  .doc(stallId)
                  .collection('categories')
                  .doc(categoryId)
                  .delete();
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}
