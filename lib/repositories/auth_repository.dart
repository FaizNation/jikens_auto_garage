import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email, 
      password: password
    );
  }

  Future<UserCredential> register(String fullName, String email, String password) async {
    // 1. Create Firebase Auth User
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Save user profile to Firestore `users` collection
    if (userCredential.user != null) {
      final role = email.toLowerCase() == 'admin@gmail.com' ? 'admin' : 'customer';
      
      final userModel = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        fullName: fullName,
        role: role, 
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toJson());
    }

    return userCredential;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Get the role of a user from Firestore
  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['role'] ?? 'customer';
      }
    } catch (e) {
      if (_auth.currentUser?.email == 'admin@gmail.com') return 'admin';
    }
    return 'customer';
  }

  /// Get full user profile (role + displayName) from Firestore
  Future<Map<String, String>> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          'role': data['role'] ?? 'customer',
          'displayName': data['fullName'] ?? data['email'] ?? 'User',
        };
      }
    } catch (e) {
      if (_auth.currentUser?.email == 'admin@gmail.com') {
        return {'role': 'admin', 'displayName': 'Admin'};
      }
    }
    return {'role': 'customer', 'displayName': 'User'};
  }
}
