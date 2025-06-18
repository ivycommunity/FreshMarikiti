import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fresh_marikiti/core/providers/auth_provider.dart';
import 'package:fresh_marikiti/core/providers/order_provider.dart';
import 'package:fresh_marikiti/core/config/theme_extensions.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/services/location_service.dart';
import 'package:fresh_marikiti/core/models/order_model.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:fresh_marikiti/core/services/api_service.dart';
import 'package:fresh_marikiti/core/services/navigation_service.dart';

class NavigationScreen extends StatefulWidget {
  final Order? order;

  const NavigationScreen({
    super.key,
    this.order,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  
  Position? _currentPosition;
  LatLng? _destination;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  bool _isNavigating = false;
  bool _hasArrived = false;
  double _distanceToDestination = 0.0;
  int _estimatedTimeMinutes = 0;
  String _currentInstruction = 'Getting directions...';
  
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _navigationUpdateTimer;
  
  final List<LatLng> _routePoints = [];
  int _currentRoutePointIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
    LoggerService.info('Navigation screen initialized', tag: 'NavigationScreen');
  }

  Future<void> _initializeNavigation() async {
    try {
      // Get current location
      final position = await _locationService.getCurrentLocation();
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        
        // Set destination based on order
        if (widget.order != null) {
          await _setDestinationFromOrder();
        }
        
        // Start location tracking
        _startLocationTracking();
        _generateRoute();
      }
    } catch (e) {
      LoggerService.error('Failed to initialize navigation', error: e, tag: 'NavigationScreen');
      if (mounted) {
        _showError('Failed to get location. Please check GPS permissions.');
      }
    }
  }

  Future<void> _setDestinationFromOrder() async {
    if (widget.order == null) return;
    
    try {
      // Get coordinates from delivery address using geocoding API
      final response = await ApiService.get('/geocoding/coordinates?address=${Uri.encodeComponent(widget.order!.deliveryAddress.fullAddress)}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _destination = LatLng(
            data['latitude'].toDouble(),
            data['longitude'].toDouble(),
          );
        });
        
        _updateMarkers();
      } else {
        throw Exception('Failed to geocode address: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to set destination', error: e, tag: 'NavigationScreen');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not locate delivery address: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startLocationTracking() {
    _positionStreamSubscription = _locationService.getPositionStream().listen(
      (Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
          
          _updateMarkers();
          _updateNavigation();
          
          // Update camera position
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          );
        }
      },
      onError: (e) {
        LoggerService.error('Location tracking error', error: e, tag: 'NavigationScreen');
      },
    );
  }

  void _updateMarkers() {
    if (_currentPosition == null) return;
    
    final markers = <Marker>{};
    
    // Current location marker
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );
    
    // Destination marker
    if (_destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: widget.order?.deliveryAddress.fullAddress ?? 'Delivery Location',
          ),
        ),
      );
    }
    
    setState(() {
      _markers = markers;
    });
  }

  Future<void> _generateRoute() async {
    if (_currentPosition == null || _destination == null) return;
    
    try {
      // Get route from Google Directions API via backend
      final response = await ApiService.post('/navigation/directions', {
        'origin': {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
        },
        'destination': {
          'latitude': _destination!.latitude,
          'longitude': _destination!.longitude,
        },
        'mode': 'driving', // or 'walking', 'bicycling' based on vehicle type
      });
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routePoints = <LatLng>[];
        
        // Parse encoded polyline from Google Directions API
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          
          // Decode polyline points
          if (route['overview_polyline'] != null && route['overview_polyline']['points'] != null) {
            final encodedPolyline = route['overview_polyline']['points'];
            routePoints.addAll(_decodePolyline(encodedPolyline));
          }
          
          // Extract detailed steps for navigation instructions
          if (route['legs'] != null && route['legs'].isNotEmpty) {
            final leg = route['legs'][0];
            _estimatedTimeMinutes = (leg['duration']['value'] / 60).round();
            _distanceToDestination = leg['distance']['value'].toDouble();
          }
        }
        
        setState(() {
          _routePoints.clear();
          _routePoints.addAll(routePoints);
          _currentRoutePointIndex = 0;
          
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: routePoints,
              color: Colors.blue,
              width: 4,
              patterns: [PatternItem.dash(30), PatternItem.gap(20)],
            ),
          };
        });
        
        _updateNavigationInstructions();
      } else {
        throw Exception('Failed to get directions: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Failed to generate route', error: e, tag: 'NavigationScreen');
      // Fallback to simple calculation for basic functionality
      _calculateDistanceAndTime();
      _updateNavigationInstructions();
    }
  }

  // Decode Google Polyline Algorithm
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
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

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  void _updateNavigation() {
    if (_currentPosition == null || _destination == null) return;
    
    final currentLatLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final distanceToDestination = Geolocator.distanceBetween(
      currentLatLng.latitude,
      currentLatLng.longitude,
      _destination!.latitude,
      _destination!.longitude,
    );
    
    setState(() {
      _distanceToDestination = distanceToDestination;
      _hasArrived = distanceToDestination < 50; // Within 50 meters
    });
    
    if (_hasArrived && _isNavigating) {
      _onArrival();
    }
    
    _updateNavigationInstructions();
  }

  void _calculateDistanceAndTime() {
    if (_currentPosition == null || _destination == null) return;
    
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _destination!.latitude,
      _destination!.longitude,
    );
    
    // Estimate time based on average speed (30 km/h in city)
    final timeInHours = (distance / 1000) / 30;
    
    setState(() {
      _distanceToDestination = distance;
      _estimatedTimeMinutes = (timeInHours * 60).round();
    });
  }

  void _updateNavigationInstructions() {
    if (_routePoints.isEmpty || _currentPosition == null) return;
    
    // Find nearest route point
    double minDistance = double.infinity;
    int nearestIndex = 0;
    
    for (int i = 0; i < _routePoints.length; i++) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _routePoints[i].latitude,
        _routePoints[i].longitude,
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }
    
    _currentRoutePointIndex = nearestIndex;
    
    // Generate instruction based on position
    String instruction;
    if (_hasArrived) {
      instruction = 'You have arrived at your destination';
    } else if (_distanceToDestination < 100) {
      instruction = 'Destination is nearby';
    } else if (_distanceToDestination < 500) {
      instruction = 'Continue straight ahead';
    } else {
      instruction = 'Follow the route to your destination';
    }
    
    setState(() {
      _currentInstruction = instruction;
    });
  }

  void _onArrival() {
    setState(() {
      _isNavigating = false;
    });
    
    // Vibrate to notify arrival
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🎉 You have arrived at your destination!'),
        backgroundColor: context.colors.freshGreen,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Confirm',
          textColor: Colors.white,
          onPressed: () => _confirmArrival(),
        ),
      ),
    );
  }

  void _confirmArrival() {
    if (widget.order != null) {
      NavigationService.toDeliveryDetails(widget.order!);
    } else {
      Navigator.pop(context);
    }
  }

  void _startNavigation() {
    setState(() {
      _isNavigating = true;
    });
    
    _navigationUpdateTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _updateNavigation(),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Navigation started'),
        backgroundColor: context.colors.ecoBlue,
      ),
    );
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
    });
    
    _navigationUpdateTimer?.cancel();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Navigation stopped'),
        backgroundColor: context.colors.textSecondary,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _navigationUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, OrderProvider>(
      builder: (context, authProvider, orderProvider, child) {
        return Scaffold(
          backgroundColor: context.colors.surface,
          appBar: _buildAppBar(),
          body: _currentPosition == null
              ? _buildLoadingState()
              : Stack(
                  children: [
                    _buildMap(),
                    _buildNavigationOverlay(),
                    if (_hasArrived) _buildArrivalOverlay(),
                  ],
                ),
          bottomNavigationBar: _buildBottomControls(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.colors.ecoBlue,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Navigation',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          if (widget.order != null)
            Text(
              'Order #${widget.order!.orderNumber}',
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(_isNavigating ? Icons.pause : Icons.play_arrow),
          onPressed: _isNavigating ? _stopNavigation : _startNavigation,
          tooltip: _isNavigating ? 'Stop Navigation' : 'Start Navigation',
        ),
        IconButton(
          icon: const Icon(Icons.my_location),
          onPressed: _centerOnCurrentLocation,
          tooltip: 'Center on Location',
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Getting your location...',
            style: context.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Please ensure GPS is enabled',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        if (_currentPosition != null) {
          _centerOnCurrentLocation();
        }
      },
      initialCameraPosition: CameraPosition(
        target: LatLng(
          _currentPosition?.latitude ?? -1.2921,
          _currentPosition?.longitude ?? 36.8219,
        ),
        zoom: 16.0,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      mapType: MapType.normal,
      zoomControlsEnabled: false,
      compassEnabled: true,
      trafficEnabled: true,
      onTap: (LatLng location) {
        // Allow setting custom destination by tapping
        if (widget.order == null) {
          setState(() {
            _destination = location;
          });
          _updateMarkers();
          _generateRoute();
        }
      },
    );
  }

  Widget _buildNavigationOverlay() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
        child: Padding(
          padding: AppSpacing.paddingMD,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isNavigating 
                          ? context.colors.freshGreen 
                          : context.colors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isNavigating ? Icons.navigation : Icons.navigation_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentInstruction,
                          style: context.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_destination != null)
                          Text(
                            widget.order?.deliveryAddress.fullAddress ?? 'Custom Destination',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (_destination != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _buildNavigationMetric(
                      'Distance',
                      '${(_distanceToDestination / 1000).toStringAsFixed(1)} km',
                      Icons.route,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: context.colors.outline,
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    ),
                    _buildNavigationMetric(
                      'ETA',
                      '${_estimatedTimeMinutes} min',
                      Icons.access_time,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: context.colors.outline,
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    ),
                    _buildNavigationMetric(
                      'Speed',
                      '${(_currentPosition?.speed ?? 0 * 3.6).toStringAsFixed(0)} km/h',
                      Icons.speed,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationMetric(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: context.colors.ecoBlue),
          const SizedBox(height: 2),
          Text(
            value,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrivalOverlay() {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Card(
        elevation: 12,
        color: context.colors.freshGreen,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLG),
        child: Padding(
          padding: AppSpacing.paddingLG,
          child: Column(
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                '🎉 You have arrived!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton(
                onPressed: _confirmArrival,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: context.colors.freshGreen,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                ),
                child: const Text('Confirm Arrival'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: AppSpacing.paddingMD,
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isNavigating ? _stopNavigation : _startNavigation,
                icon: Icon(_isNavigating ? Icons.pause : Icons.play_arrow),
                label: Text(_isNavigating ? 'Stop Navigation' : 'Start Navigation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isNavigating 
                      ? context.colors.textSecondary 
                      : context.colors.ecoBlue,
                  foregroundColor: Colors.white,
                  padding: AppSpacing.paddingMD,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (widget.order != null)
              ElevatedButton.icon(
                onPressed: () => NavigationService.toDeliveryDetails(widget.order!),
                icon: const Icon(Icons.info),
                label: const Text('Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.marketOrange,
                  foregroundColor: Colors.white,
                  padding: AppSpacing.paddingMD,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusMD),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _centerOnCurrentLocation() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          16.0,
        ),
      );
    }
  }
} 