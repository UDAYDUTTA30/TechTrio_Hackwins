// lib/screens/doctor/manage_session_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/session_model.dart';
import '../../models/patient_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageSessionScreen extends StatefulWidget {
  final SessionModel session;
  final PatientModel patient;

  const ManageSessionScreen({
    super.key,
    required this.session,
    required this.patient,
  });

  @override
  State<ManageSessionScreen> createState() => _ManageSessionScreenState();
}

class _ManageSessionScreenState extends State<ManageSessionScreen> {
  final _firestoreService = FirestoreService();
  bool _loading = false;

  Future<void> _markCompleted() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Session Completed'),
        content: const Text(
          'Confirm that this therapy session has been completed. '
              'The patient will be able to submit feedback after this.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Completed'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _loading = true);
      try {
        final doctorId = FirebaseAuth.instance.currentUser!.uid;

        await _firestoreService.markSessionCompleted(
          widget.session.sessionId,
          doctorId,
        );

        // Notify patient
        await NotificationService.notifySessionCompleted(
          patientId: widget.patient.userId,
          therapyName: widget.session.therapyName,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session marked as completed'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _rescheduleSession() async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: widget.session.scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (newDate != null) {
      setState(() => _loading = true);
      try {
        final doctorId = FirebaseAuth.instance.currentUser!.uid;

        await _firestoreService.rescheduleSession(
          widget.session.sessionId,
          newDate,
          doctorId,
        );

        // Notify patient
        await NotificationService.notifySessionRescheduled(
          patientId: widget.patient.userId,
          therapyName: widget.session.therapyName,
          newDate: newDate,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session rescheduled'),
              backgroundColor: Colors.blue,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _cancelSession() async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancellation:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g., Patient unavailable, rescheduled',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Session'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _loading = true);
      try {
        await _firestoreService.cancelSession(
          widget.session.sessionId,
          controller.text.trim().isEmpty
              ? 'Cancelled by doctor'
              : controller.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session cancelled'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _markMissed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Missed'),
        content: const Text(
          'This will mark the session as missed. '
              'Use this when the patient did not attend.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Missed'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _loading = true);
      try {
        await _firestoreService.markSessionMissed(widget.session.sessionId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session marked as missed'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canComplete =
        widget.session.status == 'scheduled' || widget.session.status == 'pending';

    final isCompleted = widget.session.status == 'completed';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Session'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Session Info
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.session.therapyName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.person,
                      label: 'Patient',
                      value: widget.patient.name,
                    ),
                    _InfoRow(
                      icon: Icons.calendar_today,
                      label: 'Scheduled',
                      value: DateFormat('EEEE, MMM dd, yyyy')
                          .format(widget.session.scheduledDate),
                    ),
                    _InfoRow(
                      icon: Icons.access_time,
                      label: 'Duration',
                      value: widget.session.duration,
                    ),
                    _InfoRow(
                      icon: Icons.label,
                      label: 'Status',
                      value: widget.session.status.toUpperCase(),
                      valueColor: _getStatusColor(widget.session.status),
                    ),
                    if (widget.session.completedAt != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.check_circle,
                        label: 'Completed',
                        value: DateFormat('MMM dd, yyyy hh:mm a')
                            .format(widget.session.completedAt!),
                        valueColor: Colors.green,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            if (isCompleted) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This session has been completed. '
                            'Patient can now submit feedback.',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Text(
                'Session Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (canComplete)
                ElevatedButton.icon(
                  onPressed: _markCompleted,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark Session Completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),

              if (canComplete) const SizedBox(height: 12),

              if (canComplete)
                OutlinedButton.icon(
                  onPressed: _rescheduleSession,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Reschedule Session'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    foregroundColor: Colors.blue,
                  ),
                ),

              const SizedBox(height: 12),

              if (canComplete)
                OutlinedButton.icon(
                  onPressed: _markMissed,
                  icon: const Icon(Icons.event_busy),
                  label: const Text('Mark as Missed'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    foregroundColor: Colors.orange,
                  ),
                ),

              const SizedBox(height: 12),

              if (canComplete)
                OutlinedButton.icon(
                  onPressed: _cancelSession,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Session'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    foregroundColor: Colors.red,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'scheduled':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'missed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}