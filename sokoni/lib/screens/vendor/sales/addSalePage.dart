import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MakeSalePage extends StatefulWidget {
  final String stallId;
  const MakeSalePage({super.key, required this.stallId});

  @override
  State<MakeSalePage> createState() => _MakeSalePageState();
}

class _MakeSalePageState extends State<MakeSalePage> {
  List<Map<String, dynamic>> _cart = [];
  double _total = 0;
  String _paymentMethod = 'Cash';
  String _customerPhone = '';
  bool _loading = false;

  void _showProductListModal() async {
    try {
      setState(() => _loading = true);

      // Get all categories in the stall
      final categoriesSnapshot = await FirebaseFirestore.instance
          .collection('stalls')
          .doc(widget.stallId)
          .collection('categories')
          .get();

      List<Map<String, dynamic>> allProducts = [];

      for (final categoryDoc in categoriesSnapshot.docs) {
        final categoryId = categoryDoc.id;
        final categoryName = categoryDoc['name'];

        final subcategoriesSnapshot = await FirebaseFirestore.instance
            .collection('stalls')
            .doc(widget.stallId)
            .collection('categories')
            .doc(categoryId)
            .collection('subcategories')
            .get();

        if (subcategoriesSnapshot.docs.isNotEmpty) {
          for (final subcategoryDoc in subcategoriesSnapshot.docs) {
            final subcategoryId = subcategoryDoc.id;
            final subcategoryName = subcategoryDoc['name'];

            final productsSnapshot = await FirebaseFirestore.instance
                .collection('stalls')
                .doc(widget.stallId)
                .collection('categories')
                .doc(categoryId)
                .collection('subcategories')
                .doc(subcategoryId)
                .collection('products')
                .get();

            allProducts.addAll(productsSnapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
              'categoryId': categoryId,
              'categoryName': categoryName,
              'subcategoryId': subcategoryId,
              'subcategoryName': subcategoryName,
            }));
          }
        } else {
          final productsSnapshot = await FirebaseFirestore.instance
              .collection('stalls')
              .doc(widget.stallId)
              .collection('categories')
              .doc(categoryId)
              .collection('products')
              .get();

          allProducts.addAll(productsSnapshot.docs.map((doc) => {
            'id': doc.id,
            ...doc.data(),
            'categoryId': categoryId,
            'categoryName': categoryName,
            'subcategoryId': null,
            'subcategoryName': null,
          }));
        }
      }

      final availableProducts =
      allProducts.where((p) => p['quantity'] > 0).toList();

      if (mounted) {
        setState(() => _loading = false);

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).colorScheme.background, // theme-aware
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            // For search functionality
            List<Map<String, dynamic>> filteredProducts = List.from(availableProducts);
            final TextEditingController searchController = TextEditingController();

            void filterProducts(String query) {
              query = query.toLowerCase();
              filteredProducts = availableProducts.where((product) {
                final name = (product['name'] ?? '').toString().toLowerCase();
                final category = (product['categoryName'] ?? '').toString().toLowerCase();
                final subcategory = (product['subcategoryName'] ?? '').toString().toLowerCase();
                return name.contains(query) ||
                    category.contains(query) ||
                    subcategory.contains(query);
              }).toList();
            }

            return StatefulBuilder(
              builder: (context, setModalState) => DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.85,
                minChildSize: 0.6,
                maxChildSize: 0.95,
                builder: (context, scrollController) => Stack(
                  children: [
                    Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'All Products (${filteredProducts.length})',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        // Search Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextField(
                            controller: searchController,
                            onChanged: (query) {
                              setModalState(() {
                                filterProducts(query);
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search products...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Product List
                        Expanded(
                          child: filteredProducts.isEmpty
                              ? const Center(child: Text('No products found'))
                              : ListView.builder(
                            controller: scrollController,
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: product['imageUrl'] != null
                                      ? Image.network(
                                    product['imageUrl'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                      : const Icon(Icons.image, size: 50),
                                ),
                                title: Text(
                                  product['name'],
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Price: Ksh${product['price']}",
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground,
                                      ),
                                    ),
                                    Text(
                                      "In Stock: ${product['quantity']}",
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground,
                                      ),
                                    ),
                                    Text(
                                      product['subcategoryName'] != null
                                          ? "Category: ${product['categoryName']} > ${product['subcategoryName']}"
                                          : "Category: ${product['categoryName']}",
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () =>
                                    _showQuantitySelector(product),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 70),
                      ],
                    ),
                    // Done Button
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton.extended(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.done),
                        label: const Text('Done'),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Error fetching all products: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load products')),
        );
      }
    }
  }


  void _showQuantitySelector(Map<String, dynamic> product) {
    int selectedQuantity = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Select Quantity"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("${product['name']} (Available: ${product['quantity']})"),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: selectedQuantity > 1
                          ? () => setDialogState(() => selectedQuantity--)
                          : null,
                    ),
                    Text('$selectedQuantity', style: const TextStyle(fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: selectedQuantity < product['quantity']
                          ? () => setDialogState(() => selectedQuantity++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text("Add to Cart"),
                onPressed: () {
                  setState(() {
                    _cart.add({
                      'id': product['id'],
                      'name': product['name'],
                      'price': product['price'],
                      'quantity': selectedQuantity,
                      'categoryId': product['categoryId'],
                      'subcategoryId': product['subcategoryId'],
                    });
                    _total += product['price'] * selectedQuantity;
                  });
                  _saveSaleToLocal();
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
      },
    );
  }

  void _editCartQuantity(int index) {
    int currentQty = _cart[index]['quantity'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Quantity"),
          content: StatefulBuilder(builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Current: $currentQty"),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: currentQty > 1
                          ? () => setDialogState(() => currentQty--)
                          : null,
                    ),
                    Text('$currentQty', style: const TextStyle(fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setDialogState(() => currentQty++),
                    ),
                  ],
                ),
              ],
            );
          }),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Update"),
              onPressed: () {
                setState(() {
                  int oldQty = _cart[index]['quantity'];
                  double price = _cart[index]['price'];
                  _cart[index]['quantity'] = currentQty;
                  _total += price * (currentQty - oldQty);
                });
                _saveSaleToLocal();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveSaleToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sale_${widget.stallId}', jsonEncode({
      'cart': _cart,
      'total': _total,
      'paymentMethod': _paymentMethod,
      'customerPhone': _customerPhone,
    }));
  }

  Future<void> _loadSaleFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('sale_${widget.stallId}');
    if (saved != null) {
      final data = jsonDecode(saved);
      setState(() {
        _cart = List<Map<String, dynamic>>.from(data['cart']);
        _total = data['total']?.toDouble() ?? 0;
        _paymentMethod = data['paymentMethod'] ?? 'Cash';
        _customerPhone = data['customerPhone'] ?? '';
      });
    }
  }

  Future<void> _clearLocalSale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sale_${widget.stallId}');
  }

  void _removeFromCart(int index) {
    setState(() {
      _total -= _cart[index]['price'] * _cart[index]['quantity'];
      _cart.removeAt(index);
      _saveSaleToLocal();
    });
  }

  Future<void> _submitSale() async {
    if (_cart.isEmpty) return;

    setState(() => _loading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final productsCollection = FirebaseFirestore.instance
          .collection('stalls')
          .doc(widget.stallId)
          .collection('categories');

      // First verify all products and quantities
      for (var item in _cart) {
        DocumentReference productRef;

        if (item['subcategoryId'] != null) {
          // Product is in a subcategory
          productRef = productsCollection
              .doc(item['categoryId'])
              .collection('subcategories')
              .doc(item['subcategoryId'])
              .collection('products')
              .doc(item['id']);
        } else {
          // Product is directly in category
          productRef = productsCollection
              .doc(item['categoryId'])
              .collection('products')
              .doc(item['id']);
        }

        final productDoc = await productRef.get();

        if (!productDoc.exists) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Product "${item['name']}" not found in inventory'),
          ));
          return;
        }

        final availableQty = productDoc['quantity'] ?? 0;
        if (item['quantity'] > availableQty) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              'Not enough stock for "${item['name']}". Available: $availableQty, Requested: ${item['quantity']}',
            ),
          ));
          return;
        }

        // Add to batch update
        batch.update(productRef, {
          'quantity': FieldValue.increment(-item['quantity'])
        });
      }

      // Record the sale
      final saleData = {
        'products': _cart,
        'total': _total,
        'paymentMethod': _paymentMethod,
        'customerPhone': _paymentMethod == 'Mpesa' ? _customerPhone : null,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('stalls')
          .doc(widget.stallId)
          .collection('sales')
          .add(saleData);

      // Commit all inventory updates
      await batch.commit();
      await _clearLocalSale();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale recorded and inventory updated!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to complete sale')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSaleFromLocal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Sale'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _showProductListModal,
              child: const Text('Add Product'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _cart.isEmpty
                  ? const Center(child: Text('No products in cart'))
                  : ListView.builder(
                itemCount: _cart.length,
                itemBuilder: (context, index) {
                  final item = _cart[index];
                  return ListTile(
                    title: Text('${item['name']} x${item['quantity']}'),
                    subtitle: Text('Total: Ksh${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editCartQuantity(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeFromCart(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Total: Ksh${_total.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: _paymentMethod,
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value!;
                  _saveSaleToLocal();
                });
              },
              items: const [
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                DropdownMenuItem(value: 'Mpesa', child: Text('Mpesa')),
              ],
            ),
            if (_paymentMethod == 'Mpesa') ...[
              TextField(
                decoration: const InputDecoration(labelText: 'Customer Phone'),
                onChanged: (val) {
                  _customerPhone = val;
                  _saveSaleToLocal();
                },
              ),
            ],
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _submitSale,
              child: const Text('Submit Sale'),
            ),
          ],
        ),
      ),
    );
  }
}