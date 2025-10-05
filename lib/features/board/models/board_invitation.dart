import 'package:cloud_firestore/cloud_firestore.dart';

class BoardInvitation {
  final String invitationId;
  final String boardId;
  final String boardName;
  final String invitedEmail;
  final String invitedBy;
  final String invitedByName;
  final String role;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String status; // 'pending', 'accepted', 'expired'

  BoardInvitation({
    required this.invitationId,
    required this.boardId,
    required this.boardName,
    required this.invitedEmail,
    required this.invitedBy,
    required this.invitedByName,
    required this.role,
    required this.createdAt,
    required this.expiresAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'boardId': boardId,
      'boardName': boardName,
      'invitedEmail': invitedEmail,
      'invitedBy': invitedBy,
      'invitedByName': invitedByName,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': status,
    };
  }

  factory BoardInvitation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BoardInvitation(
      invitationId: doc.id,
      boardId: data['boardId'] ?? '',
      boardName: data['boardName'] ?? '',
      invitedEmail: data['invitedEmail'] ?? '',
      invitedBy: data['invitedBy'] ?? '',
      invitedByName: data['invitedByName'] ?? '',
      role: data['role'] ?? 'viewer',
      createdAt: _asDate(data['createdAt']),
      expiresAt: _asDate(data['expiresAt']),
      status: data['status'] ?? 'pending',
    );
  }

  static DateTime _asDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return DateTime.now();
  }
}