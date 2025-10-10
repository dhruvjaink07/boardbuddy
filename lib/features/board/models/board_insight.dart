class BoardInsights {
  final String boardId;
  final double projectHealthScore;
  final Map<String, double> teamContribution;
  final Map<String, Map<String, dynamic>>? teamContributionWithNames; // ADD THIS
  final Map<String, int> taskTrends;
  final Map<String, double> resourceUsage;

  BoardInsights({
    required this.boardId,
    required this.projectHealthScore,
    required this.teamContribution,
    this.teamContributionWithNames, // ADD THIS
    required this.taskTrends,
    required this.resourceUsage,
  });

  Map<String, dynamic> toMap() => {
    'boardId': boardId,
    'projectHealthScore': projectHealthScore,
    'teamContribution': teamContribution,
    'teamContributionWithNames': teamContributionWithNames, // ADD THIS
    'taskTrends': taskTrends,
    'resourceUsage': resourceUsage,
  };

  factory BoardInsights.fromMap(Map<String, dynamic> map) => BoardInsights(
    boardId: map['boardId'] ?? '',
    projectHealthScore: (map['projectHealthScore'] ?? 0.0).toDouble(),
    teamContribution: Map<String, double>.from(map['teamContribution'] ?? {}),
    teamContributionWithNames: map['teamContributionWithNames'] != null 
        ? Map<String, Map<String, dynamic>>.from(map['teamContributionWithNames'])
        : null, // ADD THIS
    taskTrends: Map<String, int>.from(map['taskTrends'] ?? {}),
    resourceUsage: Map<String, double>.from(map['resourceUsage'] ?? {}),
  );
}
