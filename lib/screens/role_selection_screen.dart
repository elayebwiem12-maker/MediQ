import 'package:flutter/material.dart';
import 'package:fluttercousd/screens/patient_login_screen.dart';
import 'package:fluttercousd/screens/admin_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D9E75),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_hospital, size: 90, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'MediQ',
                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Text(
                  'Gestion des files d\'attente',
                  style: TextStyle(fontSize: 15, color: Colors.white70),
                ),
                const SizedBox(height: 50),
                const Text(
                  'Choisissez votre rôle',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PatientLoginScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.person, size: 48, color: Color(0xFF1D9E75)),
                              SizedBox(height: 8),
                              Text(
                                'Patient',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1D9E75)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.admin_panel_settings, size: 48, color: Colors.white),
                              SizedBox(height: 8),
                              Text(
                                'Administrateur',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}