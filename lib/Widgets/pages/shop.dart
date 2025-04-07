import 'package:flutter/material.dart';
import 'package:marikiti/core/constants/providers/product_provider.dart';
import 'package:marikiti/homepage.dart';
import 'package:provider/provider.dart';

class ShopPage extends StatelessWidget {
  final Product product;

  const ShopPage({required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    final vendors = Provider.of<ProductProvider>(context)
        .getVendorsByProductName(product.name);

    return Scaffold(
      backgroundColor: const Color(0xFFFDE5C7), // light peach background
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D5227), // dark green
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        title: Text(
          product.name,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.95,
          children: product.vendors
              .map((vendor) => VendorCard(vendor: vendor, image: product.image))
              .toList(),
        ),
      ),
    );
  }
}

class VendorCard extends StatelessWidget {
  final Seller vendor;
  final String image;

  const VendorCard({required this.vendor, required this.image, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.asset(
              image,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Vendor Name
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12, right: 12),
            child: Text(
              vendor.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          // Price and Quantity
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
            child: Text(
              'Ksh ${vendor.price.toStringAsFixed(0)} - ${vendor.quantity}',
              style: const TextStyle(fontSize: 12),
            ),
          ),

          const Spacer(),

          // Add to cart button
          ElevatedButton(onPressed: () {}, child: Text("Add to cart"))
        ],
      ),
    );
  }
}
