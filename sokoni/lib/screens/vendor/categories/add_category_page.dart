import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddCategoryPage extends StatefulWidget {
  final String stallId;

  const AddCategoryPage({super.key, required this.stallId});

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _subcategoryController = TextEditingController();
  final List<String> _subcategories = [];
  File? _imageFile;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File file) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance
          .ref()
          .child('categories/${widget.stallId}/$fileName.jpg');

      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  void _addSubcategory() {
    final text = _subcategoryController.text.trim();
    if (text.isNotEmpty && !_subcategories.contains(text)) {
      setState(() {
        _subcategories.add(text);
        _subcategoryController.clear();
      });
    }
  }

  void _removeSubcategory(String sub) {
    setState(() {
      _subcategories.remove(sub);
    });
  }

  Future<void> _submitCategory({bool resetForm = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      }

      final categoryData = {
        'name': _nameController.text.trim(),
        'imageUrl': imageUrl ?? '',
        'createdAt': Timestamp.now(),
      };

      final categoryRef = await FirebaseFirestore.instance
          .collection('stalls')
          .doc(widget.stallId)
          .collection('categories')
          .add(categoryData);

      if (_subcategories.isNotEmpty) {
        final subcategoriesRef = categoryRef.collection('subcategories');
        for (String sub in _subcategories) {
          await subcategoriesRef.add({
            'name': sub,
            'createdAt': Timestamp.now(),
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added successfully!')),
        );

        if (resetForm) {
          // Clear form for another entry
          _formKey.currentState!.reset();
          _nameController.clear();
          _subcategoryController.clear();
          _subcategories.clear();
          _imageFile = null;
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error adding category: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add category')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Category')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _imageFile == null
                    ? Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Text('Tap to select category image'),
                  ),
                )
                    : Image.file(_imageFile!, height: 150, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Category Name'),
                validator: (value) =>
                value!.isEmpty ? 'Enter a category name' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _subcategoryController,
                      decoration:
                      const InputDecoration(labelText: 'Add Subcategory'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addSubcategory,
                  )
                ],
              ),
              Wrap(
                spacing: 8,
                children: _subcategories
                    .map((sub) => Chip(
                  label: Text(sub),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => _removeSubcategory(sub),
                ))
                    .toList(),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _loading
                          ? null
                          : () => _submitCategory(resetForm: true),
                      icon: const Icon(Icons.add),
                      label: _loading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                      )
                          : const Text('Save & Add Another'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : () {
                        _submitCategory(resetForm: true);
                        Navigator.pop(context);},
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
