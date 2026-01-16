import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/doctor/doctor_home_screen.dart';
import '../screens/patient/patient_home_screen.dart';

class RoleRouter extends StatefulWidget {
  final String uid;

  const RoleRouter({super.key, required this.uid});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      final data = snapshot.data();
      if (data == null) {
        _user = null;
      } else {
        _user = UserModel.fromMap(data, snapshot.id);
      }
    } catch (_) {
      _user = null;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('User profile not found')),
      );
    }

    switch (_user!.role) {
      case 'admin':
        return AdminHomeScreen(user: _user!);
      case 'doctor':
        return DoctorHomeScreen(user: _user!);
      default:
        return PatientHomeScreen(user: _user!);
    }
  }
}
