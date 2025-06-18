import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';
import 'logger_service.dart';

class LocationService {
  static StreamSubscription<Position>? _positionStream;
  static Position? _currentPosition;
  static bool _isTracking = false;
  static String? _currentTrackingId;
  
  // Location update listeners
  static final Map<String, Function> _locationListeners = {};
  static final List<Map<String, dynamic>> _locationHistory = [];
  
  // Delivery tracking
  static final Map<String, Map<String, dynamic>> _activeDeliveries = {};
  static final Map<String, List<Map<String, dynamic>>> _deliveryRoutes = {};
  
  // Geofencing
  static final List<Map<String, dynamic>> _geofences = [];
  static final Set<String> _activeGeofences = {};
  
  // Route optimization
  static Timer? _routeOptimizationTimer;
  static const Duration _optimizationInterval = Duration(minutes: 5);

  // Initialize location services with comprehensive permissions
  static Future<Map<String, dynamic>> initialize() async {
    try {
      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {
          'success': false,
          'error': 'Location services are disabled',
          'action': 'enable_location_services',
        };
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {
            'success': false,
            'error': 'Location permissions are denied',
            'action': 'request_permissions',
          };
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {
          'success': false,
          'error': 'Location permissions are permanently denied',
          'action': 'open_app_settings',
        };
      }

      // Get initial position
      await _getCurrentPosition();
      
      // Load user geofences
      await _loadUserGeofences();
      
      LoggerService.info('Location service initialized', tag: 'LocationService');
      return {'success': true, 'position': _currentPosition};
    } catch (e) {
      LoggerService.error('Failed to initialize location service', tag: 'LocationService', error: e);
      return {
        'success': false,
        'error': 'Location initialization failed: $e',
      };
    }
  }

  // Get current location for navigation
  Future<Position> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      _currentPosition = position;
      LoggerService.info('Current location retrieved for navigation', tag: 'LocationService');
      return position;
    } catch (e) {
      LoggerService.error('Failed to get current location', tag: 'LocationService', error: e);
      rethrow;
    }
  }

  // Get position stream for real-time navigation
  Stream<Position> getPositionStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // Update every 1 meter for navigation
      timeLimit: Duration(seconds: 5),
    );

    return Geolocator.getPositionStream(
      locationSettings: locationSettings,
    );
  }

  // Get current position with enhanced accuracy
  static Future<Position?> getCurrentPosition({bool highAccuracy = true}) async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      
      LoggerService.info('Current position updated', tag: 'LocationService');
      return _currentPosition;
    } catch (e) {
      LoggerService.error('Failed to get current position', tag: 'LocationService', error: e);
      return null;
    }
  }

  // Start real-time location tracking for deliveries
  static Future<bool> startDeliveryTracking({
    required String deliveryId,
    String? driverId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (_isTracking) {
        await stopTracking();
      }

      _currentTrackingId = deliveryId;
      _isTracking = true;
      
      // Configure location settings
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
        timeLimit: Duration(seconds: 5),
      );

      // Start position stream
      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) => _handleLocationUpdate(position, deliveryId),
        onError: (error) => _handleLocationError(error),
      );

      // Start route optimization
      _startRouteOptimization(deliveryId);
      
      // Initialize delivery tracking
      _activeDeliveries[deliveryId] = {
        'id': deliveryId,
        'driverId': driverId,
        'startTime': DateTime.now().toIso8601String(),
        'startLocation': _currentPosition != null ? {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
        } : null,
        'metadata': metadata ?? {},
        'status': 'tracking',
      };

      LoggerService.info('Delivery tracking started for $deliveryId', tag: 'LocationService');
      return true;
    } catch (e) {
      LoggerService.error('Failed to start delivery tracking', tag: 'LocationService', error: e);
      return false;
    }
  }

  // Stop location tracking
  static Future<void> stopTracking() async {
    try {
      await _positionStream?.cancel();
      _positionStream = null;
      _isTracking = false;
      
      // Stop route optimization
      _routeOptimizationTimer?.cancel();
      _routeOptimizationTimer = null;
      
      // Finalize active delivery
      if (_currentTrackingId != null) {
        final delivery = _activeDeliveries[_currentTrackingId!];
        if (delivery != null) {
          delivery['endTime'] = DateTime.now().toIso8601String();
          delivery['status'] = 'completed';
          
          // Save delivery data
          await _saveDeliveryData(_currentTrackingId!, delivery);
        }
        _currentTrackingId = null;
      }
      
      LoggerService.info('Location tracking stopped', tag: 'LocationService');
    } catch (e) {
      LoggerService.error('Failed to stop tracking', tag: 'LocationService', error: e);
    }
  }

  // Get real-time delivery tracking information
  static Future<Map<String, dynamic>> getDeliveryTracking(String deliveryId) async {
    try {
      final response = await ApiService.get('/deliveries/$deliveryId/tracking');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'tracking': data['tracking'],
          'currentLocation': data['currentLocation'],
          'estimatedArrival': data['estimatedArrival'],
          'route': data['route'] ?? [],
          'milestones': data['milestones'] ?? [],
        };
      } else {
        throw Exception('Failed to get tracking: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to get delivery tracking', tag: 'LocationService', error: e);
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Calculate delivery cost based on distance
  static Future<Map<String, dynamic>> calculateDeliveryCost({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String deliveryType = 'standard',
  }) async {
    try {
      final response = await ApiService.post('/deliveries/calculate-cost', {
        'startLocation': {'latitude': startLat, 'longitude': startLng},
        'endLocation': {'latitude': endLat, 'longitude': endLng},
        'deliveryType': deliveryType,
      });
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to calculate cost: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Route calculation failed', tag: 'LocationService', error: e);
      
      // Fallback to Haversine formula
      final distance = _calculateHaversineDistance(startLat, startLng, endLat, endLng);
      return {
        'success': true,
        'distance': distance,
        'cost': _calculateFallbackCost(distance, deliveryType),
        'estimatedTime': _estimateDeliveryTime(distance),
        'fallback': true,
      };
    }
  }

  // Calculate distance using Haversine formula
  static double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  static double _calculateFallbackCost(double distance, String deliveryType) {
    double baseCost = 50.0; // KSH 50 base cost
    double perKmRate = deliveryType == 'express' ? 20.0 : 15.0;
    return baseCost + (distance * perKmRate);
  }

  static int _estimateDeliveryTime(double distance) {
    // Estimate in minutes based on average speed
    double averageSpeed = 25.0; // km/h
    return ((distance / averageSpeed) * 60).round();
  }

  // Get address from coordinates
  static Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final response = await ApiService.get('/geocode/reverse?lat=$latitude&lng=$longitude');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['address'] ?? 'Unknown location';
      }
      
      // Fallback to local geocoding
      return 'Location at ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    } catch (e) {
      LoggerService.error('Failed to get address', tag: 'LocationService', error: e);
      return 'Location unavailable';
    }
  }

  // Private helper methods
  static Future<void> _getCurrentPosition() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      LoggerService.error('Failed to get initial position', tag: 'LocationService', error: e);
    }
  }

  static void _handleLocationUpdate(Position position, String deliveryId) {
    _currentPosition = position;
    _locationHistory.add({
      'timestamp': DateTime.now().toIso8601String(),
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'deliveryId': deliveryId,
    });

    // Update delivery tracking
    if (_activeDeliveries.containsKey(deliveryId)) {
      _activeDeliveries[deliveryId]!['currentLocation'] = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }

    _notifyListeners('location_update', {
      'position': position,
      'deliveryId': deliveryId,
    });

    // Send to backend
    _sendLocationUpdate(position, deliveryId);
  }

  static void _handleLocationError(dynamic error) {
    LoggerService.error('Location stream error', tag: 'LocationService', error: error);
    _notifyListeners('location_error', error);
  }

  static Future<void> _sendLocationUpdate(Position position, String deliveryId) async {
    try {
      await ApiService.post('/deliveries/$deliveryId/location', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      LoggerService.error('Failed to send location update', tag: 'LocationService', error: e);
    }
  }

  static void _notifyListeners(String event, dynamic data) {
    for (final listener in _locationListeners.values) {
      try {
        listener(event, data);
      } catch (e) {
        LoggerService.error('Location event listener error', tag: 'LocationService', error: e);
      }
    }
  }

  static void _startRouteOptimization(String deliveryId) {
    _routeOptimizationTimer = Timer.periodic(_optimizationInterval, (timer) async {
      try {
        // Optimize route based on current location and traffic
        await _optimizeRoute(deliveryId);
      } catch (e) {
        LoggerService.error('Route optimization error', tag: 'LocationService', error: e);
      }
    });
  }

  static Future<void> _optimizeRoute(String deliveryId) async {
    // Implementation for route optimization
  }

  static Future<void> _loadUserGeofences() async {
    try {
      final response = await ApiService.get('/user/geofences');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _geofences.clear();
        _geofences.addAll(List<Map<String, dynamic>>.from(data['geofences'] ?? []));
      }
    } catch (e) {
      LoggerService.error('Failed to load user geofences', tag: 'LocationService', error: e);
    }
  }

  static Future<void> _saveDeliveryData(String deliveryId, Map<String, dynamic> deliveryData) async {
    try {
      await ApiService.post('/deliveries/$deliveryId/complete', {
        'deliveryData': deliveryData,
        'locationHistory': _locationHistory.where((loc) => loc['deliveryId'] == deliveryId).toList(),
      });
    } catch (e) {
      LoggerService.error('Failed to save delivery data', tag: 'LocationService', error: e);
    }
  }

  // Public utility methods
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return _calculateHaversineDistance(lat1, lon1, lat2, lon2);
  }

  static bool get isTracking => _isTracking;
  static Position? get currentPosition => _currentPosition;
  static String? get currentTrackingId => _currentTrackingId;

  // Cleanup
  static void dispose() {
    _positionStream?.cancel();
    _routeOptimizationTimer?.cancel();
    _locationListeners.clear();
    _locationHistory.clear();
    _activeDeliveries.clear();
    _deliveryRoutes.clear();
    _geofences.clear();
    _activeGeofences.clear();
    LoggerService.info('Location service disposed', tag: 'LocationService');
  }
} 