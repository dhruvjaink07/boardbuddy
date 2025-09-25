import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/board/presentation/widgets/kanban_column.dart';
import 'package:boardbuddy/features/board/presentation/widgets/task_card.dart';
import 'package:boardbuddy/features/board/presentation/task_details_screen.dart';

class BoardViewScreen extends StatefulWidget {
  const BoardViewScreen({super.key});

  @override
  State<BoardViewScreen> createState() => _BoardViewScreenState();
}

class _BoardViewScreenState extends State<BoardViewScreen> {
  List<Map<String, dynamic>> todoTasks = [
    {
      'id': '1',
      'title': 'Design System Updates',
      'description': 'Update color palette and typography system',
      'priority': 'High',
      'assignees': ['JD', 'SM'],
      'dueDate': 'Dec 15',
      'progress': 3,
    },
    {
      'id': '2',
      'title': 'API Integration',
      'description': 'Implement new payment gateway',
      'priority': 'High',
      'assignees': ['Dev'],
      'dueDate': 'Dec 20',
      'progress': 1,
    },
  ];

  List<Map<String, dynamic>> inProgressTasks = [
    {
      'id': '3',
      'title': 'User Research',
      'description': 'Conduct user interviews for new features',
      'priority': 'Medium',
      'assignees': ['AB'],
      'dueDate': 'Dec 18',
      'progress': 2,
    },
    {
      'id': '4',
      'title': 'Mobile App Testing',
      'description': 'QA testing for iOS and Android',
      'priority': 'Low',
      'assignees': ['QA'],
      'dueDate': 'Dec 25',
      'progress': 4,
    },
  ];

  List<Map<String, dynamic>> doneTasks = [
    {
      'id': '5',
      'title': 'Documentation',
      'description': 'Update API documentation',
      'priority': 'Medium',
      'assignees': ['TW'],
      'dueDate': 'Dec 10',
      'progress': 5,
    },
  ];

  void _onTaskMoved(String taskId, String fromColumn, String toColumn) {
    setState(() {
      Map<String, dynamic>? task;
      
      // Remove from source
      if (fromColumn == 'todo') {
        task = todoTasks.firstWhere((t) => t['id'] == taskId);
        todoTasks.removeWhere((t) => t['id'] == taskId);
      } else if (fromColumn == 'inprogress') {
        task = inProgressTasks.firstWhere((t) => t['id'] == taskId);
        inProgressTasks.removeWhere((t) => t['id'] == taskId);
      } else if (fromColumn == 'done') {
        task = doneTasks.firstWhere((t) => t['id'] == taskId);
        doneTasks.removeWhere((t) => t['id'] == taskId);
      }

      // Add to destination
      if (task != null) {
        if (toColumn == 'todo') {
          todoTasks.add(task);
        } else if (toColumn == 'inprogress') {
          inProgressTasks.add(task);
        } else if (toColumn == 'done') {
          doneTasks.add(task);
        }
      }
    });
  }

  // Show popup menu like Instagram
  void _showTaskActions(BuildContext context, Map<String, dynamic> task, String currentColumn, Offset tapPosition) {
    // Get available columns (exclude current column)
    List<Map<String, String>> availableColumns = [];
    
    if (currentColumn != 'todo') {
      availableColumns.add({'id': 'todo', 'title': 'Move to To Do', 'icon': '📋'});
    }
    if (currentColumn != 'inprogress') {
      availableColumns.add({'id': 'inprogress', 'title': 'Move to In Progress', 'icon': '⏳'});
    }
    if (currentColumn != 'done') {
      availableColumns.add({'id': 'done', 'title': 'Move to Done', 'icon': '✅'});
    }

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        tapPosition.dx,
        tapPosition.dy,
        tapPosition.dx + 1,
        tapPosition.dy + 1,
      ),
      color: AppColors.card,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      items: <PopupMenuEntry<String>>[
        // Task info header
        PopupMenuItem<String>(
          enabled: false,
          height: 60,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task['priority']),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task['title'],
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 1,
                  color: AppColors.textSecondary.withOpacity(0.1),
                ),
              ],
            ),
          ),
        ),
        
        // Move options
        ...availableColumns.map<PopupMenuItem<String>>((column) => PopupMenuItem<String>(
          value: column['id'],
          height: 50,
          child: Row(
            children: [
              Text(
                column['icon']!,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  column['title']!,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
            ],
          ),
        )),
        
        // Divider
        const PopupMenuDivider(),
        
        // Edit option
        PopupMenuItem<String>(
          value: 'edit',
          height: 50,
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              const Text(
                'Edit Task',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Delete option
        PopupMenuItem<String>(
          value: 'delete',
          height: 50,
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.red,
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Task',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        if (value == 'edit') {
          // Handle edit
          _showEditDialog(task);
        } else if (value == 'delete') {
          // Handle delete
          _showDeleteDialog(task, currentColumn);
        } else {
          // Handle move
          _onTaskMoved(task['id'], currentColumn, value);
          _showSuccessMessage('Task moved successfully');
        }
      }
    });
  }

  void _showEditDialog(Map<String, dynamic> task) {
    // Show edit dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Edit Task',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Edit functionality will be implemented here.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> task, String currentColumn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Delete Task',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${task['title']}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTask(task['id'], currentColumn);
              _showSuccessMessage('Task deleted successfully');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteTask(String taskId, String column) {
    setState(() {
      if (column == 'todo') {
        todoTasks.removeWhere((t) => t['id'] == taskId);
      } else if (column == 'inprogress') {
        inProgressTasks.removeWhere((t) => t['id'] == taskId);
      } else if (column == 'done') {
        doneTasks.removeWhere((t) => t['id'] == taskId);
      }
    });
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Helper method to get priority color
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Board View',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // To Do Column
            KanbanColumn(
              title: 'To Do',
              tasks: todoTasks,
              columnId: 'todo',
              onTaskMoved: _onTaskMoved,
              onTaskLongPress: _showTaskActions,
              onTaskTap: (task) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TaskDetailsScreen(task: task),
                  ),
                );
              },
            ),
            // In Progress Column
            KanbanColumn(
              title: 'In Progress',
              tasks: inProgressTasks,
              columnId: 'inprogress',
              onTaskMoved: _onTaskMoved,
              onTaskLongPress: _showTaskActions,
              onTaskTap: (task) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TaskDetailsScreen(task: task),
                  ),
                );
              },
            ),
            // Done Column
            KanbanColumn(
              title: 'Done',
              tasks: doneTasks,
              columnId: 'done',
              onTaskMoved: _onTaskMoved,
              onTaskLongPress: _showTaskActions,
              onTaskTap: (task) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TaskDetailsScreen(task: task),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 32,
              minWidth: 180,
            ),
            child: FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              onPressed: () async {
                // Open TaskDetailsScreen in "add" mode (no task passed).
                final result = await Navigator.of(context).push<Map<String, dynamic>?>(
                  MaterialPageRoute(
                    builder: (_) => const TaskDetailsScreen(),
                  ),
                );

                if (result != null) {
                  // If result indicates delete action, ignore for add flow
                  if (result['_action'] == 'delete') return;

                  setState(() {
                    // Ensure it has an id
                    final newTask = Map<String, dynamic>.from(result);
                    if (newTask['id'] == null) {
                      newTask['id'] = DateTime.now().millisecondsSinceEpoch.toString();
                    }
                    // Default new tasks go to To Do
                    todoTasks.add(newTask);
                  });

                  _showSuccessMessage('Task created');
                }
              },
              icon: const Icon(Icons.add, color: AppColors.textPrimary),
              label: const Text(
                'Add Task',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}