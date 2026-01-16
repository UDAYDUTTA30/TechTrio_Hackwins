import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    UserCredential? cred;

    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      // Check if admin already created profile
      final existingProfile = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      final role = existingProfile.docs.isNotEmpty
          ? existingProfile.docs.first['role']
          : 'patient';

      final user = UserModel(
        uid: uid,
        email: email,
        role: role,
        name: name,
        phone: phone,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(user.toMap());
      return user;
    } catch (e) {
      if (cred?.user != null) {
        await cred!.user!.delete(); // rollback
      }
      rethrow;
    }
  }

  Future<UserModel?> signIn(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final doc =
    await _firestore.collection('users').doc(result.user!.uid).get();

    return UserModel.fromMap(
      doc.data() as Map<String, dynamic>,
      doc.id,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
