import 'package:flutter/material.dart';

class Product {
  final String name;
  final String image;
  final String vendor;
  final double price;

  Product(
      {required this.name,
      required this.image,
      required this.vendor,
      required this.price});
}

class OrderProvider extends ChangeNotifier {
  final List<Product> _products = [
    Product(
        name: "Avocado",
        image: "assets/avocado.jpeg",
        vendor: "Auma",
        price: 20),
    Product(
        name: "Banana",
        image: "assets/banana.png",
        vendor: "Robert Wanjiru",
        price: 5),
    Product(
        name: "Milk",
        image: "assets/milk.jpeg",
        vendor: "Halima Hassan",
        price: 60),
    Product(
        name: "Meat",
        image: "assets/meat.jpeg",
        vendor: "Abdi Hassan",
        price: 400),
    Product(
        name: "Carrot",
        image: "assets/carrot.jpeg",
        vendor: "Collins Saitoti",
        price: 30),
    Product(
        name: "Sukuma Wiki",
        image: "assets/kales.jpeg",
        vendor: "Mary ",
        price: 20),
  ];

  final List<Product> _cart = [];

  List<Product> getProductsByCategory(String category) {
    switch (category) {
      case "Fruits":
        return _products
            .where((product) => ["Avocado", "Banana"].contains(product.name))
            .toList();
      case "Dairy":
        return _products
            .where((product) => ["Milk", "Meat"].contains(product.name))
            .toList();
      case "Veggies":
        return _products
            .where(
                (product) => ["Sukuma Wiki", "Carrot"].contains(product.name))
            .toList();
      default:
        return [];
    }
  }

  List<Product> get cart => _cart;

  void addToCart(Product product) {
    _cart.add(product);
    notifyListeners();
  }
}
