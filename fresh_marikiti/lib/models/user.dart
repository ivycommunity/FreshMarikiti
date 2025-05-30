import 'package:flutter/foundation.dart';

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
  final String phoneNumber;
  final UserRole role;
  final String? imageUrl;
  final Map<String, dynamic>? additionalData;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.imageUrl,
    this.additionalData,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      role: _parseRole(json['role']),
      imageUrl: json['imageUrl'],
      additionalData: json['additionalData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role.toString().split('.').last,
      'imageUrl': imageUrl,
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

  bool get isVendor => role == UserRole.vendor || role == UserRole.vendorAdmin;
  bool get isAdmin => role == UserRole.admin;
  bool get isRider => role == UserRole.rider;
  bool get isConnector => role == UserRole.connector;
  bool get isCustomer => role == UserRole.customer;
} 