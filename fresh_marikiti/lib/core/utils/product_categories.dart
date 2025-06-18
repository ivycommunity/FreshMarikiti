class ProductCategories {
  static const List<String> categories = [
    'Fruits',
    'Vegetables',
    'Grains & Cereals',
    'Dairy & Eggs',
    'Meat & Poultry',
    'Fish & Seafood',
    'Herbs & Spices',
    'Beverages',
    'Snacks',
    'Other',
  ];

  static const Map<String, List<String>> subCategories = {
    'Fruits': [
      'Tropical Fruits',
      'Citrus Fruits',
      'Berries',
      'Stone Fruits',
      'Other Fruits',
    ],
    'Vegetables': [
      'Leafy Greens',
      'Root Vegetables',
      'Cruciferous',
      'Nightshades',
      'Legumes',
      'Other Vegetables',
    ],
    'Grains & Cereals': [
      'Rice',
      'Wheat',
      'Maize',
      'Barley',
      'Oats',
      'Other Grains',
    ],
    'Dairy & Eggs': [
      'Milk',
      'Cheese',
      'Yogurt',
      'Eggs',
      'Butter',
      'Other Dairy',
    ],
    'Meat & Poultry': [
      'Chicken',
      'Beef',
      'Pork',
      'Goat',
      'Lamb',
      'Other Meat',
    ],
    'Fish & Seafood': [
      'Fresh Fish',
      'Dried Fish',
      'Shellfish',
      'Other Seafood',
    ],
    'Herbs & Spices': [
      'Fresh Herbs',
      'Dried Spices',
      'Seasoning Blends',
      'Salt',
      'Other Seasonings',
    ],
    'Beverages': [
      'Juices',
      'Tea',
      'Coffee',
      'Traditional Drinks',
      'Other Beverages',
    ],
    'Snacks': [
      'Nuts',
      'Dried Fruits',
      'Traditional Snacks',
      'Other Snacks',
    ],
    'Other': [
      'Miscellaneous',
    ],
  };

  static const Map<String, String> categoryIcons = {
    'Fruits': '🍎',
    'Vegetables': '🥬',
    'Grains & Cereals': '🌾',
    'Dairy & Eggs': '🥛',
    'Meat & Poultry': '🍗',
    'Fish & Seafood': '🐟',
    'Herbs & Spices': '🌿',
    'Beverages': '🥤',
    'Snacks': '🥜',
    'Other': '📦',
  };

  static const Map<String, String> categoryColors = {
    'Fruits': '#FF6B6B',
    'Vegetables': '#4ECDC4',
    'Grains & Cereals': '#FFE66D',
    'Dairy & Eggs': '#A8E6CF',
    'Meat & Poultry': '#FF8E53',
    'Fish & Seafood': '#4DABF7',
    'Herbs & Spices': '#51CF66',
    'Beverages': '#845EC2',
    'Snacks': '#F39C12',
    'Other': '#95A5A6',
  };

  // Helper methods
  static String getCategoryIcon(String category) {
    return categoryIcons[category] ?? '📦';
  }

  static String getCategoryColor(String category) {
    return categoryColors[category] ?? '#95A5A6';
  }

  static List<String> getSubCategories(String category) {
    return subCategories[category] ?? ['Other'];
  }

  static bool isValidCategory(String category) {
    return categories.contains(category);
  }

  static bool isValidSubCategory(String category, String subCategory) {
    final subs = subCategories[category];
    return subs != null && subs.contains(subCategory);
  }

  // Search functionality
  static List<String> searchCategories(String query) {
    if (query.isEmpty) return categories;
    
    return categories.where((category) =>
      category.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  static List<String> getRecommendedCategories() {
    // Return most commonly used categories
    return [
      'Fruits',
      'Vegetables',
      'Grains & Cereals',
      'Dairy & Eggs',
    ];
  }

  // Category statistics helpers
  static Map<String, int> getCategoryStats(List<Map<String, dynamic>> products) {
    final stats = <String, int>{};
    
    for (final category in categories) {
      stats[category] = 0;
    }
    
    for (final product in products) {
      final category = product['category'] as String?;
      if (category != null && stats.containsKey(category)) {
        stats[category] = stats[category]! + 1;
      }
    }
    
    return stats;
  }

  // Get default category
  static String getDefaultCategory() {
    return categories.first; // Returns 'Fruits'
  }
} 