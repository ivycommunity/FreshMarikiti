class ConnectorOrder {
  final String id;
  final String customerId;
  final String customerName;
  final List<OrderItem> items;
  final String status;
  final DateTime createdAt;
  final String deliveryAddress;
  final double totalAmount;

  ConnectorOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.deliveryAddress,
    required this.totalAmount,
  });

  factory ConnectorOrder.fromJson(Map<String, dynamic> json) {
    return ConnectorOrder(
      id: json['_id'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      deliveryAddress: json['deliveryAddress'],
      totalAmount: json['totalAmount'].toDouble(),
    );
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'],
      productName: json['productName'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
    );
  }
}

class WasteCollectionTask {
  final String id;
  final String vendorId;
  final String vendorName;
  final String status;
  final DateTime scheduledDate;
  final String location;
  final String wasteType;
  final double estimatedWeight;

  WasteCollectionTask({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.status,
    required this.scheduledDate,
    required this.location,
    required this.wasteType,
    required this.estimatedWeight,
  });

  factory WasteCollectionTask.fromJson(Map<String, dynamic> json) {
    return WasteCollectionTask(
      id: json['_id'],
      vendorId: json['vendorId'],
      vendorName: json['vendorName'],
      status: json['status'],
      scheduledDate: DateTime.parse(json['scheduledDate']),
      location: json['location'],
      wasteType: json['wasteType'],
      estimatedWeight: json['estimatedWeight'].toDouble(),
    );
  }
}

class EcoPointsHistory {
  final String id;
  final String vendorId;
  final String vendorName;
  final int points;
  final String action;
  final DateTime date;
  final String description;

  EcoPointsHistory({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.points,
    required this.action,
    required this.date,
    required this.description,
  });

  factory EcoPointsHistory.fromJson(Map<String, dynamic> json) {
    return EcoPointsHistory(
      id: json['_id'],
      vendorId: json['vendorId'],
      vendorName: json['vendorName'],
      points: json['points'],
      action: json['action'],
      date: DateTime.parse(json['date']),
      description: json['description'],
    );
  }
}

class ConnectorProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String status;
  final int totalOrdersProcessed;
  final int totalWasteCollected;
  final double rating;

  ConnectorProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.totalOrdersProcessed,
    required this.totalWasteCollected,
    required this.rating,
  });

  factory ConnectorProfile.fromJson(Map<String, dynamic> json) {
    return ConnectorProfile(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      status: json['status'],
      totalOrdersProcessed: json['totalOrdersProcessed'],
      totalWasteCollected: json['totalWasteCollected'],
      rating: json['rating'].toDouble(),
    );
  }
}

class ConnectorStats {
  final int totalOrders;
  final int activeOrders;
  final int completedOrders;
  final int pendingWasteCollections;
  final int completedWasteCollections;
  final double totalEcoPointsAwarded;

  ConnectorStats({
    required this.totalOrders,
    required this.activeOrders,
    required this.completedOrders,
    required this.pendingWasteCollections,
    required this.completedWasteCollections,
    required this.totalEcoPointsAwarded,
  });

  factory ConnectorStats.fromJson(Map<String, dynamic> json) {
    return ConnectorStats(
      totalOrders: json['totalOrders'],
      activeOrders: json['activeOrders'],
      completedOrders: json['completedOrders'],
      pendingWasteCollections: json['pendingWasteCollections'],
      completedWasteCollections: json['completedWasteCollections'],
      totalEcoPointsAwarded: json['totalEcoPointsAwarded'].toDouble(),
    );
  }
} 