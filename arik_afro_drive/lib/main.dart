import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart'; // This is your Client Map screen
import 'screens/driver_dashboard.dart'; // This is your Driver screen

void main() {
  runApp(const ArikAfroDrive());
}

class ArikAfroDrive extends StatelessWidget {
  const ArikAfroDrive({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arik Afro Drive',
      theme: ThemeData(
        primaryColor: const Color(0xFF1A1A1A), // Keeps your dark brand theme
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // ✅ Start at Welcome Screen (Your original design)
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/driver': (context) => const DriverDashboard(),
      },
    );
  }
}
