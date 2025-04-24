import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../discounts/addDiscountPage.dart';
import '../../flash sales/add_flashSale.dart';
import 'edit_product.dart';

class ProductDetailPage extends StatefulWidget {
  final String stallId;
  final String categoryId;
  final String productId;

  const ProductDetailPage({
    Key? key,
    required this.stallId,
    required this.categoryId,
    required this.productId,
  }) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  DocumentSnapshot? productDoc;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final doc = await FirebaseFirestore.instance
        .collection('stalls')
        .doc(widget.stallId)
        .collection('categories')
        .doc(widget.categoryId)
        .collection('products')
        .doc(widget.productId)
        .get();
    setState(() {
      productDoc = doc;
      loading = false;
    });
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'N/A';
    return DateFormat.yMMMd().add_jm().format(ts.toDate());
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = productDoc?.data() as Map<String, dynamic>?;
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: Text('Product not found')),
      );
    }

    final name = data['name'] ?? 'Unnamed';
    final price = (data['price'] ?? 0).toDouble();
    final quantity = (data['quantity'] ?? 0).toInt();
    final desc = data['description'] ?? '';
    final imageUrl = data['imageUrl'] as String?;
    final createdAt = data['createdAt'] as Timestamp?;
    final updatedAt = data['updatedAt'] as Timestamp?;
    final discount = (data['discountPercent'] ?? 0).toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            Text(name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Price: Ksh $price', style: const TextStyle(fontSize: 16)),
                if (discount > 0) ...[
                  const SizedBox(width: 16),
                  Text('Discount: $discount%', style: TextStyle(color: Colors.red[700])),
                ]
              ],
            ),
            const SizedBox(height: 8),
            Text('Quantity: $quantity', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('Description', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(desc),
            const Divider(height: 32),
            Text('Created: ${_formatDate(createdAt)}'),
            Text('Updated: ${_formatDate(updatedAt)}'),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProductPage(
                          stallId: widget.stallId,
                          categoryId: widget.categoryId,
                          productId: widget.productId,
                        ),
                      ),
                    ).then((_) => _loadProduct());
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.local_offer),
                  label: const Text('Discount'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddDiscountsPage(stallId: widget.stallId),
                      ),
                    ).then((_) => _loadProduct());
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Flash Sale'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddFlashSalePage(stallId: widget.stallId),
                      ),
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Product'),
                        content: const Text('Are you sure you want to delete this product?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await FirebaseFirestore.instance
                          .collection('stalls')
                          .doc(widget.stallId)
                          .collection('categories')
                          .doc(widget.categoryId)
                          .collection('products')
                          .doc(widget.productId)
                          .delete();
                      if (mounted) Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
