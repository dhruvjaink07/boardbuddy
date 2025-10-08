import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/comments/presentation/chat_list_view.dart';
import 'package:boardbuddy/features/comments/presentation/chat_input_field.dart';
import 'package:boardbuddy/features/comments/data/comment_repository.dart';

class BoardChatScreen extends StatelessWidget {
  final String boardId;
  final String boardTitle;

  const BoardChatScreen({
    super.key,
    required this.boardId,
    required this.boardTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              boardTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Text(
              'Team Chat',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        backgroundColor: AppColors.card,
        elevation: 1,
        actions: [
          // Temporary test button
          IconButton(
            onPressed: () async {
              try {
                await CommentRepository.instance.addComment(
                  boardId: boardId,
                  message: 'Test message ${DateTime.now().millisecondsSinceEpoch}',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test message sent!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Test failed: $e')),
                );
              }
            },
            icon: const Icon(Icons.bug_report),
            tooltip: 'Test Send',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatListView(boardId: boardId),
          ),
          ChatInputField(
            boardId: boardId,
            hintText: 'Message the team...',
          ),
        ],
      ),
    );
  }
}