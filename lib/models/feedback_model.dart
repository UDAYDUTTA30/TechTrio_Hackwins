import 'package:cloud_firestore/cloud_firestore.dart';

// lib/models/feedback_model.dart
class FeedbackModel {
  final String feedbackId;
  final String sessionId;
  final String patientId;
  final int rating; // 1-5
  final String comments;
  final List<String> symptoms;
  final DateTime createdAt;

  FeedbackModel({
    required this.feedbackId,
    required this.sessionId,
    required this.patientId,
    required this.rating,
    required this.comments,
    required this.symptoms,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'feedbackId': feedbackId,
      'sessionId': sessionId,
      'patientId': patientId,
      'rating': rating,
      'comments': comments,
      'symptoms': symptoms,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      feedbackId: map['feedbackId'] ?? '',
      sessionId: map['sessionId'] ?? '',
      patientId: map['patientId'] ?? '',
      rating: map['rating'] ?? 0,
      comments: map['comments'] ?? '',
      symptoms: List<String>.from(map['symptoms'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
