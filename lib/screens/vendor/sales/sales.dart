import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sokoni/screens/vendor/sales/saleDetailPage.dart';

class SalesPage extends StatefulWidget {
  final String vendorId;
  const SalesPage({super.key, required this.vendorId});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  DateTime? startDate;
  DateTime? endDate;
  String searchQuery = '';

  Future<List<QueryDocumentSnapshot>> _fetchVendorStalls() async {
    final query = await FirebaseFirestore.instance
        .collection('stalls')
        .where('vendor', isEqualTo: widget.vendorId)
        .get();
    return query.docs;
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
          )
        ],
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: _fetchVendorStalls(),
        builder: (context, stallSnap) {
          if (!stallSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final stalls = stallSnap.data!;
          if (stalls.isEmpty) return const Center(child: Text("No stalls found"));

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collectionGroup('sales')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, salesSnap) {
              if (!salesSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final allSales = salesSnap.data!.docs
                  .where((doc) => stalls.any((stall) => doc.reference.path.contains(stall.id)))
                  .toList();

              final filteredSales = allSales.where((sale) {
                final timestamp = (sale['timestamp'] as Timestamp?)?.toDate();
                final productNames = (sale['products'] as List<dynamic>)
                    .map((p) => p['name'].toString().toLowerCase())
                    .join(' ');
                final stallId = sale.reference.parent.parent?.id ?? '';
                final stallName = stalls.firstWhere((s) => s.id == stallId)['name'].toString().toLowerCase();

                final matchesSearch = productNames.contains(searchQuery.toLowerCase()) ||
                    stallName.contains(searchQuery.toLowerCase());

                final inDateRange = (startDate == null || timestamp!.isAfter(startDate!)) &&
                    (endDate == null || timestamp!.isBefore(endDate!.add(const Duration(days: 1))));

                return matchesSearch && inDateRange;
              }).toList();

              double totalRevenue = filteredSales.fold(0, (sum, sale) => sum + (sale['total'] as num).toDouble());

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total Revenue: Ksh ${totalRevenue.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        TextField(
                          decoration: const InputDecoration(
                            hintText: "Search by product or stall",
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => setState(() => searchQuery = value),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filteredSales.length,
                      itemBuilder: (context, index) {
                        final sale = filteredSales[index];
                        final stallId = sale.reference.parent.parent?.id ?? '';
                        final stall = stalls.firstWhere((s) => s.id == stallId);
                        final total = sale['total'];
                        final paymentMethod = sale['paymentMethod'];
                        final customerPhone = sale['customerPhone'];
                        final timestamp = (sale['timestamp'] as Timestamp?)?.toDate();
                        final dateStr = timestamp != null
                            ? DateFormat('yyyy-MM-dd hh:mm a').format(timestamp)
                            : 'N/A';

                        final products = sale['products'] as List<dynamic>;

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 3,
                          child: ListTile(
                            title: Text("Ksh ${total.toStringAsFixed(2)}",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text("🛍️ Stall: ${stall['name']}"),
                                Text("💳 Payment: $paymentMethod"),
                                if (customerPhone != null) Text("📱 Phone: $customerPhone"),
                                Text("🕒 Date: $dateStr"),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  children: products
                                      .map((p) => Chip(
                                    label: Text("${p['name']} x${p['quantity']}"),
                                  ))
                                      .toList(),
                                )
                              ],
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SaleDetailsPage(sale: sale, stallName: stall['name']),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              );
            },
          );
        },
      ),
    );
  }
}


