import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // -------- Get current user stream ----------
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // -------- Current User ----------
  User? get currentUser => _auth.currentUser;

  // -------- Google Sign-In (Primary Method) ----------
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Always mirror to /users collection
      await _createOrUpdateUserDoc(userCredential.user);
      return userCredential.user;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // -------- Email & Password Sign-In (Secondary Method) ----------
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _createOrUpdateUserDoc(userCredential.user);
      return userCredential.user;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // -------- Email Registration ----------
  Future<User?> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      // Update display name
      await userCredential.user?.updateDisplayName(name.trim());

      // Always mirror to /users collection
      await _createOrUpdateUserDoc(userCredential.user, name: name.trim());
      return userCredential.user;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // -------- Password Reset (Free via Firebase) ----------
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // -------- Sign-Out ----------
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // -------- Delete Account ----------
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth account
      await user.delete();
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // -------- Get User Data ----------
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // -------- Private: Create/Update User Document ----------
  Future<void> _createOrUpdateUserDoc(User? user, {String? name}) async {
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final now = FieldValue.serverTimestamp();

    final userData = {
      'name': name ?? user.displayName ?? '',
      'email': user.email ?? '',
      'photoURL': user.photoURL ?? '',
      'lastLogin': now,
    };

    // Check if this is a new user
    final doc = await userRef.get();
    if (!doc.exists) {
      userData['createdAt'] = now;
    }

    await userRef.set(userData, SetOptions(merge: true));
  }

  // -------- Private: Handle Auth Exceptions ----------
  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Try again later.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'Password should be at least 6 characters.';
        case 'operation-not-allowed':
          return 'Sign-in method not enabled.';
        case 'invalid-credential':
          return 'Invalid login credentials.';
        case 'network-request-failed':
          return 'Network error. Check your connection.';
        case 'requires-recent-login':
          return 'Please log in again to perform this action.';
        default:
          return e.message ?? 'Authentication failed.';
      }
    }
    return 'An unexpected error occurred.';
  }

  // Call this after successful login
  Future<void> cacheLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
  }
}
