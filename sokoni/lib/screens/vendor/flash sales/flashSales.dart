import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FlashSalesPage extends StatelessWidget {
  final String stallId;
  const FlashSalesPage({Key? key, required this.stallId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flash Sales')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stalls')
            .doc(stallId)
            .collection('flash_sales')
            .orderBy('startTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No flash sales available.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final saleDoc = docs[index];
              final data = saleDoc.data() as Map<String, dynamic>;
              final startTime = (data['startTime'] as Timestamp).toDate();
              final endTime = (data['endTime'] as Timestamp).toDate();
              final now = DateTime.now();
              final isActive = now.isAfter(startTime) && now.isBefore(endTime);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('stalls')
                    .doc(stallId)
                    .collection('products')
                    .doc(data['productId'])
                    .get(),
                builder: (context, prodSnap) {
                  String productName = 'Loading...';
                  String? productImage;
                  if (prodSnap.hasData && prodSnap.data!.exists) {
                    final prodData = prodSnap.data!.data() as Map<String, dynamic>;
                    productName = prodData['name'] ?? 'Unnamed';
                    productImage = prodData['image'] as String?;
                  }

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ListTile(
                      onTap: () {
                        // TODO: Navigate to FlashSaleDetailPage
                      },
                      leading: productImage != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          productImage,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      )
                          : const Icon(Icons.flash_on, size: 40),
                      title: Text(productName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Discount: ${data['discountPercent']}%'),
                          Text(
                            'From: ${DateFormat.yMMMd().add_jm().format(startTime)}',
                          ),
                          Text(
                            'To:   ${DateFormat.yMMMd().add_jm().format(endTime)}',
                          ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: isActive ? Colors.green.shade800 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
