import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditDiscountPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditDiscountPage({super.key, required this.product});

  @override
  State<EditDiscountPage> createState() => _EditDiscountPageState();
}

class _EditDiscountPageState extends State<EditDiscountPage> {
  final _formKey = GlobalKey<FormState>();
  late double discountPercent;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    discountPercent = (widget.product['discountPercent'] ?? 0).toDouble();
    startDate = widget.product['discountStart']?.toDate();
    endDate = widget.product['discountEnd']?.toDate();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? (startDate ?? DateTime.now()) : (endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  void _saveDiscount() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save to Firestore or backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discount updated successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.product['image'] as String?;
    final name = widget.product['name'] ?? 'Unnamed Product';

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Discount')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(image, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    initialValue: discountPercent.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Discount Percentage (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final numValue = double.tryParse(value ?? '');
                      if (numValue == null || numValue < 0 || numValue > 100) {
                        return 'Enter a valid discount (0–100%)';
                      }
                      return null;
                    },
                    onChanged: (val) {
                      setState(() {
                        discountPercent = double.tryParse(val) ?? discountPercent;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    title: const Text("Start Date"),
                    subtitle: Text(
                      startDate != null ? DateFormat.yMMMMd().format(startDate!) : "Select a date",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context, true),
                    ),
                  ),
                  ListTile(
                    title: const Text("End Date"),
                    subtitle: Text(
                      endDate != null ? DateFormat.yMMMMd().format(endDate!) : "Select a date",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () => _selectDate(context, false),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: _saveDiscount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
