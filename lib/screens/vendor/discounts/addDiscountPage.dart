import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddDiscountsPage extends StatefulWidget {
  final String stallId;

  const AddDiscountsPage({super.key, required this.stallId});

  @override
  State<AddDiscountsPage> createState() => _AddDiscountsPageState();
}

class _AddDiscountsPageState extends State<AddDiscountsPage> {
  final _formKey = GlobalKey<FormState>();
  double? _discountPercent;
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _selectedProductIds = [];
  final Map<String, DocumentSnapshot> _selectedProductsMap = {};

  bool _loading = false;

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitDiscounts() async {
    if (!_formKey.currentState!.validate() || _selectedProductIds.isEmpty) return;

    if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (var productId in _selectedProductIds) {
        final ref = FirebaseFirestore.instance
            .collection('stalls')
            .doc(widget.stallId)
            .collection('products')
            .doc(productId);

        batch.update(ref, {
          'discountPercent': _discountPercent,
          'discountStart': _startDate != null ? Timestamp.fromDate(_startDate!) : null,
          'discountEnd': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discounts applied successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to apply discounts')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime? date) {
    return date == null ? 'Not set' : DateFormat.yMMMd().format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Discounts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Discount %
              TextFormField(
                decoration: const InputDecoration(labelText: 'Discount (%)'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  final d = double.tryParse(val ?? '');
                  if (d == null || d <= 0 || d >= 100) {
                    return 'Enter a valid discount between 1–99';
                  }
                  return null;
                },
                onChanged: (val) => _discountPercent = double.tryParse(val),
              ),

              const SizedBox(height: 16),

              // Start & End Dates
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Date'),
                      subtitle: Text(_formatDate(_startDate)),
                      onTap: () => _pickDate(true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('End Date'),
                      subtitle: Text(_formatDate(_endDate)),
                      onTap: () => _pickDate(false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Product selection
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('stalls')
                      .doc(widget.stallId)
                      .collection('products')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();

                    final products = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final doc = products[index];
                        final isSelected = _selectedProductIds.contains(doc.id);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedProductIds.add(doc.id);
                                _selectedProductsMap[doc.id] = doc;
                              } else {
                                _selectedProductIds.remove(doc.id);
                                _selectedProductsMap.remove(doc.id);
                              }
                            });
                          },
                          title: Text(doc['name']),
                          subtitle: Text("Price: ${doc['price']}"),
                          secondary: doc['image'] != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              doc['image'],
                              height: 50,
                              width: 50,
                              fit: BoxFit.cover,
                            ),
                          )
                              : const Icon(Icons.image),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Preview selected products
              if (_selectedProductIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Preview:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ..._selectedProductIds.map((id) {
                        final product = _selectedProductsMap[id];
                        return ListTile(
                          title: Text(product?['name'] ?? ''),
                          subtitle: Text(
                              'Price: ${product?['price']} | Discount: $_discountPercent%'),
                          leading: product?['image'] != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product!['image'],
                              height: 40,
                              width: 40,
                              fit: BoxFit.cover,
                            ),
                          )
                              : const Icon(Icons.image),
                        );
                      }).toList(),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // Submit
              ElevatedButton.icon(
                onPressed: _submitDiscounts,
                icon: const Icon(Icons.save),
                label: const Text('Apply Discounts'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
