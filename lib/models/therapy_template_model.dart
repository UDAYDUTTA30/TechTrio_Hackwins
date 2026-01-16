// lib/models/therapy_template_model.dart
class TherapyTemplateModel {
  final String templateId;
  final String name;
  final String description;
  final List<TherapySession> therapies;
  final int durationDays;
  final List<String> prePrecautions;
  final List<String> postPrecautions;

  TherapyTemplateModel({
    required this.templateId,
    required this.name,
    required this.description,
    required this.therapies,
    required this.durationDays,
    required this.prePrecautions,
    required this.postPrecautions,
  });

  Map<String, dynamic> toMap() {
    return {
      'templateId': templateId,
      'name': name,
      'description': description,
      'therapies': therapies.map((t) => t.toMap()).toList(),
      'durationDays': durationDays,
      'prePrecautions': prePrecautions,
      'postPrecautions': postPrecautions,
    };
  }

  factory TherapyTemplateModel.fromMap(Map<String, dynamic> map) {
    return TherapyTemplateModel(
      templateId: map['templateId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      therapies: (map['therapies'] as List)
          .map((t) => TherapySession.fromMap(t))
          .toList(),
      durationDays: map['durationDays'] ?? 0,
      prePrecautions: List<String>.from(map['prePrecautions'] ?? []),
      postPrecautions: List<String>.from(map['postPrecautions'] ?? []),
    );
  }
}

class TherapySession {
  final String therapyName;
  final String duration;
  final int dayNumber;

  TherapySession({
    required this.therapyName,
    required this.duration,
    required this.dayNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'therapyName': therapyName,
      'duration': duration,
      'dayNumber': dayNumber,
    };
  }

  factory TherapySession.fromMap(Map<String, dynamic> map) {
    return TherapySession(
      therapyName: map['therapyName'] ?? '',
      duration: map['duration'] ?? '',
      dayNumber: map['dayNumber'] ?? 0,
    );
  }
}