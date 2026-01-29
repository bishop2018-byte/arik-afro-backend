import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; 
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class JourneyScreen extends StatefulWidget {
  final int tripId;
  final String clientName;
  final String pickupAddress;
  final String destinationAddress;

  const JourneyScreen({
    super.key, 
    required this.tripId, 
    required this.clientName,
    required this.pickupAddress,
    required this.destinationAddress
  });

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  // --- MAP VARIABLES ---
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  LatLng? _pickupLocation;
  
  // --- TRIP VARIABLES ---
  String status = "accepted"; // accepted -> started -> completed
  String fare = "0.00";
  String earnings = "0.00";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMapData(); // Load the map pin immediately
  }

  // --- 🗺️ LOAD MAP PIN ---
  Future<void> _loadMapData() async {
    try {
      List<Location> locations = await locationFromAddress(widget.pickupAddress);
      if (locations.isNotEmpty) {
        setState(() {
          _pickupLocation = LatLng(locations.first.latitude, locations.first.longitude);
          
          _markers.add(Marker(
            markerId: const MarkerId("pickup"),
            position: _pickupLocation!,
            infoWindow: InfoWindow(title: "Pickup: ${widget.clientName}"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ));
        });
        
        // Zoom into the pin
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLngZoom(_pickupLocation!, 15));
      }
    } catch (e) {
      print("Could not find address on map: $e");
    }
  }

  // --- 🚗 OPEN EXTERNAL NAV ---
  Future<void> launchNavigation() async {
    final String destination = Uri.encodeComponent(widget.pickupAddress); // Navigate to PICKUP first
    final Uri navUrl = Uri.parse("google.navigation:q=$destination");
    
    if (await canLaunchUrl(navUrl)) {
      await launchUrl(navUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open Maps app")));
    }
  }

  // --- ▶️ API: START TRIP ---
  Future<void> startJourney() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/trips/start'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"trip_id": widget.tripId}),
      );

      if (response.statusCode == 200) {
        setState(() => status = "started");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🚙 Trip Started! Drive safe.")));
        
        // Optional: Switch navigation to destination now
      }
    } catch(e) { 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection Error")));
    }
    setState(() => isLoading = false);
  }

  // --- ⏹️ API: END TRIP ---
  Future<void> endJourney() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/trips/end'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"trip_id": widget.tripId}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          status = "completed";
          fare = data['total_fare'].toString();
          earnings = data['driver_earnings'].toString();
        });
        _showPaymentPopup(data['symbol'] ?? '₦');
      }
    } catch(e) { print(e); }
    setState(() => isLoading = false);
  }

  // --- 💰 PAYMENT POPUP ---
  void _showPaymentPopup(String symbol) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("🏁 Trip Completed"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Total Fare:", style: TextStyle(fontSize: 14)),
            Text("$symbol $fare", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
            const Divider(),
            const Text("Your Earnings:", style: TextStyle(fontSize: 14)),
            Text("$symbol $earnings", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); 
              Navigator.pop(context); // Return to Dashboard
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            child: const Text("Collect Cash & Close"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // LAYER 1: THE MAP (Full Screen)
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(7.2571, 5.2058), // Default (Akure)
              zoom: 14,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // We hide default button to not cover UI
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),

          // LAYER 2: TOP BAR (Back Button)
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // LAYER 3: BOTTOM CARD (Controls)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client Info
                  Row(
                    children: [
                      const CircleAvatar(radius: 25, backgroundColor: Colors.black, child: Icon(Icons.person, color: Colors.white)),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.clientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Text("Cash Trip", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Spacer(),
                      // Navigation Button (Round)
                      FloatingActionButton.small(
                        onPressed: launchNavigation,
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.navigation, color: Colors.white),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 15),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Address Text
                  Row(
                    children: [
                      Icon(status == "started" ? Icons.flag : Icons.my_location, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          status == "started" ? "Dest: ${widget.destinationAddress}" : "Pickup: ${widget.pickupAddress}",
                          style: const TextStyle(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // MAIN ACTION BUTTON
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (status == "accepted")
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: startJourney,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, 
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        child: const Text("I'VE ARRIVED / START TRIP"),
                      ),
                    )
                  else if (status == "started")
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: endJourney,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red, 
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        child: const Text("END TRIP"),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}