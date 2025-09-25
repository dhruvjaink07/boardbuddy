class TaskCard {
  final String id; // unified id (accepts old cardId on input)
  final String title;
  final String description;

  // UI/behaviour fields
  final String priority; // 'High' | 'Medium' | 'Low'
  final String? category;
  final DateTime? dueDate;
  final List<String> assignees; // initials or user ids shown as avatars
  final List<Subtask> subtasks; // checklist items
  final List<Attachment> attachments;
  final List<String> tags;

  // metadata
  final String? createdBy;
  final DateTime createdAt;
  final DateTime lastUpdated;

  // board placement
  final String status; // e.g. 'todo', 'inprogress', 'done'

  TaskCard({
    required this.id,
    required this.title,
    required this.description,
    this.priority = 'Medium',
    this.category,
    this.dueDate,
    List<String>? assignees,
    List<Subtask>? subtasks,
    List<Attachment>? attachments,
    List<String>? tags,
    this.createdBy,
    DateTime? createdAt,
    DateTime? lastUpdated,
    this.status = 'todo',
  })  : assignees = assignees ?? [],
        subtasks = subtasks ?? [],
        attachments = attachments ?? [],
        tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now();

  // computed progress: percent (0..100) based on subtasks if present
  int get progress {
    if (subtasks.isEmpty) return 0;
    final done = subtasks.where((s) => s.done).length;
    return ((done / subtasks.length) * 100).round();
  }

  TaskCard copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    String? category,
    DateTime? dueDate,
    List<String>? assignees,
    List<Subtask>? subtasks,
    List<Attachment>? attachments,
    List<String>? tags,
    String? createdBy,
    DateTime? createdAt,
    DateTime? lastUpdated,
    String? status,
  }) {
    return TaskCard(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      assignees: assignees ?? List.from(this.assignees),
      subtasks: subtasks ?? List.from(this.subtasks),
      attachments: attachments ?? List.from(this.attachments),
      tags: tags ?? List.from(this.tags),
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'priority': priority,
        'category': category,
        'dueDate': dueDate?.toIso8601String(),
        'assignees': assignees,
        'subtasks': subtasks.map((s) => s.toMap()).toList(),
        'attachments': attachments.map((a) => a.toMap()).toList(),
        'tags': tags,
        'createdBy': createdBy,
        'createdAt': createdAt.toIso8601String(),
        'lastUpdated': lastUpdated.toIso8601String(),
        'status': status,
      };

  // fromMap is permissive: supports legacy keys (cardId) and both string/date shapes
  factory TaskCard.fromMap(Map<String, dynamic> map) {
    final id = map['id'] ?? map['cardId'] ?? map['card_id'] ?? '';
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    final subtasksRaw = map['subtasks'] ?? map['checklist'] ?? [];
    final attachmentsRaw = map['attachments'] ?? [];

    return TaskCard(
      id: id.toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      priority: (map['priority'] ?? 'Medium').toString(),
      category: map['category']?.toString(),
      dueDate: parseDate(map['dueDate']),
      assignees: List<String>.from(map['assignees'] ?? map['assigned'] ?? []),
      subtasks: List<Map<String, dynamic>>.from(subtasksRaw)
          .map((m) => Subtask.fromMap(m))
          .toList(),
      attachments: List<Map<String, dynamic>>.from(attachmentsRaw)
          .map((m) => Attachment.fromMap(m))
          .toList(),
      tags: List<String>.from(map['tags'] ?? []),
      createdBy: map['createdBy']?.toString() ?? map['created_by']?.toString(),
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      lastUpdated: parseDate(map['lastUpdated']) ?? DateTime.now(),
      status: (map['status'] ?? map['columnId'] ?? 'todo').toString(),
    );
  }
}

class Subtask {
  final String title;
  final bool done;

  Subtask({
    required this.title,
    this.done = false,
  });

  Subtask copyWith({String? title, bool? done}) =>
      Subtask(title: title ?? this.title, done: done ?? this.done);

  Map<String, dynamic> toMap() => {'title': title, 'done': done};

  factory Subtask.fromMap(Map<String, dynamic> map) => Subtask(
        title: map['title']?.toString() ?? '',
        done: map['done'] == true || (map['done']?.toString() == 'true'),
      );
}

class Attachment {
  final String name;
  final String url;
  final String? type; // mime or custom type

  Attachment({required this.name, required this.url, this.type});

  Map<String, dynamic> toMap() => {'name': name, 'url': url, 'type': type};

  factory Attachment.fromMap(Map<String, dynamic> map) => Attachment(
        name: map['name']?.toString() ?? '',
        url: map['url']?.toString() ?? '',
        type: map['type']?.toString(),
      );
}
