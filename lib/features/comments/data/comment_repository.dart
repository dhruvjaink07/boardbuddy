import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boardbuddy/features/comments/data/comment_model.dart';

class CommentRepository {
  static final instance = CommentRepository._();
  CommentRepository._();

  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _commentsCollection(String boardId) {
    return _firestore.collection('boards').doc(boardId).collection('comments');
  }

  // Stream comments for board chat - FIXED QUERY
  Stream<List<Comment>> streamBoardComments(String boardId) {
    print('📡 Streaming board comments for board: $boardId');
    return _commentsCollection(boardId)
        .where('cardId', isEqualTo: null) // Changed from isNull: true
        .snapshots()
        .map((snapshot) {
          print('📨 Received ${snapshot.docs.length} board comments');
          final comments = snapshot.docs.map((doc) {
            print('📄 Comment doc: ${doc.id} - ${doc.data()}');
            return Comment.fromDoc(doc);
          }).toList();
          // Sort in memory instead of using orderBy
          comments.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return comments;
        })
        .handleError((error) {
          print('❌ Error streaming board comments: $error');
          return <Comment>[];
        });
  }

  // Alternative approach - get ALL comments and filter in code
  Stream<List<Comment>> streamBoardCommentsAlternative(String boardId) {
    print('📡 Streaming ALL comments for board: $boardId and filtering locally');
    return _commentsCollection(boardId)
        .snapshots()
        .map((snapshot) {
          print('📨 Received ${snapshot.docs.length} total comments');
          final allComments = snapshot.docs.map((doc) {
            print('📄 Comment doc: ${doc.id} - ${doc.data()}');
            return Comment.fromDoc(doc);
          }).toList();
          
          // Filter for board comments (no cardId)
          final boardComments = allComments.where((comment) => comment.cardId == null).toList();
          print('🏢 Board comments after filtering: ${boardComments.length}');
          
          // Sort by timestamp
          boardComments.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return boardComments;
        })
        .handleError((error) {
          print('❌ Error streaming board comments: $error');
          return <Comment>[];
        });
  }

  // Stream comments for a specific card
  Stream<List<Comment>> streamCardComments(String boardId, String cardId) {
    print('📡 Streaming card comments for board: $boardId, card: $cardId');
    return _commentsCollection(boardId)
        .where('cardId', isEqualTo: cardId)
        .snapshots()
        .map((snapshot) {
          print('📨 Received ${snapshot.docs.length} card comments');
          final comments = snapshot.docs.map((doc) => Comment.fromDoc(doc)).toList();
          // Sort in memory instead of using orderBy
          comments.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return comments;
        })
        .handleError((error) {
          print('❌ Error streaming card comments: $error');
          return <Comment>[];
        });
  }

  // Add a new comment/message with detailed logging
  Future<String> addComment({
    required String boardId,
    String? cardId,
    required String message,
    List<String>? attachments,
    String? replyToId,
  }) async {
    try {
      print('💬 Adding comment...');
      print('   Board ID: $boardId');
      print('   Card ID: $cardId');
      print('   Message: $message');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No authenticated user');
        throw Exception('User not authenticated');
      }

      print('👤 User: ${user.uid} (${user.displayName ?? user.email})');

      // Check if board exists
      final boardDoc = await _firestore.collection('boards').doc(boardId).get();
      if (!boardDoc.exists) {
        print('❌ Board does not exist: $boardId');
        throw Exception('Board not found');
      }
      
      print('✅ Board exists');
      print('🗂️ Board data: ${boardDoc.data()}');

      final commentData = Comment(
        id: '',
        boardId: boardId,
        cardId: cardId,
        userId: user.uid,
        userName: user.displayName ?? user.email ?? 'Unknown User',
        userPhotoUrl: user.photoURL,
        message: message,
        timestamp: DateTime.now(),
        attachments: attachments,
        replyToId: replyToId,
      ).toMap();

      print('📝 Comment data to save: $commentData');

      final docRef = await _commentsCollection(boardId).add(commentData);
      print('✅ Comment added with ID: ${docRef.id}');
      
      // Verify the comment was saved by reading it back
      final savedDoc = await docRef.get();
      print('🔍 Saved comment verification: ${savedDoc.exists}');
      print('🔍 Saved comment data: ${savedDoc.data()}');
      
      return docRef.id;
    } catch (e, stackTrace) {
      print('❌ Error adding comment: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Debug method to get all comments
  Future<List<Comment>> getAllComments(String boardId) async {
    try {
      print('🔍 Getting ALL comments for debugging...');
      final snapshot = await _commentsCollection(boardId).get();
      print('🔍 Total documents in comments collection: ${snapshot.docs.length}');
      
      for (final doc in snapshot.docs) {
        print('🔍 Doc ${doc.id}: ${doc.data()}');
      }
      
      final comments = snapshot.docs.map((doc) => Comment.fromDoc(doc)).toList();
      return comments;
    } catch (e) {
      print('❌ Error getting all comments: $e');
      return [];
    }
  }

  // Delete a comment with error handling
  Future<void> deleteComment({
    required String boardId,
    required String commentId,
  }) async {
    try {
      print('🗑️ Deleting comment: $commentId from board: $boardId');
      await _commentsCollection(boardId).doc(commentId).delete();
      print('✅ Comment deleted successfully');
    } catch (e) {
      print('❌ Error deleting comment: $e');
      rethrow;
    }
  }

  // Add reaction with error handling
  Future<void> addReaction({
    required String boardId,
    required String commentId,
    required String emoji,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('👍 Adding reaction $emoji to comment $commentId');
      await _commentsCollection(boardId).doc(commentId).update({
        'reactions.$emoji': FieldValue.arrayUnion([user.uid]),
      });
      print('✅ Reaction added successfully');
    } catch (e) {
      print('❌ Error adding reaction: $e');
      // Don't rethrow for reactions - fail silently
    }
  }

  // Remove reaction with error handling
  Future<void> removeReaction({
    required String boardId,
    required String commentId,
    required String emoji,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('👎 Removing reaction $emoji from comment $commentId');
      await _commentsCollection(boardId).doc(commentId).update({
        'reactions.$emoji': FieldValue.arrayRemove([user.uid]),
      });
      print('✅ Reaction removed successfully');
    } catch (e) {
      print('❌ Error removing reaction: $e');
      // Don't rethrow for reactions - fail silently
    }
  }
}