import 'package:flutter/material.dart';
import 'package:boardbuddy/core/services/board_analytics.dart';
import 'package:boardbuddy/features/board/models/board_insight.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:boardbuddy/features/board/presentation/board_view_screen.dart';
import 'dart:math' as math;

// Replace FutureBuilder<BoardInsights> with dashboard payload and add “Needs Attention”
class BoardAnalyticsScreen extends StatelessWidget {
  final String? boardId;
  const BoardAnalyticsScreen({super.key, this.boardId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: FutureBuilder<AnalyticsDashboardData>(
        future: loadAnalyticsDashboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _errorState(context, snapshot.error?.toString());
          }

          final data = snapshot.data!;
          return _buildAnalyticsContent(context, data);
        },
      ),
    );
  }

  Widget _errorState(BuildContext context, String? msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Failed to load analytics',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              msg ?? 'Check permissions and try again',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(BuildContext context, AnalyticsDashboardData data) {
    final insights = data.all;

    // Identify boards needing help (health < 60 or todo-heavy)
    final needingHelp = List.of(data.perBoard)
      ..sort((a, b) => a.insights.projectHealthScore.compareTo(b.insights.projectHealthScore));
    final attention = needingHelp.where((b) {
      final t = b.insights.taskTrends;
      final total = t['total'] ?? 0;
      final todo = t['todo'] ?? 0;
      final todoRatio = total == 0 ? 0.0 : todo / total;
      return b.insights.projectHealthScore < 60 || todoRatio > 0.55;
    }).take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (attention.isNotEmpty) ...[
            _buildNeedsAttention(attention, context),
            const SizedBox(height: 16),
          ],
          _buildHeaderStats(insights),
          const SizedBox(height: 24),
          _buildHealthScoreCard(insights),
          const SizedBox(height: 24),
          _buildTaskDistributionChart(insights),
          const SizedBox(height: 24),
          _buildProgressChart(insights),
          const SizedBox(height: 24),
          _buildResourceUsageCard(insights),
          const SizedBox(height: 24),
          _buildTeamContributionChart(insights),
        ],
      ),
    );
  }

  Widget _buildNeedsAttention(List<BoardInsightWithName> boards, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Text('Boards needing attention',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          ...boards.map((b) {
            final t = b.insights.taskTrends;
            final total = t['total'] ?? 0;
            final done = t['completed'] ?? 0;
            final todo = t['todo'] ?? 0;
            final health = b.insights.projectHealthScore;
            final color = health < 40
                ? AppColors.error
                : health < 60
                    ? AppColors.warning
                    : AppColors.success;

            String reason;
            final todoRatio = total == 0 ? 0.0 : todo / total;
            if (health < 40) {
              reason = 'Very low health';
            } else if (todoRatio > 0.65) {
              reason = 'Heavy TODO load';
            } else {
              reason = 'Lagging completion';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(width: 4, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          '$reason • $done/$total done',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text('${health.toStringAsFixed(1)}%',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BoardViewScreen(board: null), // uses boardId inside fetch – pass via route if needed
                          settings: RouteSettings(arguments: {'boardId': b.boardId, 'boardTitle': b.name}),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: color),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('View Board', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(BoardInsights insights) {
    final total = insights.taskTrends['total'] ?? 0;
    final completed = insights.taskTrends['completed'] ?? 0;
    final files = insights.resourceUsage['fileUploads']?.toInt() ?? 0;
    final comments = insights.resourceUsage['commentsCount']?.toInt() ?? 0;

    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Tasks', total.toString(), Icons.assignment_outlined, AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Completed', completed.toString(), Icons.check_circle_outline, AppColors.success)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Files', files.toString(), Icons.attach_file_outlined, AppColors.warning)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Comments', comments.toString(), Icons.comment_outlined, AppColors.info)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(BoardInsights insights) {
    final score = insights.projectHealthScore;
    final color = score >= 75 ? AppColors.success : score >= 50 ? AppColors.warning : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_outlined, color: color, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Project Health Score',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: CircularPercentIndicator(
              radius: 80.0,
              lineWidth: 12.0,
              percent: score / 100,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${score.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Health',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              progressColor: color,
              backgroundColor: AppColors.textSecondary.withOpacity(0.2),
              circularStrokeCap: CircularStrokeCap.round,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              _getHealthDescription(score),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getHealthDescription(double score) {
    if (score >= 75) return 'Excellent! Your project is on track with great progress.';
    if (score >= 50) return 'Good progress, but there\'s room for improvement.';
    return 'Needs attention. Consider reviewing task distribution and engagement.';
  }

  Widget _buildTaskDistributionChart(BoardInsights insights) {
    final total = insights.taskTrends['total'] ?? 0;
    final completed = insights.taskTrends['completed'] ?? 0;
    final inProgress = insights.taskTrends['inProgress'] ?? 0;
    final todo = insights.taskTrends['todo'] ?? 0;

    if (total == 0) {
      return _buildEmptyChart('No tasks to display');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task Distribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              // Keep it within card bounds on all screens
              final maxChartSize = 140.0; // smaller than before
              final size = math.min(constraints.maxWidth, maxChartSize);
              final outerRadius = size * 0.48;
              final centerSpace = size * 0.34;

              final sections = <PieChartSectionData>[
                if (completed > 0)
                  PieChartSectionData(
                    color: AppColors.success,
                    value: completed.toDouble(),
                    radius: outerRadius,
                    title: '', // hide default labels
                  ),
                if (inProgress > 0)
                  PieChartSectionData(
                    color: AppColors.warning,
                    value: inProgress.toDouble(),
                    radius: outerRadius,
                    title: '',
                  ),
                if (todo > 0)
                  PieChartSectionData(
                    color: AppColors.primary,
                    value: todo.toDouble(),
                    radius: outerRadius,
                    title: '',
                  ),
              ];

              return Column(
                children: [
                  SizedBox(
                    height: size,
                    child: PieChart(
                      PieChartData(
                        startDegreeOffset: -90,
                        sectionsSpace: 4,
                        centerSpaceRadius: centerSpace,
                        sections: sections,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Compact legend with counts so it’s always readable
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (completed > 0) _legend('Done', completed, AppColors.success),
                      if (inProgress > 0) _legend('Progress', inProgress, AppColors.warning),
                      if (todo > 0) _legend('Todo', todo, AppColors.primary),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart(BoardInsights insights) {
    final total = insights.taskTrends['total'] ?? 0;
    final completed = insights.taskTrends['completed'] ?? 0;
    final inProgress = insights.taskTrends['inProgress'] ?? 0;
    final todo = insights.taskTrends['todo'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildProgressBar('Completed', completed, total, AppColors.success),
          const SizedBox(height: 16),
          _buildProgressBar('In Progress', inProgress, total, AppColors.warning),
          const SizedBox(height: 16),
          _buildProgressBar('Todo', todo, total, AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, int total, Color color) {
    final percentage = total == 0 ? 0.0 : (value / total);
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$value / $total',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          lineHeight: 8.0,
          percent: percentage,
          backgroundColor: AppColors.textSecondary.withOpacity(0.2),
          progressColor: color,
          barRadius: const Radius.circular(4),
        ),
      ],
    );
  }

  Widget _buildResourceUsageCard(BoardInsights insights) {
    final avgChecklist = insights.resourceUsage['avgChecklistCompletion'] ?? 0.0;
    final files = insights.resourceUsage['fileUploads']?.toInt() ?? 0;
    final comments = insights.resourceUsage['commentsCount']?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resource Usage',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Avg Checklist',
                  '${avgChecklist.toStringAsFixed(1)}%',
                  Icons.checklist_outlined,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Files Uploaded',
                  files.toString(),
                  Icons.attach_file_outlined,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Comments',
                  comments.toString(),
                  Icons.comment_outlined,
                  AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamContributionChart(BoardInsights insights) {
    if (insights.teamContribution.isEmpty) {
      return _buildEmptyChart('No team assignments yet');
    }

    final entries = insights.teamContribution.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Team Contribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ...entries.map((entry) {
            final colors = [
              AppColors.primary,
              AppColors.success,
              AppColors.warning,
              AppColors.info,
              AppColors.error,
            ];
            final color = colors[entries.indexOf(entry) % colors.length];
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${entry.value.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearPercentIndicator(
                    lineHeight: 8.0,
                    percent: entry.value / 100,
                    backgroundColor: AppColors.textSecondary.withOpacity(0.2),
                    progressColor: color,
                    barRadius: const Radius.circular(4),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              color: AppColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class AppColors {
  // Base Colors
  static const Color primary = Color(0xFFFF6A00); // Orange
  static const Color background = Color(0xFF121212); // Dark Background
  static const Color surface = Color(
    0xFF1E1E1E,
  ); // Slightly lighter than background
  static final Color? secondary = Colors.grey[600];

  // Home-specific
  static const Color card = Color(0xFF23232A);
  static const Color filterSelected = Color(0xFF2D255A);
  static const Color filterUnselected = card;

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.grey;

  // Borders / Outline
  static const Color border = Color(0xFF333333);

  // Others
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF42A5F5); // Blue for info/metrics
}