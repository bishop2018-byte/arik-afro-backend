import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import '../api_constants.dart'; // ❌ Commented out to ensure we use the hardcoded link

import 'driver_dashboard.dart';
import 'home_screen.dart';
import 'role_selection_screen.dart';
import 'admin_dashboard.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoading = false;

  // ✅ FIXED: DIRECT CLOUD LINK
  final String baseUrl = "https://arik-api.onrender.com";

  Future<void> login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in all fields")));
      return;
    }

    setState(() => isLoading = true);

    // ✅ FIXED: Using the direct Cloud URL
    final String url = '$baseUrl/api/auth/login';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        var userData = jsonDecode(response.body);
        
        if (!mounted) return;

        // Routing Logic
        if (userData['role'] == 'driver') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DriverDashboard(userData: userData)));
        } else if (userData['role'] == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminDashboard(userData: userData)));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen(userData: userData)));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Failed. Check credentials.")));
      }
    } catch (e) {
      print("Login Error: $e"); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Server Connection Error. Check your internet.")));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login"), backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView( // Added scroll view to prevent overflow on small screens
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              const Icon(Icons.local_taxi, size: 80, color: Colors.black),
              const SizedBox(height: 10),
              const Text("Arik Afro Drive", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 10),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock)), obscureText: true),
              const SizedBox(height: 20),
              
              isLoading 
                ? const CircularProgressIndicator(color: Colors.black)
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: login, 
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                      child: const Text("LOGIN"),
                    ),
                  ),
              
              const SizedBox(height: 20),
              
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RoleSelectionScreen()));
                },
                child: const Text("Don't have an account? Register", style: TextStyle(color: Colors.black)),
              )
            ],
          ),
        ),
      ),
    );
  }
}