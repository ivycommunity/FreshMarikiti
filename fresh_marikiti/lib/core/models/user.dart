enum UserRole {
  customer,
  vendor,
  rider,
  connector,
  admin,
  vendorAdmin
}

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final int ecoPoints;
  final int totalEcoPointsEarned;
  final int totalEcoPointsRedeemed;
  final double walletBalance;
  final bool isActive;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? imageUrl;
  final String? profilePicture;
  final double rating;
  final int totalRatings;
  final String? location;
  final Map<String, double>? coordinates;
  final Map<String, dynamic>? additionalData;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.ecoPoints = 0,
    this.totalEcoPointsEarned = 0,
    this.totalEcoPointsRedeemed = 0,
    this.walletBalance = 0.0,
    this.isActive = true,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
    this.imageUrl,
    this.profilePicture,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.location,
    this.coordinates,
    this.additionalData,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    Map<String, double>? coords;
    if (json['coordinates'] != null) {
      final coordsData = json['coordinates'] as Map<String, dynamic>;
      coords = {
        'latitude': (coordsData['latitude'] as num?)?.toDouble() ?? 0.0,
        'longitude': (coordsData['longitude'] as num?)?.toDouble() ?? 0.0,
      };
    }

    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: _parseRole(json['role'] ?? 'customer'),
      ecoPoints: json['ecoPoints']?.toInt() ?? 0,
      totalEcoPointsEarned: json['totalEcoPointsEarned']?.toInt() ?? 0,
      totalEcoPointsRedeemed: json['totalEcoPointsRedeemed']?.toInt() ?? 0,
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] ?? true,
      fcmToken: json['fcmToken'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      imageUrl: json['imageUrl'],
      profilePicture: json['profilePicture'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['totalRatings']?.toInt() ?? 0,
      location: json['location'],
      coordinates: coords,
      additionalData: json['additionalData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.toString().split('.').last,
      'ecoPoints': ecoPoints,
      'totalEcoPointsEarned': totalEcoPointsEarned,
      'totalEcoPointsRedeemed': totalEcoPointsRedeemed,
      'walletBalance': walletBalance,
      'isActive': isActive,
      'fcmToken': fcmToken,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'imageUrl': imageUrl,
      'profilePicture': profilePicture,
      'rating': rating,
      'totalRatings': totalRatings,
      'location': location,
      'coordinates': coordinates,
      'additionalData': additionalData,
    };
  }

  static UserRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'customer':
        return UserRole.customer;
      case 'vendor':
        return UserRole.vendor;
      case 'rider':
        return UserRole.rider;
      case 'connector':
        return UserRole.connector;
      case 'admin':
        return UserRole.admin;
      case 'vendoradmin':
        return UserRole.vendorAdmin;
      default:
        return UserRole.customer;
    }
  }

  // Helper methods for role checks
  bool get isCustomer => role == UserRole.customer;
  bool get isVendor => role == UserRole.vendor;
  bool get isRider => role == UserRole.rider;
  bool get isConnector => role == UserRole.connector;
  bool get isAdmin => role == UserRole.admin;
  bool get isVendorAdmin => role == UserRole.vendorAdmin;

  // Eco points helpers
  bool get hasEcoPoints => ecoPoints > 0;
  double get ecoPointsRedemptionRate => totalEcoPointsEarned > 0 
      ? (totalEcoPointsRedeemed / totalEcoPointsEarned) * 100 
      : 0.0;
  
  // Rating helpers
  bool get hasRating => totalRatings > 0;
  String get ratingDisplay => hasRating ? rating.toStringAsFixed(1) : 'New';
  
  // Location helpers
  bool get hasLocation => location != null && location!.isNotEmpty;
  bool get hasCoordinates => coordinates != null && 
      coordinates!.containsKey('latitude') && 
      coordinates!.containsKey('longitude');

  // Copy with method for immutable updates
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    int? ecoPoints,
    int? totalEcoPointsEarned,
    int? totalEcoPointsRedeemed,
    double? walletBalance,
    bool? isActive,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
    String? profilePicture,
    double? rating,
    int? totalRatings,
    String? location,
    Map<String, double>? coordinates,
    Map<String, dynamic>? additionalData,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      ecoPoints: ecoPoints ?? this.ecoPoints,
      totalEcoPointsEarned: totalEcoPointsEarned ?? this.totalEcoPointsEarned,
      totalEcoPointsRedeemed: totalEcoPointsRedeemed ?? this.totalEcoPointsRedeemed,
      walletBalance: walletBalance ?? this.walletBalance,
      isActive: isActive ?? this.isActive,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      profilePicture: profilePicture ?? this.profilePicture,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      location: location ?? this.location,
      coordinates: coordinates ?? this.coordinates,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  // Compare users for equality
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          phone == other.phone &&
          role == other.role &&
          ecoPoints == other.ecoPoints &&
          isActive == other.isActive &&
          fcmToken == other.fcmToken;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      email.hashCode ^
      phone.hashCode ^
      role.hashCode ^
      ecoPoints.hashCode ^
      isActive.hashCode ^
      fcmToken.hashCode;
}