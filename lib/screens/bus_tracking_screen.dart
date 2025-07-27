import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({super.key});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  WebViewController? _webViewController;
  bool _isMapLoaded = false;
  bool _showRoute = true;
  String _distance = '0.00';

  // Initial camera position (you can adjust these coordinates)
  final _center = const {
    'latitude': 44.4056,
    'longitude': 8.9463
  }; // Genova, Italy

  // Bus location (example coordinates)
  final _busLocation = const {
    'latitude': 44.4156,
    'longitude': 8.9563
  }; // Near Genova

  // User's current location
  Map<String, double>? _userLocation;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      debugPrint('Loading map.html from assets...');
      final String mapHtml = await rootBundle.loadString('assets/map.html');
      debugPrint('map.html loaded successfully');

      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              debugPrint('Page started loading: $url');
            },
            onPageFinished: (String url) {
              debugPrint('Page finished loading: $url');
              setState(() {
                _isMapLoaded = true;
              });
              _updateMapMarkers();
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('Web resource error: ${error.description}');
            },
          ),
        )
        ..addJavaScriptChannel(
          'Flutter',
          onMessageReceived: (JavaScriptMessage message) {
            debugPrint('Message from JavaScript: ${message.message}');
          },
        )
        ..loadHtmlString(mapHtml, baseUrl: 'https://unpkg.com');

      debugPrint('WebView controller initialized');
    } catch (e) {
      debugPrint('Error initializing WebView: $e');
    }
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
        _userLocation = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
        _isLoadingLocation = false;
      });

      // Update markers on the map
      await _updateMapMarkers();
    } catch (e) {
      _showLocationError('Error getting location: $e');
    }
  }

  Future<void> _updateMapMarkers() async {
    if (_webViewController == null || !_isMapLoaded) {
      debugPrint('WebView not ready yet');
      return;
    }

    try {
      debugPrint('Updating map markers...');

      // Update bus location
      await _webViewController!.runJavaScript(
          'try { updateBusLocation(${_busLocation['longitude']}, ${_busLocation['latitude']}); } catch(e) { console.error("Error updating bus location:", e); }');

      // Update user location if available
      if (_userLocation != null) {
        await _webViewController!.runJavaScript(
            'try { updateUserLocation(${_userLocation!['longitude']}, ${_userLocation!['latitude']}); } catch(e) { console.error("Error updating user location:", e); }');

        // Show route between user and bus if enabled
        if (_showRoute) {
          await _webViewController!.runJavaScript(
              'try { showRoute(${_userLocation!['latitude']}, ${_userLocation!['longitude']}, ${_busLocation['latitude']}, ${_busLocation['longitude']}); } catch(e) { console.error("Error showing route:", e); }');
        } else {
          await _webViewController!.runJavaScript(
              'try { clearRoute(); } catch(e) { console.error("Error clearing route:", e); }');
        }

        // Update distance
        final distance = await _getDistance();
        setState(() {
          _distance = distance;
        });

        // Fit bounds to show both markers
        double minLat =
            min(_busLocation['latitude']!, _userLocation!['latitude']!);
        double maxLat =
            max(_busLocation['latitude']!, _userLocation!['latitude']!);
        double minLng =
            min(_busLocation['longitude']!, _userLocation!['longitude']!);
        double maxLng =
            max(_busLocation['longitude']!, _userLocation!['longitude']!);

        await _webViewController!.runJavaScript(
            'try { fitBounds($minLng, $minLat, $maxLng, $maxLat); } catch(e) { console.error("Error fitting bounds:", e); }');
      }

      debugPrint('Map markers updated successfully');
    } catch (e) {
      debugPrint('Error updating markers: $e');
    }
  }

  Future<void> _clearRoute() async {
    if (_webViewController == null || !_isMapLoaded) return;

    try {
      await _webViewController!.runJavaScript(
          'try { clearRoute(); } catch(e) { console.error("Error clearing route:", e); }');
      debugPrint('Route cleared');
    } catch (e) {
      debugPrint('Error clearing route: $e');
    }
  }

  Future<String> _getDistance() async {
    if (_webViewController == null || !_isMapLoaded || _userLocation == null) {
      return '0.00';
    }

    try {
      final result = await _webViewController!.runJavaScriptReturningResult(
          'try { calculateDistance(${_userLocation!['latitude']}, ${_userLocation!['longitude']}, ${_busLocation['latitude']}, ${_busLocation['longitude']}); } catch(e) { "0.00"; }');
      return result.toString();
    } catch (e) {
      debugPrint('Error getting distance: $e');
      return '0.00';
    }
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
        'https://www.openstreetmap.org/directions?engine=fossgis_osrm_car&route=${_userLocation!['latitude']},${_userLocation!['longitude']};${_busLocation['latitude']},${_busLocation['longitude']}');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'SMUCT BUS SERVICE',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                if (_webViewController != null)
                  WebViewWidget(
                    controller: _webViewController!,
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
                // Route Toggle Button
                Positioned(
                  top: 16,
                  left: 16,
                  child: FloatingActionButton(
                    heroTag: "routeToggle",
                    onPressed: () {
                      setState(() {
                        _showRoute = !_showRoute;
                      });
                      _updateMapMarkers();
                    },
                    backgroundColor: _showRoute ? Colors.blue : Colors.grey,
                    child: Icon(
                      _showRoute ? Icons.route : Icons.route_outlined,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Distance Display
                if (_userLocation != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.straighten,
                              color: Colors.blue, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${_distance} km',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
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
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      // Directions Button
                      ElevatedButton.icon(
                        onPressed: _openDirections,
                        icon: const Icon(Icons.directions, color: Colors.white),
                        label: const Text('Directions',
                            style: TextStyle(color: Colors.white)),
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
                          _buildTimelineStop(
                              'Genova-Fant D\'italia', 'Starting stop', '16:45',
                              isFirst: true),
                          _buildTimelineConnector(),
                          _buildTimelineStop('2 stops', '', '',
                              isStopPoint: false),
                          _buildTimelineConnector(),
                          _buildTimelineStop(
                              'Milano-Malpensa', 'Final stop', '19:53',
                              isLast: true),
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

  Widget _buildTimelineStop(String title, String subtitle, String time,
      {bool isFirst = false, bool isLast = false, bool isStopPoint = true}) {
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
                border:
                    Border.all(color: Colors.white, width: isStopPoint ? 2 : 0),
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
