class TaskCard {
  final String id;
  final String title;
  final String description;

  final String priority; // 'High'|'Medium'|'Low'
  final String? category;
  final DateTime? dueDate;
  final List<String> assignees;
  final List<Subtask> subtasks;
  final List<Attachment> attachments;
  final List<String> tags;

  final String? createdBy;
  final DateTime createdAt;
  final DateTime lastUpdated;

  final String status; // e.g. 'todo','inprogress','done'

  TaskCard({
    required this.id,
    required this.title,
    this.description = '',
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

  factory TaskCard.fromMap(Map<String, dynamic> map) {
    String parseId(dynamic v) => v?.toString() ?? '';
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    final subtasksRaw = (map['subtasks'] ?? []);
    final attachmentsRaw = (map['attachments'] ?? []);

    return TaskCard(
      id: parseId(map['id'] ?? map['cardId'] ?? map['card_id']),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      priority: (map['priority'] ?? 'Medium').toString(),
      category: map['category']?.toString(),
      dueDate: parseDate(map['dueDate']),
      assignees: List<String>.from(map['assignees'] ?? map['assigned'] ?? []),
      subtasks: List<Map<String, dynamic>>.from(subtasksRaw).map((m) => Subtask.fromMap(m)).toList(),
      attachments: List<Map<String, dynamic>>.from(attachmentsRaw).map((m) => Attachment.fromMap(m)).toList(),
      tags: List<String>.from(map['tags'] ?? []),
      createdBy: map['createdBy']?.toString(),
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      lastUpdated: parseDate(map['lastUpdated']) ?? DateTime.now(),
      status: (map['status'] ?? map['columnId'] ?? 'todo').toString(),
    );
  }
}

class Subtask {
  final String title;
  final bool done;
  Subtask({required this.title, this.done = false});

  Map<String, dynamic> toMap() => {'title': title, 'done': done};
  factory Subtask.fromMap(Map<String, dynamic> m) =>
      Subtask(title: m['title']?.toString() ?? '', done: m['done'] == true || (m['done']?.toString() == 'true'));
}

class Attachment {
  final String name;
  final String url;
  final String? type;
  Attachment({required this.name, required this.url, this.type});

  Map<String, dynamic> toMap() => {'name': name, 'url': url, 'type': type};
  factory Attachment.fromMap(Map<String, dynamic> m) => Attachment(name: m['name']?.toString() ?? '', url: m['url']?.toString() ?? '', type: m['type']?.toString());
}
