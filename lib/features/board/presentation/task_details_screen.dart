import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/board/models/task_card.dart' as task_model;
import 'package:boardbuddy/features/files/presentation/file_list_view.dart';

class TaskAction {
  final String action; // 'save' or 'delete'
  final task_model.TaskCard? task;
  TaskAction({required this.action, this.task});
}

class TaskDetailsScreen extends StatefulWidget {
  final String boardId;
  final String? columnId; // NEW: Add columnId parameter
  final task_model.TaskCard? task;
  
  const TaskDetailsScreen({
    super.key, 
    required this.boardId, 
    this.columnId, // NEW: Add this parameter
    this.task,
  });

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
  DateTime? _dueDate;
  bool _isCompleted = false; // NEW: Add completion state

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _assigneesController = TextEditingController(text: (widget.task?.assignees ?? []).join(', '));
    _category = widget.task?.category ?? '';
    _categoryController = TextEditingController(text: _category);
    _priority = widget.task?.priority ?? 'medium';
    _dueDate = widget.task?.dueDate;
    _isCompleted = widget.task?.isCompleted ?? false; // NEW: Initialize completion
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
        ? task_model.TaskCard(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            description: desc,
            priority: _priority,
            category: _category.isEmpty ? null : _category,
            assignees: assignees,
            status: 'todo',
            progress: 0.0,
            dueDate: _dueDate,
            isCompleted: _isCompleted,
            boardId: widget.boardId,
            columnId: widget.columnId ?? 'todo',
            attachments: const [], // Initialize empty lists
            checklist: const [],
          )
        : widget.task!.copyWith(
            title: title,
            description: desc,
            priority: _priority,
            category: _category.isEmpty ? null : _category,
            assignees: assignees,
            dueDate: _dueDate,
            isCompleted: _isCompleted,
            completedAt: _isCompleted ? DateTime.now() : null, // Set completion time
          );

    Navigator.of(context).pop(TaskAction(action: 'save', task: task));
  }

  void _onDelete() {
    if (widget.task == null) {
      Navigator.of(context).pop(null);
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Task', 
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete this task? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(TaskAction(action: 'delete', task: widget.task));
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _clearDueDate() {
    setState(() {
      _dueDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          widget.task == null ? 'New Task' : 'Edit Task',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (widget.task != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _onDelete,
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            // NEW: Completion toggle for existing tasks
            if (widget.task != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isCompleted ? AppColors.success : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: _isCompleted ? AppColors.success : AppColors.textSecondary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isCompleted ? 'Task Completed' : 'Mark as Complete',
                            style: TextStyle(
                              color: _isCompleted ? AppColors.success : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (_isCompleted && widget.task?.completedAt != null)
                            Text(
                              'Completed ${_formatDate(widget.task!.completedAt!)}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isCompleted,
                      onChanged: (value) {
                        setState(() {
                          _isCompleted = value;
                        });
                      },
                      activeColor: AppColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Title field
            const Text('Title', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description field
            const Text('Description', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Priority and Category row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      const Text('Priority', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'urgent', child: Text('🔴 Urgent')),
                          DropdownMenuItem(value: 'high', child: Text('🟠 High')),
                          DropdownMenuItem(value: 'medium', child: Text('🟡 Medium')),
                          DropdownMenuItem(value: 'low', child: Text('🟢 Low')),
                        ],
                        onChanged: (v) => setState(() => _priority = v ?? 'medium'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      const Text('Category', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Due date section
            const Text('Due Date', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                title: Text(
                  _dueDate != null ? _formatDate(_dueDate!) : 'No due date set',
                  style: TextStyle(
                    color: _dueDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                trailing: _dueDate != null 
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                      onPressed: _clearDueDate,
                    )
                  : null,
                onTap: _selectDueDate,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Assignees field
            const Text('Assignees (comma separated)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _assigneesController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'AS, MB, JD',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                prefixIcon: const Icon(Icons.people_outline, color: AppColors.primary),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  widget.task == null ? 'Create Task' : 'Save Changes',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Attachments section (only for existing tasks)
            if (widget.task != null && widget.task!.columnId != null) ...[
              const Text(
                'Attachments', 
                style: TextStyle(
                  color: AppColors.textPrimary, 
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TaskAttachmentsSection(
                  boardId: widget.boardId,
                  columnId: widget.task!.columnId ?? '',
                  cardId: widget.task!.id,
                  attachments: widget.task!.attachments,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    if (targetDate == today) {
      return 'Today';
    } else if (targetDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (targetDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}