import 'package:flutter/material.dart';
import 'package:marikiti/Widgets/pages/cart.dart';
import 'package:marikiti/core/constants/providers/product_provider.dart';
import 'package:marikiti/core/constants/providers/cart_provider.dart';
import 'package:marikiti/homepage.dart';
//import 'package:marikiti/models/cartmodel.dart';
import 'package:provider/provider.dart';

class ShopPage extends StatelessWidget {
  final Product product;

  const ShopPage({required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //backgroundColor: const Color(0xFFFDE5C7), // light peach background
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            product.name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => CartPage()));
              },
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            return SizedBox(
              height: constraints.maxHeight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.73,
                  children: product.vendors
                      .map((vendor) =>
                          VendorCard(vendor: vendor, product: product))
                      .toList(),
                ),
              ),
            );
          }),
        ));
  }
}

class VendorCard extends StatefulWidget {
  final Product product;
  final Seller vendor;

  const VendorCard({required this.vendor, required this.product, super.key});

  @override
  State<VendorCard> createState() => _VendorCardState();
}

class _VendorCardState extends State<VendorCard> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final stock = context.watch<ProductProvider>().getSellerStock(
          widget.product.name,
          widget.vendor.name,
        );

    bool canIncrement = _quantity < stock;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Card(
        color: Color(0xFFFFE7D1),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Product Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.asset(
              widget.product.image,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // Item name
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(0, 8, 0, 0),
                child: Text(
                  widget.product.name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                child: Text(
                  widget.vendor.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                child: Text(
                  'Ksh ${widget.vendor.price.toStringAsFixed(0)} - ${widget.vendor.quantity}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Row(
                //crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(30, 8, 4, 4),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          //border: Border.all(color: Colors.white, width: 1.5),
                          borderRadius: BorderRadius.circular(18)),
                      child: Row(
                        children: [
                          GestureDetector(
                              child: Icon(
                                Icons.remove_circle,
                                size: 22,
                              ),
                              onTap: () {
                                if (_quantity > 1) {
                                  setState(() {
                                    _quantity--;
                                  });
                                }
                              }),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "${_quantity}",
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                          GestureDetector(
                              child: Icon(
                                Icons.add_circle,
                                size: 22,
                              ),
                              onTap: () {
                                if (canIncrement) {
                                  setState(() {
                                    _quantity++;
                                  });
                                }
                              }),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                      onTap: () {
                        cartProvider.addItemToCart(CartItem(
                            product: widget.product,
                            vendor: widget.vendor,
                            quantity: _quantity));
                        // Show a snackbar to notify the user
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('item added to cart!')));
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => CartPage()));
                      },
                      child: Icon(Icons.shopping_cart)),
                ],
              ),
            ],
          )
        ]));
  }
}
