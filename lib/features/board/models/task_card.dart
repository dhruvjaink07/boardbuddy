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
  final String title;
  final String description;
  final String priority;
  final String? category;
  final double progress;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? lastUpdated;
  final List<String> assignees;
  final List<AttachmentMeta> attachments;
  final List<ChecklistItem> checklist;
  final String? status;
  // NEW: Completion tracking fields
  final bool? isCompleted;
  final DateTime? completedAt;
  // NEW: Analytics denormalization fields  
  final String? boardId;
  final String? columnId;
  final String? assigneeId; // Make sure this field exists

  const TaskCard({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = 'medium',
    this.category,
    this.progress = 0.0,
    this.dueDate,
    this.createdAt,
    this.lastUpdated,
    this.assignees = const [],
    this.attachments = const [],
    this.checklist = const [],
    this.status,
    // NEW fields
    this.isCompleted,
    this.completedAt,
    this.boardId,
    this.columnId,
    this.assigneeId,
  });

  factory TaskCard.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc, String columnId) {
    final data = doc.data() ?? {};
    return TaskCard.fromMap(data, doc.id, columnId);
  }

  factory TaskCard.fromMap(Map<String, dynamic> map, [String? id, String? columnId]) {
    return TaskCard(
      id: id ?? map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      priority: map['priority'] ?? 'medium',
      category: map['category'],
      progress: (map['progress'] ?? 0.0).toDouble(),
      dueDate: map['dueDate'] is Timestamp 
        ? (map['dueDate'] as Timestamp).toDate()
        : DateTime.tryParse(map['dueDate']?.toString() ?? ''),
      createdAt: map['createdAt'] is Timestamp 
        ? (map['createdAt'] as Timestamp).toDate()
        : DateTime.tryParse(map['createdAt']?.toString() ?? ''),
      lastUpdated: map['lastUpdated'] is Timestamp 
        ? (map['lastUpdated'] as Timestamp).toDate()
        : DateTime.tryParse(map['lastUpdated']?.toString() ?? ''),
      assignees: List<String>.from(map['assignees'] ?? []),
      attachments: (map['attachments'] as List<dynamic>?)
          ?.map((a) => AttachmentMeta.fromMap(a as Map<String, dynamic>))
          .toList() ?? [],
      checklist: (map['checklist'] as List<dynamic>?)
          ?.map((item) => ChecklistItem.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      status: map['status'],
      // NEW: Completion fields
      isCompleted: map['isCompleted'] as bool?,
      completedAt: map['completedAt'] is Timestamp 
        ? (map['completedAt'] as Timestamp).toDate()
        : DateTime.tryParse(map['completedAt']?.toString() ?? ''),
      // NEW: Analytics fields
      boardId: map['boardId'] ?? columnId,
      columnId: map['columnId'] ?? columnId,
      assigneeId: map['assigneeId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      if (category != null) 'category': category,
      'progress': progress,
      if (dueDate != null) 'dueDate': dueDate,
      if (createdAt != null) 'createdAt': createdAt,
      if (lastUpdated != null) 'lastUpdated': lastUpdated,
      'assignees': assignees,
      'attachments': attachments.map((a) => a.toMap()).toList(),
      'checklist': checklist.map((item) => item.toMap()).toList(),
      if (status != null) 'status': status,
      // NEW: Completion fields
      if (isCompleted != null) 'isCompleted': isCompleted,
      if (completedAt != null) 'completedAt': completedAt,
      // NEW: Analytics fields
      if (boardId != null) 'boardId': boardId,
      if (columnId != null) 'columnId': columnId,
      if (assigneeId != null) 'assigneeId': assigneeId,
    };
  }

  Map<String, dynamic> toCreateMap() {
    final map = toMap();
    map['createdAt'] = FieldValue.serverTimestamp();
    map['lastUpdated'] = FieldValue.serverTimestamp();
    return map;
  }

  Map<String, dynamic> toUpdateMap() {
    final map = toMap();
    map['lastUpdated'] = FieldValue.serverTimestamp();
    return map;
  }

  TaskCard copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    String? category,
    double? progress,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? lastUpdated,
    List<String>? assignees,
    List<AttachmentMeta>? attachments,
    List<ChecklistItem>? checklist,
    String? status,
    // NEW: Completion fields
    bool? isCompleted,
    DateTime? completedAt,
    // NEW: Analytics fields
    String? boardId,
    String? columnId,
    String? assigneeId,
  }) {
    return TaskCard(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      progress: progress ?? this.progress,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      assignees: assignees ?? this.assignees,
      attachments: attachments ?? this.attachments,
      checklist: checklist ?? this.checklist,
      status: status ?? this.status,
      // NEW: Completion fields
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      // NEW: Analytics fields
      boardId: boardId ?? this.boardId,
      columnId: columnId ?? this.columnId,
      assigneeId: assigneeId ?? this.assigneeId,
    );
  }
}
