import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'editFlashSale.dart';

// import 'add_flashSale.dart';

class FlashSaleDetailPage extends StatefulWidget {
  final String stallId;
  final String flashSaleId;

  const FlashSaleDetailPage({
    super.key,
    required this.stallId,
    required this.flashSaleId,
  });

  @override
  State<FlashSaleDetailPage> createState() => _FlashSaleDetailPageState();
}

class _FlashSaleDetailPageState extends State<FlashSaleDetailPage> {
  DocumentSnapshot? flashSaleDoc;
  DocumentSnapshot? productDoc;
  Timer? countdownTimer;
  Duration? remainingTime;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchFlashSaleDetails();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchFlashSaleDetails() async {
    final flashSnap = await FirebaseFirestore.instance
        .collection('stalls')
        .doc(widget.stallId)
        .collection('flash_sales')
        .doc(widget.flashSaleId)
        .get();

    final productId = flashSnap['productId'];
    final productSnap = await FirebaseFirestore.instance
        .collection('stalls')
        .doc(widget.stallId)
        .collection('products')
        .doc(productId)
        .get();

    setState(() {
      flashSaleDoc = flashSnap;
      productDoc = productSnap;
      loading = false;
    });

    startCountdown();
  }

  void startCountdown() {
    if (flashSaleDoc == null || !flashSaleDoc!['active']) return;

    final end = flashSaleDoc!['endTime'].toDate();
    countdownTimer?.cancel();

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final diff = end.difference(now);

      if (diff.isNegative) {
        countdownTimer?.cancel();
        setState(() {
          remainingTime = Duration.zero;
        });
      } else {
        setState(() {
          remainingTime = diff;
        });
      }
    });
  }

  String formatDate(Timestamp timestamp) {
    return DateFormat.yMMMd().add_jm().format(timestamp.toDate());
  }

  double get discountedPrice {
    final price = productDoc!['price'];
    final discount = flashSaleDoc!['discountPercent'];
    return price - (price * discount / 100);
  }

  String formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    final s = duration.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}h : ${m.toString().padLeft(2, '0')}m : ${s.toString().padLeft(2, '0')}s';
  }

  Future<void> toggleActiveStatus() async {
    final current = flashSaleDoc!['active'];
    await flashSaleDoc!.reference.update({
      'active': !current,
      'updatedAt': Timestamp.now(),
    });
    await fetchFlashSaleDetails();
  }

  Future<void> deleteFlashSale() async {
    await flashSaleDoc!.reference.delete();
    if (mounted) Navigator.pop(context);
  }

  void navigateToEditPage() {
    if (flashSaleDoc != null && flashSaleDoc!.data() != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditFlashSalePage(
            stallId: widget.stallId,
            flashSaleId: widget.flashSaleId,
            existingData: flashSaleDoc!.data() as Map<String, dynamic>,
          ),
        ),
      ).then((_) => fetchFlashSaleDetails());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load flash sale data')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Flash Sale Details"),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: navigateToEditPage),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Delete Flash Sale"),
                  content: const Text("Are you sure you want to delete this sale?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
                  ],
                ),
              );
              if (confirmed == true) await deleteFlashSale();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product
                Row(
                  children: [
                    if (productDoc?['image'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          productDoc!['image'],
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        productDoc!['name'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Pricing Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Original: \$${productDoc!['price']}", style: const TextStyle(decoration: TextDecoration.lineThrough)),
                    Text("Discount: ${flashSaleDoc!['discountPercent']}%"),
                    Text("Now: \$${discountedPrice.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),

                // Timer
                if (flashSaleDoc!['active'] && remainingTime != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        "Ends in: ${formatDuration(remainingTime!)}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("Starts", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(formatDate(flashSaleDoc!['startTime'])),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("Ends", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(formatDate(flashSaleDoc!['endTime'])),
                    ]),
                  ],
                ),
                const Divider(height: 32),

                // Status + Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      flashSaleDoc!['active'] ? "Status: Active ✅" : "Status: Inactive ❌",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: flashSaleDoc!['active'] ? Colors.green : Colors.red,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: toggleActiveStatus,
                      icon: const Icon(Icons.toggle_on),
                      label: Text(flashSaleDoc!['active'] ? "Deactivate" : "Activate"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: flashSaleDoc!['active'] ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // 📊 Analytics
                Text("Analytics", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Items Sold:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(flashSaleDoc!['itemsSold']?.toString() ?? "0"),
                  ],
                ),
                const SizedBox(height: 16),

                // 📄 Activity Log
                Text("Activity Log", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text("Created by: ${flashSaleDoc!['createdBy'] ?? 'Unknown'}"),
                Text("Created: ${formatDate(flashSaleDoc!['createdAt'])}"),
                Text("Last updated: ${formatDate(flashSaleDoc!['updatedAt'])}"),
                // Status Toggle
                Row(
                  children: [
                    const Text("Status: "),
                    Chip(
                      label: Text(
                        flashSaleDoc!['active'] ? "Active" : "Inactive",
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: flashSaleDoc!['active'] ? Colors.green : Colors.grey,
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: toggleActiveStatus,
                      icon: Icon(flashSaleDoc!['active'] ? Icons.pause : Icons.play_arrow),
                      label: Text(flashSaleDoc!['active'] ? "Deactivate" : "Activate"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: flashSaleDoc!['active'] ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Activity Log
                const Text("Activity Log", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Created by: ${flashSaleDoc!['createdBy']}"),
                    Text("On: ${formatDate(flashSaleDoc!['createdAt'])}"),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Last updated:"),
                    Text(formatDate(flashSaleDoc!['updatedAt'])),
                  ],
                ),

                const Divider(height: 32),

                // Analytics (Optional)
                const Text("Analytics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Items sold during flash sale:"),
                    Text("${flashSaleDoc!['itemsSold'] ?? 0}"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


