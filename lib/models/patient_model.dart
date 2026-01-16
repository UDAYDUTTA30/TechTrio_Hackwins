
import 'package:cloud_firestore/cloud_firestore.dart';

// lib/models/patient_model.dart
class PatientModel {
  final String patientId;
  final String userId; // Reference to user account (if patient has login)
  final String doctorId;
  final String name;
  final int age;
  final String gender;
  final Map<String, dynamic> assessment;
  final DateTime createdAt;

  PatientModel({
    required this.patientId,
    required this.userId,
    required this.doctorId,
    required this.name,
    required this.age,
    required this.gender,
    required this.assessment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'userId': userId,
      'doctorId': doctorId,
      'name': name,
      'age': age,
      'gender': gender,
      'assessment': assessment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PatientModel.fromMap(Map<String, dynamic> map) {
    return PatientModel(
      patientId: map['patientId'] ?? '',
      userId: map['userId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? '',
      assessment: Map<String, dynamic>.from(map['assessment'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}