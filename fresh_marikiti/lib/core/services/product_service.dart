import 'dart:convert';
import 'dart:io';
import 'package:fresh_marikiti/core/models/product.dart';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProductService {
  // Using ApiService base URL instead of hardcoded URL
  static String get _baseUrl => ApiService.baseUrl;

  // =================== CUSTOMER/PUBLIC METHODS ===================

  /// Get all products with filters and pagination
  static Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    String? vendor,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String>[];
      queryParams.add('page=$page');
      queryParams.add('limit=$limit');
      
      if (category != null && category != 'all') queryParams.add('category=${Uri.encodeComponent(category)}');
      if (search != null && search.isNotEmpty) queryParams.add('search=${Uri.encodeComponent(search)}');
      if (vendor != null) queryParams.add('vendor=${Uri.encodeComponent(vendor)}');
      if (minPrice != null) queryParams.add('minPrice=$minPrice');
      if (maxPrice != null) queryParams.add('maxPrice=$maxPrice');
      if (inStock != null) queryParams.add('inStock=$inStock');
      if (sortBy != null) queryParams.add('sortBy=$sortBy');
      if (sortOrder != null) queryParams.add('sortOrder=$sortOrder');

      final url = '/products?${queryParams.join('&')}';
      LoggerService.info('Fetching products: $url', tag: 'ProductService');

      final response = await ApiService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = (data['products'] ?? data['data'] ?? [])
            .map<Product>((json) => Product.fromJson(json))
            .toList();

        // Cache products for offline access
        await _cacheProducts(products);

        return {
          'success': true,
          'products': products,
          'pagination': data['pagination'] ?? {},
          'total': data['total'] ?? products.length,
        };
      } else {
        LoggerService.error('Failed to fetch products: ${response.statusCode}', tag: 'ProductService');
        // Try to load from cache
        final cachedProducts = await _getCachedProducts();
        return {
          'success': false,
          'products': cachedProducts,
          'message': 'Using cached data - network error',
        };
      }
    } catch (e) {
      LoggerService.error('Error fetching products', error: e, tag: 'ProductService');
      // Fallback to cached data
      final cachedProducts = await _getCachedProducts();
      return {
        'success': false,
        'products': cachedProducts,
        'message': 'Network error - using cached data',
      };
    }
  }

  /// Get single product details
  static Future<Product?> getProductById(String productId) async {
    try {
      LoggerService.info('Fetching product details: $productId', tag: 'ProductService');

      final response = await ApiService.get('/products/$productId');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Product.fromJson(data['product'] ?? data);
      } else {
        LoggerService.error('Product not found: $productId', tag: 'ProductService');
        return null;
      }
    } catch (e) {
      LoggerService.error('Error fetching product details', error: e, tag: 'ProductService');
      return null;
    }
  }

  /// Get products by category
  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final result = await getProducts(category: category, limit: 100);
      return result['products'] ?? [];
    } catch (e) {
      LoggerService.error('Error fetching products by category', error: e, tag: 'ProductService');
      return [];
    }
  }

  /// Search products
  static Future<List<Product>> searchProducts(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      
      final result = await getProducts(search: query, limit: 50);
      return result['products'] ?? [];
    } catch (e) {
      LoggerService.error('Error searching products', error: e, tag: 'ProductService');
      return [];
    }
  }

  /// Get product categories
  static Future<List<String>> getCategories() async {
    try {
      LoggerService.info('Fetching product categories', tag: 'ProductService');

      final response = await ApiService.get('/products/categories');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['categories'] ?? []);
      } else {
        // Return default categories if API fails
        return _getDefaultCategories();
      }
    } catch (e) {
      LoggerService.error('Error fetching categories', error: e, tag: 'ProductService');
      return _getDefaultCategories();
    }
  }

  /// Get featured products
  static Future<List<Product>> getFeaturedProducts() async {
    try {
      final result = await getProducts(limit: 10, sortBy: 'rating', sortOrder: 'desc');
      return result['products'] ?? [];
    } catch (e) {
      LoggerService.error('Error fetching featured products', error: e, tag: 'ProductService');
      return [];
    }
  }

  // =================== VENDOR METHODS ===================

  /// Get vendor's products
  static Future<List<Product>> getVendorProducts({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      String url = '/products/vendor/my?page=$page&limit=$limit';
      if (status != null && status != 'all') {
        url += '&status=$status';
      }

      LoggerService.info('Fetching vendor products', tag: 'ProductService');

      final response = await ApiService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = (data['products'] ?? data['data'] ?? [])
            .map<Product>((json) => Product.fromJson(json))
            .toList();
        return products;
      } else {
        LoggerService.error('Failed to fetch vendor products: ${response.statusCode}', tag: 'ProductService');
        return [];
      }
    } catch (e) {
      LoggerService.error('Error fetching vendor products', error: e, tag: 'ProductService');
      return [];
    }
  }

  /// Create new product (Vendor)
  static Future<Map<String, dynamic>> createProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required int stock,
    String? unit,
    List<String>? images,
    bool isOrganic = false,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      LoggerService.info('Creating new product: $name', tag: 'ProductService');

      final productData = {
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'stock': stock,
        'unit': unit ?? 'piece',
        'images': images ?? [],
        'isOrganic': isOrganic,
        'status': 'active',
        if (additionalData != null) ...additionalData,
      };

      final response = await ApiService.post('/products', productData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        LoggerService.info('Product created successfully: ${data['productId'] ?? data['id']}', tag: 'ProductService');
        return {
          'success': true,
          'product': Product.fromJson(data['product'] ?? data),
          'productId': data['productId'] ?? data['id'],
        };
      } else {
        final error = json.decode(response.body);
        LoggerService.error('Product creation failed: ${error['message']}', tag: 'ProductService');
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to create product',
        };
      }
    } catch (e) {
      LoggerService.error('Error creating product', error: e, tag: 'ProductService');
      return {
        'success': false,
        'message': 'Network error: Failed to create product',
      };
    }
  }

  /// Update product (Vendor)
  static Future<Map<String, dynamic>> updateProduct({
    required String productId,
    String? name,
    String? description,
    double? price,
    String? category,
    int? stock,
    String? unit,
    List<String>? images,
    bool? isOrganic,
    String? status,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      LoggerService.info('Updating product: $productId', tag: 'ProductService');

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (category != null) updateData['category'] = category;
      if (stock != null) updateData['stock'] = stock;
      if (unit != null) updateData['unit'] = unit;
      if (images != null) updateData['images'] = images;
      if (isOrganic != null) updateData['isOrganic'] = isOrganic;
      if (status != null) updateData['status'] = status;
      if (additionalData != null) updateData.addAll(additionalData);

      final response = await ApiService.put('/products/$productId', updateData);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        LoggerService.info('Product updated successfully: $productId', tag: 'ProductService');
        return {
          'success': true,
          'product': Product.fromJson(data['product'] ?? data),
        };
      } else {
        final error = json.decode(response.body);
        LoggerService.error('Product update failed: ${error['message']}', tag: 'ProductService');
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to update product',
        };
      }
    } catch (e) {
      LoggerService.error('Error updating product', error: e, tag: 'ProductService');
      return {
        'success': false,
        'message': 'Network error: Failed to update product',
      };
    }
  }

  /// Delete product (Vendor)
  static Future<bool> deleteProduct(String productId) async {
    try {
      LoggerService.info('Deleting product: $productId', tag: 'ProductService');

      final response = await ApiService.delete('/products/$productId');

      if (response.statusCode == 200) {
        LoggerService.info('Product deleted successfully: $productId', tag: 'ProductService');
        return true;
      } else {
        LoggerService.error('Failed to delete product: $productId', tag: 'ProductService');
        return false;
      }
    } catch (e) {
      LoggerService.error('Error deleting product', error: e, tag: 'ProductService');
      return false;
    }
  }

  /// Update product stock
  static Future<bool> updateStock(String productId, int newStock) async {
    try {
      final response = await ApiService.patch('/products/$productId/stock', {
        'stock': newStock,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Error updating stock', error: e, tag: 'ProductService');
      return false;
    }
  }

  /// Upload product images
  static Future<Map<String, dynamic>> uploadProductImages(String productId, List<File> images) async {
    try {
      LoggerService.info('Uploading ${images.length} images for product: $productId', tag: 'ProductService');

      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/products/$productId/images'));
      
      // Add auth header
      final token = await StorageService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add image files
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        request.files.add(await http.MultipartFile.fromPath('images', file.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        LoggerService.info('Images uploaded successfully for product: $productId', tag: 'ProductService');
        return {
          'success': true,
          'imageUrls': data['imageUrls'] ?? [],
        };
      } else {
        LoggerService.error('Failed to upload images: ${response.statusCode}', tag: 'ProductService');
        return {
          'success': false,
          'message': 'Failed to upload images',
        };
      }
    } catch (e) {
      LoggerService.error('Error uploading images', error: e, tag: 'ProductService');
      return {
        'success': false,
        'message': 'Network error: Failed to upload images',
      };
    }
  }

  // =================== ANALYTICS METHODS ===================

  /// Get vendor product analytics
  static Future<Map<String, dynamic>> getVendorAnalytics({String period = 'month'}) async {
    try {
      final response = await ApiService.get('/products/analytics?period=$period');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        LoggerService.error('Failed to fetch vendor analytics', tag: 'ProductService');
        return {};
      }
    } catch (e) {
      LoggerService.error('Error fetching vendor analytics', error: e, tag: 'ProductService');
      return {};
    }
  }

  /// Get product performance
  static Future<Map<String, dynamic>> getProductPerformance(String productId, {String period = 'month'}) async {
    try {
      final response = await ApiService.get('/products/$productId/analytics?period=$period');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        LoggerService.error('Failed to fetch product performance', tag: 'ProductService');
        return {};
      }
    } catch (e) {
      LoggerService.error('Error fetching product performance', error: e, tag: 'ProductService');
      return {};
    }
  }

  // =================== RATING METHODS ===================

  /// Rate product
  static Future<bool> rateProduct(String productId, int rating, {String? comment}) async {
    try {
      final response = await ApiService.post('/products/$productId/rating', {
        'rating': rating,
        if (comment != null) 'comment': comment,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('Error rating product', error: e, tag: 'ProductService');
      return false;
    }
  }

  /// Get product ratings
  static Future<Map<String, dynamic>> getProductRatings(String productId) async {
    try {
      final response = await ApiService.get('/products/$productId/ratings');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {};
      }
    } catch (e) {
      LoggerService.error('Error fetching product ratings', error: e, tag: 'ProductService');
      return {};
    }
  }

  // =================== CACHE METHODS ===================

  /// Cache products for offline access
  static Future<void> _cacheProducts(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJson = products.map((p) => p.toJson()).toList();
      await prefs.setString('cached_products', json.encode(productsJson));
      await prefs.setString('products_cache_time', DateTime.now().toIso8601String());
    } catch (e) {
      LoggerService.error('Error caching products', error: e, tag: 'ProductService');
    }
  }

  /// Get cached products
  static Future<List<Product>> _getCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_products');
      if (cachedData != null) {
        final List<dynamic> productsJson = json.decode(cachedData);
        return productsJson.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      LoggerService.error('Error loading cached products', error: e, tag: 'ProductService');
    }
    return [];
  }

  /// Get default categories
  static List<String> _getDefaultCategories() {
    return [
      'Fruits',
      'Vegetables',
      'Grains & Cereals',
      'Dairy Products',
      'Meat & Poultry',
      'Fish & Seafood',
      'Herbs & Spices',
      'Beverages',
      'Organic',
      'Others',
    ];
  }

  /// Clear product cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_products');
      await prefs.remove('products_cache_time');
    } catch (e) {
      LoggerService.error('Error clearing product cache', error: e, tag: 'ProductService');
    }
  }

  /// Check if cache is fresh (less than 1 hour old)
  static Future<bool> isCacheFresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimeString = prefs.getString('products_cache_time');
      if (cacheTimeString != null) {
        final cacheTime = DateTime.parse(cacheTimeString);
        final now = DateTime.now();
        return now.difference(cacheTime).inHours < 1;
      }
    } catch (e) {
      LoggerService.error('Error checking cache freshness', error: e, tag: 'ProductService');
    }
    return false;
  }
} 