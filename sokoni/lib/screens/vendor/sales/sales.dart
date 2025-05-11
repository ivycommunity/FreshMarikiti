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
        .where('vendorId', isEqualTo: widget.vendorId)
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
          print(stalls);
          if (stalls.isEmpty) {
            return const Center(child: Text("No stalls found"));
          }

          // Stall IDs for filtering
          final stallIds = stalls.map((s) => s.id).toList();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collectionGroup('sales')
                //.orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, salesSnap) {
              if (!salesSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Filter only sales from stalls owned by this vendor
              final vendorSales = salesSnap.data!.docs.where((saleDoc) {
                final timestamp = saleDoc['timestamp'];
                print("SALE ID: ${saleDoc.id}, TIMESTAMP: $timestamp (${timestamp.runtimeType})");

                final parentPath = saleDoc.reference.parent.parent?.id;
                return parentPath != null && stallIds.contains(parentPath);
              }).toList();

              // Apply search and date filters
              final filteredSales = vendorSales.where((sale) {
                final timestamp = (sale['timestamp'] as Timestamp?)?.toDate();

                final productsList = (sale['products'] as List<dynamic>);
                final productNames = productsList
                    .map((p) => p['name'].toString().toLowerCase())
                    .join(' ');

                final stallId = sale.reference.parent.parent?.id ?? '';
                final matchingStalls = stalls.where((s) => s.id == stallId).toList();
                final stallName = matchingStalls.isNotEmpty
                    ? matchingStalls.first['name'].toString().toLowerCase()
                    : '';

                final matchesSearch = productNames.contains(searchQuery.toLowerCase()) ||
                    stallName.contains(searchQuery.toLowerCase());

                final inDateRange = (startDate == null || (timestamp != null && timestamp.isAfter(startDate!))) &&
                    (endDate == null || (timestamp != null && timestamp.isBefore(endDate!.add(const Duration(days: 1)))));

                return matchesSearch && inDateRange;
              }).toList();

              double totalRevenue = filteredSales.fold(
                0,
                    (sum, sale) => sum + (sale['total'] as num).toDouble(),
              );

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Revenue: Ksh ${totalRevenue.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
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

                        final matchingStalls = stalls.where((s) => s.id == stallId).toList();
                        final stallName = matchingStalls.isNotEmpty
                            ? matchingStalls.first['name']
                            : 'Unknown Stall';

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
                            title: Text(
                              "Ksh ${total.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text("🛍️ Stall: $stallName"),
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
                                builder: (_) => SaleDetailsPage(sale: sale, stallName: stallName),
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
