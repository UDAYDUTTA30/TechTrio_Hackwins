// lib/screens/doctor/view_feedback_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/patient_model.dart';
import '../../models/therapy_plan_model.dart';
import '../../models/session_model.dart';
import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';
import '../../services/gemini_service.dart';
import 'assessment_screen.dart';

class ViewFeedbackScreen extends StatefulWidget {
  final PatientModel patient;

  const ViewFeedbackScreen({super.key, required this.patient});

  @override
  State<ViewFeedbackScreen> createState() => _ViewFeedbackScreenState();
}

class _ViewFeedbackScreenState extends State<ViewFeedbackScreen> {
  final firestoreService = FirestoreService();
  bool _loadingAI = false;
  String? _aiSummary;

  Future<void> _showAISummary(List<SessionModel> sessions) async {
    setState(() => _loadingAI = true);

    try {
      // Collect feedback data
      final feedbackList = <Map<String, dynamic>>[];

      for (var session in sessions) {
        final feedback = await firestoreService.getSessionFeedback(session.sessionId);
        if (feedback != null) {
          feedbackList.add({
            'sessionNumber': session.sessionNumber,
            'therapyName': session.therapyName,
            'rating': feedback.rating,
            'comments': feedback.comments,
            'symptoms': feedback.symptoms,
          });
        }
      }

      if (feedbackList.isEmpty) {
        setState(() {
          _aiSummary = 'No feedback available to summarize.';
          _loadingAI = false;
        });
        _showSummaryDialog();
        return;
      }

      final summary = await GeminiService.summarizeFeedback(
        feedbackList: feedbackList,
      );

      setState(() {
        _aiSummary = summary ?? 'Unable to generate summary. Please try again.';
        _loadingAI = false;
      });

      _showSummaryDialog();
    } catch (e) {
      setState(() {
        _aiSummary = 'Error: ${e.toString()}';
        _loadingAI = false;
      });
      _showSummaryDialog();
    }
  }

  void _showSummaryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.purple),
            SizedBox(width: 8),
            Text('AI Feedback Summary'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.purple),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI-generated summary for informational purposes only',
                        style: TextStyle(fontSize: 12, color: Colors.purple),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(_aiSummary ?? 'Loading...'),
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

  void _showDecisionMenu(TherapyPlanModel plan) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Therapy Decision',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose an action for this therapy plan',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            _DecisionButton(
              icon: Icons.play_circle_outline,
              title: 'Continue Therapy',
              subtitle: 'Keep current plan active',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                _continueTherapy(plan);
              },
            ),
            const SizedBox(height: 12),

            _DecisionButton(
              icon: Icons.pause_circle_outline,
              title: 'Pause Therapy',
              subtitle: 'Temporarily pause treatment',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _pauseTherapy(plan);
              },
            ),
            const SizedBox(height: 12),

            _DecisionButton(
              icon: Icons.swap_horiz,
              title: 'Switch Therapy',
              subtitle: 'Start new therapy plan',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _switchTherapy(plan);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _continueTherapy(TherapyPlanModel plan) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Continue Therapy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add notes about continuing this therapy:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g., Patient showing good progress',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await firestoreService.continueTherapyPlan(
          plan.planId,
          controller.text.trim().isEmpty
              ? 'Therapy continued by doctor'
              : controller.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Therapy plan updated'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _pauseTherapy(TherapyPlanModel plan) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause Therapy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide reason for pausing:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g., Patient needs rest, side effects',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Pause'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await firestoreService.pauseTherapyPlan(
          plan.planId,
          controller.text.trim().isEmpty
              ? 'Paused by doctor'
              : controller.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Therapy plan paused'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _switchTherapy(TherapyPlanModel plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Therapy'),
        content: const Text(
          'This will complete the current plan and start a new assessment. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Switch'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Mark current plan as completed
        await firestoreService.completeTherapyPlan(
          plan.planId,
          'Completed - Switching to new therapy',
        );

        if (mounted) {
          // Navigate to assessment screen for new plan
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AssessmentScreen(
                patientId: widget.patient.patientId,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patient.name),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<TherapyPlanModel?>(
        future: firestoreService.getActiveTherapyPlan(widget.patient.patientId),
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
          final isPaused = plan.status == 'paused';

          return Column(
            children: [
              // Patient Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isPaused ? Colors.orange[50] : Colors.green[50],
                  border: Border(
                    bottom: BorderSide(
                      color: isPaused ? Colors.orange : Colors.green,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.templateName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isPaused)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'PAUSED',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Started: ${DateFormat('MMM dd, yyyy').format(plan.startDate)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (plan.pausedDate != null) ...[
                      Text(
                        'Paused: ${DateFormat('MMM dd, yyyy').format(plan.pausedDate!)}',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Age: ${widget.patient.age}'),
                        const SizedBox(width: 16),
                        Text('Gender: ${widget.patient.gender}'),
                      ],
                    ),
                    if (plan.doctorNotes != null && plan.doctorNotes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.note, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Text(
                                  'Doctor Notes:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              plan.doctorNotes!,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // AI Summary Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _loadingAI ? null : () async {
                    final sessions = await firestoreService
                        .getPlanSessions(plan.planId)
                        .first;
                    _showAISummary(sessions);
                  },
                  icon: _loadingAI
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_loadingAI ? 'Generating...' : 'AI Summary'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[100],
                    foregroundColor: Colors.purple[900],
                  ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                                  label: Text(
                                                    symptom,
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
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
      floatingActionButton: FutureBuilder<TherapyPlanModel?>(
        future: firestoreService.getActiveTherapyPlan(widget.patient.patientId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return FloatingActionButton.extended(
              onPressed: () => _showDecisionMenu(snapshot.data!),
              icon: const Icon(Icons.medical_services),
              label: const Text('Make Decision'),
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _DecisionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DecisionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}