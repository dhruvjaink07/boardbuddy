import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/board/models/task_card.dart' as task_model;
import 'package:boardbuddy/features/files/presentation/file_list_view.dart';
import 'package:boardbuddy/features/files/presentation/cloudinary_test_widget.dart';

class TaskAction {
  final String action; // 'save' or 'delete'
  final task_model.TaskCard? task;
  TaskAction({required this.action, this.task});
}

class TaskDetailsScreen extends StatefulWidget {
  final String boardId;
  final task_model.TaskCard? task;
  const TaskDetailsScreen({super.key, required this.boardId, this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _assigneesController;
  late TextEditingController _categoryController;

  String _priority = 'medium';
  String _category = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _assigneesController = TextEditingController(text: (widget.task?.assignees ?? []).join(', '));
    _category = widget.task?.category ?? '';
    _categoryController = TextEditingController(text: _category);
    _priority = widget.task?.priority ?? 'medium';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assigneesController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _onSave() {
    final title = _titleController.text.trim();
    final desc = _descriptionController.text.trim();
    final assignees = _assigneesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    final task = (widget.task == null)
        ? task_model.TaskCard.fromMap({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'title': title,
            'description': desc,
            'priority': _priority,
            'category': _category,
            'assignees': assignees,
            'subtasks': [],
            'status': 'todo',
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
            'columnId': 'todo',
            'progress': 0.0,
          })
        : widget.task!.copyWith(
            title: title,
            description: desc,
            priority: _priority,
            category: _category,
            assignees: assignees,
            lastUpdated: DateTime.now(), // fixed: use lastUpdated (not updatedAt)
          );

    Navigator.of(context).pop(TaskAction(action: 'save', task: task));
  }

  void _onDelete() {
    if (widget.task == null) {
      Navigator.of(context).pop(null);
      return;
    }
    Navigator.of(context).pop(TaskAction(action: 'delete', task: widget.task));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          widget.task == null ? 'New Task' : 'Edit Task',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          if (widget.task != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
              onPressed: _onDelete,
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Title', style: TextStyle(color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Task title',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Description', style: TextStyle(color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Task description',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Priority', style: TextStyle(color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _priority,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                  ],
                  onChanged: (v) => setState(() => _priority = v ?? 'medium'),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Category', style: TextStyle(color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _categoryController,
                  onChanged: (v) => _category = v,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g., Design',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          const Text('Assignees (comma separated)', style: TextStyle(color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _assigneesController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'AS, MB',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Save', style: TextStyle(color: AppColors.textPrimary)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          if (widget.task != null) ...[
            const Text('Attachments', style: TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            TaskAttachmentsSection(
              boardId: widget.boardId,
              columnId: widget.task!.columnId,
              cardId: widget.task!.id,
              attachments: widget.task!.attachments,
            ),
            const SizedBox(height: 24),
            // ADD THIS TEST WIDGET TEMPORARILY
            const CloudinaryTestWidget(),
          ],
        ]),
      ),
    );
  }
}