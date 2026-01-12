// lib/services/therapy_template_service.dart
import '../models/therapy_template_model.dart';

class TherapyTemplateService {
  // Predefined therapy templates (in real app, these would be in Firestore)
  static List<TherapyTemplateModel> getPredefinedTemplates() {
    return [
      TherapyTemplateModel(
        templateId: 'template_1',
        name: 'Panchakarma Basic (7 Days)',
        description: 'Basic detoxification therapy for general wellness',
        durationDays: 7,
        therapies: [
          TherapySession(therapyName: 'Abhyanga (Oil Massage)', duration: '45 min', dayNumber: 1),
          TherapySession(therapyName: 'Swedana (Steam Therapy)', duration: '20 min', dayNumber: 1),
          TherapySession(therapyName: 'Abhyanga', duration: '45 min', dayNumber: 2),
          TherapySession(therapyName: 'Swedana', duration: '20 min', dayNumber: 2),
          TherapySession(therapyName: 'Virechana (Purgation)', duration: '2 hours', dayNumber: 3),
          TherapySession(therapyName: 'Rest & Diet', duration: 'Full day', dayNumber: 4),
          TherapySession(therapyName: 'Basti (Enema)', duration: '45 min', dayNumber: 5),
          TherapySession(therapyName: 'Abhyanga', duration: '45 min', dayNumber: 6),
          TherapySession(therapyName: 'Shirodhara (Oil on Forehead)', duration: '30 min', dayNumber: 7),
        ],
        prePrecautions: [
          'Avoid heavy meals 3 hours before',
          'Drink warm water',
          'Avoid cold beverages',
          'Wear comfortable clothing',
        ],
        postPrecautions: [
          'Rest for 30 minutes after therapy',
          'Avoid cold water bath for 2 hours',
          'Follow prescribed diet',
          'Avoid strenuous activities',
        ],
      ),
      TherapyTemplateModel(
        templateId: 'template_2',
        name: 'Stress Relief (5 Days)',
        description: 'Specialized therapy for stress and anxiety management',
        durationDays: 5,
        therapies: [
          TherapySession(therapyName: 'Shirodhara', duration: '45 min', dayNumber: 1),
          TherapySession(therapyName: 'Abhyanga', duration: '45 min', dayNumber: 2),
          TherapySession(therapyName: 'Shirodhara', duration: '45 min', dayNumber: 3),
          TherapySession(therapyName: 'Pada Abhyanga (Foot Massage)', duration: '30 min', dayNumber: 4),
          TherapySession(therapyName: 'Shirodhara', duration: '45 min', dayNumber: 5),
        ],
        prePrecautions: [
          'Empty stomach or light meal',
          'Arrive 10 minutes early',
          'Inform about any allergies',
        ],
        postPrecautions: [
          'Rest for 1 hour',
          'Avoid screen time',
          'Practice deep breathing',
        ],
      ),
      TherapyTemplateModel(
        templateId: 'template_3',
        name: 'Joint Pain Relief (10 Days)',
        description: 'Therapy for joint pain and arthritis management',
        durationDays: 10,
        therapies: [
          TherapySession(therapyName: 'Abhyanga with Herbal Oil', duration: '50 min', dayNumber: 1),
          TherapySession(therapyName: 'Janu Basti (Knee Treatment)', duration: '40 min', dayNumber: 2),
          TherapySession(therapyName: 'Abhyanga', duration: '50 min', dayNumber: 3),
          TherapySession(therapyName: 'Pinda Swedana', duration: '45 min', dayNumber: 4),
          TherapySession(therapyName: 'Janu Basti', duration: '40 min', dayNumber: 5),
          TherapySession(therapyName: 'Abhyanga', duration: '50 min', dayNumber: 6),
          TherapySession(therapyName: 'Basti Therapy', duration: '45 min', dayNumber: 7),
          TherapySession(therapyName: 'Abhyanga', duration: '50 min', dayNumber: 8),
          TherapySession(therapyName: 'Janu Basti', duration: '40 min', dayNumber: 9),
          TherapySession(therapyName: 'Final Assessment', duration: '30 min', dayNumber: 10),
        ],
        prePrecautions: [
          'Avoid heavy exercise before session',
          'Inform about pain levels',
          'Wear loose clothing',
        ],
        postPrecautions: [
          'Avoid cold exposure',
          'Do gentle stretching as advised',
          'Follow prescribed diet',
          'Take adequate rest',
        ],
      ),
    ];
  }
}