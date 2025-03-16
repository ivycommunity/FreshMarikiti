import 'package:flutter/material.dart';

class ItemProvider extends ChangeNotifier {
  // Controllers for input fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Image file path (assuming you're picking an image)
  String? _imagePath;
  String? get imagePath => _imagePath;

  void setImagePath(String path) {
    _imagePath = path;
    notifyListeners();
  }

  // Method to clear fields (useful after adding/editing an item)
  void clearFields() {
    nameController.clear();
    quantityController.clear();
    priceController.clear();
    descriptionController.clear();
    _imagePath = null;
    notifyListeners();
  }

  // Mock method to save item
  void saveItem() {
    String name = nameController.text;
    String quantity = quantityController.text;
    String price = priceController.text;
    String description = descriptionController.text;
// to display the items saved in the logs 
    print("Item Saved: Name: $name, Quantity: $quantity, Price: $price, Description: $description, Image: $_imagePath");
    
    // Clear fields after saving
    clearFields();
  }

  @override
  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
