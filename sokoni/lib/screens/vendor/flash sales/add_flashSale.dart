import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddFlashSalePage extends StatefulWidget {
  final String stallId;

  const AddFlashSalePage({super.key, required this.stallId});

  @override
  State<AddFlashSalePage> createState() => _AddFlashSalePageState();
}

class _AddFlashSalePageState extends State<AddFlashSalePage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProductId;
  DocumentSnapshot? _selectedProductDoc;
  double? _discountPercent;
  DateTime? _startTime;
  DateTime? _endTime;
  bool _loading = false;
  List<QueryDocumentSnapshot> _selectedProducts = [];
  double? _newPrice;

  Widget _buildDiscountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Discount Options', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // Discount Percentage Input
        TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Discount (%)'),
          validator: (val) {
            if ((val == null || val.isEmpty) && (_newPrice == null)) {
              return 'Enter discount or new price';
            }
            if (val != null && val.isNotEmpty) {
              final discount = double.tryParse(val);
              if (discount == null || discount <= 0 || discount >= 100) {
                return 'Enter a valid discount (1–99%)';
              }
            }
            return null;
          },
          onChanged: (val) {
            _discountPercent = double.tryParse(val);
            _newPrice = null; // Clear new price if discount is set
            setState(() {});
          },
        ),
        const SizedBox(height: 12),
        // New Price Input
        TextFormField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'New Price'),
          validator: (val) {
            if ((val == null || val.isEmpty) && (_discountPercent == null)) {
              return 'Enter new price or discount';
            }
            if (val != null && val.isNotEmpty) {
              final price = double.tryParse(val);
              if (price == null || price <= 0) {
                return 'Enter a valid price';
              }
            }
            return null;
          },
          onChanged: (val) {
            _newPrice = double.tryParse(val);
            _discountPercent = null; // Clear discount if price is set
            setState(() {});
          },
        ),
      ],
    );
  }

  Future<void> _pickDateTime(bool isStart) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (pickedTime == null) return;

    final selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        _startTime = selectedDateTime;
      } else {
        _endTime = selectedDateTime;
      }
    });
  }

  Future<bool> _checkForClashingSales(String productId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('stalls')
        .doc(widget.stallId)
        .collection('flash_sales')
        .where('productId', isEqualTo: productId)
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(_endTime!))
        .where('endTime', isGreaterThanOrEqualTo: Timestamp.fromDate(_startTime!))
        .get();

    for (var doc in snapshot.docs) {
      final start = (doc['startTime'] as Timestamp).toDate();
      final end = (doc['endTime'] as Timestamp).toDate();

      final bool overlaps = _startTime!.isBefore(end) && _endTime!.isAfter(start);
      if (overlaps) return true;
    }
    return false;
  }


  Future<void> _submitFlashSale() async {
    if (!_formKey.currentState!.validate() ||
        _selectedProducts.isEmpty ||
        _startTime == null ||
        _endTime == null) return;

    if (_endTime!.isBefore(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    if (_discountPercent == null && _newPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter discount or new price')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      for (var product in _selectedProducts) {
        final productId = product.id;
        final productPrice = (product['price'] ?? 0).toDouble();

        // If user entered new price → calculate discount
        double discountPercent = _discountPercent ??
            (100 - ((_newPrice! / productPrice) * 100)).clamp(1, 99);

        // Check for clash
        final clash = await _checkForClashingSales(productId);
        if (clash) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product "${product['name']}" already has a flash sale during that time.'),
            ),
          );
          continue; // Skip this product and continue with others
        }

        await FirebaseFirestore.instance
            .collection('stalls')
            .doc(widget.stallId)
            .collection('flash_sales')
            .add({
          'productId': productId,
          'discountPercent': discountPercent,
          'startTime': Timestamp.fromDate(_startTime!),
          'endTime': Timestamp.fromDate(_endTime!),
          'createdAt': Timestamp.now(),
          'active': true,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flash Sale(s) created!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create flash sale')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }


  String formatDate(DateTime? date) {
    return date == null ? 'Not selected' : DateFormat.yMMMd().add_jm().format(date);
  }

  Future<void> _showProductPickerSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return ProductPickerSheet(
              stallId: widget.stallId,
              initialSelected: _selectedProducts.map((doc) => doc.id).toSet(),
              onSelected: (selectedProducts) {
                setState(() {
                  _selectedProducts = selectedProducts;
                });
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Flash Sale')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Products
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: _selectedProducts.isEmpty
                      ? ''
                      : '${_selectedProducts.length} product(s) selected',
                ),
                decoration: const InputDecoration(
                  labelText: 'Select Products',
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                onTap: () {
                  _showProductPickerSheet(context);
                },
                validator: (val) => _selectedProducts.isEmpty ? 'Select at least one product' : null,
              ),

              const SizedBox(height: 16),

              // Discount
              _buildDiscountSection(),

              const SizedBox(height: 16),

              // Start Time
              ListTile(
                title: const Text('Start Time'),
                subtitle: Text(formatDate(_startTime)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDateTime(true),
              ),

              // End Time
              ListTile(
                title: const Text('End Time'),
                subtitle: Text(formatDate(_endTime)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDateTime(false),
              ),

              const SizedBox(height: 24),

              // Preview Card
              if (_selectedProducts.isNotEmpty &&
                  _discountPercent != null &&
                  _startTime != null &&
                  _endTime != null)
                Card(
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🔍 Preview',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._selectedProducts.map((product) {
                          final price = (product['price'] as num).toDouble();
                          final discount = (_discountPercent! / 100);
                          final newPrice = price - (price * discount);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                if (product['imageUrl'] != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      product['imageUrl'],
                                      height: 60,
                                      width: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Old Price: ${price.toStringAsFixed(2)}",
                                        style: TextStyle(
                                          color: Theme.of(context).textTheme.bodyMedium?.color,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                      Text(
                                        "New Price: ${newPrice.toStringAsFixed(2)}",
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        Text(
                          "Discount: $_discountPercent%",
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        Text(
                          "From: ${formatDate(_startTime)}",
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        Text(
                          "To: ${formatDate(_endTime)}",
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.flash_on),
                label: _loading
                    ? const CircularProgressIndicator.adaptive()
                    : const Text('Create Flash Sale'),
                onPressed: _loading ? null : _submitFlashSale,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductPickerSheet extends StatefulWidget {
  final String stallId;
  final Set<String> initialSelected;
  final Function(List<QueryDocumentSnapshot>) onSelected;

  const ProductPickerSheet({
    super.key,
    required this.stallId,
    required this.initialSelected,
    required this.onSelected,
  });

  @override
  State<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<ProductPickerSheet> {
  List<QueryDocumentSnapshot> _allProducts = [];
  List<QueryDocumentSnapshot> _filteredProducts = [];
  Set<String> _selectedProductIds = {};
  bool _loading = true;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _selectedProductIds = Set.from(widget.initialSelected);
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    List<QueryDocumentSnapshot> products = [];

    final categoriesSnapshot = await FirebaseFirestore.instance
        .collection('stalls')
        .doc(widget.stallId)
        .collection('categories')
        .get();

    for (var categoryDoc in categoriesSnapshot.docs) {
      final categoryId = categoryDoc.id;

      // Products directly in category
      final categoryProductsSnapshot = await FirebaseFirestore.instance
          .collection('stalls')
          .doc(widget.stallId)
          .collection('categories')
          .doc(categoryId)
          .collection('products')
          .get();

      products.addAll(categoryProductsSnapshot.docs);

      // Subcategories
      final subcategoriesSnapshot = await FirebaseFirestore.instance
          .collection('stalls')
          .doc(widget.stallId)
          .collection('categories')
          .doc(categoryId)
          .collection('subcategories')
          .get();

      for (var subcategoryDoc in subcategoriesSnapshot.docs) {
        final subcategoryId = subcategoryDoc.id;

        final subProductsSnapshot = await FirebaseFirestore.instance
            .collection('stalls')
            .doc(widget.stallId)
            .collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .doc(subcategoryId)
            .collection('products')
            .get();

        products.addAll(subProductsSnapshot.docs);
      }
    }

    setState(() {
      _allProducts = products;
      _filteredProducts = products;
      _loading = false;
    });
  }

  void _searchProducts(String query) {
    setState(() {
      _searchText = query;
      _filteredProducts = _allProducts.where((doc) {
        final name = (doc['name'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchProducts,
            ),
            const SizedBox(height: 16),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
              child: _filteredProducts.isEmpty
                  ? const Center(child: Text('No products found.'))
                  : ListView.builder(
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  final isSelected = _selectedProductIds.contains(product.id);
                  return ListTile(
                    leading: product['imageUrl'] != null
                        ? CircleAvatar(
                      backgroundImage: NetworkImage(product['imageUrl']),
                    )
                        : const CircleAvatar(
                      child: Icon(Icons.image_not_supported),
                    ),
                    title: Text(product['name'] ?? 'Unnamed'),
                    subtitle: Text(
                        'Price: ${product['price'] ?? 'N/A'} | Qty: ${product['quantity'] ?? 0}'),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedProductIds.add(product.id);
                          } else {
                            _selectedProductIds.remove(product.id);
                          }
                        });
                      },
                    ),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedProductIds.remove(product.id);
                        } else {
                          _selectedProductIds.add(product.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Confirm Selection'),
              onPressed: () {
                final selectedProducts = _allProducts
                    .where((p) => _selectedProductIds.contains(p.id))
                    .toList();
                widget.onSelected(selectedProducts);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

