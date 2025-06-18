import 'package:fresh_marikiti/core/models/product.dart';

class CartItem {
  final String id;
  final Product product;
  final int quantity;
  final DateTime addedAt;
  final Map<String, dynamic>? customizations;
  final String? notes;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.addedAt,
    this.customizations,
    this.notes,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      product: Product.fromJson(json['product'] ?? {}),
      quantity: json['quantity'] ?? 1,
      addedAt: DateTime.parse(json['addedAt'] ?? DateTime.now().toIso8601String()),
      customizations: json['customizations'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
      'customizations': customizations,
      'notes': notes,
    };
  }

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    DateTime? addedAt,
    Map<String, dynamic>? customizations,
    String? notes,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
      customizations: customizations ?? this.customizations,
      notes: notes ?? this.notes,
    );
  }

  // Helper methods
  double get unitPrice => product.price;
  double get totalPrice => product.price * quantity;
  bool get isInStock => product.quantityAvailable >= quantity;
  bool get hasCustomizations => customizations != null && customizations!.isNotEmpty;
  bool get hasNotes => notes != null && notes!.isNotEmpty;

  String get stockStatus {
    if (product.quantityAvailable >= quantity) {
      return 'In Stock';
    } else if (product.quantityAvailable > 0) {
      return 'Limited Stock';
    } else {
      return 'Out of Stock';
    }
  }

  // Time-based helpers
  String get timeInCart {
    final now = DateTime.now();
    final difference = now.difference(addedAt);
    
    if (difference.inMinutes < 1) {
      return 'Just added';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  bool get isRecentlyAdded => DateTime.now().difference(addedAt).inMinutes < 5;
}

class CartCoupon {
  final String id;
  final String code;
  final String title;
  final String description;
  final String type; // 'percentage', 'fixed', 'shipping'
  final double value;
  final double minimumAmount;
  final double? maximumDiscount;
  final DateTime validFrom;
  final DateTime validUntil;
  final bool isActive;
  final List<String> applicableCategories;
  final List<String> excludedProducts;
  final int usageLimit;
  final int usedCount;
  final bool isFirstTimeOnly;

  CartCoupon({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    this.minimumAmount = 0.0,
    this.maximumDiscount,
    required this.validFrom,
    required this.validUntil,
    this.isActive = true,
    this.applicableCategories = const [],
    this.excludedProducts = const [],
    this.usageLimit = 0,
    this.usedCount = 0,
    this.isFirstTimeOnly = false,
  });

  factory CartCoupon.fromJson(Map<String, dynamic> json) {
    return CartCoupon(
      id: json['_id'] ?? json['id'] ?? '',
      code: json['code'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'percentage',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      minimumAmount: (json['minimumAmount'] as num?)?.toDouble() ?? 0.0,
      maximumDiscount: (json['maximumDiscount'] as num?)?.toDouble(),
      validFrom: DateTime.parse(json['validFrom'] ?? DateTime.now().toIso8601String()),
      validUntil: DateTime.parse(json['validUntil'] ?? DateTime.now().add(const Duration(days: 30)).toIso8601String()),
      isActive: json['isActive'] ?? true,
      applicableCategories: List<String>.from(json['applicableCategories'] ?? []),
      excludedProducts: List<String>.from(json['excludedProducts'] ?? []),
      usageLimit: json['usageLimit'] ?? 0,
      usedCount: json['usedCount'] ?? 0,
      isFirstTimeOnly: json['isFirstTimeOnly'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'description': description,
      'type': type,
      'value': value,
      'minimumAmount': minimumAmount,
      'maximumDiscount': maximumDiscount,
      'validFrom': validFrom.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'isActive': isActive,
      'applicableCategories': applicableCategories,
      'excludedProducts': excludedProducts,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'isFirstTimeOnly': isFirstTimeOnly,
    };
  }

  CartCoupon copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    String? type,
    double? value,
    double? minimumAmount,
    double? maximumDiscount,
    DateTime? validFrom,
    DateTime? validUntil,
    bool? isActive,
    List<String>? applicableCategories,
    List<String>? excludedProducts,
    int? usageLimit,
    int? usedCount,
    bool? isFirstTimeOnly,
  }) {
    return CartCoupon(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      value: value ?? this.value,
      minimumAmount: minimumAmount ?? this.minimumAmount,
      maximumDiscount: maximumDiscount ?? this.maximumDiscount,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      isActive: isActive ?? this.isActive,
      applicableCategories: applicableCategories ?? this.applicableCategories,
      excludedProducts: excludedProducts ?? this.excludedProducts,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
      isFirstTimeOnly: isFirstTimeOnly ?? this.isFirstTimeOnly,
    );
  }

  // Helper methods
  bool get isValid {
    final now = DateTime.now();
    return isActive && 
           now.isAfter(validFrom) && 
           now.isBefore(validUntil) &&
           (usageLimit == 0 || usedCount < usageLimit);
  }

  bool get isExpired => DateTime.now().isAfter(validUntil);
  bool get isNotYetActive => DateTime.now().isBefore(validFrom);
  bool get isUsageLimitReached => usageLimit > 0 && usedCount >= usageLimit;

  String get validityStatus {
    if (isExpired) return 'Expired';
    if (isNotYetActive) return 'Not yet active';
    if (isUsageLimitReached) return 'Usage limit reached';
    if (!isActive) return 'Inactive';
    return 'Valid';
  }

  String get timeUntilExpiry {
    final now = DateTime.now();
    final difference = validUntil.difference(now);
    
    if (difference.isNegative) return 'Expired';
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours left';
    } else {
      return '${difference.inMinutes} minutes left';
    }
  }

  // Calculate discount amount
  double getDiscountAmount(double subtotal, {List<CartItem>? cartItems}) {
    if (!isValid) return 0.0;
    if (subtotal < minimumAmount) return 0.0;

    // If category restrictions apply
    if (applicableCategories.isNotEmpty && cartItems != null) {
      final applicableAmount = cartItems
          .where((item) => applicableCategories.contains(item.product.category))
          .fold<double>(0.0, (sum, item) => sum + item.totalPrice);
      
      if (applicableAmount == 0) return 0.0;
      subtotal = applicableAmount;
    }

    // If product exclusions apply
    if (excludedProducts.isNotEmpty && cartItems != null) {
      final excludedAmount = cartItems
          .where((item) => excludedProducts.contains(item.product.id))
          .fold<double>(0.0, (sum, item) => sum + item.totalPrice);
      
      subtotal -= excludedAmount;
    }

    double discount = 0.0;

    switch (type) {
      case 'percentage':
        discount = subtotal * (value / 100);
        break;
      case 'fixed':
        discount = value;
        break;
      case 'shipping':
        // For shipping coupons, return the shipping fee as discount
        discount = value;
        break;
      default:
        discount = 0.0;
    }

    // Apply maximum discount limit if specified
    if (maximumDiscount != null && discount > maximumDiscount!) {
      discount = maximumDiscount!;
    }

    // Ensure discount doesn't exceed subtotal
    if (discount > subtotal) {
      discount = subtotal;
    }

    return discount;
  }

  // Check if coupon is applicable to cart
  bool isApplicableToCart(double cartTotal, {List<CartItem>? cartItems}) {
    // Check if coupon is valid
    if (!isValid) return false;
    
    // Check minimum amount
    if (cartTotal < minimumAmount) return false;
    
    // Check category restrictions if cart items provided
    if (cartItems != null && applicableCategories.isNotEmpty) {
      final cartCategories = cartItems.map((item) => item.product.category).toSet();
      final hasApplicableCategory = cartCategories.any((category) => 
          applicableCategories.contains(category));
      if (!hasApplicableCategory) return false;
    }
    
    // Check excluded products if cart items provided
    if (cartItems != null && excludedProducts.isNotEmpty) {
      final cartProductIds = cartItems.map((item) => item.product.id).toSet();
      final hasExcludedProduct = cartProductIds.any((productId) => 
          excludedProducts.contains(productId));
      if (hasExcludedProduct) return false;
    }
    
    return true;
  }

  // Get validation message for UI feedback
  String getValidationMessage(double cartTotal, {List<CartItem>? cartItems}) {
    if (!isActive) {
      return 'This coupon is inactive';
    }
    
    if (isExpired) {
      return 'This coupon has expired';
    }
    
    if (isNotYetActive) {
      return 'This coupon is not yet active';
    }
    
    if (isUsageLimitReached) {
      return 'This coupon has reached its usage limit';
    }
    
    if (cartTotal < minimumAmount) {
      return 'Minimum order amount of KES ${minimumAmount.toStringAsFixed(0)} required';
    }
    
    if (cartItems != null && applicableCategories.isNotEmpty) {
      final cartCategories = cartItems.map((item) => item.product.category).toSet();
      final hasApplicableCategory = cartCategories.any((category) => 
          applicableCategories.contains(category));
      if (!hasApplicableCategory) {
        return 'This coupon is only applicable to: ${applicableCategories.join(', ')}';
      }
    }
    
    if (cartItems != null && excludedProducts.isNotEmpty) {
      final cartProductIds = cartItems.map((item) => item.product.id).toSet();
      final hasExcludedProduct = cartProductIds.any((productId) => 
          excludedProducts.contains(productId));
      if (hasExcludedProduct) {
        return 'This coupon cannot be applied to some items in your cart';
      }
    }
    
    return 'Coupon applied successfully';
  }

  // Display helpers
  String get discountDisplay {
    switch (type) {
      case 'percentage':
        return '${value.toInt()}% OFF';
      case 'fixed':
        return 'KES ${value.toStringAsFixed(2)} OFF';
      case 'shipping':
        return 'FREE SHIPPING';
      default:
        return 'DISCOUNT';
    }
  }

  String get valueDisplay {
    switch (type) {
      case 'percentage':
        String display = '${value.toInt()}% off';
        if (maximumDiscount != null) {
          display += ' (max KES ${maximumDiscount!.toStringAsFixed(2)})';
        }
        return display;
      case 'fixed':
        return 'KES ${value.toStringAsFixed(2)} off';
      case 'shipping':
        return 'Free shipping';
      default:
        return 'Discount';
    }
  }

  String get minimumAmountDisplay {
    if (minimumAmount > 0) {
      return 'Minimum order: KES ${minimumAmount.toStringAsFixed(2)}';
    }
    return 'No minimum order';
  }

  // Usage statistics
  double get usagePercentage {
    if (usageLimit == 0) return 0.0;
    return (usedCount / usageLimit) * 100;
  }

  int get remainingUses {
    if (usageLimit == 0) return -1; // Unlimited
    return usageLimit - usedCount;
  }
}

// Cart summary model
class CartSummary {
  final int itemCount;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double tax;
  final double total;
  final String? appliedCouponCode;
  final List<String> warnings;

  CartSummary({
    required this.itemCount,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    this.tax = 0.0,
    required this.total,
    this.appliedCouponCode,
    this.warnings = const [],
  });

  factory CartSummary.calculate({
    required List<CartItem> items,
    required double deliveryFee,
    CartCoupon? appliedCoupon,
    double taxRate = 0.0,
  }) {
    final itemCount = items.fold<int>(0, (sum, item) => sum + item.quantity);
    final subtotal = items.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
    final discount = appliedCoupon?.getDiscountAmount(subtotal, cartItems: items) ?? 0.0;
    final tax = (subtotal - discount) * taxRate;
    final total = subtotal + deliveryFee + tax - discount;

    // Generate warnings
    final warnings = <String>[];
    for (final item in items) {
      if (!item.isInStock) {
        warnings.add('${item.product.name} is out of stock');
      } else if (item.product.quantityAvailable < item.quantity) {
        warnings.add('${item.product.name} has limited stock');
      }
    }

    return CartSummary(
      itemCount: itemCount,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      tax: tax,
      total: total,
      appliedCouponCode: appliedCoupon?.code,
      warnings: warnings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemCount': itemCount,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'tax': tax,
      'total': total,
      'appliedCouponCode': appliedCouponCode,
      'warnings': warnings,
    };
  }

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasDiscount => discount > 0;
  bool get hasTax => tax > 0;
  
  String get savingsDisplay {
    if (discount > 0) {
      return 'You saved KES ${discount.toStringAsFixed(2)}';
    }
    return '';
  }
} 