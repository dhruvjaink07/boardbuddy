import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/board/models/task_card.dart';
import 'package:boardbuddy/features/files/presentation/attachment_tile.dart';
import 'package:boardbuddy/features/files/presentation/upload_button.dart';
import 'package:boardbuddy/features/files/data/file_repository.dart';
import 'package:boardbuddy/features/files/services/cloudinary_service.dart';

class TaskAttachmentsSection extends StatefulWidget {
  final String boardId;
  final String columnId;
  final String cardId;
  final List<AttachmentMeta> attachments;

  const TaskAttachmentsSection({
    super.key,
    required this.boardId,
    required this.columnId,
    required this.cardId,
    required this.attachments,
  });

  @override
  State<TaskAttachmentsSection> createState() => _TaskAttachmentsSectionState();
}

class _TaskAttachmentsSectionState extends State<TaskAttachmentsSection> {
  bool _showUploadHistory = false;

  @override
  void initState() {
    super.initState();
    // Initialize CloudinaryService
    CloudinaryService.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 12),
      Row(
        children: [
          const Text(
            'Attachments',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          if (widget.attachments.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.attachments.length}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      
      // Upload button
      UploadAttachmentButton(
        boardId: widget.boardId,
        columnId: widget.columnId,
        cardId: widget.cardId,
        onUploaded: (meta) {
          setState(() {});
        },
      ),
      
      const SizedBox(height: 16),
      
      // Toggle for upload history
      Row(
        children: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showUploadHistory = !_showUploadHistory;
              });
            },
            icon: Icon(
              _showUploadHistory ? Icons.expand_less : Icons.expand_more,
              color: AppColors.primary,
            ),
            label: Text(
              _showUploadHistory ? 'Hide Upload History' : 'Show Upload History',
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${CloudinaryService.instance.cachedUploadsCount} cached',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
      
      const SizedBox(height: 12),
      
      // Current attachments
      if (widget.attachments.isEmpty)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: const Center(
            child: Column(
              children: [
                Icon(
                  Icons.attach_file_outlined,
                  color: AppColors.textSecondary,
                  size: 48,
                ),
                SizedBox(height: 8),
                Text(
                  'No attachments yet',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Upload files to share with your team',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        )
      else
        Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Column(
                children: widget.attachments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final attachment = entry.value;
                  return Column(
                    children: [
                      AttachmentTile(
                        meta: attachment,
                        onDelete: () async {
                          try {
                            await FileRepository.instance.removeAttachmentFromCard(
                              boardId: widget.boardId,
                              columnId: widget.columnId,
                              cardId: widget.cardId,
                              meta: attachment,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Attachment removed'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to remove: ${e.toString().split(':').last.trim()}'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                      if (index < widget.attachments.length - 1)
                        const Divider(height: 1, color: AppColors.border),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      
      // Upload history section
      if (_showUploadHistory) ...[
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Recent Uploads',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        await CloudinaryService.instance.clearCache();
                        setState(() {});
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              _buildUploadHistory(),
            ],
          ),
        ),
      ],
    ]);
  }

  Widget _buildUploadHistory() {
    final uploads = CloudinaryService.instance.getCachedUploads();
    
    if (uploads.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No upload history',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: uploads.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final upload = uploads[index];
        final meta = AttachmentMeta(
          name: upload.filename,
          url: upload.url,
          type: upload.fileType,
          size: upload.size,
          uploadedAt: upload.uploadedAt,
        );
        
        return AttachmentTile(
          meta: meta,
          onDelete: () async {
            await CloudinaryService.instance.deleteCachedUpload(upload.publicId);
            setState(() {});
          },
        );
      },
    );
  }
}