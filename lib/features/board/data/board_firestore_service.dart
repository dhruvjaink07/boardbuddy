import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boardbuddy/features/board/models/board.dart';
import 'package:boardbuddy/features/board/models/board_column.dart';
import 'package:boardbuddy/features/board/models/task_card.dart' as task_model;
import 'package:boardbuddy/features/user/data/user_service.dart';

class BoardFirestoreService {
  BoardFirestoreService._();
  static final instance = BoardFirestoreService._();

  CollectionReference<Map<String, dynamic>> boardsCol() =>
      FirebaseFirestore.instance.collection('boards');

  // Live count of members
  Stream<int> membersCountStream(String boardId) {
    return boardsCol()
        .doc(boardId)
        .collection('members')
        .snapshots()
        .map((s) => s.docs.length);
  }

  // Live list of members (uid + role)
  Stream<List<Map<String, String>>> membersStream(String boardId) {
    return boardsCol()
        .doc(boardId)
        .collection('members')
        .snapshots()
        .map((s) => s.docs
            .map((d) => {
                  'uid': d.id,
                  'role': (d.data()['role'] as String?) ?? 'viewer',
                })
            .toList());
  }

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
  Stream<List<task_model.TaskCard>> streamCards(String boardId, String columnId) {
    return boardsCol()
        .doc(boardId)
        .collection('columns')
        .doc(columnId)
        .collection('cards')
        .snapshots()
        .map((s) => s.docs.map((d) => task_model.TaskCard.fromDoc(d, columnId)).toList());
  }

  bool _isDoneSlug(String s) {
    final x = (s).toLowerCase().trim();
    return x.contains('done') || x.contains('complete') || x.contains('closed');
  }

  String _slugify(String? title) {
    if (title == null) return '';
    return title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  // When upserting a card ensure boardId/columnId/status/isCompleted/completedAt are consistent
  Future<String> upsertCard({
    required String boardId,
    required String columnId,
    required task_model.TaskCard card,
  }) async {
    final cardsCol = boardsCol()
        .doc(boardId)
        .collection('columns')
        .doc(columnId)
        .collection('cards');

    final docRef = card.id.isNotEmpty ? cardsCol.doc(card.id) : cardsCol.doc();
    final isUpdate = card.id.isNotEmpty;

    final payload = isUpdate ? card.toUpdateMap() : card.toCreateMap();

    // denormalize for analytics
    payload['boardId'] = boardId;
    payload['columnId'] = columnId;

    // normalize status
    final statusStr = (payload['status'] ?? _slugify(card.status)).toString();
    payload['status'] = statusStr;

    // compute completion flags
    final isDone = (payload['isCompleted'] == true) || _isDoneSlug(statusStr);
    payload['isCompleted'] = isDone;
    if (isDone) {
      payload['completedAt'] = payload['completedAt'] ?? FieldValue.serverTimestamp();
    } else {
      // if explicitly moving out of done, clear completedAt
      if (payload.containsKey('completedAt')) payload['completedAt'] = null;
    }

    await docRef.set(payload, SetOptions(merge: true));
    return docRef.id;
  }

  // Move a card and keep completion flags in sync with the destination column
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

    // Read destination column title to derive status
    final toColSnap = await boardsCol().doc(boardId).collection('columns').doc(toColumn).get();
    final toTitle = (toColSnap.data()?['title'] ?? toColSnap.data()?['name'] ?? '').toString();
    final toSlug = _slugify(toTitle);
    final isDone = _isDoneSlug(toSlug);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(fromRef);
      if (!snap.exists) return;
      final data = Map<String, dynamic>.from(snap.data() ?? {});
      data['boardId'] = boardId;
      data['columnId'] = toColumn;
      data['status'] = (data['status'] ?? '').toString().isEmpty ? toSlug : data['status'];
      data['isCompleted'] = isDone;
      data['lastUpdated'] = FieldValue.serverTimestamp();
      if (isDone) {
        data['completedAt'] = FieldValue.serverTimestamp();
      } else {
        data['completedAt'] = null;
      }

      tx.set(toRef, data, SetOptions(merge: true));
      tx.delete(fromRef);
    });
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
    required Map<String, List<task_model.TaskCard>> tasksByColumn,
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

      final cards = tasksByColumn[col.columnId] ?? const <task_model.TaskCard>[];
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

  // Stream a single board
  Stream<Board> streamBoard(String boardId) {
    return boardsCol().doc(boardId).snapshots().map((d) => Board.fromDoc(d));
  }

  // Update board metadata (name/description/theme/maxEditors)
  Future<void> updateBoardMeta({
    required String boardId,
    String? name,
    String? description,
    String? theme,
    int? maxEditors,
  }) async {
    final map = <String, dynamic>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (theme != null) 'theme': theme,
      if (maxEditors != null) 'maxEditors': maxEditors,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
    if (map.length == 1) return; // only lastUpdated – nothing to update
    await boardsCol().doc(boardId).set(map, SetOptions(merge: true));
  }

  // Quick stats for settings page
  Future<int> countColumns(String boardId) async {
    final qs = await boardsCol().doc(boardId).collection('columns').get();
    return qs.size;
  }

  Future<int> countCards(String boardId) async {
    int total = 0;
    final cols = await boardsCol().doc(boardId).collection('columns').get();
    for (final c in cols.docs) {
      final agg = await c.reference.collection('cards').count().get();
      total += (agg.count ?? 0); // fix: count is int?
    }
    return total;
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

  // Role for a specific user on a board
  Stream<String?> roleStream(String boardId, String userId) {
    return boardsCol()
        .doc(boardId)
        .collection('members')
        .doc(userId)
        .snapshots()
        .map((d) => d.data()?['role'] as String?);
  }

  // Optional: transfer ownership safely (single owner)
  Future<void> transferOwnership({
    required String boardId,
    required String newOwnerId,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) throw Exception('Not signed in');

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final boardRef = boardsCol().doc(boardId);
      final boardSnap = await tx.get(boardRef);
      final data = boardSnap.data() as Map<String, dynamic>? ?? {};
      final ownerId = data['ownerId'] as String?;
      if (ownerId != currentUid) throw Exception('Only current owner can transfer ownership');

      final newOwnerRef = boardRef.collection('members').doc(newOwnerId);
      final oldOwnerRef = boardRef.collection('members').doc(ownerId);

      tx.update(boardRef, {
        'ownerId': newOwnerId,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      tx.set(newOwnerRef, {'role': 'owner', 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      tx.set(oldOwnerRef, {'role': 'editor', 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    });

    // Make sure new owner is in memberIds
    await boardsCol().doc(boardId).update({
      'memberIds': FieldValue.arrayUnion([newOwnerId]),
    });
  }

  // Member management (owner only per rules)
  Future<void> addMember({
    required String boardId,
    required String userId,
    required String role, // 'editor' | 'viewer'
  }) async {
    // Prevent adding another "owner" through this path
    final safeRole = role == 'owner' ? 'editor' : role;

    final ref = boardsCol().doc(boardId).collection('members').doc(userId);
    await ref.set({
      'role': safeRole,
      'addedAt': FieldValue.serverTimestamp(),
      'addedBy': FirebaseAuth.instance.currentUser?.uid,
    }, SetOptions(merge: true));

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
    final db = FirebaseFirestore.instance;
    final boardRef = boardsCol().doc(boardId);
    final memberRef = boardRef.collection('members').doc(userId);

    await db.runTransaction((tx) async {
      final boardSnap = await tx.get(boardRef);
      final data = boardSnap.data() as Map<String, dynamic>? ?? {};
      final ownerId = data['ownerId'] as String?;

      if (ownerId == userId) {
        throw Exception('Cannot remove the owner');
      }

      // delete role doc and update array in one atomic step
      tx.delete(memberRef);
      tx.update(boardRef, {
        'memberIds': FieldValue.arrayRemove([userId]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  // Enhanced member invitation (handles both registered and unregistered users)
  Future<String> inviteMember({
    required String boardId,
    required String email,
    required String role,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('Not signed in');

    // First, try to find existing user
    final existingUser = await UserService.instance.findUserByEmail(email);

    if (existingUser != null) {
      // User exists - add them directly
      await addMember(
        boardId: boardId,
        userId: existingUser.uid,
        role: role,
      );
      return 'added'; // User was added immediately
    } else {
      // User doesn't exist - create pending invitation
      final board = await boardsCol().doc(boardId).get();
      final boardData = board.data();
      
      await UserService.instance.createInvitation(
        boardId: boardId,
        boardName: boardData?['name'] ?? 'Board',
        email: email,
        role: role,
        invitedBy: currentUser.uid,
        invitedByName: currentUser.displayName ?? currentUser.email ?? 'Someone',
      );
      return 'invited'; // Invitation was sent
    }
  }

  // Process pending invitations when user signs up
  Future<void> processPendingInvitations(String userEmail) async {
    final invitations = await UserService.instance.getPendingInvitations(userEmail);
    
    for (final invitation in invitations) {
      try {
        // Add user to board
        await addMember(
          boardId: invitation.boardId,
          userId: FirebaseAuth.instance.currentUser!.uid,
          role: invitation.role,
        );
        
        // Mark invitation as accepted
        await UserService.instance.acceptInvitation(invitation.invitationId);
      } catch (e) {
        print('Error processing invitation ${invitation.invitationId}: $e');
      }
    }
  }

  Future<void> addAttachmentToCard({
     required String boardId,
     required String columnId,
     required String cardId,
    required task_model.AttachmentMeta meta,
   }) async {
    final ref = boardsCol()
        .doc(boardId)
        .collection('columns')
        .doc(columnId)
        .collection('cards')
        .doc(cardId);

    await ref.update({
      'attachments': FieldValue.arrayUnion([meta.toMap()]),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeAttachmentFromCard({
     required String boardId,
     required String columnId,
     required String cardId,
    required task_model.AttachmentMeta meta,
   }) async {
    final ref = boardsCol()
        .doc(boardId)
        .collection('columns')
        .doc(columnId)
        .collection('cards')
        .doc(cardId);

    await ref.update({
      'attachments': FieldValue.arrayRemove([meta.toMap()]),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
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

  // NEW: one-time backfill so existing cards get boardId/columnId
  Future<void> backfillCardBoardIdsForBoard(String boardId) async {
    final boardRef = boardsCol().doc(boardId);
    final cols = await boardRef.collection('columns').get();
    final batch = FirebaseFirestore.instance.batch();
    for (final c in cols.docs) {
      final cards = await c.reference.collection('cards').get();
      for (final card in cards.docs) {
        final data = card.data();
        final hasBoardId = data['boardId'] != null && '${data['boardId']}'.isNotEmpty;
        final hasColumnId = data['columnId'] != null && '${data['columnId']}'.isNotEmpty;
        if (!hasBoardId || !hasColumnId) {
          batch.set(card.reference, {
            'boardId': boardId,
            'columnId': c.id,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    }
    await batch.commit();
  }

  // NEW: backfill all boards you’re a member of
  Future<void> backfillMyBoards() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final qs = await boardsCol().where('memberIds', arrayContains: uid).get();
    for (final d in qs.docs) {
      await backfillCardBoardIdsForBoard(d.id);
    }
  }
}
