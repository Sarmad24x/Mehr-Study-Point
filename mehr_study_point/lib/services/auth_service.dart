import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current Firebase user
  User? get currentUser => _auth.currentUser;

  // Sign in with Email/Password
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

  // Google Sign In with Linking Logic
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential;
      try {
        // Try standard sign in
        userCredential = await _auth.signInWithCredential(credential);
      } catch (e) {
        // If an account already exists with Email/Password, we catch the error
        if (e is FirebaseAuthException && e.code == 'account-exists-with-different-credential') {
          rethrow;
        }
        rethrow;
      }

      if (userCredential.user != null) {
        // Sync Firestore profile
        final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        
        if (!doc.exists) {
          // Check if this is the first user
          final usersQuery = await _firestore.collection('users').limit(1).get();
          final isFirstUser = usersQuery.docs.isEmpty;

          final newUser = UserModel(
            id: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            name: userCredential.user!.displayName ?? 'New User',
            role: isFirstUser ? UserRole.admin : UserRole.employee,
            photoUrl: userCredential.user!.photoURL,
          );
          await createUserInFirestore(newUser);
        }
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Method to add a Password to a Google account (Connecting them)
  Future<void> linkEmailPassword(String email, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("No user logged in");

      final credential = EmailAuthProvider.credential(email: email, password: password);
      await user.linkWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  // Change Password
  Future<void> changePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) await user.updatePassword(newPassword);
    } catch (e) { rethrow; }
  }

  // Update Email
  Future<void> updateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateEmail(newEmail);
        await _firestore.collection('users').doc(user.uid).update({'email': newEmail});
      }
    } catch (e) { rethrow; }
  }

  // Send Email Verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Get User Data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? UserModel.fromMap(doc.data()!) : null;
    } catch (e) { return null; }
  }

  // Create User in Firestore
  Future<void> createUserInFirestore(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  // Create Employee Account (Used by Admin)
  Future<void> registerEmployee({required String email, required String password, required String name}) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (credential.user != null) {
      await createUserInFirestore(UserModel(id: credential.user!.uid, email: email, name: name, role: UserRole.employee));
    }
  }

  Future<void> deleteUserAccount(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }
}
