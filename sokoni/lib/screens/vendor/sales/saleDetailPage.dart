import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class SaleDetailsPage extends StatelessWidget {
  final DocumentSnapshot sale;
  final String stallName;

  const SaleDetailsPage({super.key, required this.sale, required this.stallName});

  @override
  Widget build(BuildContext context) {
    final total = sale['total'];
    final paymentMethod = sale['paymentMethod'];
    final customerPhone = sale['customerPhone'];
    final timestamp = (sale['timestamp'] as Timestamp?)?.toDate();
    final dateStr = timestamp != null
        ? DateFormat('yyyy-MM-dd hh:mm a').format(timestamp)
        : 'N/A';
    final products = sale['products'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(title: const Text('Sale Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Stall: $stallName", style: const TextStyle(fontSize: 18)),
            Text("Payment Method: $paymentMethod"),
            if (customerPhone != null) Text("📱 Customer Phone: $customerPhone"),
            Text("Date: $dateStr"),
            const SizedBox(height: 12),
            const Text("Products:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...products.map((p) => ListTile(
              title: Text(p['name']),
              subtitle: Text("Quantity: ${p['quantity']} | Price: ${p['price']}"),
            )),
            const Divider(),
            Text("Total: Ksh ${total.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}