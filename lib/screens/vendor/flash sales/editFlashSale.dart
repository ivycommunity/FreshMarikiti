import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditFlashSalePage extends StatefulWidget {
  final String stallId;
  final String flashSaleId;
  final Map<String, dynamic> existingData;

  const EditFlashSalePage({
    super.key,
    required this.stallId,
    required this.flashSaleId,
    required this.existingData,
  });

  @override
  State<EditFlashSalePage> createState() => _EditFlashSalePageState();
}

class _EditFlashSalePageState extends State<EditFlashSalePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController titleController;
  late TextEditingController productIdController;
  late TextEditingController discountPriceController;
  late DateTime startDate;
  late DateTime endDate;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.existingData['title']);
    productIdController = TextEditingController(text: widget.existingData['productId']);
    discountPriceController = TextEditingController(text: widget.existingData['discountPrice'].toString());
    startDate = (widget.existingData['startTime'] as Timestamp).toDate();
    endDate = (widget.existingData['endTime'] as Timestamp).toDate();
  }

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final initialDate = isStart ? startDate : endDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (pickedTime != null) {
        final fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          if (isStart) {
            startDate = fullDateTime;
          } else {
            endDate = fullDateTime;
          }
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isUpdating = true);

    try {
      await FirebaseFirestore.instance
          .collection('stalls')
          .doc(widget.stallId)
          .collection('flashSales')
          .doc(widget.flashSaleId)
          .update({
        'title': titleController.text.trim(),
        'productId': productIdController.text.trim(),
        'discountPrice': double.tryParse(discountPriceController.text) ?? 0,
        'startTime': Timestamp.fromDate(startDate),
        'endTime': Timestamp.fromDate(endDate),
        'updatedAt': Timestamp.now(),
      });

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Flash sale updated successfully")),
        );
      }
    } catch (e) {
      debugPrint("Update error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update: $e")),
      );
    } finally {
      setState(() => isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Flash Sale")),
      body: isUpdating
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                value!.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: productIdController,
                decoration: const InputDecoration(labelText: 'Product ID'),
                validator: (value) =>
                value!.isEmpty ? 'Product ID is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: discountPriceController,
                decoration: const InputDecoration(labelText: 'Discount Price'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value!.isEmpty ? 'Price is required' : null,
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text("Start Time"),
                subtitle: Text(DateFormat('yyyy-MM-dd hh:mm a').format(startDate)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _selectDateTime(context, true),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text("End Time"),
                subtitle: Text(DateFormat('yyyy-MM-dd hh:mm a').format(endDate)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _selectDateTime(context, false),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.save),
                label: const Text("Save Changes"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
