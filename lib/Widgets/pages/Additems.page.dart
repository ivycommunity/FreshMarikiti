import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marikiti/core/constants/providers/itemprovider.dart';
import 'package:provider/provider.dart';


class AddEditItemPage extends StatelessWidget {
  final bool isEditMode;

  const AddEditItemPage({super.key, this.isEditMode = false});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ItemProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isEditMode ? "Edit Item" : "Add Item"),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text("Name of Item",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: provider.nameController,
                    decoration: InputDecoration(
                      hintText: isEditMode ? "White Onions" : "Enter item name",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("Quantity", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: provider.quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: isEditMode ? "350" : "Enter quantity",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("Price", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: provider.priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: isEditMode ? "Ksh. 10" : "Enter price",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("Description",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: provider.descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: isEditMode
                          ? "show items "
                          : "Enter description",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("Image", style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final pickedFile =
                              await picker.pickImage(source: ImageSource.gallery);
          
                          if (pickedFile != null) {
                            provider.setImagePath(pickedFile.path);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300]),
                        child: const Text("Choose image"),
                      ),
                      const SizedBox(width: 10),
                      provider.imagePath != null
                          ? Image.asset(provider.imagePath!,
                              height: 50, width: 50, fit: BoxFit.cover)
                          : const SizedBox(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        provider.saveItem();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                isEditMode ? "Item Updated" : "Item Added")));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(isEditMode ? "EDIT ITEM" : "ADD ITEM"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
