
// lib/screens/patient/session_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/session_model.dart';
import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';
import 'submit_feedback_screen.dart';

class SessionDetailScreen extends StatelessWidget {
  final SessionModel session;
  final String patientId;

  const SessionDetailScreen({
    super.key,
    required this.session,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final isCompleted = session.status == 'completed';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
      ),
      body: FutureBuilder<FeedbackModel?>(
        future: firestoreService.getSessionFeedback(session.sessionId),
        builder: (context, feedbackSnapshot) {
          final feedback = feedbackSnapshot.data;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Session Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              session.therapyName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Completed',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(
                        icon: Icons.calendar_today,
                        label: 'Date',
                        value: DateFormat('EEEE, MMM dd, yyyy').format(session.scheduledDate),
                      ),
                      _InfoRow(
                        icon: Icons.access_time,
                        label: 'Duration',
                        value: session.duration,
                      ),
                      _InfoRow(
                        icon: Icons.numbers,
                        label: 'Session',
                        value: '#${session.sessionNumber}',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Pre-Session Precautions
              const Text(
                'Before Session',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: session.prePrecautions.map((precaution) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle, size: 20, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(child: Text(precaution)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Post-Session Precautions
              const Text(
                'After Session',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: session.postPrecautions.map((precaution) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle, size: 20, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(child: Text(precaution)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Feedback Section
              if (feedback != null) ...[
                const Text(
                  'Your Feedback',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: Colors.green[50],
                  child: Padding(
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
                                i < feedback.rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                              );
                            }),
                          ],
                        ),
                        if (feedback.comments.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Comments:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(feedback.comments),
                        ],
                        if (feedback.symptoms.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Symptoms:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: feedback.symptoms.map((symptom) {
                              return Chip(
                                label: Text(symptom),
                                backgroundColor: Colors.orange[100],
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ] else if (!isCompleted) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubmitFeedbackScreen(
                          session: session,
                          patientId: patientId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.feedback),
                  label: const Text('Submit Feedback'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}