import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'attendant_detail.dart';
import 'edit_attendant.dart';

class AttendantsPage extends StatefulWidget {
  final String stallId;

  const AttendantsPage({super.key, required this.stallId});

  @override
  State<AttendantsPage> createState() => _AttendantsPageState();
}

class _AttendantsPageState extends State<AttendantsPage> {
  late Stream<QuerySnapshot> _attendantsStream;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _attendantsStream = FirebaseFirestore.instance
        .collection('users')
        .where('stallId', isEqualTo: widget.stallId)
        .where('role', isEqualTo: 'attendant')
        .snapshots();
  }

  // Function to handle search
  void _filterAttendants() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendants')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by name, email, or contact',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => _filterAttendants(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _attendantsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No attendants available.'));
                }

                final attendants = snapshot.data!.docs;
                final filteredAttendants = attendants.where((attendant) {
                  final fullName = attendant['fullName'].toLowerCase();
                  final email = attendant['email'].toLowerCase();
                  final contact = attendant['contact'].toLowerCase();

                  return fullName.contains(_searchQuery) ||
                      email.contains(_searchQuery) ||
                      contact.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: filteredAttendants.length,
                  itemBuilder: (context, index) {
                    final attendant = filteredAttendants[index];
                    final fullName = attendant['fullName'];
                    final email = attendant['email'];
                    final contact = attendant['contact'];
                    final profileImage = attendant['profileImage'];

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        leading: profileImage.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            profileImage,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        )
                            : const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(fullName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: $email'),
                            Text('Contact: $contact'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            // Navigate to the Edit Attendant Page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditAttendantPage(
                                  attendantId: attendant.id,
                                ),
                              ),
                            );
                          },
                        ),
                        onTap: () {
                          // Navigate to the Attendant Detail Page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AttendantDetailPage(
                                attendantId: attendant.id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


