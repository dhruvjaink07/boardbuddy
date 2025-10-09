import 'package:boardbuddy/features/board/models/board_insight.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Add lightweight DTOs
class BoardInsightWithName {
  final String boardId;
  final String name;
  final BoardInsights insights;
  BoardInsightWithName({required this.boardId, required this.name, required this.insights});
}

class AnalyticsDashboardData {
  final BoardInsights all; // aggregated across all boards
  final List<BoardInsightWithName> perBoard; // detailed per-board
  AnalyticsDashboardData({required this.all, required this.perBoard});
}

// Load full payload: overall + per board
Future<AnalyticsDashboardData> loadAnalyticsDashboard() async {
  final overall = await computeAllBoardsInsights();
  final per = await computePerBoardInsights();
  return AnalyticsDashboardData(all: overall, perBoard: per);
}

// Returns insights for each accessible board (with board name)
Future<List<BoardInsightWithName>> computePerBoardInsights() async {
  final fs = FirebaseFirestore.instance;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const <BoardInsightWithName>[];

  final ids = <String>{};

  try {
    final owned = await fs.collection('boards').where('ownerId', isEqualTo: uid).get();
    ids.addAll(owned.docs.map((d) => d.id));
  } catch (_) {}
  try {
    final member = await fs.collection('boards').where('memberIds', arrayContains: uid).get();
    ids.addAll(member.docs.map((d) => d.id));
  } catch (_) {}

  if (ids.isEmpty) return const <BoardInsightWithName>[];

  // Fetch names in chunks
  final boardNames = <String, String>{};
  for (final chunk in _chunk(ids.toList(), 10)) {
    try {
      final qs = await fs.collection('boards').where(FieldPath.documentId, whereIn: chunk).get();
      for (final d in qs.docs) {
        boardNames[d.id] = (d.data()['name'] as String?)?.trim().isNotEmpty == true
            ? (d.data()['name'] as String)
            : d.id;
      }
    } catch (_) {
      for (final id in chunk) {
        boardNames[id] = id;
      }
    }
  }

  // Compute insights per board in parallel
  final futures = ids.map((id) async {
    final ins = await _computeInsightsForBoard(id);
    return BoardInsightWithName(boardId: id, name: boardNames[id] ?? id, insights: ins);
  }).toList();

  return Future.wait(futures);
}

// Compute insights for a single board (reuses the same algorithm)
Future<BoardInsights> _computeInsightsForBoard(String boardId) async {
  final fs = FirebaseFirestore.instance;

  final tasks = <Map<String, dynamic>>[];
  final comments = <Map<String, dynamic>>[];
  final files = <Map<String, dynamic>>[];

  // Preferred: collectionGroup with denormalized boardId
  try {
    final snaps =
        await fs.collectionGroup('cards').where('boardId', isEqualTo: boardId).get();
    for (final d in snaps.docs) {
      tasks.add(d.data());
    }
  } catch (e) {
    print('collectionGroup(cards) failed for $boardId: $e');
  }

  // Fallback: traverse columns if needed
  if (tasks.isEmpty) {
    try {
      final cols = await fs.collection('boards/$boardId/columns').get();
      for (final col in cols.docs) {
        final cards = await col.reference.collection('cards').get();
        for (final card in cards.docs) {
          final data = Map<String, dynamic>.from(card.data());
          data['status'] = data['status'] ?? '';
          data['assigneeId'] = data['assigneeId'] ?? '';
          data['checklist'] = (data['checklist'] as List?) ?? const [];
          tasks.add(data);
        }
      }
    } catch (e) {
      print('Fallback card fetch failed for $boardId: $e');
    }
  }

  // Comments and board-level files
  try {
    final c = await fs.collection('boards/$boardId/comments').get();
    comments.addAll(c.docs.map((d) => d.data()));
  } catch (e) {
    print('Comments fetch failed for $boardId: $e');
  }
  try {
    final f = await fs.collection('boards/$boardId/files').get();
    files.addAll(f.docs.map((d) => d.data()));
  } catch (e) {
    print('Files fetch failed for $boardId: $e');
  }

  // Count attachments embedded on cards
  var cardAttachmentCount = 0;
  for (final task in tasks) {
    final attachments = task['attachments'] as List<dynamic>? ?? const [];
    cardAttachmentCount += attachments.length;
  }
  final totalFiles = files.length + cardAttachmentCount;

  return _generateInsights(boardId, tasks, comments, files, totalFiles);
}

Future<BoardInsights> computeAllBoardsInsights() async {
  try {
    final fs = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return _emptyInsights('all');
    }

    final ids = <String>{};

    // Owned boards
    try {
      final owned = await fs.collection('boards').where('ownerId', isEqualTo: uid).get();
      ids.addAll(owned.docs.map((d) => d.id));
    } catch (e) {
      print('Error fetching owned boards: $e');
    }

    // Member boards
    try {
      final member = await fs.collection('boards').where('memberIds', arrayContains: uid).get();
      ids.addAll(member.docs.map((d) => d.id));
    } catch (e) {
      print('Error fetching member boards: $e');
    }

    final boardIds = ids.toList();
    if (boardIds.isEmpty) {
      return _emptyInsights('all');
    }

    final tasks = <Map<String, dynamic>>[];
    final comments = <Map<String, dynamic>>[];
    final files = <Map<String, dynamic>>[];

    // Preferred: collectionGroup by denormalized boardId on cards
    for (final chunk in _chunk(boardIds, 10)) {
      try {
        final snaps = await fs.collectionGroup('cards').where('boardId', whereIn: chunk).get();
        for (final doc in snaps.docs) {
          tasks.add(doc.data());
        }
      } catch (e) {
        print('Error fetching tasks via collectionGroup: $e');
      }
    }

    // Fallback traversal if collectionGroup returns nothing
    if (tasks.isEmpty) {
      print('ℹ️ Falling back to per-board card fetch...');
      for (final boardId in boardIds) {
        try {
          final cols = await fs.collection('boards/$boardId/columns').get();
          for (final col in cols.docs) {
            final cards = await col.reference.collection('cards').get();
            for (final card in cards.docs) {
              final data = Map<String, dynamic>.from(card.data());
              data['status'] = data['status'] ?? '';
              data['assigneeId'] = data['assigneeId'] ?? '';
              data['checklist'] = (data['checklist'] as List?) ?? const [];
              tasks.add(data);
            }
          }
        } catch (e) {
          print('Error fallback-fetching cards for board $boardId: $e');
        }
      }
    }

    // Comments and board-level files
    for (final boardId in boardIds) {
      try {
        final commentSnaps = await fs.collection('boards/$boardId/comments').get();
        for (final doc in commentSnaps.docs) {
          comments.add(doc.data());
        }
      } catch (e) {
        print('Error fetching comments for board $boardId: $e');
      }

      try {
        final fileSnaps = await fs.collection('boards/$boardId/files').get();
        for (final doc in fileSnaps.docs) {
          files.add(doc.data());
        }
      } catch (e) {
        print('Error fetching files for board $boardId: $e');
      }
    }

    // Count attachments embedded on cards
    var cardAttachmentCount = 0;
    for (final task in tasks) {
      final attachments = task['attachments'] as List<dynamic>? ?? const [];
      cardAttachmentCount += attachments.length;
    }
    final totalFiles = files.length + cardAttachmentCount;

    return _generateInsights('all', tasks, comments, files, totalFiles);
  } catch (e, st) {
    print('computeAllBoardsInsights failed: $e\n$st');
    return _emptyInsights('all');
  }
}

BoardInsights _emptyInsights(String scopeId) {
  return BoardInsights(
    boardId: scopeId,
    projectHealthScore: 0.0,
    teamContribution: const {},
    taskTrends: const {'total': 0, 'completed': 0, 'inProgress': 0, 'todo': 0},
    resourceUsage: const {
      'avgChecklistCompletion': 0.0,
      'fileUploads': 0.0,
      'commentsCount': 0.0,
    },
  );
}

String _normStatus(String? s) {
  final x = (s ?? '').toLowerCase().trim();
  if (x.contains('done') || x.contains('complete') || x.contains('closed')) return 'done';
  if (x.contains('progress') || x.contains('doing') || x.contains('review') || x.contains('qa')) return 'in_progress';
  if (x.contains('todo') || x.contains('backlog') || x.contains('open')) return 'todo';
  return 'other';
}

bool _isCardDone(Map<String, dynamic> t) {
  if (t['isCompleted'] == true) return true;
  if (t['completedAt'] != null) return true;
  return _normStatus(t['status']?.toString()) == 'done';
}

BoardInsights _generateInsights(
  String scopeId,
  List<Map<String, dynamic>> tasks,
  List<Map<String, dynamic>> comments,
  List<Map<String, dynamic>> files,
  int totalFiles,
) {
  final totalTasks = tasks.length;
  final completedTasks = tasks.where(_isCardDone).length;
  final inProgressTasks =
      tasks.where((t) => !_isCardDone(t) && _normStatus(t['status']?.toString()) == 'in_progress').length;
  final todoTasks =
      tasks.where((t) => !_isCardDone(t) && _normStatus(t['status']?.toString()) == 'todo').length;

  final completionRate = totalTasks == 0 ? 0.0 : (completedTasks / totalTasks) * 100.0;

  // Team contribution
  final memberTaskCount = <String, int>{};
  for (final task in tasks) {
    final assigneeId = task['assigneeId']?.toString();
    if (assigneeId != null && assigneeId.isNotEmpty) {
      memberTaskCount[assigneeId] = (memberTaskCount[assigneeId] ?? 0) + 1;
    }
  }
  final totalAssignments = memberTaskCount.values.fold<int>(0, (a, b) => a + b);
  final teamContribution = <String, double>{
    for (final e in memberTaskCount.entries)
      e.key: totalAssignments == 0 ? 0.0 : (e.value / totalAssignments) * 100.0
  };

  // Checklist completion average
  double checklistPct(List<dynamic> checklist) {
    if (checklist.isEmpty) return 0.0;
    var done = 0;
    for (final item in checklist) {
      if (item is Map<String, dynamic>) {
        if (item['done'] == true || item['isDone'] == true || item['checked'] == true) {
          done++;
        }
      }
    }
    return (done / checklist.length) * 100.0;
  }

  final checklistRates = <double>[];
  for (final task in tasks) {
    final list = task['checklist'] as List<dynamic>? ?? const [];
    checklistRates.add(checklistPct(list));
  }
  final avgChecklistCompletion =
      checklistRates.isEmpty ? 0.0 : checklistRates.reduce((a, b) => a + b) / checklistRates.length;

  // Engagement factor (uses board-level files + comments count)
  final engagementRaw = (comments.length + files.length) / (totalTasks + 1) * 10.0;
  final engagementFactor = engagementRaw.clamp(0.0, 20.0);

  final projectHealthScore =
      (completionRate * 0.6) + (avgChecklistCompletion * 0.2) + (engagementFactor * 0.2);

  return BoardInsights(
    boardId: scopeId,
    projectHealthScore: projectHealthScore.clamp(0.0, 100.0),
    teamContribution: teamContribution,
    taskTrends: {
      'total': totalTasks,
      'completed': completedTasks,
      'inProgress': inProgressTasks,
      'todo': todoTasks,
    },
    resourceUsage: {
      'avgChecklistCompletion': avgChecklistCompletion,
      'fileUploads': totalFiles.toDouble(),
      'commentsCount': comments.length.toDouble(),
    },
  );
}

List<List<T>> _chunk<T>(List<T> list, int size) {
  final chunks = <List<T>>[];
  for (var i = 0; i < list.length; i += size) {
    final end = (i + size < list.length) ? i + size : list.length;
    chunks.add(list.sublist(i, end));
  }
  return chunks;
}
