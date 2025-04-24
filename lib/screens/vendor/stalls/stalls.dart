import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sokoni/screens/vendor/stalls/stallDetailPage.dart';

import 'add_stall_page.dart';


class StallsPage extends StatelessWidget {
  const StallsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vendorId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Stalls'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add Stall'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddStallPage(vendorId: vendorId),
            ),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stalls')
            .where('vendorId', isEqualTo: vendorId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final stalls = snapshot.data!.docs;
          if (stalls.isEmpty) {
            return const Center(child: Text('No stalls yet.\nTap + to add one.', textAlign: TextAlign.center));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: stalls.length,
            itemBuilder: (context, i) {
              final doc = stalls[i];
              final data = doc.data()! as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StallDetailPage(stallId: doc.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Stall image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: data['imageUrl'] != null && data['imageUrl'] != ''
                              ? Image.network(
                            data['imageUrl'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                              : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.store, size: 40, color: Colors.white60),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Stall info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? 'Unnamed Stall',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data['location'] ?? 'No location set',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  Chip(
                                    label: Text(
                                      '${(data['attendants'] as List<dynamic>?)?.length ?? 0} attendants',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                  // you can add more stats here: products, categories, sales count...
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
