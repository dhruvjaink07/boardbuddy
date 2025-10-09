import 'package:cloud_firestore/cloud_firestore.dart';

class FileAttachment {
  final String id;
  final String name;
  final String url;
  final String type;
  final int size;
  final String uploadedBy;
  final DateTime uploadedAt;

  FileAttachment({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
    required this.uploadedBy,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'url': url,
    'type': type,
    'size': size,
    'uploadedBy': uploadedBy,
    'uploadedAt': uploadedAt.toIso8601String(),
  };

  factory FileAttachment.fromMap(Map<String, dynamic> map) => FileAttachment(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    url: map['url'] ?? '',
    type: map['type'] ?? '',
    size: map['size'] ?? 0,
    uploadedBy: map['uploadedBy'] ?? '',
    uploadedAt: map['uploadedAt'] is Timestamp
        ? (map['uploadedAt'] as Timestamp).toDate()
        : DateTime.tryParse(map['uploadedAt'] ?? '') ?? DateTime.now(),
  );

  // New: create from Firestore DocumentSnapshot
  factory FileAttachment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FileAttachment(
      id: doc.id,
      name: data['name'] ?? '',
      url: data['url'] ?? '',
      type: data['type'] ?? '',
      size: (data['size'] ?? 0) is int ? (data['size'] ?? 0) : int.tryParse('${data['size']}') ?? 0,
      uploadedBy: data['uploadedBy'] ?? '',
      uploadedAt: data['uploadedAt'] is Timestamp
          ? (data['uploadedAt'] as Timestamp).toDate()
          : DateTime.tryParse('${data['uploadedAt']}') ?? DateTime.now(),
    );
  }
}
