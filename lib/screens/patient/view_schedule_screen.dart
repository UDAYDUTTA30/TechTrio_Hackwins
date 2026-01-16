// lib/screens/patient/view_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/patient_model.dart';
import '../../models/therapy_plan_model.dart';
import '../../models/session_model.dart';
import '../../services/firestore_service.dart';
import 'session_detail_screen.dart';

class ViewScheduleScreen extends StatelessWidget {
  final PatientModel patient;
  final TherapyPlanModel plan;

  const ViewScheduleScreen({
    super.key,
    required this.patient,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Therapy Schedule'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.templateName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Duration: ${plan.durationDays} days',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  'Started: ${DateFormat('MMM dd, yyyy').format(plan.startDate)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<SessionModel>>(
              stream: firestoreService.getPlanSessions(plan.planId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final sessions = snapshot.data ?? [];

                if (sessions.isEmpty) {
                  return const Center(
                    child: Text('No sessions scheduled'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final isPast = session.scheduledDate.isBefore(DateTime.now());
                    final isToday = DateFormat('yyyy-MM-dd').format(session.scheduledDate) ==
                        DateFormat('yyyy-MM-dd').format(DateTime.now());
                    final isCompleted = session.status == 'completed';

                    Color cardColor = Colors.white;
                    Color statusColor = Colors.grey;
                    IconData statusIcon = Icons.schedule;

                    if (isCompleted) {
                      cardColor = Colors.green[50]!;
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                    } else if (isToday) {
                      cardColor = Colors.blue[50]!;
                      statusColor = Colors.blue;
                      statusIcon = Icons.today;
                    } else if (isPast) {
                      cardColor = Colors.orange[50]!;
                      statusColor = Colors.orange;
                      statusIcon = Icons.warning;
                    }

                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.2),
                          child: Icon(statusIcon, color: statusColor),
                        ),
                        title: Text(
                          session.therapyName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, MMM dd, yyyy').format(session.scheduledDate),
                            ),
                            Text('Duration: ${session.duration}'),
                            if (isCompleted)
                              const Text(
                                '✓ Feedback submitted',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SessionDetailScreen(
                                session: session,
                                patientId: patient.patientId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}