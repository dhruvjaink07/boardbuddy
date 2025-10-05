import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String commentId;
  final String cardId;
  final String userId;
  final String message;
  final DateTime timestamp;

  Comment({
    required this.commentId,
    required this.cardId,
    required this.userId,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'cardId': cardId,
      'userId': userId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory Comment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Comment(
      commentId: doc.id,
      cardId: data['cardId'] ?? '',
      userId: data['userId'] ?? '',
      message: data['message'] ?? '',
      timestamp: _asDate(data['timestamp']),
    );
  }

  static DateTime _asDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
  }
}
