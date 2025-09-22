import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For haptic feedback
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/board/presentation/widgets/task_card.dart';

class KanbanColumn extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> tasks;
  final String columnId;
  final Function(String taskId, String fromColumn, String toColumn) onTaskMoved;
  final Function(BuildContext context, Map<String, dynamic> task, String currentColumn, Offset position)? onTaskLongPress;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.tasks,
    required this.columnId,
    required this.onTaskMoved,
    this.onTaskLongPress,
  });

  @override
  State<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<KanbanColumn>
    with TickerProviderStateMixin {
  bool _isHovering = false;
  bool _justDropped = false;
  late AnimationController _pulseController;
  late AnimationController _dropController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Pulse animation for hover effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Drop success animation
    _dropController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _dropController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  void _onDragEnter() {
    setState(() {
      _isHovering = true;
    });
    // Light haptic feedback when entering drop zone
    HapticFeedback.selectionClick();
    // Start pulse animation
    _pulseController.repeat(reverse: true);
  }

  void _onDragExit() {
    setState(() {
      _isHovering = false;
    });
    // Stop pulse animation
    _pulseController.stop();
    _pulseController.reset();
  }

  void _onSuccessfulDrop() {
    setState(() {
      _justDropped = true;
      _isHovering = false;
    });
    
    // Strong haptic feedback for successful drop
    HapticFeedback.heavyImpact();
    
    // Stop pulse and play drop animation
    _pulseController.stop();
    _pulseController.reset();
    _dropController.forward().then((_) {
      _dropController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _justDropped = false;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header with animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isHovering 
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Animated icon
                AnimatedRotation(
                  turns: _isHovering ? 0.1 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _getColumnIcon(),
                    color: _isHovering 
                        ? AppColors.primary 
                        : AppColors.textPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: _isHovering 
                        ? AppColors.primary 
                        : AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isHovering 
                        ? AppColors.primary 
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.tasks.length.toString(),
                    style: TextStyle(
                      color: _isHovering 
                          ? AppColors.textPrimary 
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tasks List
          Expanded(
            child: ListView.builder(
              itemCount: widget.tasks.length,
              itemBuilder: (context, index) {
                final task = widget.tasks[index];
                return GestureDetector(
                  onLongPressStart: (details) {
                    // Add haptic feedback
                    HapticFeedback.mediumImpact();
                    
                    // Call the long press callback with position
                    if (widget.onTaskLongPress != null) {
                      widget.onTaskLongPress!(context, task, widget.columnId, details.globalPosition);
                    }
                  },
                  child: Draggable<Map<String, dynamic>>(
                    data: task,
                    feedback: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 260,
                        child: TaskCard(task: task),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.5,
                      child: TaskCard(task: task),
                    ),
                    child: TaskCard(task: task),
                  ),
                );
              },
            ),
          ),
          
          // Add Task Button
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            child: ElevatedButton(
              onPressed: () {
                // Handle add task action
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: AppColors.textPrimary, backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Add Task',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlaceholder(bool isDragHovering) {
    final placeholderData = _getPlaceholderData();
    
    return Center(
      child: AnimatedOpacity(
        opacity: isDragHovering ? 1.0 : 0.6,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDragHovering 
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.card.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDragHovering 
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.textSecondary.withOpacity(0.2),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    placeholderData['icon'],
                    size: isDragHovering ? 56 : 48,
                    color: isDragHovering 
                        ? AppColors.primary 
                        : AppColors.textSecondary.withOpacity(0.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    placeholderData['title'],
                    style: TextStyle(
                      color: isDragHovering 
                          ? AppColors.primary 
                          : AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    placeholderData['subtitle'],
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (isDragHovering) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Drop task here',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getPlaceholderData() {
    switch (widget.columnId) {
      case 'todo':
        return {
          'icon': Icons.lightbulb_outline,
          'title': 'No tasks planned',
          'subtitle': 'Add tasks to get started\nwith your workflow',
        };
      case 'inprogress':
        return {
          'icon': Icons.hourglass_empty,
          'title': 'Nothing in progress',
          'subtitle': 'Move tasks here when\nyou start working on them',
        };
      case 'done':
        return {
          'icon': Icons.celebration_outlined,
          'title': 'No completed tasks',
          'subtitle': 'Finished tasks will\nappear here',
        };
      default:
        return {
          'icon': Icons.inbox_outlined,
          'title': 'Column is empty',
          'subtitle': 'Drag tasks here to\norganize your work',
        };
    }
  }

  IconData _getColumnIcon() {
    switch (widget.columnId) {
      case 'todo':
        return Icons.pending_actions;
      case 'inprogress':
        return Icons.trending_up;
      case 'done':
        return Icons.check_circle;
      default:
        return Icons.list;
    }
  }
}