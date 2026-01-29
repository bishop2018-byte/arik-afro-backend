import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_constants.dart'; // ✅ NEW IMPORT

class WalletScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const WalletScreen({super.key, required this.userData});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amountController = TextEditingController();
  bool isLoading = false;
  String currentBalance = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
     if (mounted) {
       setState(() {
         currentBalance = widget.userData['wallet_balance'].toString();
       });
     }
  }

  // --- SIMULATED PAYMENT ---
  Future<void> fundWallet() async {
    if (_amountController.text.isEmpty) return;
    
    setState(() => isLoading = true);
    int amount = int.parse(_amountController.text) * 100; // Convert to Kobo
    String testRef = "TEST_${DateTime.now().millisecondsSinceEpoch}";

    // ✅ FIXED: Using central API Constant
    final String url = '${ApiConstants.baseUrl}/api/wallet/fund';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userData['user_id'] ?? widget.userData['id'],
          "reference": testRef,
          "amount": amount
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          currentBalance = data['new_balance'].toString();
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Wallet Funded (Test Mode)!")));
        _amountController.clear();
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${response.body}")));
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connection Error")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Wallet"), backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  const Text("Current Balance", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  Text("₦$currentBalance", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            const Text("DEV MODE: Add Money Instantly", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: "Amount (₦)", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            
            isLoading 
            ? const CircularProgressIndicator()
            : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: fundWallet,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                  child: const Text("SIMULATE PAYMENT"),
                ),
              )
          ],
        ),
      ),
    );
  }
}