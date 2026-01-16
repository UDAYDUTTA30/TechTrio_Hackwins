// lib/screens/doctor/assessment_screen.dart
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import 'select_template_screen.dart';

class AssessmentScreen extends StatefulWidget {
  final String patientId;

  const AssessmentScreen({
    super.key,
    required this.patientId,
  });

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  // Form controllers
  final _chiefComplaintsController = TextEditingController();
  final _medicalHistoryController = TextEditingController();
  final _currentMedicationsController = TextEditingController();
  final _allergiesController = TextEditingController();

  String _prakriti = 'Vata';
  String _digestiveHealth = 'Good';
  String _sleepQuality = 'Good';
  String _stressLevel = 'Low';

  bool _loading = false;

  @override
  void dispose() {
    _chiefComplaintsController.dispose();
    _medicalHistoryController.dispose();
    _currentMedicationsController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _saveAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final assessment = {
        'chiefComplaints': _chiefComplaintsController.text.trim(),
        'medicalHistory': _medicalHistoryController.text.trim(),
        'currentMedications': _currentMedicationsController.text.trim(),
        'allergies': _allergiesController.text.trim(),
        'prakriti': _prakriti,
        'digestiveHealth': _digestiveHealth,
        'sleepQuality': _sleepQuality,
        'stressLevel': _stressLevel,
        'assessmentDate': DateTime.now().toIso8601String(),
      };

      await _firestoreService.updatePatientAssessment(
        widget.patientId,
        assessment,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assessment saved successfully')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SelectTemplateScreen(
              patientId: widget.patientId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving assessment: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Assessment'),
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
                'Ayurvedic Assessment',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Patient ID: ${widget.patientId}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),

              // Chief Complaints
              TextFormField(
                controller: _chiefComplaintsController,
                decoration: const InputDecoration(
                  labelText: 'Chief Complaints',
                  hintText: 'Main health concerns or symptoms',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.healing),
                ),
                maxLines: 3,
                validator: (v) =>
                v == null || v.isEmpty ? 'Enter chief complaints' : null,
              ),
              const SizedBox(height: 16),

              // Medical History
              TextFormField(
                controller: _medicalHistoryController,
                decoration: const InputDecoration(
                  labelText: 'Medical History',
                  hintText: 'Past illnesses, surgeries, conditions',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.history),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Current Medications
              TextFormField(
                controller: _currentMedicationsController,
                decoration: const InputDecoration(
                  labelText: 'Current Medications',
                  hintText: 'List all current medications',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Allergies
              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(
                  labelText: 'Allergies',
                  hintText: 'Any known allergies',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning_amber),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Prakriti (Constitution)
              DropdownButtonFormField<String>(
                value: _prakriti,
                decoration: const InputDecoration(
                  labelText: 'Prakriti (Body Constitution)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: const [
                  DropdownMenuItem(value: 'Vata', child: Text('Vata')),
                  DropdownMenuItem(value: 'Pitta', child: Text('Pitta')),
                  DropdownMenuItem(value: 'Kapha', child: Text('Kapha')),
                  DropdownMenuItem(value: 'Vata-Pitta', child: Text('Vata-Pitta')),
                  DropdownMenuItem(value: 'Pitta-Kapha', child: Text('Pitta-Kapha')),
                  DropdownMenuItem(value: 'Vata-Kapha', child: Text('Vata-Kapha')),
                ],
                onChanged: (v) => setState(() => _prakriti = v!),
              ),
              const SizedBox(height: 16),

              // Digestive Health
              DropdownButtonFormField<String>(
                value: _digestiveHealth,
                decoration: const InputDecoration(
                  labelText: 'Digestive Health',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant),
                ),
                items: const [
                  DropdownMenuItem(value: 'Good', child: Text('Good')),
                  DropdownMenuItem(value: 'Moderate', child: Text('Moderate')),
                  DropdownMenuItem(value: 'Poor', child: Text('Poor')),
                ],
                onChanged: (v) => setState(() => _digestiveHealth = v!),
              ),
              const SizedBox(height: 16),

              // Sleep Quality
              DropdownButtonFormField<String>(
                value: _sleepQuality,
                decoration: const InputDecoration(
                  labelText: 'Sleep Quality',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bedtime),
                ),
                items: const [
                  DropdownMenuItem(value: 'Good', child: Text('Good')),
                  DropdownMenuItem(value: 'Moderate', child: Text('Moderate')),
                  DropdownMenuItem(value: 'Poor', child: Text('Poor')),
                ],
                onChanged: (v) => setState(() => _sleepQuality = v!),
              ),
              const SizedBox(height: 16),

              // Stress Level
              DropdownButtonFormField<String>(
                value: _stressLevel,
                decoration: const InputDecoration(
                  labelText: 'Stress Level',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.psychology),
                ),
                items: const [
                  DropdownMenuItem(value: 'Low', child: Text('Low')),
                  DropdownMenuItem(value: 'Moderate', child: Text('Moderate')),
                  DropdownMenuItem(value: 'High', child: Text('High')),
                ],
                onChanged: (v) => setState(() => _stressLevel = v!),
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _loading ? null : _saveAssessment,
                icon: _loading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.save),
                label: Text(_loading ? 'Saving...' : 'Save & Continue to Templates'),
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