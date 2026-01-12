import 'package:cloud_firestore/cloud_firestore.dart';
// lib/models/therapy_plan_model.dart
class TherapyPlanModel {
  final String planId;
  final String patientId;
  final String doctorId;
  final String templateName;
  final DateTime startDate;
  final int durationDays;
  final String status; // 'active', 'completed', 'paused'
  final DateTime createdAt;

  TherapyPlanModel({
    required this.planId,
    required this.patientId,
    required this.doctorId,
    required this.templateName,
    required this.startDate,
    required this.durationDays,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'patientId': patientId,
      'doctorId': doctorId,
      'templateName': templateName,
      'startDate': Timestamp.fromDate(startDate),
      'durationDays': durationDays,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TherapyPlanModel.fromMap(Map<String, dynamic> map) {
    return TherapyPlanModel(
      planId: map['planId'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      templateName: map['templateName'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      durationDays: map['durationDays'] ?? 0,
      status: map['status'] ?? 'active',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}