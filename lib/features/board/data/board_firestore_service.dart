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
    if (uid == null) throw Exception('Not signed in');

    final boardRef = boardsCol().doc(board.boardId);

    // 1) Create/merge board and ensure memberIds contains creator
    final data = board.toMap();
    data['ownerId'] = uid;
    final members = List<String>.from(data['memberIds'] ?? const <String>[]);
    if (!members.contains(uid)) members.add(uid);
    data['memberIds'] = members;
    data['createdAt'] = data['createdAt'] ?? FieldValue.serverTimestamp();
    data['lastUpdated'] = FieldValue.serverTimestamp();
    await boardRef.set(data, SetOptions(merge: true));

    // 2) Seed role for owner (so role-based rules pass)
    await boardRef.collection('members').doc(uid).set({
      'role': 'owner',
      'addedAt': FieldValue.serverTimestamp(),
      'addedBy': uid,
    }, SetOptions(merge: true));

    // 3) Then write columns and cards
    final batch = FirebaseFirestore.instance.batch();
    for (final col in columns) {
      final colRef = boardRef.collection('columns').doc(col.columnId);
      final colData = col.toMap();
      colData['createdAt'] = colData['createdAt'] ?? FieldValue.serverTimestamp();
      batch.set(colRef, colData, SetOptions(merge: true));

      final cards = tasksByColumn[col.columnId] ?? const <TaskCard>[];
      for (final card in cards) {
        final cardRef = card.id.isNotEmpty
            ? colRef.collection('cards').doc(card.id)
            : colRef.collection('cards').doc();
        final payload = card.toCreateMap();
        batch.set(cardRef, payload, SetOptions(merge: true));
      }
    }
    await batch.commit();
  }

  // Role helpers
  Stream<String?> myRoleStream(String boardId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream<String?>.empty();
    return boardsCol()
        .doc(boardId)
        .collection('members')
        .doc(uid)
        .snapshots()
        .map((d) => d.data()?['role'] as String?);
  }

  Future<String?> myRole(String boardId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final snap = await boardsCol().doc(boardId).collection('members').doc(uid).get();
    return snap.data()?['role'] as String?;
  }

  // Member management (owner only per rules)
  Future<void> addMember({
    required String boardId,
    required String userId,
    required String role, // 'editor' | 'viewer'
  }) async {
    final ref = boardsCol().doc(boardId).collection('members').doc(userId);
    await ref.set({
      'role': role,
      'addedAt': FieldValue.serverTimestamp(),
      'addedBy': FirebaseAuth.instance.currentUser?.uid,
    }, SetOptions(merge: true));

    // Keep legacy memberIds in sync for BoardScreen query
    await boardsCol().doc(boardId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMemberRole({
    required String boardId,
    required String userId,
    required String role,
  }) async {
    await boardsCol().doc(boardId).collection('members').doc(userId).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeMember({
    required String boardId,
    required String userId,
  }) async {
    await boardsCol().doc(boardId).collection('members').doc(userId).delete();
  }

  // // One-time backfill: create members/{uid} where memberIds already contains uid
  // Future<void> backfillMyMembership() async {
  //   final uid = FirebaseAuth.instance.currentUser?.uid;
  //   if (uid == null) return;

  //   final q = await boardsCol().where('memberIds', arrayContains: uid).get();
  //   final batch = FirebaseFirestore.instance.batch();
  //   for (final d in q.docs) {
  //     final memRef = d.reference.collection('members').doc(uid);
  //     final memSnap = await memRef.get();
  //     if (!memSnap.exists) {
  //       final isOwner = (d.data()['ownerId'] == uid);
  //       batch.set(memRef, {
  //         'role': isOwner ? 'owner' : 'editor',
  //         'addedAt': FieldValue.serverTimestamp(),
  //         'addedBy': uid,
  //       }, SetOptions(merge: true));
  //     }
  //   }
  //   await batch.commit();
  // }
}
