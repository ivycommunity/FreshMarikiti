import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';

class RouteService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String _googleMapsApiKey = 'AIzaSyAZzRk9uBUcAwOlRTaBjtuo5mkDTrZRxUk'; // TODO: Add to .env file
  
  final PolylinePoints _polylinePoints = PolylinePoints();

  // Calculate optimal route between multiple points
  Future<OptimizedRoute> calculateOptimizedRoute({
    required LatLng startLocation,
    required List<LatLng> deliveryLocations,
    required LatLng? returnLocation,
  }) async {
    try {
      // For multiple deliveries, we need to optimize the order
      List<LatLng> optimizedOrder = await _optimizeDeliveryOrder(
        startLocation,
        deliveryLocations,
      );

      // Calculate route through all optimized points
      List<LatLng> fullRoute = [startLocation, ...optimizedOrder];
      if (returnLocation != null) {
        fullRoute.add(returnLocation);
      }

      List<LatLng> polylineCoordinates = [];
      double totalDistance = 0;
      int totalDuration = 0;
      List<RouteStep> steps = [];

      // Get directions for each segment
      for (int i = 0; i < fullRoute.length - 1; i++) {
        final segment = await _getDirections(
          fullRoute[i],
          fullRoute[i + 1],
        );
        
        if (segment != null) {
          polylineCoordinates.addAll(segment.polylineCoordinates);
          totalDistance += segment.distance;
          totalDuration += segment.duration;
          steps.addAll(segment.steps);
        }
      }

      return OptimizedRoute(
        polylineCoordinates: polylineCoordinates,
        totalDistance: totalDistance,
        totalDuration: totalDuration,
        optimizedDeliveryOrder: optimizedOrder,
        steps: steps,
      );
    } catch (e) {
      throw Exception('Failed to calculate optimized route: $e');
    }
  }

  // Get real-time navigation directions
  Future<NavigationRoute?> getNavigationDirections({
    required LatLng origin,
    required LatLng destination,
    bool avoidTolls = false,
    bool avoidHighways = false,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?'
        'origin=${origin.latitude},${origin.longitude}&'
        'destination=${destination.latitude},${destination.longitude}&'
        'mode=driving&'
        'avoid=${_getAvoidParameters(avoidTolls, avoidHighways)}&'
        'key=$_googleMapsApiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          return _parseNavigationRoute(data['routes'][0]);
        }
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to get navigation directions: $e');
    }
  }

  // Get live traffic information
  Future<TrafficInfo> getTrafficInfo(LatLng location, double radiusKm) async {
    try {
      // This would integrate with Google Maps Traffic API or similar
      // For now, return mock data structure
      return TrafficInfo(
        congestionLevel: 'light', // light, moderate, heavy
        avgSpeed: 45.0, // km/h
        incidents: [], // Traffic incidents in the area
        estimatedDelay: 5, // minutes
      );
    } catch (e) {
      throw Exception('Failed to get traffic info: $e');
    }
  }

  // Calculate ETA with real-time traffic
  Future<DateTime> calculateETA({
    required LatLng currentLocation,
    required LatLng destination,
    required double currentSpeedKmh,
  }) async {
    try {
      final route = await getNavigationDirections(
        origin: currentLocation,
        destination: destination,
      );

      if (route != null) {
        // Factor in current traffic conditions
        final trafficInfo = await getTrafficInfo(currentLocation, 5.0);
        final adjustedDuration = route.duration + trafficInfo.estimatedDelay;
        
        return DateTime.now().add(Duration(minutes: adjustedDuration));
      }

      // Fallback calculation based on straight-line distance
      final distance = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        destination.latitude,
        destination.longitude,
      ) / 1000; // Convert to km

      final estimatedTimeHours = distance / (currentSpeedKmh > 0 ? currentSpeedKmh : 30);
      return DateTime.now().add(Duration(minutes: (estimatedTimeHours * 60).round()));
    } catch (e) {
      throw Exception('Failed to calculate ETA: $e');
    }
  }

  // Real-time location tracking for riders
  Stream<RiderLocationUpdate> trackRiderLocation(String riderId) async* {
    // This would connect to a real-time service like Firebase Realtime Database
    // or use WebSocket connection for live updates
    
    // For now, simulate real-time updates
    while (true) {
      await Future.delayed(const Duration(seconds: 10));
      
      // In a real implementation, this would fetch actual rider location
      yield RiderLocationUpdate(
        riderId: riderId,
        location: const LatLng(-1.2921, 36.8219), // Mock location
        timestamp: DateTime.now(),
        speed: 35.0, // km/h
        heading: 90.0, // degrees
        accuracy: 5.0, // meters
      );
    }
  }

  // Private helper methods
  Future<List<LatLng>> _optimizeDeliveryOrder(
    LatLng startLocation,
    List<LatLng> deliveryLocations,
  ) async {
    // Implement traveling salesman problem solution
    // For simplicity, using nearest neighbor algorithm
    List<LatLng> optimized = [];
    List<LatLng> remaining = List.from(deliveryLocations);
    LatLng currentLocation = startLocation;

    while (remaining.isNotEmpty) {
      LatLng nearest = remaining.first;
      double shortestDistance = _calculateDistance(currentLocation, nearest);

      for (LatLng location in remaining) {
        double distance = _calculateDistance(currentLocation, location);
        if (distance < shortestDistance) {
          nearest = location;
          shortestDistance = distance;
        }
      }

      optimized.add(nearest);
      remaining.remove(nearest);
      currentLocation = nearest;
    }

    return optimized;
  }

  Future<RouteSegment?> _getDirections(LatLng origin, LatLng destination) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?'
        'origin=${origin.latitude},${origin.longitude}&'
        'destination=${destination.latitude},${destination.longitude}&'
        'mode=driving&'
        'key=$_googleMapsApiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          List<LatLng> polylineCoordinates = _decodePolyline(
            route['overview_polyline']['points'],
          );

          List<RouteStep> steps = (leg['steps'] as List).map((step) => RouteStep(
            instruction: step['html_instructions'],
            distance: step['distance']['value'] / 1000.0, // Convert to km
            duration: step['duration']['value'] ~/ 60, // Convert to minutes
            startLocation: LatLng(
              step['start_location']['lat'],
              step['start_location']['lng'],
            ),
            endLocation: LatLng(
              step['end_location']['lat'],
              step['end_location']['lng'],
            ),
          )).toList();

          return RouteSegment(
            polylineCoordinates: polylineCoordinates,
            distance: leg['distance']['value'] / 1000.0,
            duration: leg['duration']['value'] ~/ 60,
            steps: steps,
          );
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  NavigationRoute _parseNavigationRoute(Map<String, dynamic> route) {
    final leg = route['legs'][0];
    
    List<LatLng> polylineCoordinates = _decodePolyline(
      route['overview_polyline']['points'],
    );

    List<RouteStep> steps = (leg['steps'] as List).map((step) => RouteStep(
      instruction: step['html_instructions'],
      distance: step['distance']['value'] / 1000.0,
      duration: step['duration']['value'] ~/ 60,
      startLocation: LatLng(
        step['start_location']['lat'],
        step['start_location']['lng'],
      ),
      endLocation: LatLng(
        step['end_location']['lat'],
        step['end_location']['lng'],
      ),
    )).toList();

    return NavigationRoute(
      polylineCoordinates: polylineCoordinates,
      totalDistance: leg['distance']['value'] / 1000.0,
      duration: leg['duration']['value'] ~/ 60,
      steps: steps,
      bounds: LatLngBounds(
        southwest: LatLng(
          route['bounds']['southwest']['lat'],
          route['bounds']['southwest']['lng'],
        ),
        northeast: LatLng(
          route['bounds']['northeast']['lat'],
          route['bounds']['northeast']['lng'],
        ),
      ),
    );
  }

  List<LatLng> _decodePolyline(String polyline) {
    List<PointLatLng> points = _polylinePoints.decodePolyline(polyline);
    return points.map((point) => LatLng(point.latitude, point.longitude)).toList();
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  String _getAvoidParameters(bool avoidTolls, bool avoidHighways) {
    List<String> avoid = [];
    if (avoidTolls) avoid.add('tolls');
    if (avoidHighways) avoid.add('highways');
    return avoid.join('|');
  }
}

// Data models
class OptimizedRoute {
  final List<LatLng> polylineCoordinates;
  final double totalDistance; // km
  final int totalDuration; // minutes
  final List<LatLng> optimizedDeliveryOrder;
  final List<RouteStep> steps;

  OptimizedRoute({
    required this.polylineCoordinates,
    required this.totalDistance,
    required this.totalDuration,
    required this.optimizedDeliveryOrder,
    required this.steps,
  });
}

class NavigationRoute {
  final List<LatLng> polylineCoordinates;
  final double totalDistance; // km
  final int duration; // minutes
  final List<RouteStep> steps;
  final LatLngBounds bounds;

  NavigationRoute({
    required this.polylineCoordinates,
    required this.totalDistance,
    required this.duration,
    required this.steps,
    required this.bounds,
  });
}

class RouteSegment {
  final List<LatLng> polylineCoordinates;
  final double distance; // km
  final int duration; // minutes
  final List<RouteStep> steps;

  RouteSegment({
    required this.polylineCoordinates,
    required this.distance,
    required this.duration,
    required this.steps,
  });
}

class RouteStep {
  final String instruction;
  final double distance; // km
  final int duration; // minutes
  final LatLng startLocation;
  final LatLng endLocation;

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
  });
}

class TrafficInfo {
  final String congestionLevel;
  final double avgSpeed; // km/h
  final List<TrafficIncident> incidents;
  final int estimatedDelay; // minutes

  TrafficInfo({
    required this.congestionLevel,
    required this.avgSpeed,
    required this.incidents,
    required this.estimatedDelay,
  });
}

class TrafficIncident {
  final String type; // accident, construction, road_closure
  final String description;
  final LatLng location;
  final DateTime reportedAt;

  TrafficIncident({
    required this.type,
    required this.description,
    required this.location,
    required this.reportedAt,
  });
}

class RiderLocationUpdate {
  final String riderId;
  final LatLng location;
  final DateTime timestamp;
  final double speed; // km/h
  final double heading; // degrees (0-360)
  final double accuracy; // meters

  RiderLocationUpdate({
    required this.riderId,
    required this.location,
    required this.timestamp,
    required this.speed,
    required this.heading,
    required this.accuracy,
  });
} 