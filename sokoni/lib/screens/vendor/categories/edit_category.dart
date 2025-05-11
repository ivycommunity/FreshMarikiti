import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditCategoryPage extends StatefulWidget {
  final String stallId;
  final String categoryId;

  const EditCategoryPage({
    Key? key,
    required this.stallId,
    required this.categoryId,
  }) : super(key: key);

  @override
  State<EditCategoryPage> createState() => _EditCategoryPageState();
}

class _EditCategoryPageState extends State<EditCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _subController;
  List<String> _subcategories = [];
  String? _existingImageUrl;
  File? _newImageFile;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _subController = TextEditingController();
    _loadCategoryData();
  }

  Future<void> _loadCategoryData() async {
    final doc = await FirebaseFirestore.instance
        .collection('stalls')
        .doc(widget.stallId)
        .collection('categories')
        .doc(widget.categoryId)
        .get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _existingImageUrl = data['imageUrl'];
        _subcategories = List<String>.from(data['subcategories'] ?? []);
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
    final ref = FirebaseStorage.instance
        .ref()
        .child('categories')
        .child(widget.stallId)
        .child('${widget.categoryId}.jpg');
    await ref.putFile(_newImageFile!);
    return await ref.getDownloadURL();
  }

  void _addSubcategory() {
    final text = _subController.text.trim();
    if (text.isNotEmpty && !_subcategories.contains(text)) {
      setState(() {
        _subcategories.add(text);
        _subController.clear();
      });
    }
  }

  void _removeSubcategory(String sub) {
    setState(() {
      _subcategories.remove(sub);
    });
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
          .update({
        'name': _nameController.text.trim(),
        'imageUrl': imageUrl ?? '',
        'subcategories': _subcategories,
        'updatedAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error updating category: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update category')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Category')),
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
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
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
                decoration: const InputDecoration(labelText: 'Category Name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _subController,
                      decoration: const InputDecoration(labelText: 'Add Subcategory'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addSubcategory,
                  ),
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
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save),
                label: _loading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                )
                    : const Text('Save Changes'),
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
