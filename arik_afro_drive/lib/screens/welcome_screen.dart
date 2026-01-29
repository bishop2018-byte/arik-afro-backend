import 'package:flutter/material.dart';
import 'signup_screen.dart'; // We need this to go to the next step
import 'login_screen.dart';   // In case they already have an account

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Sleek dark theme
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo or Title
            const Icon(Icons.directions_car, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "Arik Afro Drive",
              style: TextStyle(
                fontSize: 32, 
                fontWeight: FontWeight.bold, 
                color: Colors.white
              ),
            ),
            const Text(
              "Your Safety, Our Priority",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 60),

            // CLIENT BUTTON
            SizedBox(
              width: 250,
              child: ElevatedButton(
                onPressed: () {
                  // Pass 'client' as the role
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const SignupScreen(role: 'client'))
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text("I want a Ride (Client)", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),

            const SizedBox(height: 20),

            // DRIVER BUTTON
            SizedBox(
              width: 250,
              child: OutlinedButton(
                onPressed: () {
                  // Pass 'driver' as the role
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const SignupScreen(role: 'driver'))
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text("I want to Drive (Driver)", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),

            const SizedBox(height: 40),

            // LOGIN LINK
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
              child: const Text("Already have an account? Login", style: TextStyle(color: Colors.white70)),
            )
          ],
        ),
      ),
    );
  }
}