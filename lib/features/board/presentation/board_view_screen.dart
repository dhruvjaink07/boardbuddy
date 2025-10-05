import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/board/presentation/widgets/kanban_column.dart';
import 'package:boardbuddy/features/board/presentation/widgets/task_card.dart' as task_widget;
import 'package:boardbuddy/features/board/presentation/task_details_screen.dart';
import 'package:boardbuddy/features/board/models/board.dart';
import 'package:boardbuddy/features/board/models/board_column.dart';
import 'package:boardbuddy/features/board/models/task_card.dart' as task_model;
import 'package:get/get.dart'; // Add this import
import 'package:boardbuddy/routes/app_routes.dart'; // Add this import
import 'package:boardbuddy/features/board/data/board_firestore_service.dart';

class BoardViewScreen extends StatefulWidget {
  final Board? board;
  final List<BoardColumn>? columnsMeta;
  final Map<String, List<task_model.TaskCard>>? tasksByColumn;

  const BoardViewScreen({super.key, this.board, this.columnsMeta, this.tasksByColumn});

  @override
  State<BoardViewScreen> createState() => _BoardViewScreenState();
}

class _BoardViewScreenState extends State<BoardViewScreen> {
  late Board _board;
  late List<BoardColumn> _columnsMeta;
  late Map<String, List<task_model.TaskCard>> _tasksByColumn;

  List<BoardColumn> _liveColumns = const [];

  Future<void> _addTask() async {
    if (_liveColumns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a column first')),
      );
      return;
    }
    final firstColId = _liveColumns.first.columnId;
    final action = await Navigator.of(context).push<TaskAction?>(
      MaterialPageRoute(builder: (_) => const TaskDetailsScreen()),
    );
    if (action == null || action.task == null) return;
    await BoardFirestoreService.instance.upsertCard(
      boardId: _board.boardId,
      columnId: firstColId,
      card: action.task!.copyWith(columnId: firstColId),
    );
  }

  @override
  void initState() {
    super.initState();

    _board = widget.board ??
        Board(
          boardId: 'board_1',
          name: 'Portfolio Website',
          description: 'A demo board populated with sample tasks',
          theme: 'forest',
          ownerId: 'owner_1',
          memberIds: ['owner_1'],
          maxEditors: 5,
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          lastUpdated: DateTime.now(),
        );

    _columnsMeta = widget.columnsMeta ?? [
      BoardColumn(columnId: 'todo', title: 'To Do', order: 0, createdAt: DateTime.now()),
      BoardColumn(columnId: 'inprogress', title: 'In Progress', order: 1, createdAt: DateTime.now()),
      BoardColumn(columnId: 'done', title: 'Done', order: 2, createdAt: DateTime.now()),
    ];

    _tasksByColumn = widget.tasksByColumn ?? {
      for (final c in _columnsMeta) c.columnId: <task_model.TaskCard>[],
    };
  }

  List<task_model.TaskCard> _tasksForColumn(BoardColumn col) =>
      List<task_model.TaskCard>.from(_tasksByColumn[col.columnId] ?? []);

  // Replace local move with Firestore move
  void _onTaskMoved(String taskId, String fromColumn, String toColumn) {
    BoardFirestoreService.instance.moveCard(
      boardId: _board.boardId,
      taskId: taskId,
      fromColumn: fromColumn,
      toColumn: toColumn,
    );
  }

  void _replaceOrInsertTask(task_model.TaskCard updated) {
    // try replace
    for (final entry in _tasksByColumn.entries) {
      final idx = entry.value.indexWhere((t) => t.id == updated.id);
      if (idx >= 0) {
        entry.value[idx] = updated;
        setState(() {});
        return;
      }
    }
    // not found -> insert into first column
    final firstKey = _columnsMeta.first.columnId;
    _tasksByColumn[firstKey] = (_tasksByColumn[firstKey] ?? [])..add(updated);
    setState(() {});
  }

  void _deleteTaskById(String id) {
    for (final entry in _tasksByColumn.entries) {
      entry.value.removeWhere((t) => t.id == id);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_board.name),
        actions: [
          StreamBuilder<String?>(
            stream: BoardFirestoreService.instance.myRoleStream(_board.boardId),
            builder: (context, snap) {
              final isOwner = (snap.data ?? '') == 'owner';
              if (!isOwner) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: () async {
                  final uidCtrl = TextEditingController();
                  String role = 'editor';
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Add member by UID'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(controller: uidCtrl, decoration: const InputDecoration(labelText: 'User UID')),
                          const SizedBox(height: 8),
                          DropdownButton<String>(
                            value: role,
                            items: const [
                              DropdownMenuItem(value: 'editor', child: Text('Editor')),
                              DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                            ],
                            onChanged: (v) => role = v ?? 'editor',
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
                      ],
                    ),
                  );
                  if (ok == true && uidCtrl.text.trim().isNotEmpty) {
                    await BoardFirestoreService.instance.addMember(
                      boardId: _board.boardId,
                      userId: uidCtrl.text.trim(),
                      role: role,
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<String?>(
        stream: BoardFirestoreService.instance.myRoleStream(_board.boardId),
        builder: (context, roleSnap) {
          final role = roleSnap.data ?? 'viewer';
          final canEdit = role == 'owner' || role == 'editor';

          return Column(
            children: [
              // Columns + cards
              Expanded(
                child: StreamBuilder<List<BoardColumn>>(
                  stream: BoardFirestoreService.instance.streamColumns(_board.boardId),
                  builder: (context, colSnap) {
                    final cols = (colSnap.data ?? const <BoardColumn>[]);
                    _liveColumns = cols; // use real columns for FAB add
                    if (cols.isEmpty) {
                      return const Center(child: Text('No columns yet'));
                    }
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: cols.map((col) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: StreamBuilder<List<task_model.TaskCard>>(
                              stream: BoardFirestoreService.instance.streamCards(_board.boardId, col.columnId),
                              builder: (context, taskSnap) {
                                final tasks = taskSnap.data ?? const <task_model.TaskCard>[];
                                return KanbanColumn(
                                  title: col.title,
                                  tasks: tasks,
                                  columnId: col.columnId,
                                  onTaskMoved: canEdit ? _onTaskMoved : (_, __, ___) {}, // no-op for viewers
                                  onTaskTap: (task) async {
                                    if (!canEdit) return;
                                    final result = await Navigator.of(context).push<TaskAction?>(
                                      MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)),
                                    );
                                    if (result?.action == 'save' && result?.task != null) {
                                      await BoardFirestoreService.instance.upsertCard(
                                        boardId: _board.boardId,
                                        columnId: col.columnId,
                                        card: result!.task!,
                                      );
                                    } else if (result?.action == 'delete' && result?.task != null) {
                                      await BoardFirestoreService.instance.deleteCard(
                                        boardId: _board.boardId,
                                        columnId: col.columnId,
                                        taskId: result!.task!.id,
                                      );
                                    }
                                  },
                                  onTaskLongPress: (task, pos) {}, // optional
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: StreamBuilder<String?>(
        stream: BoardFirestoreService.instance.myRoleStream(_board.boardId),
        builder: (context, roleSnap) {
          final role = roleSnap.data ?? 'viewer';
          final canEdit = role == 'owner' || role == 'editor';
          if (!canEdit) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _addTask, // your existing add-task flow
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Task'),
          );
        },
      ),
    );
  }
}