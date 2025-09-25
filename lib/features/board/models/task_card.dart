class TaskCard {
  final String cardId;
  final String title;
  final String description;
  final List<String> tags;
  final DateTime? dueDate;
  final List<Map<String, dynamic>> checklist; // [{title, done}]
  final List<Map<String, dynamic>> attachments; // [{name, url, type}]
  final String createdBy;
  final DateTime createdAt;
  final DateTime lastUpdated;

  TaskCard({
    required this.cardId,
    required this.title,
    required this.description,
    required this.tags,
    this.dueDate,
    required this.checklist,
    required this.attachments,
    required this.createdBy,
    required this.createdAt,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() => {
        'cardId': cardId,
        'title': title,
        'description': description,
        'tags': tags,
        'dueDate': dueDate?.toIso8601String(),
        'checklist': checklist,
        'attachments': attachments,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory TaskCard.fromMap(Map<String, dynamic> map) => TaskCard(
        cardId: map['cardId'],
        title: map['title'],
        description: map['description'],
        tags: List<String>.from(map['tags'] ?? []),
        dueDate:
            map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
        checklist: List<Map<String, dynamic>>.from(map['checklist'] ?? []),
        attachments: List<Map<String, dynamic>>.from(map['attachments'] ?? []),
        createdBy: map['createdBy'],
        createdAt: DateTime.parse(map['createdAt']),
        lastUpdated: DateTime.parse(map['lastUpdated']),
      );
}
