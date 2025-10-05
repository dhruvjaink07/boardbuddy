import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/board/models/task_card.dart' as task_model;

class TaskCard extends StatelessWidget {
  final task_model.TaskCard task; // typed model

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final title = task.title;
    final description = task.description;
    final priority = task.priority;
    final category = task.category ?? '';
    final dueDateStr = task.dueDate?.toLocal().toString().split(' ').first ?? 'No due date';
    final assignees = task.assignees;
    final progressPct = task.progress;

    final priorityColor = _getPriorityColor(priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8)),
              child: Text('${progressPct}%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ),
          ]),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: priorityColor, borderRadius: BorderRadius.circular(6)),
                child: Text(priority.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.textSecondary.withOpacity(0.35), borderRadius: BorderRadius.circular(6)),
                child: Text(category.isEmpty ? 'General' : category, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
              ),
              const SizedBox(width: 6),
              Text(dueDateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            for (int i = 0; i < assignees.length && i < 3; i++)
              Container(
                margin: const EdgeInsets.only(right: 6),
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                alignment: Alignment.center,
                child: Text(assignees[i].toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            if (assignees.length > 3)
              Text('+${assignees.length - 3}', style: const TextStyle(color: AppColors.textSecondary)),
            const Spacer(),
            SizedBox(
              width: 80,
              height: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (progressPct / 100).clamp(0.0, 1.0),
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface.withOpacity(0.3),
                  minHeight: 6,
                ),
              ),
            ),
          ]),
        ]),
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
      case 'dev':
        return const Color(0xFF2563EB);
      case 'backend':
        return const Color(0xFF059669);
      case 'frontend':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF6B7280);
    }
  }
}