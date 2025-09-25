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

    // Use provided values (from create flow) or fallback to dummy data
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

    _columnsMeta = widget.columnsMeta ??
        [
          BoardColumn(columnId: 'todo', title: 'To Do', order: 0, createdAt: DateTime.now()),
          BoardColumn(columnId: 'inprogress', title: 'In Progress', order: 1, createdAt: DateTime.now()),
          BoardColumn(columnId: 'done', title: 'Done', order: 2, createdAt: DateTime.now()),
        ];

    _tasksByColumn = widget.tasksByColumn ??
        {
          for (final c in _columnsMeta) c.columnId: <task_model.TaskCard>[],
        };
  }

  List<task_model.TaskCard> _tasksForColumn(BoardColumn col) =>
      List<task_model.TaskCard>.from(_tasksByColumn[col.columnId] ?? []);

  void _onTaskMoved(String taskId, String fromColumn, String toColumn) {
    final from = _tasksByColumn[fromColumn];
    final to = _tasksByColumn[toColumn];
    if (from == null || to == null) return;
    final idx = from.indexWhere((t) => t.id == taskId);
    if (idx < 0) return;
    final task = from.removeAt(idx);
    final updated = task.copyWith(status: toColumn);
    to.add(updated);
    setState(() {});
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
        automaticallyImplyLeading: false, // Disable default back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            // Always navigate to main board screen, not the previous screen
            Get.offAllNamed(AppRoutes.mainScreen);
          },
        ),
        title: Text(_board.name, style: const TextStyle(color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: _columnsMeta.map((colMeta) {
            final tasks = _tasksForColumn(colMeta);
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: KanbanColumn(
                title: colMeta.title,
                tasks: tasks, // typed list
                columnId: colMeta.columnId,
                onTaskMoved: _onTaskMoved,
                onTaskLongPress: (task, pos) {
                  // placeholder
                },
                onTaskTap: (task) async {
                  // OPEN TaskDetailsScreen with the typed model and handle TaskAction result
                  final action = await Navigator.of(context).push<TaskAction?>(
                    MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)),
                  );
                  if (action == null) return;
                  if (action.action == 'delete' && action.task != null) {
                    _deleteTaskById(action.task!.id);
                  } else if (action.action == 'save' && action.task != null) {
                    // update or insert the returned model into columns
                    _replaceOrInsertTask(action.task!);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // create new task via TaskDetailsScreen (typed TaskAction result)
          final action = await Navigator.of(context).push<TaskAction?>(
            MaterialPageRoute(builder: (_) => const TaskDetailsScreen()),
          );
          if (action == null) return;
          if (action.action == 'save' && action.task != null) {
            final firstKey = _columnsMeta.first.columnId;
            _tasksByColumn[firstKey] = (_tasksByColumn[firstKey] ?? [])..add(action.task!);
            setState(() {});
          }
        },
        icon: const Icon(Icons.add, color: AppColors.textPrimary),
        label: const Text('Add Task', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.primary,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}