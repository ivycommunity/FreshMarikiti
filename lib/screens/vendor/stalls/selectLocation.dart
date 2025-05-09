import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class SelectLocationPage extends StatefulWidget {
  const SelectLocationPage({super.key});

  @override
  State<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  String _placeAddress = "Select a location";
  final Completer<GoogleMapController> _controllerCompleter = Completer();

  static const LatLng _initialPosition = LatLng(0.0236, 37.9062);

  @override
  void initState() {
    super.initState();
    _setCurrentLocation();
  }

  Future<void> _setCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permissions are permanently denied'),
        ),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _goToLocation(LatLng(position.latitude, position.longitude));
  }

  Future<void> _goToLocation(LatLng location) async {
    _pickedLocation = location;
    _updateAddress(location);

    final controller = await _controllerCompleter.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 16),
      ),
    );
    setState(() {});
  }

  Future<void> _updateAddress(LatLng location) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      location.latitude,
      location.longitude,
    );
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      setState(() {
        _placeAddress = "${place.name}, ${place.locality}, ${place.country}";
      });
    }
  }

  Future<void> _showSearchDialog() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return const SearchPlacesSheet();
      },
    ).then((result) {
      if (result != null && result is PlaceLocation) {
        _goToLocation(result.coordinates);
        setState(() {
          _placeAddress = result.address;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Stall Location'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Future.microtask(() {
              Navigator.pop(
                context,
                PlaceLocation(
                  coordinates: _pickedLocation!,
                  address: _placeAddress,
                ),
              );
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _initialPosition,
              zoom: 6,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _controllerCompleter.complete(controller);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onTap: (latLng) {
              setState(() => _pickedLocation = latLng);
              _updateAddress(latLng);
            },
            markers:
                _pickedLocation != null
                    ? {
                      Marker(
                        markerId: const MarkerId("picked"),
                        position: _pickedLocation!,
                      ),
                    }
                    : {},
          ),
          if (_pickedLocation != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(blurRadius: 5, color: Colors.black26),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.place, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_placeAddress)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_pickedLocation != null) {
                        Future.microtask(() {
                          Navigator.pop(
                            context,
                            PlaceLocation(
                              coordinates: _pickedLocation!,
                              address: _placeAddress,
                            ),
                          );
                        });
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text("Use this Location"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _setCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text("Use Current Location"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class SearchPlacesSheet extends StatefulWidget {
  const SearchPlacesSheet({super.key});

  @override
  State<SearchPlacesSheet> createState() => _SearchPlacesSheetState();
}

class _SearchPlacesSheetState extends State<SearchPlacesSheet> {
  List<dynamic> _predictions = [];
  final TextEditingController _controller = TextEditingController();

  void _onSearchChanged(String value) async {
    if (value.isEmpty) {
      setState(() => _predictions = []);
      return;
    }

    /* Commented out since it needs a Google Maps API key ----------------------------------
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$value&key=$kGoogleApiKey&components=country:ke';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() => _predictions = data['predictions']);
    }
    */
  }

  /* Commented out since it needs a Google Maps API key ----------------------------------
  Future<void> _selectPlace(String placeId) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$kGoogleApiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final location = data['result']['geometry']['location'];
      final formattedAddress = data['result']['formatted_address'];
      final lat = location['lat'];
      final lng = location['lng'];

      Navigator.pop(
        context,
        PlaceLocation(coordinates: LatLng(lat, lng), address: formattedAddress),
      );
    }
  }
*/

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
                decoration: InputDecoration(
                  hintText: "Search location",
                  hintStyle: TextStyle(color: Theme.of(context).hintColor),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_predictions.isNotEmpty)
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: _predictions.length,
                  itemBuilder: (context, index) {
                    final p = _predictions[index];
                    return Material(
                      color: Theme.of(context).cardColor,
                      child: ListTile(
                        title: Text(
                          p['description'],
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                          ),
                        ),
                        //onTap: () => _selectPlace(p['place_id']),               //Commented out since it needs a Google Maps API key ---------------------------------- 
                      ),
                    );
                  },
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text("Start typing to search"),
              ),
          ],
        ),
      ),
    );
  }
}

class PlaceLocation {
  final LatLng coordinates;
  final String address;

  PlaceLocation({required this.coordinates, required this.address});
}
