// lib/screens/patient/patient_home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/patient_model.dart';
import '../../models/therapy_plan_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'view_schedule_screen.dart';

class PatientHomeScreen extends StatelessWidget {
  final UserModel user;

  const PatientHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Therapy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: FutureBuilder<PatientModel?>(
        future: _getPatientByUserId(user.uid),
        builder: (context, patientSnapshot) {
          if (patientSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!patientSnapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Patient profile not found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please contact your doctor',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final patient = patientSnapshot.data!;

          return FutureBuilder<TherapyPlanModel?>(
            future: firestoreService.getActiveTherapyPlan(patient.patientId),
            builder: (context, planSnapshot) {
              if (planSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!planSnapshot.hasData) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.spa, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome, ${user.name}!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No therapy plan assigned yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your doctor will create a plan for you',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final plan = planSnapshot.data!;

              return Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[400]!, Colors.green[600]!],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${user.name}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          plan.templateName,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Started: ${DateFormat('MMM dd, yyyy').format(plan.startDate)}',
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quick Actions
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionCard(
                                icon: Icons.calendar_today,
                                title: 'View Schedule',
                                color: Colors.blue,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ViewScheduleScreen(
                                        patient: patient,
                                        plan: plan,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ActionCard(
                                icon: Icons.info_outline,
                                title: 'Precautions',
                                color: Colors.orange,
                                onTap: () {
                                  _showPrecautionsDialog(context, plan);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Progress Overview
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Therapy Progress',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: StreamBuilder(
                              stream: firestoreService.getPlanSessions(plan.planId),
                              builder: (context, sessionsSnapshot) {
                                if (!sessionsSnapshot.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                final sessions = sessionsSnapshot.data ?? [];
                                final completed = sessions.where((s) => s.status == 'completed').length;

                                return Column(
                                  children: [
                                    Card(
                                      color: Colors.green[50],
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            _ProgressStat(
                                              label: 'Total Sessions',
                                              value: sessions.length.toString(),
                                              icon: Icons.event_note,
                                            ),
                                            _ProgressStat(
                                              label: 'Completed',
                                              value: completed.toString(),
                                              icon: Icons.check_circle,
                                              color: Colors.green,
                                            ),
                                            _ProgressStat(
                                              label: 'Remaining',
                                              value: (sessions.length - completed).toString(),
                                              icon: Icons.pending,
                                              color: Colors.orange,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Tap "View Schedule" to see all sessions and submit feedback',
                                      style: TextStyle(color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<PatientModel?> _getPatientByUserId(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('patients')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return PatientModel.fromMap(snapshot.docs.first.data());
    }
    return null;
  }

  void _showPrecautionsDialog(BuildContext context, TherapyPlanModel plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Therapy Precautions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Before Session:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('• Avoid heavy meals 3 hours before'),
              const Text('• Drink warm water'),
              const Text('• Wear comfortable clothing'),
              const SizedBox(height: 16),
              const Text(
                'After Session:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('• Rest for 30 minutes'),
              const Text('• Avoid cold water bath for 2 hours'),
              const Text('• Follow prescribed diet'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _ProgressStat({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color ?? Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}