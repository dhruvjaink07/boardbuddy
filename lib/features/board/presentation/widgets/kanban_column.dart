import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/board/presentation/widgets/task_card.dart' as task_widget;
import 'package:boardbuddy/features/board/models/task_card.dart' as task_model;

class KanbanColumn extends StatelessWidget {
  final String title;
  final List<task_model.TaskCard> tasks; // typed
  final String columnId;
  final void Function(String taskId, String fromColumn, String toColumn)? onTaskMoved;
  final void Function(task_model.TaskCard task, Offset tapPosition)? onTaskLongPress;
  final void Function(task_model.TaskCard task) onTaskTap;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.tasks,
    required this.columnId,
    this.onTaskMoved,
    this.onTaskLongPress,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // header
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8)),
                child: Text('${tasks.length}', style: const TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // task list
          Expanded(
            child: ListView.separated(
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final t = tasks[index];
                return GestureDetector(
                  onTap: () => onTaskTap(t),
                  onLongPressStart: (details) => onTaskLongPress?.call(t, details.globalPosition),
                  child: task_widget.TaskCard(task: t), // presentation widget accepts model
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              // add new placeholder task into this column — callers can use FAB instead
            },
            icon: const Icon(Icons.add, color: AppColors.primary),
            label: const Text('Add', style: TextStyle(color: AppColors.primary)),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.card,
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}