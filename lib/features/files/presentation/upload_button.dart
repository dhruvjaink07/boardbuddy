import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/files/data/file_repository.dart';
import 'package:boardbuddy/features/board/models/task_card.dart';

class UploadAttachmentButton extends StatefulWidget {
  final String boardId;
  final String columnId;
  final String cardId;
  final void Function(AttachmentMeta meta)? onUploaded;

  const UploadAttachmentButton({
    super.key,
    required this.boardId,
    required this.columnId,
    required this.cardId,
    this.onUploaded,
  });

  @override
  State<UploadAttachmentButton> createState() => _UploadAttachmentButtonState();
}

class _UploadAttachmentButtonState extends State<UploadAttachmentButton> {
  bool _busy = false;

  Future<void> _pickAndUpload() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final res = await FilePicker.platform.pickFiles(
        withData: kIsWeb,
        allowMultiple: false,
        type: FileType.any,
      ).timeout(const Duration(seconds: 30));
      if (res == null || res.files.isEmpty) return;

      final f = res.files.single;
      final filename = f.name;
      final size = f.size;

      // Validate file size (10MB limit)
      if (size > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File too large. Maximum size is 10MB')),
          );
        }
        return;
      }

      final meta = await FileRepository.instance.uploadAndAttachToCard(
        boardId: widget.boardId,
        columnId: widget.columnId,
        cardId: widget.cardId,
        file: !kIsWeb && f.path != null ? File(f.path!) : null,
        bytes: kIsWeb ? f.bytes : null,
        filename: filename,
        size: size,
      ).timeout(const Duration(seconds: 60));

      if (meta != null && widget.onUploaded != null && mounted) {
        widget.onUploaded!(meta);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attachment uploaded')),
        );
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload timeout. Please try again')),
        );
      }
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid file format')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString().split(':').last.trim()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _busy ? null : _pickAndUpload,
      icon: _busy
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.attach_file, color: AppColors.textPrimary),
      label: const Text('Add attachment', style: TextStyle(color: AppColors.textPrimary)),
      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border)),
    );
  }
}