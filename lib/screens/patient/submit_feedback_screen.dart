// lib/screens/patient/submit_feedback_screen.dart
import 'package:flutter/material.dart';
import '../../models/session_model.dart';
import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';

class SubmitFeedbackScreen extends StatefulWidget {
  final SessionModel session;
  final String patientId;

  const SubmitFeedbackScreen({
    super.key,
    required this.session,
    required this.patientId,
  });

  @override
  State<SubmitFeedbackScreen> createState() => _SubmitFeedbackScreenState();
}

class _SubmitFeedbackScreenState extends State<SubmitFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();
  final _firestoreService = FirestoreService();

  int _rating = 3;
  final List<String> _selectedSymptoms = [];
  bool _loading = false;

  final List<String> _availableSymptoms = [
    'Nausea',
    'Dizziness',
    'Headache',
    'Fatigue',
    'Muscle Pain',
    'Discomfort',
    'Sweating',
    'Itching',
    'Other',
  ];

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // ✅ Create FeedbackModel matching the correct signature
      final feedback = FeedbackModel(
        feedbackId: '', // Will be set by Firestore
        sessionId: widget.session.sessionId,
        patientId: widget.patientId,
        rating: _rating,
        comments: _commentsController.text.trim(),
        symptoms: _selectedSymptoms,
        createdAt: DateTime.now(),
      );

      // ✅ Call with correct signature
      await _firestoreService.submitFeedback(feedback);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Gate check: Only allow if session is completed
    final canSubmit = widget.session.canReceiveFeedback;

    if (!canSubmit) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Session Feedback'),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_clock, size: 80, color: Colors.orange[300]),
                const SizedBox(height: 24),
                const Text(
                  'Feedback Not Available Yet',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'You can submit feedback after your doctor marks this session as completed.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ Main feedback form (UI preserved from original design)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Feedback'),
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
              // Session Info Card
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.session.therapyName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Session #${widget.session.sessionNumber}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Rating Section
              const Text(
                'How was your experience?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            iconSize: 40,
                            icon: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () {
                              setState(() {
                                _rating = index + 1;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getRatingLabel(_rating),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getRatingColor(_rating),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Symptoms Section
              const Text(
                'Did you experience any symptoms?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select all that apply (optional)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableSymptoms.map((symptom) {
                  final isSelected = _selectedSymptoms.contains(symptom);
                  return FilterChip(
                    label: Text(symptom),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSymptoms.add(symptom);
                        } else {
                          _selectedSymptoms.remove(symptom);
                        }
                      });
                    },
                    selectedColor: Colors.orange[200],
                    checkmarkColor: Colors.orange[900],
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Comments Section
              const Text(
                'Additional Comments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share your thoughts about the session (optional)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _commentsController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'e.g., The therapy was relaxing and helped reduce my stress...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _loading ? null : _submitFeedback,
                icon: _loading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.check_circle),
                label: Text(_loading ? 'Submitting...' : 'Submit Feedback'),
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

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Very Poor';
      case 2:
        return 'Poor';
      case 3:
        return 'Average';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    if (rating <= 2) return Colors.red;
    if (rating == 3) return Colors.orange;
    return Colors.green;
  }
}