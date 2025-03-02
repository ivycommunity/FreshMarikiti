import 'package:flutter/material.dart';

class CartItem {
  final String name;
  final String seller;
  final int price;
  final String image;
  int quantity;

  CartItem({
    required this.name,
    required this.seller,
    required this.price,
    required this.image,
    this.quantity = 1,
  });
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _cartItems = [
    CartItem(name: "10 Green Apples", seller: "Hassan Abdi", price: 250, image: "assets/green_apples.png"),
    CartItem(name: "2kg Potatoes", seller: "Maria Halima", price: 550, image: "assets/potatoes.png"),
    CartItem(name: "15 Bananas", seller: "Maria Halima", price: 150, image: "assets/bananas.png"),
    CartItem(name: "3 Pumpkins", seller: "Hassan Abdi", price: 350, image: "assets/pumpkins.png"),
    CartItem(name: "10 Oranges", seller: "Maria Halima", price: 200, image: "assets/oranges.png"),
  ];

  List<CartItem> get cartItems => _cartItems;

  int get subtotal => _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  int deliveryCharge = 100;
  int get total => subtotal + deliveryCharge;

  void increaseItems(int index) {
    _cartItems[index].quantity++;
    notifyListeners();
  }

  void reduceItems(int index) {
    if (_cartItems[index].quantity > 1) {
      _cartItems[index].quantity--;
      notifyListeners();
    }
  }

  void removeItem(int index) {
    _cartItems.removeAt(index);
    notifyListeners();
  }
}
