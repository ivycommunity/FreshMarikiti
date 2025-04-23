import 'package:flutter/material.dart';

class Seller {
  final String name;
  final double price;
  final String quantity;
  int inStock;

  Seller(
      {required this.name,
      required this.price,
      required this.quantity,
      this.inStock = 0});
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
          Seller(
            name: "Clifford Mburu",
            price: 55,
            quantity: "per litre",
            inStock: 20,
          ),
          Seller(
              name: "Joe Saitoti",
              price: 60,
              quantity: "per litre",
              inStock: 30)
        ]),

    Product(
        name: "Goat Milk",
        image: "assets/goat_milk.png",
        category: "dairy",
        vendors: [
          Seller(
              name: "Joe Saitoti",
              price: 70,
              quantity: "per litre",
              inStock: 12),
          Seller(
              name: "Ali Hassan", price: 75, quantity: "per litre", inStock: 20)
        ]),

    Product(
        name: "Ghee",
        image: "assets/ghee.png",
        category: "dairy",
        vendors: [
          Seller(
              name: "Wafula Chirchir",
              price: 600,
              quantity: "per 500g",
              inStock: 20),
          Seller(
              name: "Christine Masinde",
              price: 900,
              quantity: "per kg",
              inStock: 15)
        ]),

    Product(
        name: "Cream",
        image: "assets/cream.png",
        category: "dairy",
        vendors: [
          Seller(
              name: "Sandra Mukami",
              price: 150,
              quantity: "per jar",
              inStock: 5),
          Seller(
              name: "James Mwaura", price: 140, quantity: "per jar", inStock: 5)
        ]),

    Product(
        name: "Yoghurt",
        image: "assets/yogurt.png",
        category: "dairy",
        vendors: [
          Seller(
              name: "Charles Masaka",
              price: 600,
              quantity: "1 litre",
              inStock: 10),
          Seller(
              name: "Jackline Owino",
              price: 350,
              quantity: "450ml",
              inStock: 21)
        ]),

    // 🍎 Fruits
    Product(
        name: "Avocado",
        image: "assets/avocado.jpeg",
        category: "fruits",
        vendors: [
          Seller(
              name: "Khalifa Kairo", price: 30, quantity: "each", inStock: 32),
          Seller(
              name: "Jacinta Jackson", price: 25, quantity: "each", inStock: 23)
        ]),
    Product(
        name: "Banana",
        image: "assets/banana.png",
        category: "fruits",
        vendors: [
          Seller(
              name: "Tristan Onyango",
              price: 25,
              quantity: "per 3 pieces",
              inStock: 40),
          Seller(
              name: "Elvis Kimathi",
              price: 20,
              quantity: "per 3 pieces",
              inStock: 35)
        ]),
    Product(
        name: "Mango",
        image: "assets/mangoes.jpeg",
        category: "fruits",
        vendors: [
          Seller(
              name: "Charles Mutuku", price: 50, quantity: "each", inStock: 21),
          Seller(
              name: "Salima Mohammed", price: 50, quantity: "each", inStock: 43)
        ]),
    Product(
        name: "Oranges",
        image: "assets/orange.jpeg",
        category: "fruits",
        vendors: [
          Seller(name: "Joy Makena", price: 30, quantity: "each", inStock: 50),
          Seller(
              name: "Justin Muturi", price: 30, quantity: "each", inStock: 34)
        ]),
    Product(
        name: "Lemon",
        image: "assets/lemon.jpeg",
        category: "fruits",
        vendors: [
          Seller(
              name: "Halima Hassan", price: 25, quantity: "each", inStock: 24),
          Seller(name: "Leon Kiarie", price: 25, quantity: "each", inStock: 39)
        ]),

    // 🥬 Veggies
    Product(
        name: "Carrot",
        image: "assets/carrot.jpeg",
        category: "veggies",
        vendors: [
          Seller(
              name: "George Kimani",
              price: 50,
              quantity: "Kasuku",
              inStock: 21),
          Seller(
              name: "Dedan Kariuki", price: 50, quantity: "Kasuku", inStock: 34)
        ]),
    Product(
        name: "Green Veggies",
        image: "assets/kales.jpeg",
        category: "veggies",
        vendors: [
          Seller(
              name: "Rebecca Wangari",
              price: 10,
              quantity: "per bunch",
              inStock: 23),
          Seller(
              name: "Susan Wanjala",
              price: 10,
              quantity: "per bunch",
              inStock: 12)
        ]),
    Product(
        name: "Onions",
        image: "assets/onion.jpeg",
        category: "veggies",
        vendors: [
          Seller(
              name: "Rukia Maria", price: 80, quantity: "per kg", inStock: 100),
          Seller(
              name: "James Obado", price: 75, quantity: "per kg", inStock: 50)
        ]),
    Product(
        name: "Green Beans",
        image: "assets/green_beans.jpeg",
        category: "veggies",
        vendors: [
          Seller(
              name: "Jane Mary", price: 140, quantity: "Kasuku", inStock: 32),
          Seller(name: "Mary Auma", price: 130, quantity: "Kasuku", inStock: 51)
        ]),
    Product(
        name: "Bell Pepper",
        image: "assets/pepper.jpeg",
        category: "veggies",
        vendors: [
          Seller(
              name: "Cosmus Terta", price: 50, quantity: "each", inStock: 21),
          Seller(name: "Kate Precious", price: 50, quantity: "each", inStock: 4)
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

  // method to update the vendor's stock in
  void updateSellerStock(String productName, String sellerName, int newStock) {
    final product = _products.firstWhere((p) => p.name == productName);
    final seller = product.vendors.firstWhere((s) => s.name == sellerName);
    seller.inStock = newStock;
    notifyListeners();
  }

// A getter to retrieve the current stock
  int getSellerStock(String productName, String sellerName) {
    final product = _products.firstWhere((p) => p.name == productName);
    final seller = product.vendors.firstWhere((s) => s.name == sellerName);
    return seller.inStock;
  }
}
