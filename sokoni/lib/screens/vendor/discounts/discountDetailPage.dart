import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'editDiscountPage.dart';

class DiscountDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const DiscountDetailPage({super.key, required this.product});

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat.yMMMMd().format(date);
  }

  double _calculateDiscountedPrice(double price, double percent) {
    return price - (price * percent / 100);
  }

  @override
  Widget build(BuildContext context) {
    final image = product['image'] as String?;
    final name = product['name'] ?? 'Unnamed Product';
    final price = (product['price'] ?? 0).toDouble();
    final discountPercent = (product['discountPercent'] ?? 0).toDouble();
    final discountedPrice = _calculateDiscountedPrice(price, discountPercent);
    final start = product['discountStart'];
    final end = product['discountEnd'];

    return Scaffold(
      appBar: AppBar(title: const Text('Discount Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  image,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported, size: 60),
              ),
            const SizedBox(height: 16),
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text("Original Price: Ksh $price"),
            Text("Discount: $discountPercent%"),
            const SizedBox(height: 8),
            Text(
              "Discounted Price: Ksh ${discountedPrice.toStringAsFixed(2)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text("Start Date"),
              subtitle: Text(_formatDate(start)),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text("End Date"),
              subtitle: Text(_formatDate(end)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text("Edit Discount"),
              onPressed: () {
                // TODO: Navigate to edit discount page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditDiscountPage(product: product),
                  ),);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit Discount coming soon!')),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
