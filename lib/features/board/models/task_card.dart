import 'package:cloud_firestore/cloud_firestore.dart';

class ChecklistItem {
  final String title;
  final bool done;

  ChecklistItem({required this.title, this.done = false});

  Map<String, dynamic> toMap() => {'title': title, 'done': done};

  factory ChecklistItem.fromMap(Map<String, dynamic> map) =>
      ChecklistItem(title: map['title'] ?? '', done: map['done'] ?? false);
}

class AttachmentMeta {
  final String name;
  final String url;
  final String type;
  final int? size;
  final DateTime? uploadedAt;

  AttachmentMeta({
    required this.name,
    required this.url,
    required this.type,
    this.size,
    this.uploadedAt,
  });

  String get formattedSize {
    if (size == null || size! <= 0) return '';
    final bytes = size!;
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'url': url,
    'type': type,
    'size': size,
    'uploadedAt': uploadedAt?.toIso8601String(),
  };

  factory AttachmentMeta.fromMap(Map<String, dynamic> map) => AttachmentMeta(
    name: map['name'] ?? '',
    url: map['url'] ?? '',
    type: map['type'] ?? 'file',
    size: map['size'] as int?,
    uploadedAt: map['uploadedAt'] != null ? DateTime.tryParse(map['uploadedAt']) : null,
  );

  AttachmentMeta copyWith({
    String? name,
    String? url,
    String? type,
    int? size,
    DateTime? uploadedAt,
  }) {
    return AttachmentMeta(
      name: name ?? this.name,
      url: url ?? this.url,
      type: type ?? this.type,
      size: size ?? this.size,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}

// Back-compat types used by some UI code and AI parsing
class Subtask {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;

  Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
  });

  Subtask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      isCompleted: (map['isCompleted'] ?? map['done'] ?? false) == true,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

// Optional legacy attachment shape (kept for compatibility)
class Attachment {
  final String id;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final DateTime uploadedAt;

  Attachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
  });

  Attachment copyWith({
    String? id,
    String? fileName,
    String? filePath,
    String? fileType,
    int? fileSize,
    DateTime? uploadedAt,
  }) {
    return Attachment(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id']?.toString() ?? '',
      fileName: map['fileName'] ?? '',
      filePath: map['filePath'] ?? '',
      fileType: map['fileType'] ?? '',
      fileSize: (map['fileSize'] ?? 0) is int ? (map['fileSize'] ?? 0) : int.tryParse('${map['fileSize']}') ?? 0,
      uploadedAt: DateTime.tryParse(map['uploadedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class TaskCard {
  final String id;
  final String columnId; // location
  final String title;
  final String description;

  // AI/compat fields (kept for UI and parsing)
  final String status;        // 'todo' | 'in_progress' | 'done' ...
  final String priority;      // 'low' | 'medium' | 'high' | 'urgent'
  final String? assigneeId;   // single assignee id
  final String category;      // e.g., 'General'
  final List<String> assignees;
  final double progress;      // 0.0 - 1.0
  final List<String> labels;  // kept for compatibility

  // Canonical fields for Firestore schema
  final List<String> tags;
  final DateTime? dueDate;
  final List<ChecklistItem> checklist;
  final List<Subtask> subtasks;              // compat; mapped to checklist
  final List<AttachmentMeta> attachments;    // Firestore shape

  final String createdBy;
  final DateTime createdAt;
  final DateTime lastUpdated;

  // Alias for older code
  DateTime get updatedAt => lastUpdated;

  TaskCard({
    required this.id,
    required this.columnId,
    required this.title,
    this.description = '',
    this.status = 'todo',
    this.priority = 'medium',
    this.assigneeId,
    this.category = 'General',
    this.assignees = const [],
    this.progress = 0.0,
    this.labels = const [],
    this.tags = const [],
    this.dueDate,
    this.checklist = const [],
    this.subtasks = const [],
    this.attachments = const [],
    this.createdBy = '',
    required this.createdAt,
    required this.lastUpdated,
  });

  TaskCard copyWith({
    String? id,
    String? columnId,
    String? title,
    String? description,
    String? status,
    String? priority,
    String? assigneeId,
    String? category,
    List<String>? assignees,
    double? progress,
    List<String>? labels,
    List<String>? tags,
    DateTime? dueDate,
    List<ChecklistItem>? checklist,
    List<Subtask>? subtasks,
    List<AttachmentMeta>? attachments,
    String? createdBy,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return TaskCard(
      id: id ?? this.id,
      columnId: columnId ?? this.columnId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assigneeId: assigneeId ?? this.assigneeId,
      category: category ?? this.category,
      assignees: assignees ?? this.assignees,
      progress: progress ?? this.progress,
      labels: labels ?? this.labels,
      tags: tags ?? this.tags,
      dueDate: dueDate ?? this.dueDate,
      checklist: checklist ?? this.checklist,
      subtasks: subtasks ?? this.subtasks,
      attachments: attachments ?? this.attachments,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Use when creating a new card in Firestore
  Map<String, dynamic> toCreateMap() {
    final storeTags = (tags.isNotEmpty ? tags : labels);
    final checklistToStore = checklist.isNotEmpty
        ? checklist
        : subtasks.map((s) => ChecklistItem(title: s.title, done: s.isCompleted)).toList();

    return {
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'assigneeId': assigneeId,
      'category': category,
      'assignees': assignees,
      'progress': progress,
      'tags': storeTags,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'checklist': checklistToStore.map((e) => e.toMap()).toList(),
      'attachments': attachments.map((e) => e.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    }..removeWhere((k, v) => v == null);
  }

  // Use when updating/moving an existing card
  Map<String, dynamic> toUpdateMap() {
    final storeTags = (tags.isNotEmpty ? tags : labels);
    final checklistToStore = checklist.isNotEmpty
        ? checklist
        : subtasks.map((s) => ChecklistItem(title: s.title, done: s.isCompleted)).toList();

    return {
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'assigneeId': assigneeId,
      'category': category,
      'assignees': assignees,
      'progress': progress,
      'tags': storeTags,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'checklist': checklistToStore.map((e) => e.toMap()).toList(),
      'attachments': attachments.map((e) => e.toMap()).toList(),
      'createdBy': createdBy,
      'lastUpdated': FieldValue.serverTimestamp(),
    }..removeWhere((k, v) => v == null);
  }

  // For reading from Firestore
  factory TaskCard.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc, String columnId) {
    final data = doc.data() ?? {};
    final tags = List<String>.from(data['tags'] ?? const []);
    final labels = List<String>.from(data['labels'] ?? const []);
    final checklistList = (data['checklist'] as List<dynamic>? ?? const [])
        .map((e) => ChecklistItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return TaskCard(
      id: doc.id,
      columnId: columnId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'todo',
      priority: data['priority'] ?? 'medium',
      assigneeId: (data['assigneeId']?.toString().isNotEmpty ?? false) ? '${data['assigneeId']}' : null,
      category: data['category'] ?? 'General',
      assignees: List<String>.from(data['assignees'] ?? const []),
      progress: (data['progress'] ?? 0.0).toDouble(),
      labels: labels.isNotEmpty ? labels : tags,
      tags: tags.isNotEmpty ? tags : labels,
      dueDate: _asNullableDate(data['dueDate']),
      checklist: checklistList,
      subtasks: checklistList.map((c) => Subtask(id: '', title: c.title, isCompleted: c.done, createdAt: DateTime.now())).toList(),
      attachments: (data['attachments'] as List<dynamic>? ?? const [])
          .map((e) => AttachmentMeta.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdBy: data['createdBy'] ?? '',
      createdAt: _asDate(data['createdAt']),
      lastUpdated: _asDate(data['lastUpdated'] ?? data['updatedAt']),
    );
  }

  // For parsing JSON/AI maps (non-Firestore)
  factory TaskCard.fromMap(Map<String, dynamic> map) {
    final tags = List<String>.from(map['tags'] ?? const []);
    final labels = List<String>.from(map['labels'] ?? const []);
    final checklistRaw = (map['checklist'] as List<dynamic>?) ?? const [];
    final subtasksRaw = (map['subtasks'] as List<dynamic>?) ?? const [];

    final checklist = checklistRaw.isNotEmpty
        ? checklistRaw.map((e) => ChecklistItem.fromMap(Map<String, dynamic>.from(e as Map))).toList()
        : subtasksRaw.map((e) => ChecklistItem.fromMap({'title': (e as Map)['title'] ?? '', 'done': (e as Map)['isCompleted'] ?? false})).toList();

    final attachments = (map['attachments'] as List<dynamic>? ?? const [])
        .map((e) => AttachmentMeta.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return TaskCard(
      id: map['id']?.toString() ?? '',
      columnId: map['columnId']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'todo',
      priority: map['priority'] ?? 'medium',
      assigneeId: (map['assigneeId']?.toString().isNotEmpty ?? false) ? map['assigneeId'].toString() : null,
      category: map['category'] ?? 'General',
      assignees: List<String>.from(map['assignees'] ?? const []),
      progress: (map['progress'] ?? 0.0).toDouble(),
      labels: labels.isNotEmpty ? labels : tags,
      tags: tags.isNotEmpty ? tags : labels,
      dueDate: map['dueDate'] != null ? DateTime.tryParse('${map['dueDate']}') : null,
      checklist: checklist,
      subtasks: (map['subtasks'] as List<dynamic>? ?? const [])
          .map((e) => Subtask.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      attachments: attachments,
      createdBy: map['createdBy']?.toString() ?? map['assigneeId']?.toString() ?? '',
      createdAt: DateTime.tryParse('${map['createdAt']}') ?? DateTime.now(),
      lastUpdated: DateTime.tryParse('${map['updatedAt'] ?? map['lastUpdated']}') ?? DateTime.now(),
    );
  }

  static DateTime _asDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
  }

  static DateTime? _asNullableDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.tryParse('$v');
  }
}
