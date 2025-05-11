import 'dart:async';

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
  final String? subcategoryId;

  const ProductDetailPage({
    Key? key,
    required this.stallId,
    required this.categoryId,
    required this.productId,
    this.subcategoryId,
  }) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  DocumentSnapshot? productDoc;
  DocumentSnapshot? flashSaleDoc;
  bool loading = true;
  Timer? countdownTimer;
  Duration? timeLeft;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> _productCollection() {
    if (widget.subcategoryId != null) {
      return FirebaseFirestore.instance
          .collection('stalls')
          .doc(widget.stallId)
          .collection('categories')
          .doc(widget.categoryId)
          .collection('subcategories')
          .doc(widget.subcategoryId)
          .collection('products');
    } else {
      return FirebaseFirestore.instance
          .collection('stalls')
          .doc(widget.stallId)
          .collection('categories')
          .doc(widget.categoryId)
          .collection('products');
    }
  }

  Future<void> _loadData() async {
    final product = await _productCollection().doc(widget.productId).get();

    // Check active flash sale
    final flashSalesSnap = await FirebaseFirestore.instance
        .collection('stalls')
        .doc(widget.stallId)
        .collection('flash_sales')
        .where('productId', isEqualTo: widget.productId)
        .where('active', isEqualTo: true)
        .get();

    final now = Timestamp.now().toDate();
    flashSaleDoc = flashSalesSnap.docs.where((doc) {
      final start = (doc['startTime'] as Timestamp).toDate();
      final end = (doc['endTime'] as Timestamp).toDate();
      return now.isAfter(start) && now.isBefore(end);
    }).firstOrNull;

    setState(() {
      productDoc = product;
      loading = false;
    });

    _startCountdown();
  }

  void _startCountdown() {
    countdownTimer?.cancel();
    final now = DateTime.now();
    DateTime? endTime;

    if (flashSaleDoc != null) {
      endTime = (flashSaleDoc!['endTime'] as Timestamp).toDate();
    } else {
      final data = productDoc?.data() as Map<String, dynamic>?;
      final discountEnd = data?['discountEnd'] as Timestamp?;
      if (discountEnd != null) {
        endTime = discountEnd.toDate();
      }
    }

    if (endTime != null && now.isBefore(endTime)) {
      timeLeft = endTime.difference(now);
      countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final newLeft = endTime!.difference(DateTime.now());
        if (newLeft.isNegative) {
          countdownTimer?.cancel();
          _loadData();
        } else {
          setState(() => timeLeft = newLeft);
        }
      });
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'N/A';
    return DateFormat.yMMMd().add_jm().format(ts.toDate());
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _stopFlashSale() async {
    if (flashSaleDoc != null) {
      await flashSaleDoc!.reference.update({'active': false});
      await _loadData();
    }
  }

  Future<void> _stopDiscount() async {
    await _productCollection().doc(widget.productId).update({
      'discountPercent': null,
      'discountStart': null,
      'discountEnd': null,
    });
    await _loadData();
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

    final discountPercent = (data['discountPercent'] ?? 0).toDouble();
    final discountStart = (data['discountStart'] as Timestamp?)?.toDate();
    final discountEnd = (data['discountEnd'] as Timestamp?)?.toDate();

    final now = DateTime.now();
    final hasDiscount = discountPercent > 0 && discountStart != null && discountEnd != null && now.isAfter(discountStart) && now.isBefore(discountEnd);

    final hasFlashSale = flashSaleDoc != null;
    final double? flashDiscountPercent = hasFlashSale ? (flashSaleDoc!['discountPercent'] as num).toDouble() : null;
    final DateTime? flashStart = hasFlashSale ? (flashSaleDoc!['startTime'] as Timestamp).toDate() : null;
    final DateTime? flashEnd = hasFlashSale ? (flashSaleDoc!['endTime'] as Timestamp).toDate() : null;

    double finalPrice = price;
    if (hasFlashSale) {
      finalPrice = price * (1 - (flashDiscountPercent! / 100));
    } else if (hasDiscount) {
      finalPrice = price * (1 - (discountPercent / 100));
    }

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
                if (hasDiscount || hasFlashSale)
                  Text(
                    'Ksh $price',
                    style: const TextStyle(
                      fontSize: 16,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  'Ksh ${finalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
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
            const Divider(height: 32),

            if (hasFlashSale) ...[
              Text('🔥 Flash Sale (${flashDiscountPercent!.toStringAsFixed(0)}% off)', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              Text('From: ${DateFormat.yMMMd().add_jm().format(flashStart!)}'),
              Text('To: ${DateFormat.yMMMd().add_jm().format(flashEnd!)}'),
              if (timeLeft != null) Text('Ends in: ${_formatDuration(timeLeft!)}', style: const TextStyle(color: Colors.red)),
              TextButton(
                onPressed: _stopFlashSale,
                child: const Text('Stop Flash Sale', style: TextStyle(color: Colors.red)),
              ),
              const Divider(height: 32),
            ],

            if (hasDiscount) ...[
              Text('💸 Discount (${discountPercent.toStringAsFixed(0)}% off)', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              Text('From: ${DateFormat.yMMMd().add_jm().format(discountStart!)}'),
              Text('To: ${DateFormat.yMMMd().add_jm().format(discountEnd!)}'),
              if (timeLeft != null) Text('Ends in: ${_formatDuration(timeLeft!)}', style: const TextStyle(color: Colors.orange)),
              TextButton(
                onPressed: _stopDiscount,
                child: const Text('Stop Discount', style: TextStyle(color: Colors.red)),
              ),
              const Divider(height: 32),
            ],

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
                          subcategoryId: widget.subcategoryId,
                          productId: widget.productId,
                        ),
                      ),
                    ).then((_) => _loadData());
                  },
                ),
                if (!hasDiscount)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.local_offer),
                    label: const Text('Discount'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddDiscountsPage(stallId: widget.stallId),
                        ),
                      ).then((_) => _loadData());
                    },
                  ),
                if (!hasFlashSale)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.flash_on),
                    label: const Text('Flash Sale'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddFlashSalePage(stallId: widget.stallId),
                        ),
                      ).then((_) => _loadData());
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
                      await _productCollection().doc(widget.productId).delete();
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
