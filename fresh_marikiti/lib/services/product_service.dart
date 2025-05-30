import 'dart:convert';
import 'package:fresh_marikiti/models/product_model.dart';
import 'api_service.dart';

class ProductService {
  static Future<List<ProductModel>> fetchProducts() async {
    final response = await ApiService.get('/products');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }
} 