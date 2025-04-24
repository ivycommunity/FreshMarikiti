import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddFlashSalePage extends StatefulWidget {
  final String stallId;

  const AddFlashSalePage({super.key, required this.stallId});

  @override
  State<AddFlashSalePage> createState() => _AddFlashSalePageState();
}

class _AddFlashSalePageState extends State<AddFlashSalePage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProductId;
  DocumentSnapshot? _selectedProductDoc;
  double? _discountPercent;
  DateTime? _startTime;
  DateTime? _endTime;
  bool _loading = false;

  Future<void> _pickDateTime(bool isStart) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (pickedTime == null) return;

    final selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        _startTime = selectedDateTime;
      } else {
        _endTime = selectedDateTime;
      }
    });
  }

  Future<bool> _checkForClashingSales() async {
    final snap = await FirebaseFirestore.instance
        .collection('stalls')
        .doc(widget.stallId)
        .collection('flash_sales')
        .where('productId', isEqualTo: _selectedProductId)
        .get();

    for (var doc in snap.docs) {
      final start = (doc['startTime'] as Timestamp).toDate();
      final end = (doc['endTime'] as Timestamp).toDate();

      final bool overlaps = !(_endTime!.isBefore(start) || _startTime!.isAfter(end));
      if (overlaps) return true;
    }
    return false;
  }

  Future<void> _submitFlashSale() async {
    if (!_formKey.currentState!.validate() ||
        _selectedProductId == null ||
        _startTime == null ||
        _endTime == null) return;

    if (_endTime!.isBefore(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() => _loading = true);

    final clash = await _checkForClashingSales();
    if (clash) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product already has a flash sale during that time.'),
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('stalls')
          .doc(widget.stallId)
          .collection('flash_sales')
          .add({
        'productId': _selectedProductId,
        'discountPercent': _discountPercent,
        'startTime': Timestamp.fromDate(_startTime!),
        'endTime': Timestamp.fromDate(_endTime!),
        'createdAt': Timestamp.now(),
        'active': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flash Sale created!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create flash sale')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  String formatDate(DateTime? date) {
    return date == null ? 'Not selected' : DateFormat.yMMMd().add_jm().format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Flash Sale')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Product dropdown
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('stalls')
                    .doc(widget.stallId)
                    .collection('products')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();

                  final products = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: _selectedProductId,
                    items: products.map((doc) {
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(doc['name']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedProductId = val;
                        _selectedProductDoc = products.firstWhere((p) => p.id == val);
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Select Product'),
                    validator: (val) => val == null ? 'Select a product' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Discount
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Discount (%)'),
                validator: (val) {
                  final discount = double.tryParse(val ?? '');
                  if (discount == null || discount <= 0 || discount >= 100) {
                    return 'Enter a valid discount (1–99%)';
                  }
                  return null;
                },
                onChanged: (val) =>
                _discountPercent = double.tryParse(val),
              ),
              const SizedBox(height: 16),

              // Start Time
              ListTile(
                title: const Text('Start Time'),
                subtitle: Text(formatDate(_startTime)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDateTime(true),
              ),

              // End Time
              ListTile(
                title: const Text('End Time'),
                subtitle: Text(formatDate(_endTime)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDateTime(false),
              ),

              const SizedBox(height: 24),

              // Preview Card
              if (_selectedProductDoc != null &&
                  _discountPercent != null &&
                  _startTime != null &&
                  _endTime != null)
                Card(
                  color: Colors.grey[100],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🔍 Preview', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (_selectedProductDoc?['image'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _selectedProductDoc!['image'],
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_selectedProductDoc!['name'],
                                      style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text("Price: ${_selectedProductDoc!['price']}"),
                                  Text("Discount: $_discountPercent%"),
                                  Text("From: ${formatDate(_startTime)}"),
                                  Text("To: ${formatDate(_endTime)}"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.flash_on),
                label: _loading
                    ? const CircularProgressIndicator.adaptive()
                    : const Text('Create Flash Sale'),
                onPressed: _loading ? null : _submitFlashSale,
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
