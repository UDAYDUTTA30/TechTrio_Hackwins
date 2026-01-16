// lib/screens/patient/session_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/session_model.dart';
import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';
import '../../services/gemini_service.dart';
import 'submit_feedback_screen.dart';

class SessionDetailScreen extends StatefulWidget {
  final SessionModel session;
  final String patientId;

  const SessionDetailScreen({
    super.key,
    required this.session,
    required this.patientId,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final firestoreService = FirestoreService();
  bool _loadingAI = false;
  String? _aiExplanation;

  Future<void> _getAIExplanation() async {
    setState(() => _loadingAI = true);

    try {
      final explanation = await GeminiService.explainTherapy(
        therapyName: widget.session.therapyName,
        prePrecautions: widget.session.prePrecautions,
        postPrecautions: widget.session.postPrecautions,
      );

      setState(() {
        _aiExplanation = explanation ?? 'Unable to generate explanation. Please try again.';
        _loadingAI = false;
      });

      _showExplanationDialog();
    } catch (e) {
      setState(() {
        _aiExplanation = 'Error: ${e.toString()}';
        _loadingAI = false;
      });
      _showExplanationDialog();
    }
  }

  void _showExplanationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber),
            SizedBox(width: 8),
            Text('Understanding Your Therapy'),
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
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI-generated explanation for informational purposes only',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(_aiExplanation ?? 'Loading...'),
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

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Use model helper for gating
    final canSubmitFeedback = widget.session.canReceiveFeedback;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<FeedbackModel?>(
        future: firestoreService.getSessionFeedback(widget.session.sessionId),
        builder: (context, feedbackSnapshot) {
          final feedback = feedbackSnapshot.data;
          final hasFeedback = feedback != null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Session Info Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.session.therapyName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (canSubmitFeedback)
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
                        value: DateFormat('EEEE, MMM dd, yyyy').format(widget.session.scheduledDate),
                      ),
                      _InfoRow(
                        icon: Icons.access_time,
                        label: 'Duration',
                        value: widget.session.duration,
                      ),
                      _InfoRow(
                        icon: Icons.numbers,
                        label: 'Session',
                        value: '#${widget.session.sessionNumber}',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // AI Explanation Button
              OutlinedButton.icon(
                onPressed: _loadingAI ? null : _getAIExplanation,
                icon: _loadingAI
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.lightbulb_outline),
                label: Text(_loadingAI ? 'Loading...' : 'Explain This Therapy'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  foregroundColor: Colors.amber[700],
                  side: BorderSide(color: Colors.amber[700]!),
                ),
              ),

              const SizedBox(height: 24),

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
                    children: widget.session.prePrecautions.map((precaution) {
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
                    children: widget.session.postPrecautions.map((precaution) {
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

              // ✅ FIXED: Feedback Section with proper gating
              if (hasFeedback) ...[
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
                  elevation: 2,
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
              ] else if (canSubmitFeedback) ...[
                // ✅ Show button ONLY if session is completed
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubmitFeedbackScreen(
                          session: widget.session,
                          patientId: widget.patientId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.feedback),
                  label: const Text('Submit Feedback'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                ),
              ] else ...[
                // ✅ Show waiting message if not completed
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_clock, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Feedback will be available after your doctor marks this session as completed.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
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