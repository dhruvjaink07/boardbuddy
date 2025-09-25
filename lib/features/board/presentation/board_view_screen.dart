import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/board/presentation/widgets/kanban_column.dart';
import 'package:boardbuddy/features/board/presentation/widgets/task_card.dart';
import 'package:boardbuddy/features/board/presentation/task_details_screen.dart';
import 'package:boardbuddy/features/board/models/board.dart';
import 'package:boardbuddy/features/board/models/board_column.dart';
import 'package:boardbuddy/features/board/models/task_card.dart' as task_model;

class BoardViewScreen extends StatefulWidget {
  const BoardViewScreen({super.key});

  @override
  State<BoardViewScreen> createState() => _BoardViewScreenState();
}

class _BoardViewScreenState extends State<BoardViewScreen> {
  late Board _board;

  // keep column metadata using your BoardColumn model
  late List<BoardColumn> _columnsMeta;

  // tasks stored as typed models (task_model.TaskCard)
  late Map<String, List<task_model.TaskCard>> _tasksByColumn;

  @override
  void initState() {
    super.initState();

    _board = Board(
      boardId: 'board_1',
      name: 'Portfolio Website',
      description: 'A demo board populated with sample tasks',
      theme: 'forest',
      ownerId: 'owner_1',
      memberIds: ['owner_1', 'member_2'],
      maxEditors: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      lastUpdated: DateTime.now(),
    );

    _columnsMeta = [
      BoardColumn(columnId: 'todo', title: 'To Do', order: 0, createdAt: DateTime.now()),
      BoardColumn(columnId: 'inprogress', title: 'In Progress', order: 1, createdAt: DateTime.now()),
      BoardColumn(columnId: 'done', title: 'Done', order: 2, createdAt: DateTime.now()),
    ];

    // initialize typed tasks by converting from map shapes using TaskCard.fromMap
    _tasksByColumn = {
      'todo': [
        task_model.TaskCard.fromMap({
          'id': 't1',
          'title': 'Design landing page',
          'description': 'Create hero section and feature list',
          'priority': 'High',
          'category': 'Design',
          'dueDate': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          'assignees': ['AS', 'MB'],
          'subtasks': [
            {'title': 'Wireframe', 'done': true},
            {'title': 'Prototype', 'done': false},
          ],
          'status': 'todo',
        }),
        task_model.TaskCard.fromMap({
          'id': 't2',
          'title': 'Setup repo & CI',
          'description': 'Initialize project and add CI workflow',
          'priority': 'Medium',
          'category': 'Dev',
          'dueDate': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
          'assignees': ['JP'],
          'subtasks': [],
          'status': 'todo',
        }),
      ],
      'inprogress': [
        task_model.TaskCard.fromMap({
          'id': 't3',
          'title': 'Implement auth',
          'description': 'Sign in and signup screens',
          'priority': 'High',
          'category': 'Backend',
          'dueDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
          'assignees': ['RK'],
          'subtasks': [
            {'title': 'API', 'done': true},
            {'title': 'UI', 'done': false},
          ],
          'status': 'inprogress',
        }),
      ],
      'done': [
        task_model.TaskCard.fromMap({
          'id': 't4',
          'title': 'Project kickoff',
          'description': 'Define scope, milestones',
          'priority': 'Low',
          'category': 'Planning',
          'dueDate': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'assignees': ['PM'],
          'subtasks': [
            {'title': 'Meeting', 'done': true},
          ],
          'status': 'done',
        }),
      ],
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