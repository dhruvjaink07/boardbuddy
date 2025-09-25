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

  Map<String, dynamic> toMap() => {
        'commentId': commentId,
        'cardId': cardId,
        'userId': userId,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Comment.fromMap(Map<String, dynamic> map) => Comment(
        commentId: map['commentId'],
        cardId: map['cardId'],
        userId: map['userId'],
        message: map['message'],
        timestamp: DateTime.parse(map['timestamp']),
      );
}
