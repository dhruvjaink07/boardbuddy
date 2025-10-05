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

  // NEW: stream columns for a board
  Stream<List<BoardColumn>> streamColumns(String boardId) {
    return boardsCol()
        .doc(boardId)
        .collection('columns')
        .orderBy('order')
        .snapshots()
        .map((s) => s.docs.map((d) => BoardColumn.fromDoc(d)).toList());
  }

  // NEW: stream cards for a column
  Stream<List<TaskCard>> streamCards(String boardId, String columnId) {
    return boardsCol()
        .doc(boardId)
        .collection('columns')
        .doc(columnId)
        .collection('cards')
        .snapshots()
        .map((s) => s.docs.map((d) => TaskCard.fromDoc(d, columnId)).toList());
  }

  // NEW: move card between columns (preserves id)
  Future<void> moveCard({
    required String boardId,
    required String taskId,
    required String fromColumn,
    required String toColumn,
  }) async {
    final fromRef = boardsCol()
        .doc(boardId)
        .collection('columns')
        .doc(fromColumn)
        .collection('cards')
        .doc(taskId);

    final toRef = boardsCol()
        .doc(boardId)
        .collection('columns')
        .doc(toColumn)
        .collection('cards')
        .doc(taskId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(fromRef);
      if (!snap.exists) return;
      final data = Map<String, dynamic>.from(snap.data() ?? {});
      data['lastUpdated'] = FieldValue.serverTimestamp();
      tx.set(toRef, data, SetOptions(merge: true));
      tx.delete(fromRef);
    });
  }

  // NEW: upsert card in a column
  Future<String> upsertCard({
    required String boardId,
    required String columnId,
    required TaskCard card,
  }) async {
    final cardsCol = boardsCol()
        .doc(boardId)
        .collection('columns')
        .doc(columnId)
        .collection('cards');

    final docRef = card.id.isNotEmpty ? cardsCol.doc(card.id) : cardsCol.doc();
    final isUpdate = card.id.isNotEmpty;
    final payload = isUpdate ? card.toUpdateMap() : card.toCreateMap();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (!isUpdate && (payload['createdBy'] == null || (payload['createdBy'] as String).isEmpty)) {
      payload['createdBy'] = uid ?? '';
    }
    await docRef.set(payload, SetOptions(merge: true));
    return docRef.id;
  }

  // NEW: delete card
  Future<void> deleteCard({
    required String boardId,
    required String columnId,
    required String taskId,
  }) async {
    final ref = boardsCol()
        .doc(boardId)
        .collection('columns')
        .doc(columnId)
        .collection('cards')
        .doc(taskId);
    await ref.delete();
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
