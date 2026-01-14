// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // 'admin' | 'doctor' | 'patient'
  final String name;
  final String phone;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    required this.phone,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'name': name,
      'phone': phone,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    final role = map['role'];

    if (role != 'admin' && role != 'doctor' && role != 'patient') {
      throw Exception('Invalid user role: $role');
    }

    return UserModel(
      uid: uid, // ✅ use document ID, NOT map['uid']
      email: map['email'] as String,
      role: role as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
