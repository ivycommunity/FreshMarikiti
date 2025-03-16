import 'package:flutter/material.dart';

class Subscriptionprovider extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController subscriptionTypeController =
      TextEditingController();
  final TextEditingController deliveryTimeController = TextEditingController();
  bool _isEditing = false;
  bool get isEditing => _isEditing;

  void savestateEditing() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  void saveChanges() {
    _isEditing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.text;
    emailController.text;
    addressController.text;
    subscriptionTypeController.text;
    deliveryTimeController.dispose();
    super.dispose(); 
    
  }
}
