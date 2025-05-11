import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddVendorPage extends StatefulWidget {
  const AddVendorPage({super.key});

  @override
  State<AddVendorPage> createState() => _AddVendorPageState();
}

class _AddVendorPageState extends State<AddVendorPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String name = '';
  String email = '';
  String phone = '';
  String address = '';
  String password = '';

  bool isLoading = false;

  Future<void> _registerVendor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await _firestore.collection('users').doc(email.trim()).set({
        'uid': userCred.user!.uid,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
        'role': 'vendor',
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendor registered successfully!')),
      );
      await _firestore.collection('activity').add({
        'user': name.trim(),
        'title': 'Vendor Registration',
        'action': 'new vendor registered',
        'timestamp': Timestamp.now(),
      });

      Navigator.pop(context); // Go back to previous screen
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error registering vendor')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Add Vendor")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField("Full Name", onChanged: (val) => name = val),
              const SizedBox(height: 12),
              _buildField("Email", inputType: TextInputType.emailAddress, onChanged: (val) => email = val),
              const SizedBox(height: 12),
              _buildField("Phone Number", inputType: TextInputType.phone, onChanged: (val) => phone = val),
              const SizedBox(height: 12),
              _buildField("Address", onChanged: (val) => address = val),
              const SizedBox(height: 12),
              _buildField("Password", isPassword: true, onChanged: (val) => password = val),
              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                onPressed: _registerVendor,
                icon: const Icon(Icons.person_add),
                label: const Text("Register Vendor"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      String label, {
        required Function(String) onChanged,
        TextInputType inputType = TextInputType.text,
        bool isPassword = false,
      }) {
    return TextFormField(
      obscureText: isPassword,
      keyboardType: inputType,
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "$label is required";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
