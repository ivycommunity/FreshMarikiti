import 'package:flutter/material.dart';

class WasteRequest {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String userLocation;
  final String wasteType;
  final double estimatedWeight;
  final String description;
  final DateTime requestedPickupDate;
  final String status;
  final int ecoPointsEstimate;
  final DateTime createdAt;
  final DateTime? completedAt;
  final double? actualWeight;
  final String? notes;

  WasteRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.userLocation,
    required this.wasteType,
    required this.estimatedWeight,
    required this.description,
    required this.requestedPickupDate,
    required this.status,
    required this.ecoPointsEstimate,
    required this.createdAt,
    this.completedAt,
    this.actualWeight,
    this.notes,
  });

  factory WasteRequest.fromJson(Map<String, dynamic> json) {
    return WasteRequest(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userPhone: json['userPhone'] ?? '',
      userLocation: json['userLocation'] ?? '',
      wasteType: json['wasteType'] ?? '',
      estimatedWeight: (json['estimatedWeight'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      requestedPickupDate: DateTime.parse(json['requestedPickupDate'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'pending',
      ecoPointsEstimate: json['ecoPointsEstimate'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      actualWeight: json['actualWeight']?.toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'userLocation': userLocation,
      'wasteType': wasteType,
      'estimatedWeight': estimatedWeight,
      'description': description,
      'requestedPickupDate': requestedPickupDate.toIso8601String(),
      'status': status,
      'ecoPointsEstimate': ecoPointsEstimate,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'actualWeight': actualWeight,
      'notes': notes,
    };
  }

  // Helper method to get waste type color
  static Color getWasteTypeColor(String wasteType) {
    switch (wasteType.toLowerCase()) {
      case 'organic':
        return Colors.green;
      case 'recyclable':
        return Colors.blue;
      case 'mixed':
        return Colors.orange;
      case 'hazardous':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Calculate eco points based on weight and type
  static int calculateEcoPoints(double weight, String wasteType) {
    const pointsPerKg = {
      'organic': 5,
      'recyclable': 8,
      'mixed': 4,
      'hazardous': 10,
    };
    
    final basePoints = pointsPerKg[wasteType.toLowerCase()] ?? 4;
    return (weight * basePoints).round();
  }
} 