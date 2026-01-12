// lib/screens/doctor/view_feedback_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/patient_model.dart';
import '../../models/therapy_plan_model.dart';
import '../../models/session_model.dart';
import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';

class ViewFeedbackScreen extends StatelessWidget {
  final PatientModel patient;

  const ViewFeedbackScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text(patient.name),
      ),
      body: FutureBuilder<TherapyPlanModel?>(
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
                  Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No active therapy plan',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final plan = planSnapshot.data!;

          return Column(
            children: [
              // Patient Info Card
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
                      'Started: ${DateFormat('MMM dd, yyyy').format(plan.startDate)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Age: ${patient.age}'),
                        const SizedBox(width: 16),
                        Text('Gender: ${patient.gender}'),
                      ],
                    ),
                  ],
                ),
              ),

              // Sessions List
              Expanded(
                child: StreamBuilder<List<SessionModel>>(
                  stream: firestoreService.getPlanSessions(plan.planId),
                  builder: (context, sessionsSnapshot) {
                    if (sessionsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final sessions = sessionsSnapshot.data ?? [];

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];

                        return FutureBuilder<FeedbackModel?>(
                          future: firestoreService.getSessionFeedback(session.sessionId),
                          builder: (context, feedbackSnapshot) {
                            final feedback = feedbackSnapshot.data;
                            final hasCompleted = session.status == 'completed';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: hasCompleted
                                      ? Colors.green[100]
                                      : Colors.grey[200],
                                  child: Icon(
                                    hasCompleted ? Icons.check : Icons.schedule,
                                    color: hasCompleted ? Colors.green : Colors.grey,
                                  ),
                                ),
                                title: Text(
                                  session.therapyName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${DateFormat('MMM dd, yyyy').format(session.scheduledDate)} • ${session.duration}',
                                ),
                                children: [
                                  if (feedback != null) ...[
                                    const Divider(),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Text(
                                                'Rating: ',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              ...List.generate(5, (i) {
                                                return Icon(
                                                  i < feedback.rating
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  color: Colors.amber,
                                                  size: 20,
                                                );
                                              }),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          if (feedback.comments.isNotEmpty) ...[
                                            const Text(
                                              'Comments:',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(feedback.comments),
                                            const SizedBox(height: 12),
                                          ],
                                          if (feedback.symptoms.isNotEmpty) ...[
                                            const Text(
                                              'Symptoms Reported:',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: feedback.symptoms.map((symptom) {
                                                return Chip(
                                                  label: Text(symptom, style: const TextStyle(fontSize: 12)),
                                                  backgroundColor: Colors.orange[100],
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ] else if (hasCompleted) ...[
                                    const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        'No feedback submitted yet',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ] else ...[
                                    const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        'Session not completed',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}