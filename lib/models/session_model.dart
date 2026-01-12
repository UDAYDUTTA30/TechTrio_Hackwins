import 'package:cloud_firestore/cloud_firestore.dart';

// lib/models/session_model.dart
class SessionModel {
  final String sessionId;
  final String planId;
  final int sessionNumber;
  final String therapyName;
  final DateTime scheduledDate;
  final String status; // 'pending', 'completed', 'skipped'
  final List<String> prePrecautions;
  final List<String> postPrecautions;
  final String duration;

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
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      sessionId: map['sessionId'] ?? '',
      planId: map['planId'] ?? '',
      sessionNumber: map['sessionNumber'] ?? 0,
      therapyName: map['therapyName'] ?? '',
      scheduledDate: (map['scheduledDate'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      prePrecautions: List<String>.from(map['prePrecautions'] ?? []),
      postPrecautions: List<String>.from(map['postPrecautions'] ?? []),
      duration: map['duration'] ?? '',
    );
  }
}