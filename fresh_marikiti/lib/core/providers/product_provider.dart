import 'package:flutter/material.dart';
import 'package:fresh_marikiti/core/models/product.dart';
import 'package:fresh_marikiti/core/services/product_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  List<Product> _searchResults = [];
  List<String> _categories = [];
  
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isLoadingMore = false;
  String? _error;
  
  // Filters
  String _selectedCategory = 'All';
  double _minPrice = 0.0;
  double _maxPrice = 1000.0;
  String _sortBy = 'name';
  String _sortOrder = 'asc';
  bool _inStockOnly = true;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreProducts = true;
  
  // Search
  String _searchQuery = '';
  
  // Cache
  final Map<String, List<Product>> _categoryCache = {};
  DateTime? _lastFetchTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Getters
  List<Product> get products => List.unmodifiable(_products);
  List<Product> get featuredProducts => List.unmodifiable(_featuredProducts);
  List<Product> get searchResults => List.unmodifiable(_searchResults);
  List<String> get categories => List.unmodifiable(_categories);
  
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  
  String get selectedCategory => _selectedCategory;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;
  bool get inStockOnly => _inStockOnly;
  
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMoreProducts => _hasMoreProducts;
  String get searchQuery => _searchQuery;

  // Initialize provider
  Future<void> initialize() async {
    await loadCategories();
    await loadFeaturedProducts();
    await loadProducts();
  }

  // Load all products with current filters
  Future<void> loadProducts({bool refresh = false}) async {
    if (_isLoading && !refresh) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ProductService.getProducts(
        page: _currentPage,
        limit: 20, // Fixed page size
        category: _selectedCategory != 'All' ? _selectedCategory : null,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        minPrice: _minPrice > 0 ? _minPrice : null,
        maxPrice: _maxPrice < 1000 ? _maxPrice : null,
        inStock: _inStockOnly,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      
      if (result['success'] == true) {
        final products = List<Product>.from(result['products'] ?? []);
        
        if (_currentPage == 1 || refresh) {
          _products = products;
        } else {
          _products.addAll(products);
        }
        
        _totalPages = (result['total'] ?? products.length) ~/ 20 + 1;
        _hasMoreProducts = products.length >= 20;
      } else {
        // Handle cached data or error
        if (result['products'] != null) {
          _products = List<Product>.from(result['products']);
          _error = result['message'];
        } else {
          _error = result['message'] ?? 'Failed to load products';
        }
      }
    } catch (e) {
      LoggerService.error('Failed to load products', error: e, tag: 'ProductProvider');
      _error = 'Failed to load products: ${e.toString()}';
      if (_currentPage == 1) _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more products (pagination)
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      _currentPage++;
      await loadProducts();
    } catch (e) {
      _currentPage--; // Revert on error
      LoggerService.error('Failed to load more products', error: e);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Load featured products
  Future<void> loadFeaturedProducts() async {
    try {
      _featuredProducts = await ProductService.getFeaturedProducts();
      notifyListeners();
    } catch (e) {
      LoggerService.error('Failed to load featured products', error: e, tag: 'ProductProvider');
      _featuredProducts = _products.take(5).toList();
    }
  }

  // Load product categories
  Future<void> loadCategories() async {
    try {
      _categories = ['all', ...await ProductService.getCategories()];
      notifyListeners();
    } catch (e) {
      LoggerService.error('Failed to load categories', error: e, tag: 'ProductProvider');
      _categories = ['all', 'Fruits', 'Vegetables', 'Grains', 'Dairy', 'Meat', 'Fish'];
    }
  }

  // Search products
  Future<void> searchProducts(String query) async {
    _searchQuery = query;
    _currentPage = 1;
    
    if (query.isEmpty) {
      await loadProducts(refresh: true);
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final searchResults = await ProductService.searchProducts(query);
      _products = searchResults;
      _totalPages = 1;
      _hasMoreProducts = false;
      _error = null;
    } catch (e) {
      LoggerService.error('Search failed', error: e, tag: 'ProductProvider');
      _error = 'Search failed: ${e.toString()}';
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear search
  void clearSearch() {
    _searchResults.clear();
    _searchQuery = '';
    notifyListeners();
  }

  // Filter methods
  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      _currentPage = 1;
      loadProducts(refresh: true);
    }
  }

  void setPriceRange(double min, double max) {
    _minPrice = min;
    _maxPrice = max;
    _currentPage = 1;
    loadProducts(refresh: true);
  }

  void setSorting(String sortBy, String sortOrder) {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    _currentPage = 1;
    loadProducts(refresh: true);
  }

  void setInStockOnly(bool inStockOnly) {
    _inStockOnly = inStockOnly;
    _currentPage = 1;
    loadProducts(refresh: true);
  }

  // Reset filters
  void resetFilters() {
    _selectedCategory = 'All';
    _minPrice = 0.0;
    _maxPrice = 1000.0;
    _sortBy = 'name';
    _sortOrder = 'asc';
    _inStockOnly = true;
    _currentPage = 1;
    loadProducts(refresh: true);
  }

  // Get product by ID
  Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get products by vendor
  List<Product> getProductsByVendor(String vendorId) {
    return _products.where((product) => product.vendorId == vendorId).toList();
  }

  // Get products by category
  List<Product> getProductsByCategory(String category) {
    if (category == 'All') return _products;
    return _products.where((product) => product.category == category).toList();
  }

  // Refresh all data
  Future<void> refresh() async {
    _categoryCache.clear();
    await loadCategories();
    await loadFeaturedProducts();
    await loadProducts(refresh: true);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Private helper methods
  bool _isCacheValid() {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration;
  }

  @override
  void dispose() {
    _categoryCache.clear();
    super.dispose();
  }
} 