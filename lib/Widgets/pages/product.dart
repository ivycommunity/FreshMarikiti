import 'package:flutter/material.dart';
import 'package:marikiti/core/constants/providers/product_provider.dart';
import 'package:provider/provider.dart';

class ProductPage extends StatelessWidget {
  final String title;
  final String category;

  ProductPage({required this.title, required this.category});

  @override
  Widget build(BuildContext context) {
    final products =
        Provider.of<ProductProvider>(context).getProductsByCategory(category);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        title: Text(
          title.toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(
              name: products[index].name,
              image: products[index].image,
            );
          },
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String name;
  final String image;

  ProductCard({required this.name, required this.image});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(25.0),
          child: Image.asset(
            image,
            width: 50,
            height: 70,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[800],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          onPressed: () {},
          child: Text(
            'See vendors',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
