import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'edit_attendant.dart';

class AttendantDetailPage extends StatefulWidget {
  final String attendantId;

  const AttendantDetailPage({super.key, required this.attendantId});

  @override
  State<AttendantDetailPage> createState() => _AttendantDetailPageState();
}

class _AttendantDetailPageState extends State<AttendantDetailPage> {
  late String _fullName;
  late String _email;
  late String _contact;
  String? _profileImage;

  @override
  void initState() {
    super.initState();
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
      setState(() {
        _fullName = data['fullName'];
        _email = data['email'];
        _contact = data['contact'];
        _profileImage = data['profileImage'];
      });
    }
  }

  // Navigate to Edit Attendant Page
  void _editAttendant() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAttendantPage(attendantId: widget.attendantId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendant Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editAttendant,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _profileImage == null
            ? Center(child: const CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(_profileImage!),
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(height: 16),
            // Full Name
            Text(
              'Full Name: $_fullName',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Email
            Text(
              'Email: $_email',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            // Contact
            Text(
              'Contact: $_contact',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            // Action Button
            ElevatedButton(
              onPressed: _editAttendant,
              child: const Text('Edit Attendant'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
