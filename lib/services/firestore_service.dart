// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_model.dart';
import '../models/therapy_plan_model.dart';
import '../models/session_model.dart';
import '../models/feedback_model.dart';
import '../models/therapy_template_model.dart';
import 'therapy_template_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== PATIENT OPERATIONS ==========

  // Create patient
  Future<String> createPatient(PatientModel patient) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('patients')
          .add(patient.toMap());

      // Update with generated ID
      await docRef.update({'patientId': docRef.id});
      return docRef.id;
    } catch (e) {
      print('Create patient error: $e');
      rethrow;
    }
  }

  // Update patient assessment
  Future<void> updatePatientAssessment(
      String patientId, Map<String, dynamic> assessment) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientId)
          .update({'assessment': assessment});
    } catch (e) {
      print('Update assessment error: $e');
      rethrow;
    }
  }

  // Get patients for a doctor
  Stream<List<PatientModel>> getDoctorPatients(String doctorId) {
    return _firestore
        .collection('patients')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PatientModel.fromMap(doc.data()))
        .toList());
  }

  // Get single patient
  Future<PatientModel?> getPatient(String patientId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('patients')
          .doc(patientId)
          .get();

      if (doc.exists) {
        return PatientModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Get patient error: $e');
    }
    return null;
  }

  // ========== THERAPY PLAN OPERATIONS ==========

  // Create therapy plan
  Future<String> createTherapyPlan(TherapyPlanModel plan) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('therapy_plans')
          .add(plan.toMap());

      await docRef.update({'planId': docRef.id});
      return docRef.id;
    } catch (e) {
      print('Create therapy plan error: $e');
      rethrow;
    }
  }

  // Get therapy plan for patient
  Future<TherapyPlanModel?> getActiveTherapyPlan(String patientId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('therapy_plans')
          .where('patientId', isEqualTo: patientId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return TherapyPlanModel.fromMap(
            snapshot.docs.first.data() as Map<String, dynamic>
        );
      }
    } catch (e) {
      print('Get therapy plan error: $e');
    }
    return null;
  }

  // ========== SESSION OPERATIONS ==========

  // Create sessions for a therapy plan
  Future<void> createSessions(List<SessionModel> sessions) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (SessionModel session in sessions) {
        DocumentReference docRef = _firestore.collection('sessions').doc();
        batch.set(docRef, session.toMap());
        batch.update(docRef, {'sessionId': docRef.id});
      }

      await batch.commit();
    } catch (e) {
      print('Create sessions error: $e');
      rethrow;
    }
  }

  // Get sessions for a therapy plan
  Stream<List<SessionModel>> getPlanSessions(String planId) {
    return _firestore
        .collection('sessions')
        .where('planId', isEqualTo: planId)
        .orderBy('sessionNumber')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => SessionModel.fromMap(doc.data()))
        .toList());
  }

  // Update session status
  Future<void> updateSessionStatus(String sessionId, String status) async {
    try {
      await _firestore
          .collection('sessions')
          .doc(sessionId)
          .update({'status': status});
    } catch (e) {
      print('Update session status error: $e');
      rethrow;
    }
  }

  // ========== FEEDBACK OPERATIONS ==========

  // Submit feedback
  Future<String> submitFeedback(FeedbackModel feedback) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('feedback')
          .add(feedback.toMap());

      await docRef.update({'feedbackId': docRef.id});

      // Mark session as completed
      await updateSessionStatus(feedback.sessionId, 'completed');

      return docRef.id;
    } catch (e) {
      print('Submit feedback error: $e');
      rethrow;
    }
  }

  // Get feedback for a session
  Future<FeedbackModel?> getSessionFeedback(String sessionId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('feedback')
          .where('sessionId', isEqualTo: sessionId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return FeedbackModel.fromMap(
            snapshot.docs.first.data() as Map<String, dynamic>
        );
      }
    } catch (e) {
      print('Get session feedback error: $e');
    }
    return null;
  }

  // Get all feedback for a patient
  Stream<List<FeedbackModel>> getPatientFeedback(String patientId) {
    return _firestore
        .collection('feedback')
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FeedbackModel.fromMap(doc.data()))
        .toList());
  }

  // ========== THERAPY TEMPLATE OPERATIONS ==========

  // ✅ NEW: Auto-seed templates if collection is empty
  Future<void> ensureTemplatesExist() async {
    try {
      final snapshot = await _firestore
          .collection('therapy_templates')
          .limit(1)
          .get();

      // If templates already exist, do nothing
      if (snapshot.docs.isNotEmpty) {
        return;
      }

      // Otherwise, seed predefined templates
      print('No templates found. Seeding predefined templates...');
      final templates = TherapyTemplateService.getPredefinedTemplates();

      WriteBatch batch = _firestore.batch();
      for (var template in templates) {
        DocumentReference docRef = _firestore
            .collection('therapy_templates')
            .doc(template.templateId);
        batch.set(docRef, template.toMap());
      }

      await batch.commit();
      print('✅ Templates seeded successfully');
    } catch (e) {
      print('Error seeding templates: $e');
    }
  }

  // Get all templates
  Future<List<TherapyTemplateModel>> getAllTemplates() async {
    try {
      // ✅ Ensure templates exist before querying
      await ensureTemplatesExist();

      QuerySnapshot snapshot = await _firestore
          .collection('therapy_templates')
          .get();

      return snapshot.docs
          .map((doc) => TherapyTemplateModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Get templates error: $e');
      return [];
    }
  }

  // Get single template
  Future<TherapyTemplateModel?> getTemplate(String templateId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('therapy_templates')
          .doc(templateId)
          .get();

      if (doc.exists) {
        return TherapyTemplateModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Get template error: $e');
    }
    return null;
  }

  // ========== DOCTOR DECISION OPERATIONS ==========

  // Pause therapy plan
  Future<void> pauseTherapyPlan(String planId, String reason) async {
    try {
      await _firestore.collection('therapy_plans').doc(planId).update({
        'status': 'paused',
        'pausedDate': Timestamp.now(),
        'doctorNotes': reason,
      });
    } catch (e) {
      print('Pause therapy plan error: $e');
      rethrow;
    }
  }

  // Continue/Resume therapy plan
  Future<void> continueTherapyPlan(String planId, String notes) async {
    try {
      await _firestore.collection('therapy_plans').doc(planId).update({
        'status': 'active',
        'pausedDate': null,
        'doctorNotes': notes,
      });
    } catch (e) {
      print('Continue therapy plan error: $e');
      rethrow;
    }
  }

  // Mark therapy plan as completed
  Future<void> completeTherapyPlan(String planId, String notes) async {
    try {
      await _firestore.collection('therapy_plans').doc(planId).update({
        'status': 'completed',
        'doctorNotes': notes,
      });
    } catch (e) {
      print('Complete therapy plan error: $e');
      rethrow;
    }
  }
}