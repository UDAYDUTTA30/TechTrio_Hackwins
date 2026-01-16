import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/patient_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'assessment_screen.dart';

class CreatePatientScreen extends StatefulWidget {
  final String doctorId;

  const CreatePatientScreen({
    super.key,
    required this.doctorId,
  });

  @override
  State<CreatePatientScreen> createState() => _CreatePatientScreenState();
}

class _CreatePatientScreenState extends State<CreatePatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _gender = 'Male';
  bool _loading = false;
  bool _createLoginAccount = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createPatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final firestoreService = FirestoreService();
      String userId = '';

      // Create login account if requested
      if (_createLoginAccount) {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        // Create Firebase Auth account
        final authResult =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        userId = authResult.user!.uid;

        // Create user profile in Firestore
        final userModel = UserModel(
          uid: userId,
          email: email,
          role: 'patient',
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          createdAt: DateTime.now(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set(userModel.toMap());
      }

      // Create patient record
      final patient = PatientModel(
        patientId: '',
        userId: userId, // Empty if no login account
        doctorId: widget.doctorId,
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        gender: _gender,
        assessment: {}, // Will be filled in next screen
        createdAt: DateTime.now(),
      );

      final patientId = await firestoreService.createPatient(patient);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _createLoginAccount
                  ? 'Patient account created successfully'
                  : 'Patient registered successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AssessmentScreen(
              patientId: patientId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Patient'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Patient Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Patient Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                v == null || v.isEmpty ? 'Enter patient name' : null,
              ),
              const SizedBox(height: 16),

              // Age
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter age';
                  final age = int.tryParse(v);
                  if (age == null || age <= 0) return 'Enter valid age';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Gender
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc),
                ),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _gender = v!),
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                v == null || v.isEmpty ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 24),

              // Login Account Option
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8BC34A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF8BC34A),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.login,
                          color: Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Create Login Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                        Switch(
                          value: _createLoginAccount,
                          onChanged: (v) =>
                              setState(() => _createLoginAccount = v),
                          activeColor: const Color(0xFF2E7D32),
                        ),
                      ],
                    ),
                    if (_createLoginAccount) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Patient will be able to log in and view their therapy schedule',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ],
                ),
              ),

              // Email/Password fields (shown only if creating account)
              if (_createLoginAccount) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (!_createLoginAccount) return null;
                    if (v == null || v.isEmpty) return 'Enter email';
                    if (!v.contains('@')) return 'Enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                    helperText: 'Minimum 6 characters',
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (!_createLoginAccount) return null;
                    if (v == null || v.isEmpty) return 'Enter password';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _loading ? null : _createPatient,
                icon: _loading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.check),
                label: Text(
                  _loading ? 'Creating...' : 'Create Patient & Continue',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}