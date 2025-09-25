class Board {
  final String boardId;
  final String name;
  final String description;
  final String theme;
  final String ownerId;
  final List<String> memberIds;
  final int maxEditors; // for future constraint
  final DateTime createdAt;
  final DateTime lastUpdated;

  Board({
    required this.boardId,
    required this.name,
    required this.description,
    required this.theme,
    required this.ownerId,
    required this.memberIds,
    required this.maxEditors,
    required this.createdAt,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() => {
        'boardId': boardId,
        'name': name,
        'description': description,
        'theme': theme,
        'ownerId': ownerId,
        'memberIds': memberIds,
        'maxEditors': maxEditors,
        'createdAt': createdAt.toIso8601String(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory Board.fromMap(Map<String, dynamic> map) => Board(
        boardId: map['boardId'],
        name: map['name'],
        description: map['description'],
        theme: map['theme'],
        ownerId: map['ownerId'],
        memberIds: List<String>.from(map['memberIds'] ?? []),
        maxEditors: map['maxEditors'] ?? 5,
        createdAt: DateTime.parse(map['createdAt']),
        lastUpdated: DateTime.parse(map['lastUpdated']),
      );
}
