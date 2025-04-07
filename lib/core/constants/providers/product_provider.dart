import 'package:flutter/material.dart';

class Seller {
  final String name;
  final double price;
  final String quantity;

  Seller({required this.name, required this.price, required this.quantity});
}

class Product {
  final String name;
  final String image;
  final String category; // Added category field
  final List<Seller> vendors;

  Product(
      {required this.name,
      required this.image,
      required this.category,
      required this.vendors});
}

class ProductProvider extends ChangeNotifier {
  final List<Product> _products = [
    // 🥛 Dairy Products
    Product(
        name: "Cow Milk",
        image: "assets/cow_milk.png",
        category: "dairy",
        vendors: [
          Seller(name: "Clifford", price: 55, quantity: "per litre"),
          Seller(name: "Saitoti", price: 60, quantity: "per litre")
        ]),

    Product(
        name: "Goat Milk",
        image: "assets/goat_milk.png",
        category: "dairy",
        vendors: [
          Seller(name: "Saitoti", price: 70, quantity: "per litre"),
          Seller(name: "Ali", price: 75, quantity: "per litre")
        ]),

    Product(
        name: "Ghee",
        image: "assets/ghee.png",
        category: "dairy",
        vendors: [
          Seller(name: "Wafula", price: 600, quantity: "per 500g"),
          Seller(name: "Christine", price: 900, quantity: "per kg")
        ]),

    Product(
        name: "Cream",
        image: "assets/cream.png",
        category: "dairy",
        vendors: [
          Seller(name: "Sandra", price: 150, quantity: "per jar"),
          Seller(name: "James", price: 140, quantity: "per jar")
        ]),

    Product(
        name: "Yoghurt",
        image: "assets/yogurt.png",
        category: "dairy",
        vendors: [
          Seller(name: "Charles", price: 600, quantity: "1 litre"),
          Seller(name: "Jackline", price: 350, quantity: "450ml")
        ]),

    // 🍎 Fruits
    Product(
        name: "Avocado",
        image: "assets/avocado.jpeg",
        category: "fruits",
        vendors: [
          Seller(name: "Khalifa", price: 30, quantity: "each"),
          Seller(name: "Jacinta", price: 25, quantity: "each")
        ]),
    Product(
        name: "Banana",
        image: "assets/banana.png",
        category: "fruits",
        vendors: [
          Seller(name: "Onyango", price: 25, quantity: "per 3 pieces"),
          Seller(name: "Kimathi", price: 20, quantity: "per 3 pieces")
        ]),
    Product(
        name: "Mango",
        image: "assets/mangoes.jpeg",
        category: "fruits",
        vendors: [
          Seller(name: "Mutuku", price: 50, quantity: "each"),
          Seller(name: "Salima", price: 50, quantity: "each")
        ]),
    Product(
        name: "Oranges",
        image: "assets/orange.jpeg",
        category: "fruits",
        vendors: [
          Seller(name: "Makena", price: 30, quantity: "each"),
          Seller(name: "Justin", price: 30, quantity: "each")
        ]),
    Product(
        name: "Lemon",
        image: "assets/lemon.jpeg",
        category: "fruits",
        vendors: [
          Seller(name: "Halima", price: 25, quantity: "each"),
          Seller(name: "Leon", price: 25, quantity: "each")
        ]),

    // 🥬 Veggies
    Product(
        name: "Carrot",
        image: "assets/carrot.jpeg",
        category: "veggies",
        vendors: [
          Seller(name: "Kimani", price: 50, quantity: "Kasuku"),
          Seller(name: "Kariuki", price: 50, quantity: "Kasuku")
        ]),
    Product(
        name: "Green Veggies",
        image: "assets/kales.jpeg",
        category: "veggies",
        vendors: [
          Seller(name: "Wangari", price: 10, quantity: "per bunch"),
          Seller(name: "Susan", price: 10, quantity: "per bunch")
        ]),
    Product(
        name: "Onions",
        image: "assets/onion.jpeg",
        category: "veggies",
        vendors: [
          Seller(name: "Maria", price: 80, quantity: "per kg"),
          Seller(name: "James", price: 75, quantity: "per kg")
        ]),
    Product(
        name: "Green Beans",
        image: "assets/green_beans.jpeg",
        category: "veggies",
        vendors: [
          Seller(name: "Jane", price: 140, quantity: "Kasuku"),
          Seller(name: "Mary", price: 130, quantity: "Kasuku")
        ]),
    Product(
        name: "Bell Pepper",
        image: "assets/pepper.jpeg",
        category: "veggies",
        vendors: [
          Seller(name: "Cosmus ", price: 50, quantity: "each"),
          Seller(name: "Kate", price: 50, quantity: "each")
        ]),
  ];

  /// Returns products based on category
  List<Product> getProductsByCategory(String category) {
    return _products.where((product) => product.category == category).toList();
  }

  List<Seller> getVendorsByProductName(String productName) {
    final product = _products.firstWhere((p) => p.name == productName);
    return product.vendors;
  }
}
