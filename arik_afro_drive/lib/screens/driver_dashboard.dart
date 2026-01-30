import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'login_screen.dart';
import 'journey_screen.dart';
import 'withdrawal_screen.dart';

class DriverDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  const DriverDashboard({super.key, required this.userData});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  bool isOnline = false;
  bool isLoading = false;
  bool isPopupShowing = false;

  Timer? _jobTimer;
  Map<String, dynamic>? activeTrip;
  List<dynamic> history = [];
  String walletBalance = "0.00";

  final String baseUrl = "https://arik-api.onrender.com";

  @override
  void initState() {
    super.initState();
    checkActiveTrip();
    fetchHistory();
    fetchBalance();
  }

  // ✅ Helper to get the correct ID from nested userData
  int getUserId() {
    return widget.userData['id'] ?? widget.userData['user_id'];
  }

  // --- 💰 FETCH WALLET BALANCE ---
  Future<void> fetchBalance() async {
    int userId = getUserId();
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/drivers/profile/$userId'));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            walletBalance = data['wallet_balance'].toString();
          });
        }
      }
    } catch (e) {
      debugPrint("Balance Error: $e");
    }
  }

  // --- CHECK ACTIVE TRIP ---
  Future<void> checkActiveTrip() async {
    int userId = getUserId();
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/trips/active/$userId/driver'));
      if (response.statusCode == 200) {
        if (response.body != "null" && response.body.isNotEmpty) {
          var data = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              activeTrip = data;
              isOnline = true;
            });
            startJobTimer(); // Ensure scanner is running if online
          }
        }
      }
    } catch (e) {
      debugPrint("Active Trip Error: $e");
    }
  }

  // --- FETCH HISTORY ---
  Future<void> fetchHistory() async {
    int userId = getUserId();
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/trips/history/$userId/driver'));
      if (response.statusCode == 200) {
        if (mounted) setState(() => history = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("History Error: $e");
    }
  }

  // --- TOGGLE ONLINE STATUS (FIXED LOGIC) ---
  Future<void> toggleOnlineStatus(bool status) async {
    if (status == false) {
      setState(() => isOnline = false);
      _jobTimer?.cancel();
      return;
    }

    setState(() => isLoading = true);

    // 1. Check/Request Permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => isLoading = false);
        return;
      }
    }

    try {
      // 2. Get current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      int userId = getUserId();

      // 3. Update status and location on server
      final response = await http.post(
        Uri.parse('$baseUrl/api/drivers/update-location'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "latitude": position.latitude,
          "longitude": position.longitude,
          "is_online": true // ✅ Send online flag
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          isOnline = true;
          isLoading = false;
        });
        startJobTimer();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ You are now ONLINE")));
      } else {
        throw Exception("Server Error");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isOnline = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Connection Failed: Check Server")));
    }
  }

  // --- JOB SCANNER (POLLING) ---
  void startJobTimer() {
    _jobTimer?.cancel();
    _jobTimer = Timer.periodic(
        const Duration(seconds: 10), (timer) => checkForRequests());
  }

  Future<void> checkForRequests() async {
    if (!isOnline || activeTrip != null || isPopupShowing) return;
    int userId = getUserId();
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/api/trips/pending/$userId'));
      if (response.statusCode == 200) {
        List trips = jsonDecode(response.body);
        if (trips.isNotEmpty) _showJobOffer(trips[0]);
      }
    } catch (e) {
      debugPrint("Polling Error: $e");
    }
  }

  void _showJobOffer(Map trip) {
    setState(() => isPopupShowing = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("🎉 New Ride Request!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Passenger: ${trip['client_name']}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            const Text("Pickup:", style: TextStyle(color: Colors.grey)),
            Text(trip['pickup_address'],
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Destination:", style: TextStyle(color: Colors.grey)),
            Text(trip['destination_address'],
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => isPopupShowing = false);
            },
            child: const Text("Reject", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => acceptRide(trip),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("ACCEPT"),
          ),
        ],
      ),
    );
  }

  Future<void> acceptRide(Map trip) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/trips/accept'),
        headers: {"Content-Type": "application/json"},
        body:
            jsonEncode({"trip_id": trip['trip_id'], "driver_id": getUserId()}),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        setState(() => isPopupShowing = false);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => JourneyScreen(
                      tripId: trip['trip_id'],
                      clientName: trip['client_name'],
                      pickupAddress: trip['pickup_address'],
                      destinationAddress: trip['destination_address'],
                    ))).then((_) {
          checkActiveTrip();
          fetchHistory();
        });
      }
    } catch (e) {
      debugPrint("Accept Error: $e");
    }
  }

  void resumeTrip() {
    if (activeTrip != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => JourneyScreen(
                    tripId: activeTrip!['trip_id'],
                    clientName: activeTrip!['client_name'] ?? 'Client',
                    pickupAddress: activeTrip!['pickup_address'],
                    destinationAddress: activeTrip!['destination_address'],
                  ))).then((_) {
        checkActiveTrip();
        fetchHistory();
      });
    }
  }

  @override
  void dispose() {
    _jobTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Driver Portal"),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(icon: Icon(Icons.drive_eta), text: "Dashboard"),
                Tab(icon: Icon(Icons.history), text: "History"),
              ]),
          actions: [
            IconButton(
                onPressed: fetchHistory, icon: const Icon(Icons.refresh)),
            IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  _jobTimer?.cancel();
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()));
                })
          ],
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      children: [
                        const Text("My Earnings",
                            style: TextStyle(color: Colors.white70)),
                        Text("₦$walletBalance",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => WithdrawalScreen(
                                          userData: widget.userData))),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black),
                              child: const Text("WITHDRAW TO BANK"),
                            ))
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (activeTrip != null)
                    Container(
                      padding: const EdgeInsets.all(15),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.orange),
                        const SizedBox(width: 10),
                        const Text("Trip in Progress",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton(
                            onPressed: resumeTrip, child: const Text("RESUME"))
                      ]),
                    ),
                  SwitchListTile(
                    title: Text(isOnline ? "You are ONLINE" : "You are OFFLINE",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Go online to receive rides"),
                    value: isOnline,
                    activeThumbColor: Colors.green,
                    onChanged:
                        isLoading ? null : (val) => toggleOnlineStatus(val),
                  ),
                  if (isLoading)
                    const LinearProgressIndicator(color: Colors.green),
                  const SizedBox(height: 40),
                  if (isOnline && activeTrip == null)
                    const Column(
                      children: [
                        CircularProgressIndicator(color: Colors.green),
                        SizedBox(height: 10),
                        Text("Scanning for nearby requests...",
                            style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.green)),
                      ],
                    ),
                ],
              ),
            ),
            ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                var trip = history[index];
                return ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(trip['destination_address'] ?? 'Trip'),
                  subtitle: Text(trip['created_at'].toString().split('T')[0]),
                  trailing: Text("₦${trip['final_amount'] ?? 0}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
