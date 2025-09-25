import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';

class TaskDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? task;

  const TaskDetailsScreen({
    super.key,
    this.task,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Local subtasks (copy so UI can toggle independently)
  late List<Map<String, dynamic>> subtasks;

  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _dueDateController;
  late TextEditingController _assigneesController;
  String _priority = 'Medium';
  String _category = 'Design';

  bool get isEditMode => widget.task != null;

  @override
  void initState() {
    super.initState();

    // initialize form values from provided task or defaults
    final t = widget.task;
    _titleController = TextEditingController(text: t?['title'] ?? '');
    _descriptionController = TextEditingController(text: t?['description'] ?? '');
    _dueDateController = TextEditingController(text: t?['dueDate'] ?? '');
    _assigneesController = TextEditingController(
        text: (t?['assignees'] as List<dynamic>?)?.join(', ') ?? '');
    _priority = (t?['priority'] ?? 'Medium').toString();
    _category = (t?['category'] ?? 'Design').toString();

    subtasks = List<Map<String, dynamic>>.from(
        t?['subtasks'] ??
            [
              {'title': 'Research existing systems', 'done': true},
              {'title': 'Create component library', 'done': true},
              {'title': 'Design documentation template', 'done': false},
            ]);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 275),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    _assigneesController.dispose();
    super.dispose();
  }

  void _toggleSubtask(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      subtasks[index]['done'] = !(subtasks[index]['done'] as bool);
    });
  }

  void _showAddSubtaskDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          'Add Subtask',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Subtask title',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            border: OutlineInputBorder(borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  subtasks.add({'title': text, 'done': false});
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'medium':
        return const Color(0xFFD97706);
      case 'low':
        return const Color(0xFF059669);
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'design':
        return const Color(0xFF7C3AED);
      case 'development':
        return const Color(0xFF2563EB);
      case 'backend':
        return const Color(0xFF059669);
      case 'frontend':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF6B7280);
    }
  }

  void _saveTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    final id = widget.task?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final assignees = _assigneesController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    final taskMap = <String, dynamic>{
      'id': id,
      'title': title,
      'description': _descriptionController.text.trim(),
      'priority': _priority,
      'category': _category,
      'dueDate': _dueDateController.text.trim(),
      'assignees': assignees,
      'subtasks': subtasks,
      'progress': (subtasks.isEmpty) ? 0 : subtasks.where((s) => s['done'] == true).length,
    };

    Navigator.of(context).pop(taskMap);
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = subtasks.where((t) => t['done'] as bool).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {
                // return a special signal to delete (caller can handle)
                Navigator.of(context).pop({'_action': 'delete', 'id': widget.task!['id']});
              },
            ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
        title: Text(isEditMode ? 'Task Details' : 'Add Task', style: const TextStyle(color: AppColors.textPrimary)),
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextField(
                controller: _titleController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Task title',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textSecondary),
                decoration: InputDecoration(
                  hintText: 'Add description...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              // Priority & Category row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _priority,
                      items: ['High', 'Medium', 'Low'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (v) => setState(() => _priority = v ?? 'Medium'),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(text: _category),
                      onChanged: (v) => _category = v,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Category',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Due date & assignees
              TextField(
                controller: _dueDateController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Due date (e.g. Oct 15)',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _assigneesController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Assignees (comma separated initials or names)',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              // Subtasks header + progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtasks (${doneCount}/${subtasks.length})', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _showAddSubtaskDialog,
                    icon: const Icon(Icons.add, color: AppColors.primary),
                    label: const Text('Add', style: TextStyle(color: AppColors.primary)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: subtasks.isEmpty ? 0 : (doneCount / subtasks.length),
                  color: AppColors.primary,
                  backgroundColor: AppColors.card,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 12),

              // Subtasks list
              Column(
                children: List.generate(subtasks.length, (i) {
                  final s = subtasks[i];
                  return _SubtaskTileInternal(
                    title: s['title'] as String,
                    done: s['done'] as bool,
                    onToggle: () => _toggleSubtask(i),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Save button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(isEditMode ? 'Save changes' : 'Create task', style: const TextStyle(color: AppColors.textPrimary)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubtaskTileInternal extends StatelessWidget {
  final String title;
  final bool done;
  final VoidCallback onToggle;
  const _SubtaskTileInternal({required this.title, required this.done, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Checkbox(value: done, activeColor: AppColors.primary, onChanged: (_) => onToggle()),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                color: done ? AppColors.textSecondary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}