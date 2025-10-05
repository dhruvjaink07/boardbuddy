import 'package:cloud_firestore/cloud_firestore.dart';

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

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'order': order,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory BoardColumn.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BoardColumn(
      columnId: doc.id,
      title: data['title'] ?? '',
      order: (data['order'] ?? 0) is int ? (data['order'] ?? 0) : int.tryParse('${data['order']}') ?? 0,
      createdAt: _asDate(data['createdAt']),
    );
  }

  static DateTime _asDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
  }
}
