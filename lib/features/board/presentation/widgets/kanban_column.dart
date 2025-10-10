import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/board/presentation/widgets/task_card.dart' as task_widget;
import 'package:boardbuddy/features/board/models/task_card.dart' as task_model;
import 'package:boardbuddy/features/board/data/board_firestore_service.dart';

class KanbanColumn extends StatefulWidget {
  final String title;
  final List<task_model.TaskCard> tasks;
  final String columnId;
  final String userRole; // NEW: Add this parameter
  final Function(String taskId, String fromColumn, String toColumn) onTaskMoved;
  final Function(task_model.TaskCard task, Offset position)? onTaskLongPress;
  final Function(task_model.TaskCard task) onTaskTap;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.tasks,
    required this.columnId,
    required this.userRole, // NEW: Add this parameter
    required this.onTaskMoved,
    this.onTaskLongPress,
    required this.onTaskTap,
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

  // Add a static map to track task locations
  static Map<String, String> _taskLocations = {};

  @override
  void initState() {
    super.initState();
    
    // Track tasks in this column
    for (var task in widget.tasks) {
      _taskLocations[task.id] = widget.columnId;
    }
    
    // Animation setup
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _dropController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _dropController,
      curve: Curves.bounceOut,
    ));
  }

  @override
  void didUpdateWidget(KanbanColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update task locations when widget updates
    for (var task in widget.tasks) {
      _taskLocations[task.id] = widget.columnId;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  void _onDragEnter() {
    if (!_isHovering) {
      setState(() {
        _isHovering = true;
      });
      HapticFeedback.selectionClick();
      _pulseController.repeat(reverse: true);
    }
  }

  void _onDragExit() {
    if (_isHovering) {
      setState(() {
        _isHovering = false;
      });
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _onSuccessfulDrop() {
    setState(() {
      _justDropped = true;
      _isHovering = false;
    });
    
    HapticFeedback.mediumImpact();
    
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
          // Column Header
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isHovering 
                  ? AppColors.primary.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              boxShadow: _isHovering ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _isHovering ? 0.1 : 0.0,
                  duration: const Duration(milliseconds: 100),
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
                  duration: const Duration(milliseconds: 100),
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
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // DragTarget
          Expanded(
            child: DragTarget<task_model.TaskCard>(
              onWillAcceptWithDetails: (details) {
                final task = details.data;
                final taskId = task.id;
                final fromColumn = _taskLocations[taskId] ?? widget.columnId;
                
                if (fromColumn != widget.columnId) {
                  _onDragEnter();
                  return true;
                }
                return false;
              },
              onAcceptWithDetails: (details) {
                final task = details.data;
                final taskId = task.id;
                final fromColumn = _taskLocations[taskId] ?? widget.columnId;
                
                if (fromColumn != widget.columnId) {
                  _taskLocations[taskId] = widget.columnId;
                  widget.onTaskMoved(taskId, fromColumn, widget.columnId);
                  _onSuccessfulDrop();
                }
              },
              onLeave: (data) => _onDragExit(),
              builder: (context, candidateData, rejectedData) {
                return AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isHovering ? _pulseAnimation.value : 1.0,
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _justDropped ? _scaleAnimation.value : 1.0,
                            child: Container(
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: _isHovering 
                                    ? AppColors.primary.withOpacity(0.12)
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                border: _isHovering ? Border.all(
                                  color: AppColors.primary.withOpacity(0.4),
                                  width: 3,
                                ) : null,
                              ),
                              child: widget.tasks.isEmpty 
                                  ? _buildEmptyPlaceholder(_isHovering)
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: widget.tasks.length,
                                      itemBuilder: (context, index) {
                                        return _buildDraggableTask(widget.tasks[index], index);
                                      },
                                    ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableTask(task_model.TaskCard task, int index) {
    final canEdit = widget.userRole == 'owner' || widget.userRole == 'editor';
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 50 + (index * 25)),
      margin: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => widget.onTaskTap(task),
        onLongPressStart: (details) {
          HapticFeedback.lightImpact();
          widget.onTaskLongPress?.call(task, details.globalPosition);
        },
        child: LongPressDraggable<task_model.TaskCard>(
          data: task,
          feedback: Material(
            elevation: 16,
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
            child: Transform.scale(
              scale: 1.08,
              child: Container(
                width: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: task_widget.TaskCard(
                  task: task,
                  readOnly: !canEdit,
                  onCompletionChanged: canEdit ? (isCompleted) async {
                    await BoardFirestoreService.instance.setCardCompleted(
                      boardId: task.boardId ?? '',
                      columnId: task.columnId ?? widget.columnId,
                      cardId: task.id,
                      isCompleted: isCompleted,
                    );
                  } : null,
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.1,
            child: Transform.scale(
              scale: 0.92,
              child: task_widget.TaskCard(
                task: task,
                readOnly: !canEdit,
                onCompletionChanged: canEdit ? (isCompleted) async {
                  await BoardFirestoreService.instance.setCardCompleted(
                    boardId: task.boardId ?? '',
                    columnId: task.columnId ?? widget.columnId,
                    cardId: task.id,
                    isCompleted: isCompleted,
                  );
                } : null,
              ),
            ),
          ),
          onDragStarted: () => HapticFeedback.lightImpact(),
          onDragEnd: (details) {
            // Handle drag end
          },
          child: task_widget.TaskCard(
            task: task,
            readOnly: !canEdit,
            onCompletionChanged: canEdit ? (isCompleted) async {
              await BoardFirestoreService.instance.setCardCompleted(
                boardId: task.boardId ?? '',
                columnId: task.columnId ?? widget.columnId,
                cardId: task.id,
                isCompleted: isCompleted,
              );
            } : null,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(bool isDragHovering) {
    final placeholderData = _getPlaceholderData();
    
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDragHovering 
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.card.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDragHovering 
                      ? AppColors.primary
                      : AppColors.textSecondary.withOpacity(0.2),
                  width: isDragHovering ? 4 : 2,
                ),
              ),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      placeholderData['icon'],
                      size: isDragHovering ? 72 : 48,
                      color: isDragHovering 
                          ? AppColors.primary 
                          : AppColors.textSecondary.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isDragHovering ? 'Drop here!' : placeholderData['title'],
                    style: TextStyle(
                      color: isDragHovering 
                          ? AppColors.primary 
                          : AppColors.textSecondary,
                      fontSize: isDragHovering ? 20 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!isDragHovering) ...[
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
                ],
              ),
            ),
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
          'subtitle': 'Add tasks to get started',
        };
      case 'inprogress':
        return {
          'icon': Icons.hourglass_empty,
          'title': 'Nothing in progress',
          'subtitle': 'Move tasks here to start',
        };
      case 'done':
        return {
          'icon': Icons.celebration_outlined,
          'title': 'No completed tasks',
          'subtitle': 'Finished tasks appear here',
        };
      default:
        return {
          'icon': Icons.inbox_outlined,
          'title': 'Column is empty',
          'subtitle': 'Drag tasks here',
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