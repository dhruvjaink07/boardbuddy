import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/board/models/task_card.dart';

class AttachmentTile extends StatelessWidget {
  final AttachmentMeta meta;
  final VoidCallback? onDelete;

  const AttachmentTile({super.key, required this.meta, this.onDelete});

  IconData _iconForType(String t) {
    switch (t) {
      case 'image':
        return Icons.image_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'video':
        return Icons.videocam_outlined;
      case 'audio':
        return Icons.audiotrack_outlined;
      default:
        return Icons.attach_file;
    }
  }

  Future<void> _open() async {
    try {
      final uri = Uri.parse(meta.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback for emulator/testing
        print('Cannot launch URL: ${meta.url}');
      }
    } catch (e) {
      print('Error opening file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_iconForType(meta.type), color: AppColors.textPrimary),
      title: Text(meta.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textPrimary)),
      onTap: _open,
      trailing: onDelete == null
          ? null
          : IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: onDelete,
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      dense: true,
    );
  }
}