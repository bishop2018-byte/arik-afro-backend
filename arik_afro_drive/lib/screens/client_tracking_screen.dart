import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'home_screen.dart'; // To navigate back home

class ClientTrackingScreen extends StatefulWidget {
  final int userId;
  final Map<String, dynamic> userData; // Pass full user data to go back home
  const ClientTrackingScreen({super.key, required this.userId, required this.userData});

  @override
  State<ClientTrackingScreen> createState() => _ClientTrackingScreenState();
}

class _ClientTrackingScreenState extends State<ClientTrackingScreen> {
  Map<String, dynamic>? trip;
  Timer? _statusTimer;
  String status = "Searching...";
  bool paymentShown = false;

  @override
  void initState() {
    super.initState();
    startTracking();
  }

  void startTracking() {
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final response = await http.get(Uri.parse('http://10.0.2.2:5000/api/trips/active/${widget.userId}/client'));
        
        if (response.statusCode == 200 && response.body != "null") {
          var data = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              trip = data;
              status = data['status']; 
            });
          }

          // 🟢 AUTOMATIC PAYMENT TRIGGER
          if (status == 'completed' && !paymentShown) {
            _statusTimer?.cancel();
            setState(() => paymentShown = true);
            showPaymentDialog(data);
          }
        }
      } catch (e) { print(e); }
    });
  }

  void showPaymentDialog(Map data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("✅ Trip Completed"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 10),
            const Text("Your Receipt"),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Fare:"),
                Text("${data['currency'] ?? '₦'} ${data['final_amount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Payment deducted from Wallet.", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close popup
              // Go back to Home Screen properly
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(builder: (context) => HomeScreen(userData: widget.userData))
              );
            },
            child: const Text("Close & Rate Driver"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() { _statusTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trip Status"), automaticallyImplyLeading: false),
      body: Center(
        child: trip == null 
        ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 20), Text("Contacting Driver...")])
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status == 'accepted' ? Icons.directions_car : 
                status == 'started' ? Icons.navigation : Icons.search,
                size: 80,
                color: Colors.blue
              ),
              const SizedBox(height: 20),
              Text(
                status.toUpperCase(), 
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 2)
              ),
              const SizedBox(height: 10),
              Text("Driver: ${trip!['driver_name'] ?? 'Assigned'}"),
              const SizedBox(height: 30),
              
              if (status == 'started')
                const Text("🚕 En Route to Destination...", style: TextStyle(color: Colors.green, fontSize: 18))
              else if (status == 'accepted')
                const Text("Driver is coming to you!", style: TextStyle(color: Colors.blue, fontSize: 18)),
            ],
          ),
      ),
    );
  }
}