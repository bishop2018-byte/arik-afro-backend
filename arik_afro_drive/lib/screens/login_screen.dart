import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // ✅ DIRECT CLOUD LINK
  final String baseUrl = "https://arik-api.onrender.com";

  Future<void> login() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill in all fields")));
      return;
    }

    setState(() => isLoading = true);

    final String url = '$baseUrl/api/auth/login';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email":
              _emailController.text.trim().toLowerCase(), // ✅ Normalize email
          "password": _passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);

        // ✅ FIXED: Most backends nest the user data inside a 'user' object
        // If your backend sends it directly, keep it as responseData
        var user = responseData['user'] ?? responseData;
        String role = user['role']?.toString().toLowerCase() ?? 'client';

        if (!mounted) return;

        // ✅ PASSING DATA: We send the 'user' data to the next screen
        if (role == 'driver') {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => DriverDashboard(userData: user)));
        } else if (role == 'admin') {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => AdminDashboard(userData: user)));
        } else {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => HomeScreen(userData: user)));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid Email or Password")));
      }
    } catch (e) {
      debugPrint("Login Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Cannot connect to server. Ensure it is awake!")));
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.local_taxi, size: 100, color: Colors.black),
              const SizedBox(height: 10),
              const Text("Arik Afro Drive",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              const SizedBox(height: 40),
              TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  )),
              const SizedBox(height: 20),
              TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  )),
              const SizedBox(height: 30),
              isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: login,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: const Text("LOGIN",
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
              const SizedBox(height: 25),
              TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RoleSelectionScreen()));
                },
                child: const Text("Don't have an account? Register Here",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w600)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
