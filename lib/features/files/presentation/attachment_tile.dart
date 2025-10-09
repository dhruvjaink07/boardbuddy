import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/board/models/task_card.dart';
import 'package:boardbuddy/features/files/presentation/open_file.dart';
import 'package:timeago/timeago.dart' as timeago;

class AttachmentTile extends StatelessWidget {
  final AttachmentMeta meta;
  final VoidCallback? onDelete;
  final VoidCallback? onTap; // NEW: allow custom tap handler

  const AttachmentTile({super.key, required this.meta, this.onDelete, this.onTap});

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return Icons.image_outlined;
      case 'video':
        return Icons.videocam_outlined;
      case 'audio':
        return Icons.audiotrack_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'document':
        return Icons.description_outlined;
      case 'spreadsheet':
        return Icons.table_chart_outlined;
      case 'presentation':
        return Icons.slideshow_outlined;
      case 'text':
        return Icons.text_snippet_outlined;
      case 'archive':
        return Icons.archive_outlined;
      case 'code':
        return Icons.code_outlined;
      case 'link':
        return Icons.link_outlined;
      default:
        return Icons.attach_file_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return Colors.green;
      case 'video':
        return Colors.red;
      case 'audio':
        return Colors.purple;
      case 'pdf':
        return Colors.redAccent;
      case 'document':
        return Colors.blue;
      case 'spreadsheet':
        return Colors.teal;
      case 'presentation':
        return Colors.orange;
      case 'text':
        return Colors.grey;
      case 'archive':
        return Colors.amber;
      case 'code':
        return Colors.indigo;
      case 'link':
        return Colors.cyan;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _open() async {
    try {
      final uri = Uri.parse(meta.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Cannot launch URL: ${meta.url}');
      }
    } catch (e) {
      print('Error opening file: $e');
    }
  }

  String _getFileExtension(String filename) {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : '';
  }

  @override
  Widget build(BuildContext context) {
    final fileExtension = _getFileExtension(meta.name);
    final typeColor = _colorForType(meta.type);
    
    return InkWell(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else {
          openAttachmentViewer(
            context,
            name: meta.name,
            url: meta.url,
            type: meta.type,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: typeColor.withOpacity(0.3)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    _iconForType(meta.type),
                    color: typeColor,
                    size: 24,
                  ),
                ),
                if (fileExtension.isNotEmpty)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        fileExtension,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          title: Text(
            meta.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: typeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      meta.type.toUpperCase(),
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (meta.formattedSize.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        meta.formattedSize,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (meta.uploadedAt != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Uploaded ${timeago.format(meta.uploadedAt!)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.open_in_new, color: AppColors.primary),
                onPressed: _open,
                tooltip: 'Open file',
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: onDelete,
                  tooltip: 'Delete file',
                ),
            ],
          ),
        ),
      ),
    );
  }
}