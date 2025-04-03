import 'package:flutter/material.dart';

class Product {
  final String name;
  final String image;
  final String vendor;
  final double price;
  final String category; // Added category field

  Product({
    required this.name,
    required this.image,
    required this.vendor,
    required this.price,
    required this.category,
  });
}

class ProductProvider extends ChangeNotifier {
  final List<Product> _products = [
    // 🥛 Dairy Products
    Product(
        name: "Cow Milk",
        image: "assets/cow_milk.png",
        vendor: "Clifford",
        price: 50,
        category: "dairy"),
    Product(
        name: "Goat Milk",
        image: "assets/goat_milk.png",
        vendor: "Saitoti",
        price: 60,
        category: "dairy"),
    Product(
        name: "Ghee",
        image: "assets/ghee.png",
        vendor: "Wafula",
        price: 250,
        category: "dairy"),
    Product(
        name: "Cream",
        image: "assets/cream.png",
        vendor: "Sandra",
        price: 100,
        category: "dairy"),
    Product(
        name: "Yogurt",
        image: "assets/yogurt.png",
        vendor: "Charles",
        price: 80,
        category: "dairy"),

    // 🍎 Fruits
    Product(
        name: "Avocado",
        image: "assets/avocado.jpeg",
        vendor: "Murithi",
        price: 30,
        category: "fruits"),
    Product(
        name: "Banana",
        image: "assets/banana.png",
        vendor: "Onyango",
        price: 10,
        category: "fruits"),
    Product(
        name: "Mango",
        image: "assets/mangoes.jpeg",
        vendor: "Mutuku",
        price: 50,
        category: "fruits"),
    Product(
        name: "Oranges",
        image: "assets/orange.jpeg",
        vendor: "Makena",
        price: 40,
        category: "fruits"),
    Product(
        name: "Lemon",
        image: "assets/lemon.jpeg",
        vendor: "Halima",
        price: 70,
        category: "fruits"),

    // 🥬 Veggies
    Product(
        name: "Carrot",
        image: "assets/carrot.jpeg",
        vendor: "Kimani",
        price: 20,
        category: "veggies"),
    Product(
        name: "Sukuma Wiki",
        image: "assets/kales.jpeg",
        vendor: "Wangari",
        price: 30,
        category: "veggies"),
    Product(
        name: "Onions",
        image: "assets/onion.jpeg",
        vendor: "Maria",
        price: 25,
        category: "veggies"),
    Product(
        name: "Green Beans",
        image: "assets/green_beans.jpeg",
        vendor: "Mama Kyle",
        price: 15,
        category: "veggies"),
    Product(
        name: "Bell Pepper",
        image: "assets/pepper.jpeg",
        vendor: "Cosmus Magendi",
        price: 40,
        category: "veggies"),
  ];

  /// Returns products based on category
  List<Product> getProductsByCategory(String category) {
    return _products.where((product) => product.category == category).toList();
  }
}
