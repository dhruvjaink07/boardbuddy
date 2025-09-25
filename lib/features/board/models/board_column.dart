class BoardColumn {
  final String columnId;
  final String title;
  final int order;
  final DateTime createdAt;

  BoardColumn({
    required this.columnId,
    required this.title,
    required this.order,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'columnId': columnId,
        'title': title,
        'order': order,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BoardColumn.fromMap(Map<String, dynamic> map) => BoardColumn(
        columnId: map['columnId'],
        title: map['title'],
        order: map['order'],
        createdAt: DateTime.parse(map['createdAt']),
      );
}
