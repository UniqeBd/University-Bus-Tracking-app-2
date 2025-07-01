import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({super.key});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  GoogleMapController? mapController;
  
  // Initial camera position (you can adjust these coordinates)
  final LatLng _center = const LatLng(44.4056, 8.9463); // Genova, Italy
  
  // Bus location (example coordinates)
  final LatLng _busLocation = const LatLng(44.4156, 8.9563); // Near Genova
  
  // User's current location
  LatLng? _userLocation;
  bool _isLoadingLocation = false;
  
  // Markers for the map
  Set<Marker> _markers = {};
  
  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    _getCurrentLocation();
  }
  
  void _initializeMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId('bus'),
        position: _busLocation,
        infoWindow: const InfoWindow(
          title: 'V-Bus-1845',
          snippet: 'Genova-Milano',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      ),
    };
  }
  
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Location services are disabled.');
        return;
      }
      
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Location permissions are denied.');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showLocationError('Location permissions are permanently denied.');
        return;
      }
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _markers.add(
          Marker(
            markerId: const MarkerId('user'),
            position: _userLocation!,
            infoWindow: const InfoWindow(
              title: 'My Location',
              snippet: 'Current position',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
        _isLoadingLocation = false;
      });
      
      // Animate camera to show both user and bus location
      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            _getBoundsForMarkers(),
            50.0,
          ),
        );
      }
    } catch (e) {
      _showLocationError('Error getting location: $e');
    }
  }
  
  LatLngBounds _getBoundsForMarkers() {
    double minLat = _userLocation?.latitude ?? _busLocation.latitude;
    double maxLat = _userLocation?.latitude ?? _busLocation.latitude;
    double minLng = _userLocation?.longitude ?? _busLocation.longitude;
    double maxLng = _userLocation?.longitude ?? _busLocation.longitude;
    
    if (_userLocation != null) {
      minLat = min(minLat, _userLocation!.latitude);
      maxLat = max(maxLat, _userLocation!.latitude);
      minLng = min(minLng, _userLocation!.longitude);
      maxLng = max(maxLng, _userLocation!.longitude);
    }
    
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
  
  void _showLocationError(String message) {
    setState(() {
      _isLoadingLocation = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  Future<void> _openDirections() async {
    if (_userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please get your location first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final url = Uri.parse(
      'https://www.google.com/maps/dir/${_userLocation!.latitude},${_userLocation!.longitude}/${_busLocation.latitude},${_busLocation.longitude}'
    );
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open directions'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850], // Dark theme background
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'SMUCT BUS SERVICE',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Section
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 10,
                  ),
                  onMapCreated: _onMapCreated,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false, // We'll create our own button
                ),
                // My Location Button
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: "myLocation",
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    backgroundColor: Colors.white,
                    child: _isLoadingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          // Bus Details Section
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24.0),
                  topRight: Radius.circular(24.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'V-Bus-1845',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Genova-Milano',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      // Directions Button
                      ElevatedButton.icon(
                        onPressed: _openDirections,
                        icon: const Icon(Icons.directions, color: Colors.white),
                        label: const Text('Directions', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'On Time',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildTimelineStop('Genova-Fant D\'italia', 'Starting stop', '16:45', isFirst: true),
                          _buildTimelineConnector(),
                          _buildTimelineStop('2 stops', '', '', isStopPoint: false),
                           _buildTimelineConnector(),
                          _buildTimelineStop('Milano-Malpensa', 'Final stop', '19:53', isLast: true),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimelineStop(String title, String subtitle, String time, {bool isFirst = false, bool isLast = false, bool isStopPoint = true}) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isStopPoint ? Colors.yellow : Colors.transparent,
                border: Border.all(color: Colors.white, width: isStopPoint ? 2 : 0),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70),
                ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector() {
    return Row(
      children: [
        Container(
          margin: const EdgeInsets.only(left: 9),
          width: 2,
          height: 40,
          color: Colors.white,
        ),
        const SizedBox(width: 16),
        // Dashed line could be more complex, using a custom painter or package
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white30,
          ),
        ),
      ],
    );
  }
} 