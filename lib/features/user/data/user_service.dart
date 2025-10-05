import 'package:boardbuddy/features/auth/models/user_model.dart';
import 'package:boardbuddy/features/board/models/board_invitation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final _instance = UserService._();
  UserService._();
  static UserService get instance => _instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  CollectionReference<Map<String, dynamic>> get _invitations =>
      FirebaseFirestore.instance.collection('invitations');

  // Create/update user profile on sign-in
  Future<void> createOrUpdateUser(User firebaseUser) async {
    await _users.doc(firebaseUser.uid).set({
      'uid': firebaseUser.uid,
      'email': firebaseUser.email,
      'displayName': firebaseUser.displayName,
      'photoUrl': firebaseUser.photoURL,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Create invitation for non-registered users
  Future<void> createInvitation({
    required String boardId,
    required String boardName,
    required String email,
    required String role,
    required String invitedBy,
    required String invitedByName,
  }) async {
    final invitation = BoardInvitation(
      invitationId: '',
      boardId: boardId,
      boardName: boardName,
      invitedEmail: email.toLowerCase().trim(),
      invitedBy: invitedBy,
      invitedByName: invitedByName,
      role: role,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)), // 7 day expiry
    );

    await _invitations.add(invitation.toMap());
  }

  // Find user by email
  Future<AppUser?> findUserByEmail(String email) async {
    try {
      final query = await _users.where('email', isEqualTo: email.toLowerCase().trim()).limit(1).get();
      if (query.docs.isEmpty) return null;
      return AppUser.fromDoc(query.docs.first);
    } catch (e) {
      print('Error finding user by email: $e');
      return null;
    }
  }

  // Search users by email pattern
  Future<List<AppUser>> searchUsersByEmail(String emailPattern) async {
    try {
      final query = await _users
          .where('email', isGreaterThanOrEqualTo: emailPattern.toLowerCase())
          .where('email', isLessThan: emailPattern.toLowerCase() + '\uf8ff')
          .limit(10)
          .get();
      return query.docs.map((doc) => AppUser.fromDoc(doc)).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Add this method to find user by UID
  Future<AppUser?> findUserByUid(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromDoc(doc);
    } catch (e) {
      print('Error finding user by UID: $e');
      return null;
    }
  }

  // Check for pending invitations when user signs up
  Future<List<BoardInvitation>> getPendingInvitations(String email) async {
    try {
      final query = await _invitations
          .where('invitedEmail', isEqualTo: email.toLowerCase().trim())
          .where('status', isEqualTo: 'pending')
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .get();
      
      return query.docs.map((doc) => BoardInvitation.fromDoc(doc)).toList();
    } catch (e) {
      print('Error getting pending invitations: $e');
      return [];
    }
  }

  // Accept invitation
  Future<void> acceptInvitation(String invitationId) async {
    await _invitations.doc(invitationId).update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }
}