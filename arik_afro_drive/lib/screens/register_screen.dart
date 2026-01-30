import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String predefinedRole; // ✅ This receives the choice from the previous screen
  
  const RegisterScreen({super.key, required this.predefinedRole});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool isLoading = false;
  
  late String _role;

  // ✅ FIXED: DIRECT CLOUD LINK
  final String baseUrl = "https://arik-api.onrender.com";

  @override
  void initState() {
    super.initState();
    _role = widget.predefinedRole; // ✅ Lock in the role
  }

  Future<void> register() async {
    // Basic validation
    if (_nameController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields"))
      );
      return;
    }

    setState(() => isLoading = true);

    // ✅ FIXED: Using Render Cloud URL
    final String url = '$baseUrl/api/auth/register';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "full_name": _nameController.text.trim(),
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
          "phone": _phoneController.text.trim(),
          "role": _role 
        }),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Successful! Please Login."))
        );
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const LoginScreen())
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration Failed: ${response.body}"))
        );
      }
    } catch (e) {
      print("Registration Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server Error. Check your internet connection."))
      );
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register as ${_role == 'client' ? 'Passenger' : 'Driver'}"),
        backgroundColor: _role == 'client' ? Colors.blue : Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // ✅ VISUAL CONFIRMATION OF ROLE
            Container(
              padding: const EdgeInsets.all(15),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade200, 
                borderRadius: BorderRadius.circular(10)
              ),
              child: Row(
                children: [
                  Icon(_role == 'client' ? Icons.person : Icons.drive_eta, color: Colors.black54),
                  const SizedBox(width: 10),
                  Text(
                    "Creating ${_role.toUpperCase()} Account", 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)
                  ),
                ],
              ),
            ),

            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 10),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 10),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "Phone Number", prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 10),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock)), obscureText: true),
            const SizedBox(height: 30),
            
            isLoading 
              ? const CircularProgressIndicator(color: Colors.black)
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _role == 'client' ? Colors.blue : Colors.black, 
                      foregroundColor: Colors.white, 
                      padding: const EdgeInsets.symmetric(vertical: 15)
                    ),
                    child: const Text("COMPLETE REGISTRATION", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}