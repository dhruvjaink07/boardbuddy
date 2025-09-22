import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;

  const TaskCard({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    Color priorityColor = _getPriorityColor(task['priority']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Reduced margin for tighter layout
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8), // Less rounded for sharper look
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.1), // Add subtle border
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // Lighter shadow
            blurRadius: 2, // Less blur for sharper shadow
            offset: const Offset(0, 1), // Smaller offset
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Title
            Text(
              task['title'],
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14, // Slightly smaller
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2, // Tighter letter spacing
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing
            
            // Task Description
            Text(
              task['description'],
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.8),
                fontSize: 12, // Smaller text
                height: 1.2, // Tighter line height
                letterSpacing: -0.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            
            // Tags Row
            Row( // Changed from Wrap to Row for more control
              children: [
                // Priority Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Smaller padding
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(4), // Less rounded
                  ),
                  child: Text(
                    task['priority'].toString().toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                
                // Category Tag (if exists)
                if (task.containsKey('category'))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(task['category']),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      task['category'].toString().toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Progress Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PROGRESS',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5, // More spacing for caps
                      ),
                    ),
                    Text(
                      '${task['progress'] ?? 0}/5',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                // Progress Bar - More structured
                Container(
                  height: 4, // Thinner bar
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: ((task['progress'] ?? 0) / 5).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: priorityColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Bottom Row - More structured
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Due Date
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 10,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            task['dueDate'] ?? 'No due date',
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.8),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Assignees - More structured
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Show first 2 assignees
                      for (int i = 0; i < (task['assignees'] as List).length.clamp(0, 2); i++)
                        Container(
                          margin: EdgeInsets.only(left: i == 0 ? 0 : 2),
                          child: CircleAvatar(
                            radius: 8, // Smaller avatars
                            backgroundColor: AppColors.primary,
                            child: Text(
                              task['assignees'][i],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      // Show +X if more than 2 assignees
                      if ((task['assignees'] as List).length > 2)
                        Container(
                          margin: const EdgeInsets.only(left: 2),
                          child: CircleAvatar(
                            radius: 8,
                            backgroundColor: AppColors.textSecondary.withOpacity(0.4),
                            child: Text(
                              '+${(task['assignees'] as List).length - 2}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 6,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFDC2626); // Darker red
      case 'medium':
        return const Color(0xFFD97706); // Darker orange  
      case 'low':
        return const Color(0xFF059669); // Darker green
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'design':
        return const Color(0xFF7C3AED); // Darker purple
      case 'development':
        return const Color(0xFF2563EB); // Darker blue
      case 'backend':
        return const Color(0xFF059669); // Darker green
      case 'frontend':
        return const Color(0xFFD97706); // Darker orange
      default:
        return const Color(0xFF6B7280); // Darker gray
    }
  }
}