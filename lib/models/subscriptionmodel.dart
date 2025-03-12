import 'package:flutter/material.dart';

class SubscriptionItem {
  final String name;
  final String seller;
  final int price;
  final String image;
  int quantity;

  SubscriptionItem(
      {required this.name,
      required this.seller,
      required this.price,
      required this.image,
      this.quantity = 1});
}

class SubscriptionProvider extends ChangeNotifier {
  final List<SubscriptionItem> _subscriptionItems = [
    SubscriptionItem(
        name: "10 Green Apples",
        seller: "Hassan Abdi",
        price: 250,
        image: "assets/green_apples.png"),
    SubscriptionItem(
        name: "2kg Potatoes",
        seller: "Maria Halima",
        price: 550,
        image: "assets/potatoes.png"),
    SubscriptionItem(
        name: "15 Bananas",
        seller: "Maria Halima",
        price: 150,
        image: "assets/bananas.png"),
    SubscriptionItem(
        name: "3 Pumpkins",
        seller: "Hassan Abdi",
        price: 350,
        image: "assets/pumpkins.png"),
  ];

  List<SubscriptionItem> get subscriptionItems => _subscriptionItems;
  int get subtotal => _subscriptionItems.fold(
      0, (sum, item) => sum + (item.price * item.quantity));

  void increaseItems(int index) {
    _subscriptionItems[index].quantity++;
    notifyListeners();
  }

  void reduceItems(int index) {
    if (_subscriptionItems[index].quantity > 1) {
      _subscriptionItems[index].quantity--;
      notifyListeners();
    }
  }

  void removeItem(int index) {
    _subscriptionItems.removeAt(index);
    notifyListeners();
  }
}
