// lib/screens/doctor/assessment_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'select_template_screen.dart';

class AssessmentScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const AssessmentScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Prakriti (Body Constitution)
  String _vata = 'Moderate';
  String _pitta = 'Moderate';
  String _kapha = 'Moderate';

  // Symptoms
  final Map<String, bool> _symptoms = {
    'Joint Pain': false,
    'Digestive Issues': false,
    'Stress/Anxiety': false,
    'Sleep Problems': false,
    'Skin Issues': false,
    'Headache': false,
    'Fatigue': false,
    'Other': false,
  };

  final _notesController = TextEditingController();
  final _chiefComplaintController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    _chiefComplaintController.dispose();
    super.dispose();
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Prepare assessment data
      final assessment = {
        'prakriti': {
          'vata': _vata,
          'pitta': _pitta,
          'kapha': _kapha,
        },
        'symptoms': _symptoms.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList(),
        'chiefComplaint': _chiefComplaintController.text.trim(),
        'notes': _notesController.text.trim(),
        'assessmentDate': Timestamp.now(),
      };

      // Update patient record
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .update({'assessment': assessment});

      if (mounted) {
        // Navigate to template selection
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SelectTemplateScreen(
              patientId: widget.patientId,
              patientName: widget.patientName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPrakritiSelector(String dosha, String value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dosha,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(value: 'Low', child: Text('Low')),
            DropdownMenuItem(value: 'Moderate', child: Text('Moderate')),
            DropdownMenuItem(value: 'High', child: Text('High')),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayurvedic Assessment'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Patient: ${widget.patientName}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Prakriti Assessment
            const Text(
              'Prakriti (Body Constitution)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            _buildPrakritiSelector('Vata', _vata, (value) {
              setState(() => _vata = value!);
            }),
            const SizedBox(height: 16),
            _buildPrakritiSelector('Pitta', _pitta, (value) {
              setState(() => _pitta = value!);
            }),
            const SizedBox(height: 16),
            _buildPrakritiSelector('Kapha', _kapha, (value) {
              setState(() => _kapha = value!);
            }),

            const SizedBox(height: 32),

            // Chief Complaint
            const Text(
              'Chief Complaint',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _chiefComplaintController,
              decoration: const InputDecoration(
                hintText: 'Primary reason for consultation',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter chief complaint';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Symptoms Checklist
            const Text(
              'Symptoms Checklist',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select all that apply',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ..._symptoms.keys.map((symptom) {
              return CheckboxListTile(
                title: Text(symptom),
                value: _symptoms[symptom],
                onChanged: (value) {
                  setState(() => _symptoms[symptom] = value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            }),

            const SizedBox(height: 32),

            // Additional Notes
            const Text(
              'Additional Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Any additional observations or notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveAssessment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text(
                'Save Assessment & Select Therapy',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}