import 'package:flutter/material.dart';
import 'register_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Choose Account Type"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "How do you want to use Arik Afro?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // --- PASSENGER BUTTON ---
            _buildRoleCard(context,
                title: "I am a Passenger",
                icon: Icons.person,
                color: Colors.blue,
                role: "client"),

            const SizedBox(height: 20),

            // --- DRIVER BUTTON ---
            _buildRoleCard(context,
                title: "I am a Driver",
                icon: Icons.drive_eta,
                color: Colors.black,
                role: "driver"),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required String role}) {
    return InkWell(
      onTap: () {
        // Navigate to Register Screen with the selected role
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => RegisterScreen(predefinedRole: role)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(width: 20),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
