import 'package:flutter/material.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'dart:async';

class LocationProvider with ChangeNotifier {
  // Current location
  Map<String, double>? _currentLocation;
  String? _currentAddress;
  
  // Location tracking
  bool _isTrackingEnabled = false;
  bool _isLocationServiceEnabled = false;
  bool _hasLocationPermission = false;
  
  // Loading states
  bool _isLoading = false;
  bool _isGettingLocation = false;
  String? _error;
  
  // Real-time tracking
  Timer? _locationTimer;
  StreamSubscription? _locationStream;
  
  // Delivery tracking
  final Map<String, Map<String, double>> _deliveryLocations = {};
  final Map<String, List<Map<String, double>>> _deliveryRoutes = {};

  // Address management
  List<Map<String, dynamic>> _savedAddresses = [];
  String? _defaultAddressId;
  bool _isLoadingAddresses = false;
  String? _addressError;

  // Getters
  Map<String, double>? get currentLocation => _currentLocation;
  String? get currentAddress => _currentAddress;
  
  bool get isTrackingEnabled => _isTrackingEnabled;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;
  bool get hasLocationPermission => _hasLocationPermission;
  
  bool get isLoading => _isLoading || _isLoadingAddresses;
  bool get isGettingLocation => _isGettingLocation;
  String? get error => _error ?? _addressError;
  
  Map<String, Map<String, double>> get deliveryLocations => Map.unmodifiable(_deliveryLocations);
  Map<String, List<Map<String, double>>> get deliveryRoutes => Map.unmodifiable(_deliveryRoutes);

  // Address management getters
  List<Map<String, dynamic>> get savedAddresses => List.unmodifiable(_savedAddresses);
  String? get defaultAddressId => _defaultAddressId;
  Map<String, dynamic>? get defaultAddress => _savedAddresses.firstWhere(
    (address) => address['id'] == _defaultAddressId,
    orElse: () => {},
  );

  // Initialize provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check location service status
      await checkLocationServiceStatus();
      
      // Request permissions if needed
      if (_isLocationServiceEnabled) {
        await requestLocationPermission();
      }
      
      // Get current location if permissions granted
      if (_hasLocationPermission) {
        await getCurrentLocation();
      }
      
      // Load saved addresses
      await loadSavedAddresses();
      
      _error = null;
    } catch (e) {
      LoggerService.error('Failed to initialize location services', error: e);
      _error = 'Failed to initialize location services: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if location services are enabled
  Future<void> checkLocationServiceStatus() async {
    try {
      // For now, assume location services are available
      _isLocationServiceEnabled = true;
      notifyListeners();
    } catch (e) {
      LoggerService.error('Failed to check location service status', error: e);
      _isLocationServiceEnabled = false;
      notifyListeners();
    }
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      // For now, assume permission is granted
      _hasLocationPermission = true;
      notifyListeners();
      return true;
    } catch (e) {
      LoggerService.error('Failed to request location permission', error: e);
      _hasLocationPermission = false;
      _error = 'Location permission denied';
      notifyListeners();
      return false;
    }
  }

  // Get current location
  Future<bool> getCurrentLocation() async {
    if (!_hasLocationPermission) {
      _error = 'Location permission not granted';
      notifyListeners();
      return false;
    }

    _isGettingLocation = true;
    notifyListeners();

    try {
      // For now, use demo location (Nairobi, Kenya)
      _currentLocation = {
        'latitude': -1.2921,
        'longitude': 36.8219,
      };
      
      // Get address from coordinates
      await _getAddressFromCoordinates(_currentLocation!);
      
      _error = null;
      return true;
    } catch (e) {
      LoggerService.error('Failed to get current location', error: e);
      _error = 'Failed to get location: ${e.toString()}';
      return false;
    } finally {
      _isGettingLocation = false;
      notifyListeners();
    }
  }

  // Address Management Methods

  // Load saved addresses
  Future<void> loadSavedAddresses() async {
    _isLoadingAddresses = true;
    _addressError = null;
    notifyListeners();

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Demo saved addresses - in real app, fetch from backend
      _savedAddresses = [
        {
          'id': 'addr_001',
          'type': 'home',
          'label': 'Home',
          'address': 'Westlands, Nairobi, Kenya',
          'details': 'Apartment 4B, Green Valley Complex',
          'isDefault': true,
          'coordinates': {'latitude': -1.2669, 'longitude': 36.8086},
          'createdAt': DateTime.now().subtract(const Duration(days: 30)),
        },
        {
          'id': 'addr_002',
          'type': 'work',
          'label': 'Office',
          'address': 'CBD, Nairobi, Kenya',
          'details': 'Kencom House, 5th Floor',
          'isDefault': false,
          'coordinates': {'latitude': -1.2864, 'longitude': 36.8172},
          'createdAt': DateTime.now().subtract(const Duration(days: 15)),
        },
        {
          'id': 'addr_003',
          'type': 'other',
          'label': 'Gym',
          'address': 'Kilimani, Nairobi, Kenya',
          'details': 'Fitness Center Plaza',
          'isDefault': false,
          'coordinates': {'latitude': -1.2921, 'longitude': 36.7846},
          'createdAt': DateTime.now().subtract(const Duration(days: 7)),
        },
      ];

      // Set default address ID
      final defaultAddr = _savedAddresses.firstWhere(
        (addr) => addr['isDefault'] == true,
        orElse: () => {},
      );
      _defaultAddressId = defaultAddr['id'];

      LoggerService.info('Loaded ${_savedAddresses.length} saved addresses', tag: 'LocationProvider');
    } catch (e) {
      LoggerService.error('Failed to load saved addresses', error: e);
      _addressError = 'Failed to load addresses: ${e.toString()}';
    } finally {
      _isLoadingAddresses = false;
      notifyListeners();
    }
  }

  // Save new address
  Future<void> saveAddress(Map<String, dynamic> addressData) async {
    try {
      // Add timestamp and ID if not provided
      final address = {
        ...addressData,
        'id': addressData['id'] ?? 'addr_${DateTime.now().millisecondsSinceEpoch}',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      // If this is set as default, remove default from others
      if (address['isDefault'] == true) {
        for (var addr in _savedAddresses) {
          addr['isDefault'] = false;
        }
        _defaultAddressId = address['id'];
      }

      _savedAddresses.add(address);
      
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 300));
      
      notifyListeners();
      LoggerService.info('Address saved: ${address['label']}', tag: 'LocationProvider');
    } catch (e) {
      LoggerService.error('Failed to save address', error: e);
      throw Exception('Failed to save address: ${e.toString()}');
    }
  }

  // Update existing address
  Future<void> updateAddress(Map<String, dynamic> updatedData) async {
    try {
      final addressId = updatedData['id'];
      final addressIndex = _savedAddresses.indexWhere((addr) => addr['id'] == addressId);
      
      if (addressIndex == -1) {
        throw Exception('Address not found');
      }

      // Update the address
      final updatedAddress = {
        ..._savedAddresses[addressIndex],
        ...updatedData,
        'updatedAt': DateTime.now(),
      };

      // If this is set as default, remove default from others
      if (updatedAddress['isDefault'] == true && _defaultAddressId != addressId) {
        for (var addr in _savedAddresses) {
          if (addr['id'] != addressId) {
            addr['isDefault'] = false;
          }
        }
        _defaultAddressId = addressId;
      }

      _savedAddresses[addressIndex] = updatedAddress;
      
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 300));
      
      notifyListeners();
      LoggerService.info('Address updated: ${updatedAddress['label']}', tag: 'LocationProvider');
    } catch (e) {
      LoggerService.error('Failed to update address', error: e);
      throw Exception('Failed to update address: ${e.toString()}');
    }
  }

  // Delete address
  Future<void> deleteAddress(String addressId) async {
    try {
      final addressIndex = _savedAddresses.indexWhere((addr) => addr['id'] == addressId);
      
      if (addressIndex == -1) {
        throw Exception('Address not found');
      }

      final address = _savedAddresses[addressIndex];
      _savedAddresses.removeAt(addressIndex);

      // If this was the default address, set another as default
      if (_defaultAddressId == addressId) {
        _defaultAddressId = null;
        if (_savedAddresses.isNotEmpty) {
          _savedAddresses.first['isDefault'] = true;
          _defaultAddressId = _savedAddresses.first['id'];
        }
      }
      
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 300));
      
      notifyListeners();
      LoggerService.info('Address deleted: ${address['label']}', tag: 'LocationProvider');
    } catch (e) {
      LoggerService.error('Failed to delete address', error: e);
      throw Exception('Failed to delete address: ${e.toString()}');
    }
  }

  // Set default address
  Future<void> setDefaultAddress(String addressId) async {
    try {
      final addressExists = _savedAddresses.any((addr) => addr['id'] == addressId);
      
      if (!addressExists) {
        throw Exception('Address not found');
      }

      // Remove default from all addresses
      for (var addr in _savedAddresses) {
        addr['isDefault'] = addr['id'] == addressId;
      }

      _defaultAddressId = addressId;
      
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 300));
      
      notifyListeners();
      LoggerService.info('Default address set: $addressId', tag: 'LocationProvider');
    } catch (e) {
      LoggerService.error('Failed to set default address', error: e);
      throw Exception('Failed to set default address: ${e.toString()}');
    }
  }

  // Set current address (for delivery)
  void setCurrentAddress(String address) {
    _currentAddress = address;
    notifyListeners();
    LoggerService.info('Current address set: $address', tag: 'LocationProvider');
  }

  // Get address by ID
  Map<String, dynamic>? getAddressById(String addressId) {
    try {
      return _savedAddresses.firstWhere((addr) => addr['id'] == addressId);
    } catch (e) {
      return null;
    }
  }

  // Get addresses by type
  List<Map<String, dynamic>> getAddressesByType(String type) {
    return _savedAddresses.where((addr) => addr['type'] == type).toList();
  }

  // Search addresses
  List<Map<String, dynamic>> searchAddresses(String query) {
    final lowerQuery = query.toLowerCase();
    return _savedAddresses.where((addr) {
      final label = (addr['label'] as String? ?? '').toLowerCase();
      final address = (addr['address'] as String? ?? '').toLowerCase();
      final details = (addr['details'] as String? ?? '').toLowerCase();
      
      return label.contains(lowerQuery) || 
             address.contains(lowerQuery) || 
             details.contains(lowerQuery);
    }).toList();
  }

  // Start location tracking
  Future<void> startLocationTracking() async {
    if (!_hasLocationPermission) {
      await requestLocationPermission();
      if (!_hasLocationPermission) return;
    }

    _isTrackingEnabled = true;
    notifyListeners();

    // Start periodic location updates
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => getCurrentLocation(),
    );
  }

  // Stop location tracking
  void stopLocationTracking() {
    _isTrackingEnabled = false;
    _locationTimer?.cancel();
    notifyListeners();
  }

  // Track delivery location
  void trackDeliveryLocation(String orderId, Map<String, double> location) {
    _deliveryLocations[orderId] = location;
    
    // Add to route if it doesn't exist
    if (!_deliveryRoutes.containsKey(orderId)) {
      _deliveryRoutes[orderId] = [];
    }
    
    // Add location to route
    _deliveryRoutes[orderId]!.add(location);
    
    notifyListeners();
  }

  // Stop tracking delivery
  void stopTrackingDelivery(String orderId) {
    _deliveryLocations.remove(orderId);
    _deliveryRoutes.remove(orderId);
    notifyListeners();
  }

  // Calculate distance between two points
  double calculateDistance(
    Map<String, double> point1,
    Map<String, double> point2,
  ) {
    final lat1 = point1['latitude']!;
    final lon1 = point1['longitude']!;
    final lat2 = point2['latitude']!;
    final lon2 = point2['longitude']!;
    
    // Simple distance calculation (not accurate for long distances)
    final deltaLat = lat2 - lat1;
    final deltaLon = lon2 - lon1;
    
    return (deltaLat * deltaLat + deltaLon * deltaLon) * 111.32; // Rough km conversion
  }

  // Get estimated delivery time
  Duration getEstimatedDeliveryTime(Map<String, double> destination) {
    if (_currentLocation == null) {
      return const Duration(hours: 1); // Default estimate
    }
    
    final distance = calculateDistance(_currentLocation!, destination);
    
    // Estimate based on distance (assuming 30 km/h average speed)
    final hours = distance / 30;
    return Duration(minutes: (hours * 60).round());
  }

  // Set delivery address
  Future<void> setDeliveryAddress(String address) async {
    try {
      // For now, just store the address
      // In a real app, you would geocode the address to get coordinates
      _currentAddress = address;
      notifyListeners();
    } catch (e) {
      LoggerService.error('Failed to set delivery address', error: e);
      _error = 'Failed to set address: ${e.toString()}';
      notifyListeners();
    }
  }

  // Get nearby vendors/locations
  List<Map<String, dynamic>> getNearbyLocations(double radiusKm) {
    if (_currentLocation == null) return [];
    
    // Demo nearby locations
    return [
      {
        'id': 'vendor_1',
        'name': 'Green Valley Farm',
        'type': 'vendor',
        'location': {'latitude': -1.2900, 'longitude': 36.8200},
        'distance': 2.5,
      },
      {
        'id': 'vendor_2',
        'name': 'Fresh Fruits Market',
        'type': 'vendor',
        'location': {'latitude': -1.2950, 'longitude': 36.8250},
        'distance': 3.8,
      },
      {
        'id': 'pickup_1',
        'name': 'Central Pickup Point',
        'type': 'pickup',
        'location': {'latitude': -1.2880, 'longitude': 36.8180},
        'distance': 1.2,
      },
    ];
  }

  // Clear error
  void clearError() {
    _error = null;
    _addressError = null;
    notifyListeners();
  }

  // Clear address error specifically
  void clearAddressError() {
    _addressError = null;
    notifyListeners();
  }

  // Private helper methods
  Future<void> _getAddressFromCoordinates(Map<String, double> coordinates) async {
    try {
      // For now, use a demo address
      _currentAddress = 'Nairobi, Kenya';
      notifyListeners();
    } catch (e) {
      LoggerService.error('Failed to get address from coordinates', error: e);
      _currentAddress = 'Unknown location';
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _locationStream?.cancel();
    super.dispose();
  }
} 