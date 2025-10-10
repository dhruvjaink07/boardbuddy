import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/board/models/task_card.dart' as task_model;

class TaskCard extends StatelessWidget {
  final task_model.TaskCard task;
  final Function(bool)? onCompletionChanged; // NEW: callback for completion
  final bool readOnly; // NEW: disable interactions for viewers

  const TaskCard({
    super.key, 
    required this.task,
    this.onCompletionChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = task.title;
    final description = task.description;
    final priority = task.priority;
    final category = task.category ?? '';
    final dueDateStr = task.dueDate?.toLocal().toString().split(' ').first ?? 'No due date';
    final assignees = task.assignees;
    final progressPct = task.progress;
    
    // NEW: Get completion status
    final isCompleted = task.isCompleted ?? false;
    final completedAt = task.completedAt;

    final priorityColor = _getPriorityColor(priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.card.withOpacity(0.7) : AppColors.card, // NEW: dim completed tasks
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted 
            ? AppColors.success.withOpacity(0.5) 
            : AppColors.textSecondary.withOpacity(0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NEW: Header with completion checkbox
            Row(
              children: [
                // NEW: Completion checkbox
                if (!readOnly)
                  GestureDetector(
                    onTap: () => onCompletionChanged?.call(!isCompleted),
                    child: Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isCompleted ? AppColors.success : Colors.transparent,
                        border: Border.all(
                          color: isCompleted ? AppColors.success : AppColors.textSecondary,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                    ),
                  ),
                // Title with strikethrough if completed
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isCompleted 
                        ? AppColors.textSecondary 
                        : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted 
                        ? TextDecoration.lineThrough 
                        : TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Progress or completion status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.success : AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isCompleted 
                      ? 'Done' 
                      : '${(progressPct * 100).round()}%',
                    style: TextStyle(
                      color: isCompleted ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: isCompleted 
                    ? AppColors.textSecondary.withOpacity(0.7)
                    : AppColors.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            const SizedBox(height: 10),
            
            // Tags and metadata
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(isCompleted ? 0.5 : 1.0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(isCompleted ? 0.2 : 0.35),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category.isEmpty ? 'General' : category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  dueDateStr,
                  style: TextStyle(
                    color: isCompleted 
                      ? AppColors.textSecondary.withOpacity(0.7)
                      : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            // Bottom row with assignees and attachments
            Row(
              children: [
                // Assignees
                for (int i = 0; i < assignees.length && i < 3; i++)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(isCompleted ? 0.7 : 1.0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      assignees[i].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (assignees.length > 3)
                  Text(
                    '+${assignees.length - 3}',
                    style: TextStyle(
                      color: isCompleted 
                        ? AppColors.textSecondary.withOpacity(0.7)
                        : AppColors.textSecondary,
                    ),
                  ),
                const Spacer(),
                
                // Progress bar (only show if not completed)
                if (!isCompleted)
                  SizedBox(
                    width: 80,
                    height: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressPct.clamp(0.0, 1.0),
                        color: AppColors.primary,
                        backgroundColor: AppColors.surface.withOpacity(0.3),
                        minHeight: 6,
                      ),
                    ),
                  ),
                
                // NEW: Completed timestamp
                if (isCompleted && completedAt != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Done ${_formatCompletedTime(completedAt)}',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                
                // Attachments
                if (task.attachments.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.attach_file,
                    size: 16,
                    color: isCompleted 
                      ? AppColors.textSecondary.withOpacity(0.7)
                      : AppColors.textSecondary,
                  ),
                  Text(
                    '${task.attachments.length}',
                    style: TextStyle(
                      color: isCompleted 
                        ? AppColors.textSecondary.withOpacity(0.7)
                        : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCompletedTime(DateTime completedAt) {
    final now = DateTime.now();
    final diff = now.difference(completedAt);
    
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return const Color(0xFF991B1B);
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
}