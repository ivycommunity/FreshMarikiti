import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProductPage extends StatefulWidget {
  final String stallId;
  final String categoryId;
  final String productId;

  const EditProductPage({
    Key? key,
    required this.stallId,
    required this.categoryId,
    required this.productId,
  }) : super(key: key);

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _descriptionController;

  String? _existingImageUrl;
  File? _newImageFile;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _quantityController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    final doc = await FirebaseFirestore.instance
        .collection('stalls')
        .doc(widget.stallId)
        .collection('categories')
        .doc(widget.categoryId)
        .collection('products')
        .doc(widget.productId)
        .get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _priceController.text = (data['price'] ?? '').toString();
        _quantityController.text = (data['quantity'] ?? '').toString();
        _descriptionController.text = data['description'] ?? '';
        _existingImageUrl = data['imageUrl'];
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _newImageFile = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_newImageFile == null) return _existingImageUrl;
    final path = 'products/${widget.stallId}/${widget.categoryId}/${widget.productId}.jpg';
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(_newImageFile!);
    return await ref.getDownloadURL();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final imageUrl = await _uploadImage();
      await FirebaseFirestore.instance
          .collection('stalls')
          .doc(widget.stallId)
          .collection('categories')
          .doc(widget.categoryId)
          .collection('products')
          .doc(widget.productId)
          .update({
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'quantity': int.parse(_quantityController.text.trim()),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error updating product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update product')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: _newImageFile != null
                        ? DecorationImage(
                      image: FileImage(_newImageFile!),
                      fit: BoxFit.cover,
                    )
                        : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty
                        ? DecorationImage(
                      image: NetworkImage(_existingImageUrl!),
                      fit: BoxFit.cover,
                    )
                        : null),
                  ),
                  alignment: Alignment.center,
                  child: _newImageFile == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)
                      ? const Icon(Icons.image, size: 60)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter product name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid price' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || int.tryParse(v) == null ? 'Enter valid quantity' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
