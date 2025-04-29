import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';


class AddProductPage extends StatefulWidget {
  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // ✅ Form key

  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _sellerIdController = TextEditingController();
  final TextEditingController _sellerNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String accessToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImNlMjNkYTE0MGY2ZDAwNGY4MDEyIiwibmFtZSI6Im1ha2F1MSIsImVtYWlsIjoibWFrYXUxQGdtYWlsLmNvbSIsImJpb2NvaW5zIjowLCJjYXJ0IjpbXSwiaWF0IjoxNzQ1OTQxNjI3LCJleHAiOjE3NDU5NDI1Nzd9.HV21d0KGAQ63duV8BCtfDbZVlXsP71-aKgn6IfHZ7OI';

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _uploadProduct() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('x-auth-token');

    print('Retrieved Token: $token');
    final uri = Uri.parse('${Constants.uri}/products/add');
    final request = http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    } else {
      request.headers['Authorization'] = 'Bearer $accessToken';
      print('Token is null');
    }

    request.fields['name'] = _nameController.text;
    request.fields['sellerid'] = _sellerIdController.text;
    request.fields['seller'] = _sellerNameController.text;
    request.fields['phonenumber'] = _phoneNumberController.text;
    request.fields['quantity'] = _quantityController.text;
    request.fields['amount'] = _amountController.text;

    if (_imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        _imageFile!.path,
      ));
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      print("Upload successful");
    } else {
      print("Failed to upload: ${response.statusCode}");
    }
  }

  void _onContinuePressed() {
    if (_formKey.currentState!.validate()) {
      _uploadProduct();
    } else {
      print('Form is invalid');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add A Product',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'ADD MORE ITEMS TO YOUR ONLINE STALL',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: Icon(Icons.menu, color: Colors.black),
        actions: [
          CircleAvatar(
            backgroundImage: AssetImage('assets/vendor1.jpeg'),
          ),
          SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form( // ✅ Wrap everything in a Form
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: _imageFile == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image, size: 48, color: Colors.black54),
                        SizedBox(height: 8),
                        Text("Tap to upload", style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
                        Text("Or take a photo", style: TextStyle(color: Colors.black)),
                      ],
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_imageFile!.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                ProductTextField(textController: _nameController, labelText: 'Product Name'),
                SizedBox(height: 24),
                ProductTextField(textController: _sellerIdController, labelText: 'Seller ID'),
                SizedBox(height: 24),
                ProductTextField(textController: _sellerNameController, labelText: 'Seller Name'),
                SizedBox(height: 24),
                ProductTextField(textController: _phoneNumberController, labelText: 'Phone Number', keyboard: TextInputType.phone),
                SizedBox(height: 24),
                ProductTextField(textController: _quantityController, labelText: 'Quantity', keyboard: TextInputType.number),
                SizedBox(height: 24),
                ProductTextField(textController: _amountController, labelText: 'Amount'),
                SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: _onContinuePressed, // ✅ This triggers validation
                  label: Text("CONTINUE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  icon: Icon(Icons.upload, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[900],
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    // Save draft logic
                  },
                  child: Text("SAVE AS DRAFT", style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    side: BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class ProductTextField extends StatelessWidget {
  final TextEditingController textController;
  final String labelText;
  final TextInputType? keyboard;

  ProductTextField({
    super.key,
    required this.labelText,
    required this.textController,
    this.keyboard,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: textController,
      cursorColor: Colors.green,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.black45),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.green, width: 2),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey, width: 1),
        ),
      ),
      style: TextStyle(color: Colors.black),
      keyboardType: keyboard,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $labelText';
        }
        return null;
      },
    );
  }
}

