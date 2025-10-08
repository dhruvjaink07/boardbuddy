import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/comments/data/comment_model.dart';
import 'package:boardbuddy/features/comments/data/comment_repository.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatListView extends StatefulWidget {
  final String boardId;
  final String? cardId;

  const ChatListView({
    super.key,
    required this.boardId,
    this.cardId,
  });

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  final _scrollController = ScrollController();
  bool _hasError = false;
  String? _errorMessage;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorState();
    }

    return StreamBuilder<List<Comment>>(
      stream: widget.cardId != null
          ? CommentRepository.instance.streamCardComments(widget.boardId, widget.cardId!)
          : CommentRepository.instance.streamBoardCommentsAlternative(widget.boardId), // Use alternative method
      builder: (context, snapshot) {
        // Handle different connection states
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        // Handle errors
        if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _hasError = true;
                _errorMessage = snapshot.error.toString();
              });
            }
          });
          return _buildErrorState();
        }

        final comments = snapshot.data ?? [];
        
        // Auto-scroll to bottom when new messages arrive
        if (comments.isNotEmpty) {
          _scrollToBottom();
        }

        if (comments.isEmpty) {
          return _buildEmptyStateWithDebug(); // Add debug info
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            final isMe = FirebaseAuth.instance.currentUser?.uid == comment.userId;
            
            return ChatBubble(
              comment: comment,
              isMe: isMe,
              boardId: widget.boardId,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyStateWithDebug() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.cardId != null ? Icons.comment_outlined : Icons.chat_outlined,
              color: AppColors.textSecondary,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              widget.cardId != null 
                  ? 'No comments yet'
                  : 'No messages yet',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.cardId != null 
                  ? 'Be the first to comment on this task!'
                  : 'Start the conversation with your team!',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Debug button
            ElevatedButton(
              onPressed: () async {
                final comments = await CommentRepository.instance.getAllComments(widget.boardId);
                print('🔍 Debug: Found ${comments.length} total comments');
                for (final comment in comments) {
                  print('🔍 Comment: ${comment.id} - cardId: ${comment.cardId} - message: ${comment.message}');
                }
              },
              child: const Text('Debug Comments'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to load messages',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Retry', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.cardId != null ? Icons.comment_outlined : Icons.chat_outlined,
              color: AppColors.textSecondary,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              widget.cardId != null 
                  ? 'No comments yet'
                  : 'No messages yet',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.cardId != null 
                  ? 'Be the first to comment on this task!'
                  : 'Start the conversation with your team!',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final Comment comment;
  final bool isMe;
  final String boardId;

  const ChatBubble({
    super.key,
    required this.comment,
    required this.isMe,
    required this.boardId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: comment.userPhotoUrl != null
                  ? NetworkImage(comment.userPhotoUrl!)
                  : null,
              backgroundColor: AppColors.primary,
              child: comment.userPhotoUrl == null
                  ? Text(
                      _getInitials(comment.userName),
                      style: const TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Text(
                      comment.userName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                GestureDetector(
                  onLongPress: () => _showMessageOptions(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                        bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                      ),
                      border: isMe ? null : Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.message,
                          style: TextStyle(
                            color: isMe ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        if (comment.reactions?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          _buildReactions(),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: EdgeInsets.only(
                    left: isMe ? 0 : 12,
                    right: isMe ? 12 : 0,
                  ),
                  child: Text(
                    timeago.format(comment.timestamp),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: comment.userPhotoUrl != null
                  ? NetworkImage(comment.userPhotoUrl!)
                  : null,
              backgroundColor: AppColors.primary,
              child: comment.userPhotoUrl == null
                  ? Text(
                      _getInitials(comment.userName),
                      style: const TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Widget _buildReactions() {
    return Wrap(
      spacing: 4,
      children: comment.reactions!.entries.map((entry) {
        final emoji = entry.key;
        final userIds = entry.value;
        final currentUser = FirebaseAuth.instance.currentUser;
        final hasReacted = currentUser != null && userIds.contains(currentUser.uid);
        
        return GestureDetector(
          onTap: () async {
            if (hasReacted) {
              await CommentRepository.instance.removeReaction(
                boardId: boardId,
                commentId: comment.id,
                emoji: emoji,
              );
            } else {
              await CommentRepository.instance.addReaction(
                boardId: boardId,
                commentId: comment.id,
                emoji: emoji,
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: hasReacted ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasReacted ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              '$emoji ${userIds.length}',
              style: TextStyle(
                fontSize: 10,
                color: hasReacted ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showMessageOptions(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Text('👍', style: TextStyle(fontSize: 20)),
              title: const Text('Like', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                CommentRepository.instance.addReaction(
                  boardId: boardId,
                  commentId: comment.id,
                  emoji: '👍',
                );
              },
            ),
            ListTile(
              leading: const Text('❤️', style: TextStyle(fontSize: 20)),
              title: const Text('Love', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                CommentRepository.instance.addReaction(
                  boardId: boardId,
                  commentId: comment.id,
                  emoji: '❤️',
                );
              },
            ),
            ListTile(
              leading: const Text('😄', style: TextStyle(fontSize: 20)),
              title: const Text('Laugh', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                CommentRepository.instance.addReaction(
                  boardId: boardId,
                  commentId: comment.id,
                  emoji: '😄',
                );
              },
            ),
            if (currentUser?.uid == comment.userId) ...[
              const Divider(color: AppColors.border),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Delete', style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.card,
                      title: const Text('Delete Message', style: TextStyle(color: AppColors.textPrimary)),
                      content: const Text(
                        'Are you sure you want to delete this message?',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    try {
                      await CommentRepository.instance.deleteComment(
                        boardId: boardId,
                        commentId: comment.id,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete message: $e')),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}