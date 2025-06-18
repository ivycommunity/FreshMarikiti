class Product {
  final String id;
  final String vendorId;
  final String name;
  final String? description;
  final double price;
  final int quantityAvailable;
  final String? imageUrl;
  final List<String> images;
  final String category;
  final double averageRating;
  final int totalRatings;
  final bool isActive;
  final bool isOrganic;
  final String location;
  final String? unit;
  final Map<String, dynamic>? nutritionInfo;
  final List<String>? tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Compatibility properties for EditProductScreen
  int get stockQuantity => quantityAvailable;
  int get lowStockThreshold => 10; // Default value
  List<String> get imageUrls => images;

  Product({
    required this.id,
    required this.vendorId,
    required this.name,
    this.description,
    required this.price,
    required this.quantityAvailable,
    this.imageUrl,
    this.images = const [],
    this.category = 'fresh produce',
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.isActive = true,
    this.isOrganic = false,
    this.location = 'Main Store',
    this.unit = 'piece',
    this.nutritionInfo,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      vendorId: json['vendor'] is Map 
          ? json['vendor']['_id'] ?? json['vendor']['id'] 
          : json['vendor'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantityAvailable: json['quantityAvailable']?.toInt() ?? json['stock']?.toInt() ?? 0,
      imageUrl: json['imageUrl'],
      images: List<String>.from(json['images'] ?? [json['imageUrl']].where((e) => e != null)),
      category: json['category'] ?? 'fresh produce',
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['totalRatings']?.toInt() ?? 0,
      isActive: json['isActive'] ?? json['status'] == 'active',
      isOrganic: json['isOrganic'] ?? false,
      location: json['location'] ?? 'Main Store',
      unit: json['unit'] ?? 'piece',
      nutritionInfo: json['nutritionInfo'] as Map<String, dynamic>?,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor': vendorId,
      'name': name,
      'description': description,
      'price': price,
      'quantityAvailable': quantityAvailable,
      'stock': quantityAvailable,
      'imageUrl': imageUrl,
      'images': images,
      'category': category,
      'averageRating': averageRating,
      'rating': averageRating,
      'totalRatings': totalRatings,
      'isActive': isActive,
      'status': isActive ? 'active' : 'inactive',
      'isOrganic': isOrganic,
      'location': location,
      'unit': unit,
      'nutritionInfo': nutritionInfo,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isAvailable => isActive && quantityAvailable > 0;
  bool get isInStock => isAvailable; // Alias for compatibility
  bool get hasRating => totalRatings > 0;
  String get ratingDisplay => hasRating ? averageRating.toStringAsFixed(1) : 'New';
  bool get isFeatured => averageRating >= 4.0 && totalRatings >= 5;
  bool get hasImages => images.isNotEmpty;
  String get primaryImage => images.isNotEmpty ? images.first : (imageUrl ?? '');
  
  // Price formatting
  String get formattedPrice => 'KSh ${price.toStringAsFixed(2)}';
  String get pricePerUnit => '$formattedPrice per $unit';
  
  // Stock status
  String get stockStatus {
    if (!isActive) return 'Inactive';
    if (quantityAvailable == 0) return 'Out of Stock';
    if (quantityAvailable < 10) return 'Low Stock';
    return 'In Stock';
  }

  // Organic badge
  String get organicBadge => isOrganic ? 'Organic' : '';

  Product copyWith({
    String? id,
    String? vendorId,
    String? name,
    String? description,
    double? price,
    int? quantityAvailable,
    String? imageUrl,
    List<String>? images,
    String? category,
    double? averageRating,
    int? totalRatings,
    bool? isActive,
    bool? isOrganic,
    String? location,
    String? unit,
    Map<String, dynamic>? nutritionInfo,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantityAvailable: quantityAvailable ?? this.quantityAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      category: category ?? this.category,
      averageRating: averageRating ?? this.averageRating,
      totalRatings: totalRatings ?? this.totalRatings,
      isActive: isActive ?? this.isActive,
      isOrganic: isOrganic ?? this.isOrganic,
      location: location ?? this.location,
      unit: unit ?? this.unit,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 