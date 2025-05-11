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
  Map<String, Map<String, dynamic>> _selectedProductsMap = {};
  // final Map<String, DocumentSnapshot> _selectedProductsMap = {};

  bool _loading = false;
  bool _useDiscount = true;  // true = discount %, false = new price
  double? _newPrice;
  bool _submitting = false;

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
        final selected = _selectedProductsMap[productId];
        if (selected == null) continue;

        final categoryId = selected['categoryId'];
        final subcategoryId = selected['subcategoryId'];

        late DocumentReference ref;

        if (subcategoryId != null) {
          // 🟢 Under subcategory
          ref = FirebaseFirestore.instance
              .collection('stalls')
              .doc(widget.stallId)
              .collection('categories')
              .doc(categoryId)
              .collection('subcategories')
              .doc(subcategoryId)
              .collection('products')
              .doc(productId);
        } else {
          // 🟡 Directly under category
          ref = FirebaseFirestore.instance
              .collection('stalls')
              .doc(widget.stallId)
              .collection('categories')
              .doc(categoryId)
              .collection('products')
              .doc(productId);
        }

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
              // Toggle switch
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Discount %'),
                      value: true,
                      groupValue: _useDiscount,
                      onChanged: (val) => setState(() => _useDiscount = val!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('New Price'),
                      value: false,
                      groupValue: _useDiscount,
                      onChanged: (val) => setState(() => _useDiscount = val!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

          // Discount % field
              if (_useDiscount)
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
                  onChanged: (val) {
                    setState(() {
                      _discountPercent = double.tryParse(val);
                      _newPrice = null;  // Reset new price
                    });
                  },
                ),

          // New Price field
              if (!_useDiscount)
                TextFormField(
                  decoration: const InputDecoration(labelText: 'New Price'),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    final p = double.tryParse(val ?? '');
                    if (p == null || p <= 0) {
                      return 'Enter a valid price';
                    }
                    return null;
                  },
                  onChanged: (val) {
                    setState(() {
                      _newPrice = double.tryParse(val);
                      _discountPercent = null;  // Reset discount
                    });
                  },
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
                      .collection('categories')
                      .snapshots(),
                  builder: (context, catSnap) {
                    if (!catSnap.hasData) {
                      print("No categories found");
                      return const Center(child: CircularProgressIndicator());
                    }

                    final categories = catSnap.data!.docs;

                    return ListView(
                      children: categories.map((catDoc) {
                        final catName = catDoc['name'];
                        final categoryId = catDoc.id;

                        return FutureBuilder<QuerySnapshot>(
                          future: catDoc.reference.collection('products').get(),
                          builder: (context, prodSnap) {
                            final catProducts = prodSnap.data?.docs ?? [];

                            return StreamBuilder<QuerySnapshot>(
                              stream: catDoc.reference.collection('subcategories').snapshots(),
                              builder: (context, subSnap) {
                                if (!subSnap.hasData) {
                                  print("No subcategories found");
                                  return const SizedBox();
                                }

                                final subcategories = subSnap.data!.docs;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    // 🔥 Category-level products
                                    if (catProducts.isNotEmpty)
                                      ExpansionTile(
                                        title: Text('$catName'),
                                        children: catProducts.map((prodDoc) {
                                          final isSelected = _selectedProductIds.contains(prodDoc.id);
                                          return CheckboxListTile(
                                            value: isSelected,
                                            onChanged: (val) {
                                              setState(() {
                                                if (val == true) {
                                                  _selectedProductIds.add(prodDoc.id);
                                                  _selectedProductsMap[prodDoc.id] = {
                                                    'productId': prodDoc.id,
                                                    'categoryId': categoryId,
                                                    'subcategoryId': null, // 🟡 Direct category product
                                                    'data': prodDoc.data(),
                                                  };
                                                } else {
                                                  _selectedProductIds.remove(prodDoc.id);
                                                  _selectedProductsMap.remove(prodDoc.id);
                                                }
                                              });
                                            },
                                            title: Text(prodDoc['name']),
                                            subtitle: Text("Price: ${prodDoc['price']}"),
                                            secondary: prodDoc['imageUrl'] != null
                                                ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                prodDoc['imageUrl'],
                                                height: 50,
                                                width: 50,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                                : const Icon(Icons.image),
                                          );
                                        }).toList(),
                                      ),

                                    // 🔥 Subcategory products
                                    ...subcategories.map((subDoc) {
                                      final subName = subDoc['name'];
                                      final subcategoryId = subDoc.id;

                                      return StreamBuilder<QuerySnapshot>(
                                        stream: subDoc.reference.collection('products').snapshots(),
                                        builder: (context, subProdSnap) {
                                          if (!subProdSnap.hasData) return const SizedBox();

                                          final products = subProdSnap.data!.docs;

                                          return ExpansionTile(
                                            title: Text('$catName > $subName'),
                                            children: products.map((prodDoc) {
                                              final isSelected = _selectedProductIds.contains(prodDoc.id);
                                              return CheckboxListTile(
                                                value: isSelected,
                                                onChanged: (val) {
                                                  setState(() {
                                                    if (val == true) {
                                                      _selectedProductIds.add(prodDoc.id);
                                                      _selectedProductsMap[prodDoc.id] = {
                                                        'productId': prodDoc.id,
                                                        'categoryId': categoryId,
                                                        'subcategoryId': subcategoryId, // 🟢 Subcategory product
                                                        'data': prodDoc.data(),
                                                      };
                                                    } else {
                                                      _selectedProductIds.remove(prodDoc.id);
                                                      _selectedProductsMap.remove(prodDoc.id);
                                                    }
                                                  });
                                                },
                                                title: Text(prodDoc['name']),
                                                subtitle: Text("Price: ${prodDoc['price']}"),
                                                secondary: prodDoc['imageUrl'] != null
                                                    ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    prodDoc['imageUrl'],
                                                    height: 50,
                                                    width: 50,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                                    : const Icon(Icons.image),
                                              );
                                            }).toList(),
                                          );
                                        },
                                      );
                                    }).toList(),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      }).toList(),
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
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      ..._selectedProductIds.map((id) {
                        final product = _selectedProductsMap[id];
                        final price = double.tryParse(product?['data']?['price'].toString() ?? '0') ?? 0;
                        final discount = _discountPercent ?? 0;
                        final newPrice = price - (price * discount / 100);

                        return ListTile(
                          title: Text(
                            product?['data']?['name'] ?? '',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          subtitle: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Old: ',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: 'Ksh${price.toStringAsFixed(2)}  ',
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.red,
                                  ),
                                ),
                                TextSpan(
                                  text: 'New: ',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: 'Ksh${newPrice.toStringAsFixed(2)}  ',
                                  style: const TextStyle(color: Colors.green),
                                ),
                                TextSpan(
                                  text: '($_discountPercent% off)',
                                  style: const TextStyle(color: Colors.orange),
                                ),
                              ],
                            ),
                          ),
                          leading: product?['data']?['imageUrl'] != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product!['data']['imageUrl'],
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
                onPressed: (_selectedProductIds.isNotEmpty && !_submitting) ? _submitDiscounts : null,
                icon: _submitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.save),
                label: Text(_submitting ? 'Applying...' : 'Apply Discounts'),
              ),


            ],
          ),
        ),
      ),
    );
  }
}
