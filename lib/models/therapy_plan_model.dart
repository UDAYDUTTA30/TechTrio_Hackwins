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
  final DateTime? pausedDate; // NEW: When therapy was paused
  final String? doctorNotes; // NEW: Doctor's notes/decisions

  TherapyPlanModel({
    required this.planId,
    required this.patientId,
    required this.doctorId,
    required this.templateName,
    required this.startDate,
    required this.durationDays,
    required this.status,
    required this.createdAt,
    this.pausedDate,
    this.doctorNotes,
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
      'pausedDate': pausedDate != null ? Timestamp.fromDate(pausedDate!) : null,
      'doctorNotes': doctorNotes,
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
      pausedDate: map['pausedDate'] != null
          ? (map['pausedDate'] as Timestamp).toDate()
          : null,
      doctorNotes: map['doctorNotes'],
    );
  }

  // Helper to create a copy with updated fields
  TherapyPlanModel copyWith({
    String? planId,
    String? patientId,
    String? doctorId,
    String? templateName,
    DateTime? startDate,
    int? durationDays,
    String? status,
    DateTime? createdAt,
    DateTime? pausedDate,
    String? doctorNotes,
  }) {
    return TherapyPlanModel(
      planId: planId ?? this.planId,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      templateName: templateName ?? this.templateName,
      startDate: startDate ?? this.startDate,
      durationDays: durationDays ?? this.durationDays,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      pausedDate: pausedDate ?? this.pausedDate,
      doctorNotes: doctorNotes ?? this.doctorNotes,
    );
  }
}