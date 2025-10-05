import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/board/presentation/widgets/kanban_column.dart';
import 'package:boardbuddy/features/board/presentation/widgets/task_card.dart';
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
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            // Always navigate to main board screen, not the previous screen
            Get.offAllNamed(AppRoutes.mainScreen);
          },
        ),
        title: Text(_board.name, style: const TextStyle(color: AppColors.textPrimary)),
      ),
      body: StreamBuilder<List<BoardColumn>>(
        stream: BoardFirestoreService.instance.streamColumns(_board.boardId),
        builder: (context, colSnap) {
          if (colSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (colSnap.hasError) {
            return Center(child: Text('Failed to load columns', style: const TextStyle(color: AppColors.textSecondary)));
          }
          final cols = (colSnap.data ?? _columnsMeta)..sort((a, b) => a.order.compareTo(b.order));
          if (cols.isEmpty) {
            return const Center(child: Text('No columns yet', style: TextStyle(color: AppColors.textSecondary)));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: cols.map((colMeta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: StreamBuilder<List<task_model.TaskCard>>(
                    stream: BoardFirestoreService.instance.streamCards(_board.boardId, colMeta.columnId),
                    builder: (context, taskSnap) {
                      final tasks = taskSnap.data ?? const <task_model.TaskCard>[];
                      return KanbanColumn(
                        title: colMeta.title,
                        tasks: tasks,
                        columnId: colMeta.columnId,
                        onTaskMoved: _onTaskMoved,
                        onTaskLongPress: (task, pos) {},
                        onTaskTap: (task) async {
                          final action = await Navigator.of(context).push<TaskAction?>(
                            MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)),
                          );
                          if (action == null) return;
                          if (action.action == 'delete' && action.task != null) {
                            await BoardFirestoreService.instance.deleteCard(
                              boardId: _board.boardId,
                              columnId: colMeta.columnId,
                              taskId: action.task!.id,
                            );
                          } else if (action.action == 'save' && action.task != null) {
                            await BoardFirestoreService.instance.upsertCard(
                              boardId: _board.boardId,
                              columnId: colMeta.columnId,
                              card: action.task!,
                            );
                          }
                        },
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final action = await Navigator.of(context).push<TaskAction?>(
            MaterialPageRoute(builder: (_) => const TaskDetailsScreen()),
          );
          if (action == null || action.task == null) return;
          final firstColId = (_columnsMeta.isNotEmpty ? _columnsMeta.first.columnId : 'todo');
          await BoardFirestoreService.instance.upsertCard(
            boardId: _board.boardId,
            columnId: firstColId,
            card: action.task!.copyWith(columnId: firstColId),
          );
        },
        icon: const Icon(Icons.add, color: AppColors.textPrimary),
        label: const Text('Add Task', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.primary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}