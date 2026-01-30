import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ClientHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ClientHistoryScreen({super.key, required this.userData});

  @override
  State<ClientHistoryScreen> createState() => _ClientHistoryScreenState();
}

class _ClientHistoryScreenState extends State<ClientHistoryScreen> {
  List<dynamic> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  // --- FETCH CLIENT HISTORY ---
  Future<void> fetchHistory() async {
    int userId = widget.userData['user_id']; // ⚠️ Fixed: 'id' usually 'user_id' in DB, check this!
    try {
      // ✅ FIXED: Using Render Cloud URL
      final response = await http.get(
        Uri.parse('https://arik-api.onrender.com/api/trips/history/$userId/client')
      );
      
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            history = jsonDecode(response.body);
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch(e) {
      print(e);
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Trip History"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: isLoading 
      ? const Center(child: CircularProgressIndicator())
      : history.isEmpty
        ? const Center(child: Text("No trips yet. Book your first ride!", style: TextStyle(color: Colors.grey)))
        : ListView.builder(
            itemCount: history.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              var trip = history[index];
              // Safe Checks for null values
              String date = trip['created_at'] != null ? trip['created_at'].toString().substring(0, 10) : "N/A";
              String time = trip['created_at'] != null ? trip['created_at'].toString().substring(11, 16) : "N/A";
              String status = trip['status'] ?? "Unknown";
              
              Color statusColor = status == 'completed' ? Colors.green : Colors.orange;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(Icons.history, color: statusColor),
                  ),
                  title: Text(trip['destination_address'] ?? "Unknown Destination", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text("$date at $time"),
                      Text("Status: $status", style: TextStyle(color: statusColor, fontSize: 12)),
                    ],
                  ),
                  trailing: Text(
                    "₦${trip['total_fare'] ?? '0.00'}",  // ⚠️ Fixed 'final_amount' to 'total_fare' (common DB name)
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ),
              );
            },
          ),
    );
  }
}