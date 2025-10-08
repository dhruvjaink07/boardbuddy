import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/board/models/task_card.dart';
import 'package:boardbuddy/features/files/presentation/attachment_tile.dart';
import 'package:boardbuddy/features/files/presentation/upload_button.dart';
import 'package:boardbuddy/features/files/data/file_repository.dart';

class TaskAttachmentsSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 12),
      const Text('Attachments', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      UploadAttachmentButton(boardId: boardId, columnId: columnId, cardId: cardId),
      const SizedBox(height: 8),
      if (attachments.isEmpty)
        const Text('No attachments yet', style: TextStyle(color: AppColors.textSecondary))
      else
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: attachments.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, i) {
              final a = attachments[i];
              return AttachmentTile(
                meta: a,
                onDelete: () async {
                  try {
                    await FileRepository.instance.removeAttachmentFromCard(
                      boardId: boardId,
                      columnId: columnId,
                      cardId: cardId,
                      meta: a,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attachment removed')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to remove: ${e.toString().split(':').last.trim()}')),
                    );
                  }
                },
              );
            },
          ),
        ),
    ]);
  }
}