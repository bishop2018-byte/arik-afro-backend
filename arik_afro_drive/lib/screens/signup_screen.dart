import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart'; 

class SignupScreen extends StatefulWidget {
  final String role; // We receive 'client' or 'driver' here
  
  const SignupScreen({super.key, required this.role});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Common Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  // Driver-Specific Controllers
  final TextEditingController licenseController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();

  // ✅ FIXED: DIRECT CLOUD LINK
  final String baseUrl = "https://arik-api.onrender.com";

  Future<void> registerUser() async {
    // Basic validation
    if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields"))
      );
      return;
    }

    // ✅ FIXED: Using Cloud URL
    final String url = '$baseUrl/api/auth/register'; 

    // Create the data packet
    Map<String, dynamic> requestBody = {
      "full_name": nameController.text.trim(),
      "email": emailController.text.trim(),
      "phone": phoneController.text.trim(),
      "password": passwordController.text.trim(),
      "role": widget.role, 
    };

    // If they are a driver, add the extra professional details
    if (widget.role == 'driver') {
      requestBody["license_number"] = licenseController.text.trim();
      requestBody["years_experience"] = experienceController.text.trim();
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      // Note: Render/Postgres often returns 201 for "Created"
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        String successMessage = widget.role == 'driver' 
            ? '✅ Application Submitted! Waiting for Admin Approval.' 
            : '✅ Account Created Successfully!';

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
        
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      } else {
        if (!mounted) return;
        var errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${errorData['error'] ?? 'Registration failed'}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      print("Signup Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Could not connect to server. Check your internet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDriver = widget.role == 'driver';

    return Scaffold(
      appBar: AppBar(
        title: Text(isDriver ? "Driver Registration 🚖" : "Client Sign Up 👤"),
        backgroundColor: isDriver ? Colors.black : Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text("Create your account", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              // Common Fields
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: passwordController, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()), obscureText: true),
              const SizedBox(height: 20),

              // --- DRIVER ONLY FIELDS ---
              if (isDriver) ...[
                const Divider(),
                const Text("Professional Details", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(controller: licenseController, decoration: const InputDecoration(labelText: "Driver's License Number", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: experienceController, decoration: const InputDecoration(labelText: "Years of Experience", border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 20),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: registerUser,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: isDriver ? Colors.black : Colors.blue,
                  ),
                  child: Text(isDriver ? "Submit Application" : "Create Account", style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}