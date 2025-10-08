import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String boardId;
  final String? cardId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String message;
  final DateTime timestamp;
  final List<String>? attachments;
  final Map<String, List<String>>? reactions; // emoji -> [userIds]
  final String? replyToId;

  Comment({
    required this.id,
    required this.boardId,
    this.cardId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.message,
    required this.timestamp,
    this.attachments,
    this.reactions,
    this.replyToId,
  });

  factory Comment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Comment(
      id: doc.id,
      boardId: data['boardId'] ?? '',
      cardId: data['cardId'],
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown User',
      userPhotoUrl: data['userPhotoUrl'],
      message: data['message'] ?? '',
      timestamp: _parseTimestamp(data['timestamp']),
      attachments: data['attachments'] != null 
          ? List<String>.from(data['attachments']) 
          : null,
      reactions: data['reactions'] != null
          ? Map<String, List<String>>.from(
              (data['reactions'] as Map).map(
                (k, v) => MapEntry(k.toString(), List<String>.from(v))
              )
            )
          : null,
      replyToId: data['replyToId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'boardId': boardId,
      'cardId': cardId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'attachments': attachments,
      'reactions': reactions,
      'replyToId': replyToId,
    }..removeWhere((key, value) => value == null);
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return DateTime.now();
  }

  Comment copyWith({
    String? id,
    String? boardId,
    String? cardId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? message,
    DateTime? timestamp,
    List<String>? attachments,
    Map<String, List<String>>? reactions,
    String? replyToId,
  }) {
    return Comment(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      cardId: cardId ?? this.cardId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      attachments: attachments ?? this.attachments,
      reactions: reactions ?? this.reactions,
      replyToId: replyToId ?? this.replyToId,
    );
  }
}