import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? userEmail;
  String? profileImageUrl;
  String name = '';
  String phone = '';
  String address = '';
  String role = '';
  bool isLoading = true;

  final picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userEmail = user.email;
      final doc = await FirebaseFirestore.instance.collection('users').doc(userEmail).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          name = data['name'] ?? '';
          phone = data['phone'] ?? '';
          address = data['address'] ?? '';
          role = data['role'] ?? '';
          profileImageUrl = data['profileImageUrl'];
          isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final storageRef = FirebaseStorage.instance
            .ref('profile_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}');
        await storageRef.putFile(File(picked.path));
        final url = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .update({'profileImageUrl': url});

        setState(() {
          profileImageUrl = url;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.email).update({
        'name': name,
        'phone': phone,
        'address': address,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : const AssetImage("assets/images/mama-1.jpg") as ImageProvider,
                  ),
                  Positioned(
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: _pickImage,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField("Full Name", name, (val) => setState(() => name = val),
                  validator: (val) => val!.isEmpty ? "Name required" : null),
              const SizedBox(height: 24),
              _buildTextField("Phone Number", phone, (val) => setState(() => phone = val)),
              const SizedBox(height: 24),
              _buildTextField("Address", address, (val) => setState(() => address = val)),
              const SizedBox(height: 24),
              _buildReadOnlyField("Email", userEmail ?? ''),
              const SizedBox(height: 24),
              _buildReadOnlyField("Role", role),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.save, color: Colors.black,),
                label: const Text("Save Changes", style: TextStyle(color: Colors.black),),
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      String value,
      Function(String) onChanged, {
        String? Function(String?)? validator,
      }) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return TextFormField(
      initialValue: value,
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        // filled: true,
        // fillColor: Colors.yellow,
      ),
    );
  }
}
