import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sokoni/screens/vendor/stalls/selectLocation.dart';
import 'package:uuid/uuid.dart';

import '../categories/add_category_page.dart';

class AddStallPage extends StatefulWidget {
  final String vendorId;

  const AddStallPage({super.key, required this.vendorId});

  @override
  State<AddStallPage> createState() => _AddStallPageState();
}

class _AddStallPageState extends State<AddStallPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();

  File? _stallImage;
  LatLng? _selectedLatLng;
  List<String> _selectedAttendants = [];
  List<DocumentSnapshot> _attendants = [];
  String? _address;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchAttendants();
  }

  Future<void> _fetchAttendants() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'attendant')
        .get();

    setState(() {
      _attendants = snapshot.docs;
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _stallImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(String stallId) async {
    if (_stallImage == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('stalls')
        .child('$stallId.jpg');

    await ref.putFile(_stallImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _saveStall() async {
    if (!_formKey.currentState!.validate() || _selectedLatLng == null) return;

    setState(() => _loading = true);

    final stallId = const Uuid().v4();
    final imageUrl = await _uploadImage(stallId);

    final stallData = {
      'id': stallId,
      'name': _nameController.text.trim(),
      'location': _locationController.text.trim(),
      'vendorId': widget.vendorId,
      'attendants': _selectedAttendants,
      'imageUrl': imageUrl,
      'address': _address,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('stalls')
        .doc(stallId)
        .set(stallData);

    setState(() => _loading = false);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddCategoryPage(stallId: stallId)),
    );
  }


  Future<void> _selectLocation() async {
    final PlaceLocation? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SelectLocationPage()),
    );

    if (result != null) {
      setState(() {
        _selectedLatLng = result.coordinates;
        _address = result.address;
        _locationController.text = result.address;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Stall")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade200,
                    image: _stallImage != null
                        ? DecorationImage(
                      image: FileImage(_stallImage!),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: _stallImage == null
                      ? const Icon(Icons.image, size: 60)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Stall Name"),
                validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                // readOnly: true,
                decoration: InputDecoration(
                  labelText: "Location",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.location_pin),
                    onPressed: _selectLocation,
                  ),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Pick location' : null,
              ),
              const SizedBox(height: 12),
              if (_attendants.isNotEmpty)
                DropdownButtonFormField<String>(
                  items: _attendants
                      .map((doc) => DropdownMenuItem(
                    value: doc.id,
                    child: Text(doc['name']),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null &&
                        !_selectedAttendants.contains(value)) {
                      setState(() => _selectedAttendants.add(value));
                    }
                  },
                  decoration:
                  const InputDecoration(labelText: "Add Attendant"),
                ),
              if (_selectedAttendants.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: _selectedAttendants.map((id) {
                    final user = _attendants.firstWhere((doc) => doc.id == id);
                    return Chip(
                      label: Text(user['name']),
                      onDeleted: () {
                        setState(() =>
                            _selectedAttendants.removeWhere((x) => x == id));
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveStall,
                icon: const Icon(Icons.save),
                label: const Text("Save and Add Categories"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


