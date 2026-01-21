import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get User Data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Create User in Firestore (Used by Admin to add Employees)
  Future<void> createUserInFirestore(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  // MATURE: Create Employee Account (Auth + Firestore)
  Future<void> registerEmployee({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // 1. Create the user in Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // 2. Create the user profile in Firestore
        final newUser = UserModel(
          id: credential.user!.uid,
          email: email,
          name: name,
          role: UserRole.employee,
        );
        await createUserInFirestore(newUser);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete User (Firestore + potentially Auth via Cloud Functions in future)
  Future<void> deleteUserAccount(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }
}
