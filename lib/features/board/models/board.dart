import 'package:cloud_firestore/cloud_firestore.dart';

class Board {
  final String boardId;
  final String name;
  final String description;
  final String theme; // e.g., "dark_orange", "forest"
  final String ownerId;
  final List<String> memberIds;
  final int? maxEditors;
  final DateTime createdAt;
  final DateTime lastUpdated;

  Board({
    required this.boardId,
    required this.name,
    required this.description,
    required this.theme,
    required this.ownerId,
    required this.memberIds,
    this.maxEditors,
    required this.createdAt,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'theme': theme,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'maxEditors': maxEditors,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  factory Board.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Board(
      boardId: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      theme: data['theme'] ?? 'default',
      ownerId: data['ownerId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? const []),
      maxEditors: data['maxEditors'],
      createdAt: _asDate(data['createdAt']),
      lastUpdated: _asDate(data['lastUpdated']),
    );
  }

  factory Board.fromMap(Map<String, dynamic> data, String boardId) {
    return Board(
      boardId: boardId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      theme: data['theme'] ?? 'default',
      ownerId: data['ownerId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? const []),
      maxEditors: data['maxEditors'],
      createdAt: _asDate(data['createdAt']),
      lastUpdated: _asDate(data['lastUpdated']),
    );
  }

  static DateTime _asDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
  }

  Board copyWith({
    String? boardId,
    String? name,
    String? description,
    String? theme,
    String? ownerId,
    List<String>? memberIds,
    int? maxEditors,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return Board(
      boardId: boardId ?? this.boardId,
      name: name ?? this.name,
      description: description ?? this.description,
      theme: theme ?? this.theme,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      maxEditors: maxEditors ?? this.maxEditors,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
