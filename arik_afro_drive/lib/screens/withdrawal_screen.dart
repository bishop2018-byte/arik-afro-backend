import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_constants.dart'; // ✅ NEW IMPORT

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

  Future<void> requestWithdrawal() async {
    setState(() => isLoading = true);
    
    if (_amountController.text.isEmpty || _bankController.text.isEmpty || _accountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      setState(() => isLoading = false);
      return;
    }

    // ✅ FIXED: Using central API Constant
    final String url = '${ApiConstants.baseUrl}/api/withdraw/request';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userData['user_id'] ?? widget.userData['id'],
          "amount": double.parse(_amountController.text),
          "bank_name": _bankController.text,
          "account_number": _accountController.text
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Sent! Funds deducted.")));
        Navigator.pop(context); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${response.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Server Error")));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Withdraw Funds")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text("Enter your bank details to receive payment.", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 20),
            
            TextField(controller: _amountController, decoration: const InputDecoration(labelText: "Amount (₦)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
            const SizedBox(height: 15),
            TextField(controller: _bankController, decoration: const InputDecoration(labelText: "Bank Name", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _accountController, decoration: const InputDecoration(labelText: "Account Number", border: OutlineInputBorder()), keyboardType: TextInputType.number),
            
            const SizedBox(height: 30),
            isLoading 
            ? const CircularProgressIndicator()
            : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: requestWithdrawal,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                  child: const Text("SUBMIT REQUEST"),
                ),
              )
          ],
        ),
      ),
    );
  }
}