import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditAttendantPage extends StatefulWidget {
  final String attendantId;

  const EditAttendantPage({super.key, required this.attendantId});

  @override
  State<EditAttendantPage> createState() => _EditAttendantPageState();
}

class _EditAttendantPageState extends State<EditAttendantPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _contactController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _contactController = TextEditingController();

    _loadAttendantData();
  }

  // Load attendant data from Firestore
  void _loadAttendantData() async {
    DocumentSnapshot attendantDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.attendantId)
        .get();

    if (attendantDoc.exists) {
      var data = attendantDoc.data() as Map<String, dynamic>;
      _fullNameController.text = data['fullName'];
      _emailController.text = data['email'];
      _contactController.text = data['contact'];
    }
  }

  // Update attendant details
  void _updateAttendant() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.attendantId)
            .update({
          'fullName': _fullNameController.text,
          'email': _emailController.text,
          'contact': _contactController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendant updated successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating attendant')),
        );
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Attendant')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  // Basic email validation
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Contact'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateAttendant,
                child: const Text('Update Attendant'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
