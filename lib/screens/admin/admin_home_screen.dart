// lib/screens/admin/admin_home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/user_model.dart';
import 'create_doctor_screen.dart';


class AdminHomeScreen extends StatelessWidget {
  final UserModel user;

  const AdminHomeScreen({super.key, required this.user});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome, ${user.name}',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can register doctors for the clinic.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              icon: const Icon(Icons.medical_services),
              label: const Text('Register New Doctor'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateDoctorScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
