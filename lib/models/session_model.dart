import 'package:cloud_firestore/cloud_firestore.dart';

// lib/models/session_model.dart
class SessionModel {
  final String sessionId;
  final String planId;
  final int sessionNumber;
  final String therapyName;
  final DateTime scheduledDate;
  final String status; // 'scheduled', 'completed', 'cancelled', 'missed'
  final List<String> prePrecautions;
  final List<String> postPrecautions;
  final String duration;

  // NEW: Completion tracking (doctor authority)
  final DateTime? completedAt;
  final String? completedBy; // Doctor UID who marked complete

  // NEW: Reschedule tracking
  final DateTime? rescheduledFrom;
  final String? cancellationReason;

  SessionModel({
    required this.sessionId,
    required this.planId,
    required this.sessionNumber,
    required this.therapyName,
    required this.scheduledDate,
    required this.status,
    required this.prePrecautions,
    required this.postPrecautions,
    required this.duration,
    this.completedAt,
    this.completedBy,
    this.rescheduledFrom,
    this.cancellationReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'planId': planId,
      'sessionNumber': sessionNumber,
      'therapyName': therapyName,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'status': status,
      'prePrecautions': prePrecautions,
      'postPrecautions': postPrecautions,
      'duration': duration,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completedBy': completedBy,
      'rescheduledFrom': rescheduledFrom != null ? Timestamp.fromDate(rescheduledFrom!) : null,
      'cancellationReason': cancellationReason,
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      sessionId: map['sessionId'] ?? '',
      planId: map['planId'] ?? '',
      sessionNumber: map['sessionNumber'] ?? 0,
      therapyName: map['therapyName'] ?? '',
      scheduledDate: (map['scheduledDate'] as Timestamp).toDate(),
      status: map['status'] ?? 'scheduled',
      prePrecautions: List<String>.from(map['prePrecautions'] ?? []),
      postPrecautions: List<String>.from(map['postPrecautions'] ?? []),
      duration: map['duration'] ?? '',
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      completedBy: map['completedBy'],
      rescheduledFrom: map['rescheduledFrom'] != null
          ? (map['rescheduledFrom'] as Timestamp).toDate()
          : null,
      cancellationReason: map['cancellationReason'],
    );
  }

  // Helper to check if session can accept feedback
  bool get canReceiveFeedback => status == 'completed';

  // Helper to check if session is in the past
  bool get isOverdue => scheduledDate.isBefore(DateTime.now()) && status == 'scheduled';
}