import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DiscountsPage extends StatelessWidget {
  final String stallId;

  const DiscountsPage({super.key, required this.stallId});

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat.yMMMd().format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Discounts')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stalls')
            .doc(stallId)
            .collection('products')
            .where('discountPercent', isGreaterThan: 0)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No active discounts found.'));
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final doc = products[index];
              final data = doc.data() as Map<String, dynamic>;

              final image = data['image'] as String?;
              final name = data['name'] ?? 'Unnamed';
              final price = data['price'] ?? 'N/A';
              final discount = data['discountPercent']?.toDouble() ?? 0.0;
              final start = data['discountStart'] as Timestamp?;
              final end = data['discountEnd'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: image != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      image,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                      : const Icon(Icons.image, size: 50),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Price: $price'),
                      Text('Discount: $discount%'),
                      Text('Start: ${_formatDate(start)}'),
                      Text('End: ${_formatDate(end)}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      // TODO: navigate to discount detail page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Discount details coming soon!')),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
