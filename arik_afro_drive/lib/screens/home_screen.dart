import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  final String baseUrl = "https://arik-api.onrender.com";

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  // ✅ Ensures the app has permission to use GPS
  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  void showBookingDialog(int driverId, String driverName) {
    _pickupController.text = "My Current Location";
    _destController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Book Ride with $driverName",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _pickupController,
                decoration: const InputDecoration(
                    labelText: "Pickup Location",
                    prefixIcon: Icon(Icons.my_location, color: Colors.blue))),
            const SizedBox(height: 10),
            TextField(
                controller: _destController,
                decoration: const InputDecoration(
                    labelText: "Where to?",
                    prefixIcon: Icon(Icons.flag, color: Colors.red))),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (_destController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Please enter a destination")));
                return;
              }
              Navigator.pop(context);
              bookRide(driverId, driverName, _pickupController.text,
                  _destController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: const Text("CONFIRM", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> bookRide(
      int driverId, String driverName, String pickup, String dest) async {
    final String url = '$baseUrl/api/trips/book';
    int clientId = widget.userData['id'] ?? widget.userData['user_id'];

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
            MaterialPageRoute(
                builder: (context) => ClientTrackingScreen(
                      userId: clientId,
                      userData: widget.userData,
                    )));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Failed to book ride. Check your wallet balance.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Network Error: Could not reach server")));
    }
  }

  Future<void> findDrivers() async {
    setState(() => isLoading = true);

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      mapController.animateCamera(CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude)));

      final String url =
          '$baseUrl/api/drivers/nearby?latitude=${position.latitude}&longitude=${position.longitude}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> drivers = jsonDecode(response.body);
        setState(() {
          nearbyDrivers = drivers;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No drivers found in your area.")));
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Driver Find Error: $e");
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
              accountName: Text(
                  widget.userData['full_name'] ??
                      widget.userData['name'] ??
                      "User",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(widget.userData['email'] ?? ""),
              currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.black, size: 40)),
              decoration: const BoxDecoration(color: Colors.black),
            ),
            ListTile(
              leading:
                  const Icon(Icons.account_balance_wallet, color: Colors.green),
              title: const Text("My Wallet"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            WalletScreen(userData: widget.userData)));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const LoginScreen())),
            )
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("ARIK AFRO",
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(onPressed: findDrivers, icon: const Icon(Icons.refresh))
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                const CameraPosition(target: LatLng(6.5244, 3.3792), zoom: 14),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) => mapController = controller,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 350,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      offset: Offset(0, -2))
                ],
              ),
              child: Column(
                children: [
                  Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: findDrivers,
                      icon: const Icon(Icons.search, color: Colors.white),
                      label: const Text("FIND NEARBY DRIVERS",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child:
                                CircularProgressIndicator(color: Colors.black))
                        : nearbyDrivers.isEmpty
                            ? const Center(
                                child: Text(
                                    "Search to see available drivers near you",
                                    style: TextStyle(color: Colors.grey)))
                            : ListView.separated(
                                itemCount: nearbyDrivers.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(),
                                itemBuilder: (context, index) {
                                  var driver = nearbyDrivers[index];
                                  return ListTile(
                                    leading: const CircleAvatar(
                                        backgroundColor: Colors.black12,
                                        child: Icon(Icons.person,
                                            color: Colors.black)),
                                    title: Text(
                                        driver['full_name'] ?? "Arik Driver",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                        "${(driver['distance'] as num).toStringAsFixed(1)} km away"),
                                    trailing: ElevatedButton(
                                      onPressed: () => showBookingDialog(
                                          driver['driver_id'],
                                          driver['full_name']),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green),
                                      child: const Text("BOOK",
                                          style:
                                              TextStyle(color: Colors.white)),
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
