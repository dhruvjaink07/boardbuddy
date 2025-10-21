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
    // Simple count from comments subcollection
    final commentSnaps = await fs.collection('boards/$boardId/comments').get();
    comments.addAll(commentSnaps.docs.map((d) => d.data()));
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
        // Simple count from comments subcollection
        final commentSnaps = await fs.collection('boards/$boardId/comments').get();
        comments.addAll(commentSnaps.docs.map((d) => d.data()));
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

// Tasks are classified by status field or column location:
String _normStatus(String? s) {
  final x = (s ?? '').toLowerCase().trim();
  if (x.contains('done') || x.contains('complete') || x.contains('closed')) return 'done';
  if (x.contains('progress') || x.contains('doing') || x.contains('review')) return 'in_progress';
  if (x.contains('todo') || x.contains('backlog') || x.contains('open')) return 'todo';
  return 'other';
}

// Card completion check (3 ways):
bool _isCardDone(Map<String, dynamic> t) {
  if (t['isCompleted'] == true) return true;        // 1. Explicit completion flag
  if (t['completedAt'] != null) return true;       // 2. Has completion timestamp  
  return _normStatus(t['status']?.toString()) == 'done'; // 3. Status contains "done"
}

// safe short id helper
String _shortId(String id, [int len = 8]) {
  if (id == null) return '';
  return id.length <= len ? id : id.substring(0, len);
}

// Add this helper function to fetch user names
Future<Map<String, String>> _fetchUserNames(Set<String> userIds) async {
  if (userIds.isEmpty) return const {};
  
  final userNames = <String, String>{};
  final fs = FirebaseFirestore.instance;
  
  // Fetch user names in chunks of 10 (Firestore limit)
  for (final chunk in _chunk(userIds.toList(), 10)) {
    try {
      final qs = await fs.collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      
      for (final doc in qs.docs) {
        final data = doc.data();
        final displayName = data['displayName'] as String?;
        final email = data['email'] as String?;
        
        // Use displayName if available, otherwise email, otherwise fallback to ID
        userNames[doc.id] = displayName?.isNotEmpty == true 
            ? displayName! 
            : email?.isNotEmpty == true 
                ? email!.split('@').first 
                : _shortId(doc.id); // SAFE
      }
    } catch (e) {
      print('Error fetching user names: $e');
      // Fallback for failed fetches
      for (final id in chunk) {
        userNames[id] = _shortId(id); // SAFE
      }
    }
  }
  
  return userNames;
}

// Update _generateInsights to include user names
Future<BoardInsights> _generateInsights(
  String scopeId,
  List<Map<String, dynamic>> tasks,
  List<Map<String, dynamic>> comments,
  List<Map<String, dynamic>> files,
  int totalFiles,
) async {
  final totalTasks = tasks.length;
  final completedTasks = tasks.where(_isCardDone).length;
  final inProgressTasks =
      tasks.where((t) => !_isCardDone(t) && _normStatus(t['status']?.toString()) == 'in_progress').length;
  final todoTasks =
      tasks.where((t) => !_isCardDone(t) && _normStatus(t['status']?.toString()) == 'todo').length;

  final completionRate = totalTasks == 0 ? 0.0 : (completedTasks / totalTasks) * 100.0;

  // Team contribution with user names
  final memberTaskCount = <String, int>{};
  final assigneeIds = <String>{}; // Collect user IDs
  
  for (final task in tasks) {
    final assigneeId = task['assigneeId']?.toString();
    if (assigneeId != null && assigneeId.isNotEmpty) {
      memberTaskCount[assigneeId] = (memberTaskCount[assigneeId] ?? 0) + 1;
      assigneeIds.add(assigneeId);
    }
  }

  // Fetch user names for all assignees
  final userNames = await _fetchUserNames(assigneeIds);

  // Convert to percentages with names
  final totalAssignments = memberTaskCount.values.fold<int>(0, (a, b) => a + b);
  final teamContribution = <String, double>{};
  final teamContributionWithNames = <String, Map<String, dynamic>>{};
  
  for (final e in memberTaskCount.entries) {
    final percentage = totalAssignments == 0 ? 0.0 : (e.value / totalAssignments) * 100.0;
    final userName = userNames[e.key] ?? e.key.substring(0, 8);
    
    teamContribution[e.key] = percentage;
    teamContributionWithNames[e.key] = {
      'name': userName,
      'percentage': percentage,
      'taskCount': e.value,
    };
  }

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
  final avgChecklistCompletion = checklistRates.isEmpty 
    ? 0.0 
    : checklistRates.reduce((a, b) => a + b) / checklistRates.length;

  final projectHealthScore = completionRate;

  return BoardInsights(
    boardId: scopeId,
    projectHealthScore: projectHealthScore.clamp(0.0, 100.0),
    teamContribution: teamContribution,
    teamContributionWithNames: teamContributionWithNames,
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
