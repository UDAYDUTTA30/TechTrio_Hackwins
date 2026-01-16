import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_model.dart';
import '../../models/therapy_template_model.dart';
import '../../models/therapy_plan_model.dart';
import '../../models/session_model.dart';

class GenerateScheduleScreen extends StatefulWidget {
  final String patientId;
  final TherapyTemplateModel template;

  const GenerateScheduleScreen({
    super.key,
    required this.patientId,
    required this.template,
  });

  @override
  State<GenerateScheduleScreen> createState() =>
      _GenerateScheduleScreenState();
}

class _GenerateScheduleScreenState
    extends State<GenerateScheduleScreen> {
  bool _loading = false;
  UserModel? _doctor;
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _loadDoctor();
  }

  Future<void> _loadDoctor() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _doctorId = currentUser.uid;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    _doctor = UserModel.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );

    if (mounted) setState(() {});
  }

  Future<void> _generateSchedule() async {
    setState(() => _loading = true);

    try {
      final planRef =
      FirebaseFirestore.instance.collection('therapy_plans').doc();

      final plan = TherapyPlanModel(
        planId: planRef.id,
        patientId: widget.patientId,
        doctorId: _doctorId!, // ✅ FIXED
        templateName: widget.template.name,
        startDate: DateTime.now(),
        durationDays: widget.template.durationDays,
        status: 'active',
        createdAt: DateTime.now(),
      );

      await planRef.set(plan.toMap());

      final batch = FirebaseFirestore.instance.batch();

      for (int i = 0; i < widget.template.therapies.length; i++) {
        final therapy = widget.template.therapies[i];

        final sessionRef = FirebaseFirestore.instance
            .collection('sessions')
            .doc();

        final session = SessionModel(
          sessionId: sessionRef.id,
          planId: plan.planId,
          sessionNumber: i + 1,
          therapyName: therapy.therapyName,
          scheduledDate:
          plan.startDate.add(Duration(days: therapy.dayNumber - 1)),
          status: 'pending',
          prePrecautions: widget.template.prePrecautions,
          postPrecautions: widget.template.postPrecautions,
          duration: therapy.duration,
        );

        batch.set(sessionRef, session.toMap());
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Schedule generated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_doctor == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Therapy Schedule'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doctor: ${_doctor!.name}',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Patient ID: ${widget.patientId}'),
            const SizedBox(height: 8),
            Text('Template: ${widget.template.name}'),
            const SizedBox(height: 24),

            Expanded(
              child: ListView.builder(
                itemCount: widget.template.therapies.length,
                itemBuilder: (context, index) {
                  final t = widget.template.therapies[index];
                  return ListTile(
                    leading: Text('Day ${t.dayNumber}'),
                    title: Text(t.therapyName),
                    subtitle: Text('Duration: ${t.duration}'),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _generateSchedule,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Generate Schedule'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
