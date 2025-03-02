import 'package:flutter/material.dart';

class CheckoutProvider extends ChangeNotifier {
  String? _selectedPaymentMethod;
  
  String get selectedPaymentMethod => _selectedPaymentMethod ?? "";

  void setPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  bool get isPaymentSelected => _selectedPaymentMethod != null;
}
