import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sokoni/screens/vendor/sales/addSalePage.dart';
import '../attendants/add_attendant_page.dart';
import '../categories/add_category_page.dart';
import '../categories/products/add_product_page.dart';

class StallDetailPage extends StatefulWidget {
  final String stallId;
  const StallDetailPage({Key? key, required this.stallId}) : super(key: key);

  @override
  State<StallDetailPage> createState() => _StallDetailPageState();
}

class _StallDetailPageState extends State<StallDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DocumentReference _stallRef;

  @override
  void initState() {
    super.initState();
    _stallRef = FirebaseFirestore.instance.collection('stalls').doc(widget.stallId);
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _stallRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final stall = snapshot.data!;
        final data = stall.data() as Map<String, dynamic>? ?? {};
        final name = data['name'] ?? 'Stall';

        return Scaffold(
          appBar: AppBar(
            title: Text(name),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Categories'),
                Tab(text: 'Products'),
                Tab(text: 'Sales'),
                Tab(text: 'Attendants'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverview(data),
              _buildCategoriesTab(),
              _buildProductsTab(),
              _buildSalesTab(),
              _buildAttendantsTab(data),
            ],
          ),
          floatingActionButton: _buildFAB(),
        );
      },
    );
  }

  Widget _buildOverview(Map<String, dynamic> data) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (data['imageUrl'] != null && data['imageUrl'] != '')
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(data['imageUrl'], height: 180, width: double.infinity, fit: BoxFit.cover),
          ),
        const SizedBox(height: 16),
        Text(data['location'] ?? '', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _countCard('Categories', 'stalls/${widget.stallId}/categories'),
            _countCard('Products', 'stalls/${widget.stallId}/products'),
            _countCard('Sales', 'stalls/${widget.stallId}/sales'),
            Chip(label: Text('Attendants: ${(data['attendants'] as List<dynamic>?)?.length ?? 0}')),
          ],
        ),
      ],
    );
  }

  Widget _countCard(String label, String path) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(path).snapshots(),
      builder: (context, snap) {
        final count = snap.hasData ? snap.data!.docs.length : 0;
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [Text('$count', style: Theme.of(context).textTheme.headlineSmall), Text(label)],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _stallRef.collection('categories').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No categories'));
        return ListView(
          children: docs.map((d) => ListTile(title: Text(d['name']))).toList(),
        );
      },
    );
  }

  Widget _buildProductsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _stallRef.collection('products').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No products'));
        return ListView(
          children: docs.map((d) {
            return ListTile(
              leading: d['image'] != null ? Image.network(d['image'], width: 40, height: 40, fit: BoxFit.cover) : null,
              title: Text(d['name']),
              subtitle: Text('KES ${d['price']}'),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSalesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _stallRef.collection('sales').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No sales'));
        return ListView(
          children: docs.map((d) {
            final total = d['total'];
            final when = (d['timestamp'] as Timestamp).toDate();
            return ListTile(
              title: Text('Ksh ${total.toStringAsFixed(2)}'),
              subtitle: Text(DateFormat.yMMMd().add_jm().format(when)),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAttendantsTab(Map<String, dynamic> data) {
    final ids = List<String>.from(data['attendants'] ?? []);
    if (ids.isEmpty) return const Center(child: Text('No attendants'));
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: ids)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return ListView(
          children: snap.data!.docs.map((d) => ListTile(title: Text(d['name']))).toList(),
        );
      },
    );
  }

  Widget? _buildFAB() {
    switch (_tabController.index) {
      case 1:
        return FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddCategoryPage(stallId: widget.stallId)),
          ),
        );
      case 2:
        return FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(builder: (_) => AddProductPage(stallId: widget.stallId)),
            // );
          }
        );
      case 3:
        return FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MakeSalePage(stallId: widget.stallId)),
          ),
        );
      case 4:
        return FloatingActionButton(
          child: const Icon(Icons.person_add),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddAttendantPage(stallId: widget.stallId)),
          ),
        );
      default:
        return null;
    }
  }
}
