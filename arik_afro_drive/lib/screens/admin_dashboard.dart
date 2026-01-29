import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_constants.dart'; // ✅ NEW IMPORT
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  const AdminDashboard({super.key, required this.userData});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<dynamic> users = [];
  List<dynamic> trips = [];
  List<dynamic> withdrawals = [];
  bool isLoading = true;

  // ✅ FIXED: Using central API Constant
  String get baseUrl => ApiConstants.baseUrl;

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    setState(() => isLoading = true);
    try {
      final userRes = await http.get(Uri.parse('$baseUrl/api/admin/users'));
      final tripRes = await http.get(Uri.parse('$baseUrl/api/admin/trips'));
      final withRes = await http.get(Uri.parse('$baseUrl/api/admin/withdrawals'));

      if (userRes.statusCode == 200) {
        setState(() {
          users = jsonDecode(userRes.body);
          trips = jsonDecode(tripRes.body);
          withdrawals = jsonDecode(withRes.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Admin Fetch Error: $e");
      setState(() => isLoading = false);
    }
  }

  // --- APPROVE WITHDRAWAL LOGIC ---
  Future<void> approveWithdrawal(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/approve-withdrawal'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"withdrawal_id": id}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Approved!")));
        fetchAllData(); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to approve")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Control Center"),
          backgroundColor: Colors.red[900],
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: fetchAllData),
            IconButton(icon: const Icon(Icons.logout), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()))),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(icon: Icon(Icons.people), text: "Users & Wallets"),
              Tab(icon: Icon(Icons.history), text: "Trip History"),
              Tab(icon: Icon(Icons.check_circle), text: "Approvals"),
            ],
          ),
        ),
        body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
          children: [
            // TAB 1: USERS
            ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                var u = users[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(u['full_name'][0])),
                    title: Text("${u['full_name']} (${u['role']})"),
                    subtitle: Text(u['email']),
                    trailing: Text(
                      "₦${u['wallet_balance']}", 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)
                    ),
                  ),
                );
              },
            ),
            // TAB 2: TRIPS
            ListView.builder(
              itemCount: trips.length,
              itemBuilder: (context, index) {
                var t = trips[index];
                return Card(
                  child: ListTile(
                    title: Text("${t['pickup_address']} ➝ ${t['destination_address']}"),
                    subtitle: Text("Driver: ${t['driver_name']} | Client: ${t['client_name']}"),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("₦${t['total_fare']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(t['status'], style: TextStyle(color: t['status']=='completed'?Colors.green:Colors.orange)),
                      ],
                    ),
                  ),
                );
              },
            ),
            // TAB 3: APPROVALS
            withdrawals.isEmpty 
            ? const Center(child: Text("No Pending Approvals")) 
            : ListView.builder(
              itemCount: withdrawals.length,
              itemBuilder: (context, index) {
                var w = withdrawals[index];
                return Card(
                  color: Colors.yellow[50],
                  child: ListTile(
                    title: Text("Request from: ${w['full_name']}"),
                    subtitle: Text("${w['bank_name']} - ${w['account_number']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("₦${w['amount']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => approveWithdrawal(w['id']),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text("Approve"),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}