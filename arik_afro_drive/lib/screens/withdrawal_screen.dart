import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import '../api_constants.dart'; // ❌ Commented out for direct cloud link safety

class WithdrawalScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const WithdrawalScreen({super.key, required this.userData});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _amountController = TextEditingController();
  final _bankController = TextEditingController();
  final _accountController = TextEditingController();
  bool isLoading = false;

  // ✅ FIXED: DIRECT CLOUD LINK
  final String baseUrl = "https://arik-api.onrender.com";

  Future<void> requestWithdrawal() async {
    if (_amountController.text.trim().isEmpty || 
        _bankController.text.trim().isEmpty || 
        _accountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields"))
      );
      return;
    }

    setState(() => isLoading = true);

    // ✅ FIXED: Using the direct Cloud URL
    final String url = '$baseUrl/api/withdraw/request';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userData['user_id'] ?? widget.userData['id'],
          "amount": double.parse(_amountController.text.trim()),
          "bank_name": _bankController.text.trim(),
          "account_number": _accountController.text.trim()
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Request Sent! Funds deducted from wallet."))
        );
        Navigator.pop(context); 
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${response.body}"))
        );
      }
    } catch (e) {
      if (!mounted) return;
      print("Withdrawal Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server Error. Check your connection."))
      );
    }
    
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Withdraw Funds"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView( // Added to prevent keyboard overflow
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Enter your bank details to receive payment.", 
              style: TextStyle(fontSize: 16, color: Colors.grey)
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _amountController, 
              decoration: const InputDecoration(
                labelText: "Amount (₦)", 
                border: OutlineInputBorder(),
                prefixText: "₦ "
              ), 
              keyboardType: TextInputType.number
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _bankController, 
              decoration: const InputDecoration(
                labelText: "Bank Name", 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance)
              )
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _accountController, 
              decoration: const InputDecoration(
                labelText: "Account Number", 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers)
              ), 
              keyboardType: TextInputType.number
            ),
            
            const SizedBox(height: 30),
            
            isLoading 
            ? const CircularProgressIndicator(color: Colors.green)
            : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: requestWithdrawal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, 
                    foregroundColor: Colors.white, 
                    padding: const EdgeInsets.symmetric(vertical: 15)
                  ),
                  child: const Text("SUBMIT REQUEST", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
          ],
        ),
      ),
    );
  }
}