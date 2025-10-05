import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boardbuddy/features/board/models/board.dart';
import 'package:boardbuddy/features/board/models/board_column.dart';
import 'package:boardbuddy/features/board/models/task_card.dart';

class BoardFirestoreService {
  BoardFirestoreService._();
  static final instance = BoardFirestoreService._();

  CollectionReference<Map<String, dynamic>> boardsCol() =>
      FirebaseFirestore.instance.collection('boards');

  // No orderBy to avoid composite index during testing
  Stream<List<Board>> streamBoardsForUser(String userId) {
    return boardsCol()
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((s) => s.docs.map((d) => Board.fromDoc(d)).toList());
  }

  Future<void> saveGeneratedBoard({
    required Board board,
    required List<BoardColumn> columns,
    required Map<String, List<TaskCard>> tasksByColumn,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('Not signed in');
    }

    final boardRef = boardsCol().doc(board.boardId);

    // 1) Write board first so subcollection writes pass isBoardMember rules
    final boardData = board.toMap();
    boardData['ownerId'] = uid;
    boardData['memberIds'] = [uid];
    boardData['createdAt'] = boardData['createdAt'] ?? FieldValue.serverTimestamp();
    boardData['lastUpdated'] = FieldValue.serverTimestamp();
    await boardRef.set(boardData, SetOptions(merge: true));

    // 2) Then write columns and cards
    final batch = FirebaseFirestore.instance.batch();

    for (final col in columns) {
      final colRef = boardRef.collection('columns').doc(col.columnId);
      final colData = col.toMap();
      colData['createdAt'] = colData['createdAt'] ?? FieldValue.serverTimestamp();
      batch.set(colRef, colData, SetOptions(merge: true));

      final List<TaskCard> cards = tasksByColumn[col.columnId] ?? const <TaskCard>[];
      for (final card in cards) {
        final cardRef = card.id.isNotEmpty
            ? colRef.collection('cards').doc(card.id)
            : colRef.collection('cards').doc();

        final cardData = card.toCreateMap();
        batch.set(cardRef, cardData, SetOptions(merge: true));
      }
    }

    await batch.commit();
  }
}
