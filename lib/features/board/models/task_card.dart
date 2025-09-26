import 'comment.dart';

class TaskCard {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? assigneeId;
  final List<String> labels;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String columnId;
  final List<Subtask> subtasks;
  final List<Attachment> attachments;
  final List<Comment> comments;
  
  final String category;
  final List<String> assignees;
  final double progress;

  TaskCard({
    required this.id,
    required this.title,
    this.description = '',
    this.status = 'todo',
    this.priority = 'medium',
    this.assigneeId,
    this.labels = const [],
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    required this.columnId,
    this.subtasks = const [],
    this.attachments = const [],
    this.comments = const [],
    this.category = '',
    this.assignees = const [],
    this.progress = 0.0,
  });

  TaskCard copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? priority,
    String? assigneeId,
    List<String>? labels,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? columnId,
    List<Subtask>? subtasks,
    List<Attachment>? attachments,
    List<Comment>? comments,
    String? category,
    List<String>? assignees,
    double? progress,
  }) {
    return TaskCard(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assigneeId: assigneeId ?? this.assigneeId,
      labels: labels ?? this.labels,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      columnId: columnId ?? this.columnId,
      subtasks: subtasks ?? this.subtasks,
      attachments: attachments ?? this.attachments,
      comments: comments ?? this.comments,
      category: category ?? this.category,
      assignees: assignees ?? this.assignees,
      progress: progress ?? this.progress,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'assigneeId': assigneeId,
      'labels': labels,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'columnId': columnId,
      'subtasks': subtasks.map((x) => x.toMap()).toList(),
      'attachments': attachments.map((x) => x.toMap()).toList(),
      'comments': comments.map((x) => x.toMap()).toList(),
      'category': category,
      'assignees': assignees,
      'progress': progress,
    };
  }

  factory TaskCard.fromMap(Map<String, dynamic> map) {
    return TaskCard(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'todo',
      priority: map['priority'] ?? 'medium',
      assigneeId: map['assigneeId'],
      labels: List<String>.from(map['labels'] ?? []),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      columnId: map['columnId'] ?? '',
      subtasks: List<Subtask>.from(map['subtasks']?.map((x) => Subtask.fromMap(x)) ?? []),
      attachments: List<Attachment>.from(map['attachments']?.map((x) => Attachment.fromMap(x)) ?? []),
      comments: List<Comment>.from(map['comments']?.map((x) => Comment.fromMap(x)) ?? []),
      category: map['category'] ?? '',
      assignees: List<String>.from(map['assignees'] ?? []),
      progress: (map['progress'] ?? 0.0).toDouble(),
    );
  }
}

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
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

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
      id: map['id'] ?? '',
      fileName: map['fileName'] ?? '',
      filePath: map['filePath'] ?? '', // Fixed this line
      fileType: map['fileType'] ?? '',
      fileSize: map['fileSize']?.toInt() ?? 0,
      uploadedAt: DateTime.parse(map['uploadedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
