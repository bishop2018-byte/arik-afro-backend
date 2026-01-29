import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; 
import '../api_constants.dart'; // ✅ NEW IMPORT

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

  // ✅ FIXED: Using central API Constant
  String get baseUrl => ApiConstants.baseUrl;

  @override
  void initState() {
    super.initState();
    checkActiveTrip(); 
    fetchHistory();
    fetchBalance(); 
  }

  int getUserId() {
    return widget.userData['user_id'] ?? widget.userData['id'];
  }

  // --- 💰 FETCH WALLET BALANCE ---
  Future<void> fetchBalance() async {
    int userId = getUserId();
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/drivers/profile/$userId')); 
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (mounted) {
           setState(() {
             walletBalance = data['wallet_balance'].toString();
           });
        }
      }
    } catch(e) { print("Balance Error: $e"); }
  }

  // --- CHECK ACTIVE TRIP ---
  Future<void> checkActiveTrip() async {
    int userId = getUserId();
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/trips/active/$userId/driver'));
      if (response.statusCode == 200) {
        if (response.body != "null" && response.body.isNotEmpty) {
          var data = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              activeTrip = data;
              isOnline = true; 
            });
          }
        } else {
           if (mounted) setState(() => activeTrip = null);
        }
      }
    } catch(e) { print("Active Trip Error: $e"); }
  }

  // --- FETCH HISTORY ---
  Future<void> fetchHistory() async {
    int userId = getUserId(); 
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/trips/history/$userId/driver'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            history = jsonDecode(response.body);
          });
        }
      }
    } catch(e) { print("History Error: $e"); }
  }

  // --- RESUME TRIP ---
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
          ),
        ),
      ).then((_) {
        checkActiveTrip();
        fetchHistory();
      }); 
    }
  }

  // --- ACCEPT RIDE ---
  Future<void> acceptRide(Map trip) async {
    final String url = '$baseUrl/api/trips/accept';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"trip_id": trip['trip_id']}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
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
            ),
          ),
        ).then((_) {
            checkActiveTrip();
            fetchHistory();
        });
      }
    } catch (e) { print("Accept Error: $e"); }
  }

  // --- JOB SCANNER ---
  Future<void> checkForRequests() async {
    if (!isOnline) return;
    if (activeTrip != null) return; 
    if (isPopupShowing) return; 
    
    int userId = getUserId(); 
    final String url = '$baseUrl/api/trips/pending/$userId';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List trips = jsonDecode(response.body);
        if (trips.isNotEmpty) {
          _showJobOffer(trips[0]);
        }
      }
    } catch (e) { print("Polling Error: $e"); }
  }

  // --- SHOW JOB POPUP ---
  void _showJobOffer(Map trip) {
    _jobTimer?.cancel(); 
    setState(() => isPopupShowing = true);

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) => AlertDialog(
        title: const Text("🎉 New Ride Request!"),
        content: Column(
          mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Passenger: ${trip['client_name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            const Text("Pickup:", style: TextStyle(color: Colors.grey)),
            Text(trip['pickup_address'], style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Destination:", style: TextStyle(color: Colors.grey)),
            Text(trip['destination_address'], style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              setState(() => isPopupShowing = false);
              startJobTimer(); 
            },
            child: const Text("Reject", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => acceptRide(trip),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("ACCEPT RIDE"),
          ),
        ],
      ),
    );
  }

  void startJobTimer() {
    _jobTimer?.cancel(); 
    _jobTimer = Timer.periodic(const Duration(seconds: 10), (timer) => checkForRequests());
  }

  // --- TOGGLE ONLINE STATUS ---
  Future<void> toggleOnlineStatus(bool value) async {
    if (value == false) {
      setState(() => isOnline = false);
      _jobTimer?.cancel(); 
      return;
    }
    setState(() => isLoading = true);
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => isLoading = false);
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      int userId = getUserId(); 

      final response = await http.post(
        Uri.parse('$baseUrl/api/drivers/update-location'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "latitude": position.latitude,
          "longitude": position.longitude
        }),
      );

      if (response.statusCode == 200) {
        setState(() { isOnline = true; isLoading = false; });
        startJobTimer(); 
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ You are ONLINE")));
      } else {
        throw Exception("Server Error");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isOnline = false; 
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection Failed. Check Server.")));
    }
  }

  @override
  void dispose() { _jobTimer?.cancel(); super.dispose(); }

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
            ],
          ),
          actions: [
            IconButton(onPressed: fetchHistory, icon: const Icon(Icons.refresh)),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                _jobTimer?.cancel();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
            )
          ],
        ),
        body: TabBarView(
          children: [
            // TAB 1: DASHBOARD
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                   // WALLET CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        const Text("My Earnings", style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 5),
                        Text("₦$walletBalance", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => WithdrawalScreen(userData: widget.userData)));
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                            child: const Text("WITHDRAW TO BANK"),
                          ),
                        )
                      ],
                    ),
                  ),

                  // ACTIVE TRIP BANNER
                  if (activeTrip != null)
                    Container(
                      color: Colors.red,
                      padding: const EdgeInsets.all(15),
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          const Text("⚠️ Trip in Progress!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          ElevatedButton(onPressed: resumeTrip, child: const Text("RESUME"))
                        ],
                      ),
                    ),

                  // ONLINE SWITCH
                  SwitchListTile(
                    title: Text(isOnline ? "You are ONLINE" : "You are OFFLINE", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: const Text("Go online to receive rides"),
                    value: isOnline,
                    activeColor: Colors.green,
                    onChanged: (val) => toggleOnlineStatus(val), 
                  ),
                  
                  const SizedBox(height: 20),

                  if (isOnline && activeTrip == null)
                    const Center(child: Text("Scanning for jobs...", style: TextStyle(color: Colors.green, fontSize: 18, fontStyle: FontStyle.italic))),
                ],
              ),
            ),

            // TAB 2: HISTORY
            ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                var trip = history[index];
                return ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(trip['destination_address'] ?? 'Trip'),
                  subtitle: Text(trip['created_at'].toString().substring(0, 10)),
                  trailing: Text("₦${trip['final_amount'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}