// lib/screens/doctor/generate_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/therapy_template_model.dart';
import '../../models/therapy_plan_model.dart';
import '../../models/session_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../doctor/doctor_home_screen.dart';

class GenerateScheduleScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final TherapyTemplateModel template;

  const GenerateScheduleScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.template,
  });

  @override
  State<GenerateScheduleScreen> createState() => _GenerateScheduleScreenState();
}

class _GenerateScheduleScreenState extends State<GenerateScheduleScreen> {
  DateTime _startDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _generateSchedule() async {
    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final firestoreService = FirestoreService();
      final currentUser = authService.currentUser;

      if (currentUser == null) return;

      // Create therapy plan
      final plan = TherapyPlanModel(
        planId: '',
        patientId: widget.patientId,
        doctorId: currentUser.uid,
        templateName: widget.template.name,
        startDate: _startDate,
        durationDays: widget.template.durationDays,
        status: 'active',
        createdAt: DateTime.now(),
      );

      final planId = await firestoreService.createTherapyPlan(plan);

      // Create sessions based on template
      final sessions = <SessionModel>[];
      for (int i = 0; i < widget.template.therapies.length; i++) {
        final therapy = widget.template.therapies[i];
        final sessionDate = _startDate.add(Duration(days: therapy.dayNumber - 1));

        sessions.add(SessionModel(
          sessionId: '',
          planId: planId,
          sessionNumber: i + 1,
          therapyName: therapy.therapyName,
          scheduledDate: sessionDate,
          status: 'pending',
          prePrecautions: widget.template.prePrecautions,
          postPrecautions: widget.template.postPrecautions,
          duration: therapy.duration,
        ));
      }

      await firestoreService.createSessions(sessions);

      if (mounted) {
        // Show success and navigate back to home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Therapy schedule created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to doctor home
        final userData = await authService.getUserData(currentUser.uid);
        if (userData != null && mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => DoctorHomeScreen(user: userData),
            ),
                (route) => false,
          );
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Schedule'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.template.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Patient: ${widget.patientName}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Start Date Selection
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.green),
              title: const Text('Start Date'),
              subtitle: Text(DateFormat('EEEE, MMM dd, yyyy').format(_startDate)),
              trailing: const Icon(Icons.edit),
              onTap: _selectDate,
            ),
          ),

          const SizedBox(height: 24),

          // Template Details
          const Text(
            'Therapy Sessions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.template.therapies.map((therapy) {
            final sessionDate = _startDate.add(Duration(days: therapy.dayNumber - 1));
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green[100],
                  child: Text(
                    'D${therapy.dayNumber}',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                title: Text(
                  therapy.therapyName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '${DateFormat('MMM dd').format(sessionDate)} • ${therapy.duration}',
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Precautions
          const Text(
            'Pre-Session Precautions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.template.prePrecautions.map((precaution) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, size: 20, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(precaution)),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          const Text(
            'Post-Session Precautions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.template.postPrecautions.map((precaution) {
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
          }),

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _generateSchedule,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
            ),
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text(
              'Generate Schedule',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}