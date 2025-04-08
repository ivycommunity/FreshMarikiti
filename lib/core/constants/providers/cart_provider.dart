import 'package:flutter/material.dart';
import 'package:marikiti/core/constants/providers/product_provider.dart';
//import 'package:marikiti/models/cartmodel.dart'; // Assuming this file contains the Product and Seller models

class CartItem {
  final Product product;
  final Seller vendor;
  int quantity;

  CartItem(
      {required this.product, required this.vendor, required this.quantity});
}

class CartProvider with ChangeNotifier {
  List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  // calculate subtotal for cart
  double get subtotal {
    return _cartItems.fold(0, (total, item) {
      return total + item.vendor.price * item.quantity;
    });
  }

  double get deliveryCharge {
    return 50.0; // Example delivery charge, you can modify this logic
  }

  double get total {
    return subtotal + deliveryCharge;
  }

  // Add item to cart
  void addItemToCart(CartItem item) {
    // Check if the item already exists in the cart
    final existingItemIndex = _cartItems.indexWhere((cartItem) =>
        cartItem.product.name == item.product.name &&
        cartItem.vendor.name == item.vendor.name);
    if (existingItemIndex != -1) {
      // If the item already exists, increase its quantity
      _cartItems[existingItemIndex].quantity += item.quantity;
    } else {
      // Otherwise, add the new item to the cart
      _cartItems.add(item);
    }
    notifyListeners();
  }

  // Remove item from cart
  void removeItem(int index) {
    _cartItems.removeAt(index);
    notifyListeners();
  }

  // Increase item quantity
  void increaseItems(int index) {
    _cartItems[index].quantity++;
    notifyListeners();
  }

  // Decrease item quantity
  void reduceItems(int index) {
    if (_cartItems[index].quantity > 1) {
      _cartItems[index].quantity--;
      notifyListeners();
    }
  }
}
