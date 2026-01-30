import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:google_maps_flutter/google_maps_flutter.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
// import '../api_constants.dart'; // ❌ Commented out to prevent potential import errors

import 'login_screen.dart';
import 'client_tracking_screen.dart'; 
import 'wallet_screen.dart'; 

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> nearbyDrivers = [];
  bool isLoading = false;
  late GoogleMapController mapController;
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destController = TextEditingController();

  // ✅ FIXED: DIRECT CLOUD LINK
  final String baseUrl = "https://arik-api.onrender.com";

  void showBookingDialog(int driverId, String driverName) {
    _pickupController.text = "My Current Location"; 
    _destController.clear(); 
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Book Ride with $driverName"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _pickupController, decoration: const InputDecoration(labelText: "Pickup", prefixIcon: Icon(Icons.my_location))),
            TextField(controller: _destController, decoration: const InputDecoration(labelText: "Destination", prefixIcon: Icon(Icons.flag))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); 
              bookRide(driverId, driverName, _pickupController.text, _destController.text);
            },
            child: const Text("CONFIRM REQUEST"),
          )
        ],
      ),
    );
  }

  Future<void> bookRide(int driverId, String driverName, String pickup, String dest) async {
    final String url = '$baseUrl/api/trips/book';
    // ✅ Check for both user_id and id to avoid null errors
    int clientId = widget.userData['user_id'] ?? widget.userData['id']; 

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "client_id": clientId, 
          "driver_id": driverId,
          "pickup_address": pickup,
          "destination_address": dest,
          "currency": "NGN"
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => ClientTrackingScreen(
            userId: clientId, 
            userData: widget.userData, 
          ))
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection Error")));
    }
  }

  Future<void> findDrivers() async {
    setState(() => isLoading = true);
    
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      mapController.animateCamera(CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)));

      // ✅ FIXED: Using Cloud URL with coordinates
      final String url = '$baseUrl/api/drivers/nearby?latitude=${position.latitude}&longitude=${position.longitude}';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        List<dynamic> allDrivers = jsonDecode(response.body);
        List<dynamic> validDrivers = allDrivers.where((d) => d['driver_id'] != null).toList();

        setState(() {
          nearbyDrivers = validDrivers;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Driver Find Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.userData['full_name'] ?? "User"),
              accountEmail: Text(widget.userData['email'] ?? ""),
              currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person)),
              decoration: const BoxDecoration(color: Colors.black),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.green),
              title: const Text("My Wallet"),
              subtitle: const Text("Fund your account"),
              onTap: () {
                Navigator.pop(context); 
                Navigator.push(context, MaterialPageRoute(builder: (context) => WalletScreen(userData: widget.userData)));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
            )
          ],
        ),
      ),

      appBar: AppBar(
        title: const Text("Arik Afro"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(6.5244, 3.3792), 
              zoom: 14,
            ),
            myLocationEnabled: true,
            onMapCreated: (controller) => mapController = controller,
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 400, 
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Where to?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: findDrivers,
                      icon: const Icon(Icons.search),
                      label: const Text("FIND DRIVERS NEAR ME"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, 
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15)
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  
                  Expanded(
                    child: isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : nearbyDrivers.isEmpty 
                      ? const Center(child: Text("No drivers found yet."))
                      : ListView.builder(
                          itemCount: nearbyDrivers.length,
                          itemBuilder: (context, index) {
                            var driver = nearbyDrivers[index];
                            double distance = (driver['distance'] as num).toDouble();
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.drive_eta)),
                              title: Text(driver['full_name'] ?? "Driver"),
                              subtitle: Text("${distance.toStringAsFixed(1)} km away"),
                              trailing: ElevatedButton(
                                onPressed: () => showBookingDialog(driver['driver_id'], driver['full_name']),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                child: const Text("Book"),
                              ),
                            );
                          },
                        ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}