import 'package:boardbuddy/features/auth/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/board/data/board_firestore_service.dart';
import 'package:boardbuddy/features/user/data/user_service.dart';

class BoardMembersScreen extends StatefulWidget {
  final String boardId;
  final List<String> memberIds; // kept but not relied upon
  final bool isOwner;

  const BoardMembersScreen({
    super.key,
    required this.boardId,
    required this.memberIds,
    required this.isOwner,
  });

  @override
  State<BoardMembersScreen> createState() => _BoardMembersScreenState();
}

class _BoardMembersScreenState extends State<BoardMembersScreen> {
  final Set<String> _removing = {};

  Future<void> _confirmAndRemove(String userId, String role) async {
    if (!widget.isOwner || role == 'owner') return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove member'),
        content: const Text('This user will lose access to the board. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _removing.add(userId));
    try {
      await BoardFirestoreService.instance.removeMember(
        boardId: widget.boardId,
        userId: userId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member removed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _removing.remove(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Board Members')),
      body: StreamBuilder<List<Map<String, String>>>(
        stream: BoardFirestoreService.instance.membersStream(widget.boardId),
        builder: (context, snap) {
          final members = snap.data ?? [];
          if (members.isEmpty) {
            return const Center(child: Text('No members', style: TextStyle(color: AppColors.textSecondary)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final uid = members[index]['uid']!;
              final role = members[index]['role']!;
              final removing = _removing.contains(uid);
              final canRemove = widget.isOwner && role != 'owner';

              return FutureBuilder<AppUser?>(
                future: UserService.instance.findUserByUid(uid),
                builder: (context, userSnap) {
                  final user = userSnap.data;
                  final title = user?.displayName ?? user?.email ?? uid;
                  final initial = (user?.displayName?.isNotEmpty == true
                          ? user!.displayName![0]
                          : (user?.email?.isNotEmpty == true ? user!.email![0] : 'U'))
                      .toUpperCase();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(initial, style: const TextStyle(color: AppColors.textPrimary)),
                    ),
                    title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
                    subtitle: Text(role, style: const TextStyle(color: AppColors.textSecondary)),
                    trailing: canRemove
                        ? (removing
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                                onPressed: () => _confirmAndRemove(uid, role),
                              ))
                        : null,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}