class BoardInsights {
  final String boardId;
  final double projectHealthScore;
  final Map<String, double> teamContribution; // userId → %
  final Map<String, int> taskTrends; // "completed" → count
  final Map<String, double> resourceUsage; // e.g., "timeSpent": hrs

  BoardInsights({
    required this.boardId,
    required this.projectHealthScore,
    required this.teamContribution,
    required this.taskTrends,
    required this.resourceUsage,
  });

  Map<String, dynamic> toMap() => {
        'boardId': boardId,
        'projectHealthScore': projectHealthScore,
        'teamContribution': teamContribution,
        'taskTrends': taskTrends,
        'resourceUsage': resourceUsage,
      };

  factory BoardInsights.fromMap(Map<String, dynamic> map) => BoardInsights(
        boardId: map['boardId'],
        projectHealthScore: (map['projectHealthScore'] ?? 0).toDouble(),
        teamContribution:
            Map<String, double>.from(map['teamContribution'] ?? {}),
        taskTrends: Map<String, int>.from(map['taskTrends'] ?? {}),
        resourceUsage: Map<String, double>.from(map['resourceUsage'] ?? {}),
      );
}
