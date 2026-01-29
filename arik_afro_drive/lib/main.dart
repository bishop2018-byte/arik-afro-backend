import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart'; // We import the new Welcome Screen here

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
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // This tells the app to start at the "Role Selection" screen
      home: const WelcomeScreen(), 
    );
  }
}