import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';

class TrackingService {
  static TrackingService? _instance;
  static TrackingService get instance => _instance ??= TrackingService._();
  
  TrackingService._();

  late socket_io.Socket _socket;
  final StreamController<Position> _positionController = StreamController<Position>.broadcast();
  final StreamController<Map<String, dynamic>> _orderUpdatesController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Position> get positionStream => _positionController.stream;
  Stream<Map<String, dynamic>> get orderUpdatesStream => _orderUpdatesController.stream;

  bool _isConnected = false;
  String? _currentOrderId;

  void initialize() {
    LoggerService.info('Initializing tracking service', tag: 'TrackingService');
    
    _socket = socket_io.io(ApiService.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.on('connect', (_) {
      LoggerService.info('Socket connected', tag: 'TrackingService');
      _isConnected = true;
    });

    _socket.on('disconnect', (_) {
      LoggerService.info('Socket disconnected', tag: 'TrackingService');
      _isConnected = false;
    });

    _socket.on('orderUpdate', (data) {
      LoggerService.debug('Received order update: $data', tag: 'TrackingService');
      _orderUpdatesController.add(data);
    });

    _socket.on('riderLocationUpdate', (data) {
      LoggerService.debug('Received rider location update: $data', tag: 'TrackingService');
      _orderUpdatesController.add(data);
    });
  }

  Future<void> startTracking(String orderId) async {
    try {
      _currentOrderId = orderId;
      
      if (!_isConnected) {
        _socket.connect();
      }
      
      _socket.emit('joinOrderRoom', orderId);
      
      // Start location tracking
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );
      
      Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) {
          _positionController.add(position);
          
          // Emit location to server if rider/connector
          if (_isConnected && _currentOrderId != null) {
            _socket.emit('updateLocation', {
              'orderId': _currentOrderId,
              'latitude': position.latitude,
              'longitude': position.longitude,
              'timestamp': position.timestamp.toIso8601String(),
            });
          }
        },
        onError: (error) {
          LoggerService.error('Location stream error', tag: 'TrackingService', error: error);
        },
      );

      // Also update location in API
      await _updateLocationInAPI(orderId);
      
    } catch (e) {
      LoggerService.error('Error starting tracking', tag: 'TrackingService', error: e);
    }
  }

  Future<void> _updateLocationInAPI(String orderId) async {
    try {
      final position = await Geolocator.getCurrentPosition();
      await ApiService.patch('/orders/$orderId/location', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': position.timestamp.toIso8601String(),
      });
    } catch (e) {
      LoggerService.error('Error updating location in API', tag: 'TrackingService', error: e);
    }
  }

  void stopTracking() {
    if (_currentOrderId != null) {
      _socket.emit('leaveOrderRoom', _currentOrderId);
    }
    _currentOrderId = null;
    
    if (_isConnected) {
      _socket.disconnect();
    }
  }

  Future<Map<String, dynamic>> getEstimatedDeliveryTime({
    required LatLng origin,
    required LatLng destination,
    String transportMode = 'driving',
  }) async {
    try {
      final response = await ApiService.post('/maps/estimate', {
        'origin': {
          'latitude': origin.latitude,
          'longitude': origin.longitude,
        },
        'destination': {
          'latitude': destination.latitude,
          'longitude': destination.longitude,
        },
        'mode': transportMode,
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get delivery estimate: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error getting delivery estimate', tag: 'TrackingService', error: e);
      rethrow;
    }
  }

  Future<List<LatLng>> getRoute({
    required LatLng origin,
    required LatLng destination,
    String transportMode = 'driving',
  }) async {
    try {
      final response = await ApiService.post('/maps/route', {
        'origin': {
          'latitude': origin.latitude,
          'longitude': origin.longitude,
        },
        'destination': {
          'latitude': destination.latitude,
          'longitude': destination.longitude,
        },
        'mode': transportMode,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List<dynamic>?;
        
        if (routes != null && routes.isNotEmpty) {
          final points = routes[0]['overview_polyline']['points'] as String;
          return _decodePolyline(points);
        }
      }
      
      return [];
    } catch (e) {
      LoggerService.error('Error getting route', tag: 'TrackingService', error: e);
      return [];
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polylineCoordinates = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polylineCoordinates.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polylineCoordinates;
  }

  Future<Map<String, dynamic>> getDeliveryEstimate({
    required LatLng pickupLocation,
    required LatLng deliveryLocation,
  }) async {
    try {
      final response = await ApiService.post('/maps/estimate', {
        'pickup': {
          'latitude': pickupLocation.latitude,
          'longitude': pickupLocation.longitude,
        },
        'delivery': {
          'latitude': deliveryLocation.latitude,
          'longitude': deliveryLocation.longitude,
        },
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get delivery estimate: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error getting delivery estimate', tag: 'TrackingService', error: e);
      return {
        'distance': 0,
        'duration': 0,
        'estimatedFee': 0,
      };
    }
  }

  void dispose() {
    _positionController.close();
    _orderUpdatesController.close();
    if (_isConnected) {
      _socket.disconnect();
    }
  }
} 