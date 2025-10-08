import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:boardbuddy/features/files/services/cloudinary_service.dart';
import 'package:boardbuddy/features/files/data/file_model.dart';
import 'package:boardbuddy/features/board/models/task_card.dart';

class FileRepository {
  FileRepository._();
  static final FileRepository instance = FileRepository._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _boards() => _db.collection('boards');

  // Helper: guess simple type from filename
  String _guessType(String filename) {
    final f = filename.toLowerCase();
    if (f.endsWith('.png') || f.endsWith('.jpg') || f.endsWith('.jpeg') || f.endsWith('.gif') || f.endsWith('.webp')) {
      return 'image';
    }
    if (f.endsWith('.pdf')) return 'pdf';
    if (f.endsWith('.mp4') || f.endsWith('.mov') || f.endsWith('.webm')) return 'video';
    if (f.endsWith('.mp3') || f.endsWith('.wav')) return 'audio';
    if (f.endsWith('.doc') || f.endsWith('.docx')) return 'document';
    if (f.endsWith('.xls') || f.endsWith('.xlsx')) return 'spreadsheet';
    if (f.endsWith('.ppt') || f.endsWith('.pptx')) return 'presentation';
    return 'file';
  }

  // Upload to Cloudinary and save under boards/{boardId}/files/{fileId}
  Future<FileAttachment?> uploadBoardFile({
    required String boardId,
    File? file,
    Uint8List? bytes,
    required String filename,
    int size = 0,
  }) async {
    final folder = 'boards/$boardId';
    final metadata = await CloudinaryService.instance.upload(
      file: kIsWeb ? null : file,
      bytes: kIsWeb ? bytes : null,
      filename: filename,
      folder: folder,
    );
    if (metadata == null) return null;

    final ref = _boards().doc(boardId).collection('files').doc();
    final model = FileAttachment(
      id: ref.id,
      name: filename,
      url: metadata.url,
      type: metadata.fileType,
      size: metadata.size,
      uploadedBy: 'system', // fill with uid in caller if needed
      uploadedAt: metadata.uploadedAt,
    );

    await ref.set({
      'id': model.id,
      ...model.toMap(),
    });

    return model;
  }

  Stream<List<FileAttachment>> streamBoardFiles(String boardId) {
    return _boards()
        .doc(boardId)
        .collection('files')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => FileAttachment.fromMap(d.data())).toList());
  }

  // Upload and attach to a specific card (stores meta in card.attachments array)
  Future<AttachmentMeta?> uploadAndAttachToCard({
    required String boardId,
    required String columnId,
    required String cardId,
    File? file,
    Uint8List? bytes,
    required String filename,
    int size = 0,
  }) async {
   try {
      final folder = 'boards/$boardId/cards/$cardId';
      final metadata = await CloudinaryService.instance.upload(
        file: kIsWeb ? null : file,
        bytes: kIsWeb ? bytes : null,
        filename: filename,
        folder: folder,
      ).timeout(const Duration(seconds: 45));
      if (metadata == null) return null;

      final meta = AttachmentMeta(
        name: filename,
        url: metadata.url,
        type: metadata.fileType,
        size: metadata.size,
        uploadedAt: metadata.uploadedAt,
      );

      final cardRef = _boards()
          .doc(boardId)
          .collection('columns')
          .doc(columnId)
          .collection('cards')
          .doc(cardId);

      // Append meta to attachments array
     await cardRef.update({
        'attachments': FieldValue.arrayUnion([meta.toMap()]),
        'lastUpdated': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      // Optional: also record at board-level "files"
      final ref = _boards().doc(boardId).collection('files').doc();
     await ref.set({
        'id': ref.id,
        'name': filename,
        'url': metadata.url,
        'type': metadata.fileType,
        'size': metadata.size,
        'uploadedBy': 'system',
        'uploadedAt': metadata.uploadedAt.toIso8601String(),
        'cardId': cardId,
        'columnId': columnId,
      }).timeout(const Duration(seconds: 10));

      return meta;
   } catch (e) {
     print('Error uploading file: $e');
     rethrow;
   }
  }

  Future<void> removeAttachmentFromCard({
    required String boardId,
    required String columnId,
    required String cardId,
    required AttachmentMeta meta,
  }) async {
   try {
      final cardRef = _boards()
          .doc(boardId)
          .collection('columns')
          .doc(columnId)
          .collection('cards')
          .doc(cardId);

     await cardRef.update({
        'attachments': FieldValue.arrayRemove([meta.toMap()]),
        'lastUpdated': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
   } catch (e) {
     print('Error removing attachment: $e');
     rethrow;
   }
  }
}