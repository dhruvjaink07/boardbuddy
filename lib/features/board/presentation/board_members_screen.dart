import 'package:boardbuddy/features/auth/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/user/data/user_service.dart';
import 'package:boardbuddy/features/board/data/board_firestore_service.dart';

class BoardMembersScreen extends StatelessWidget {
  final String boardId;
  final List<String> memberIds;
  final bool isOwner;

  const BoardMembersScreen({
    super.key,
    required this.boardId,
    required this.memberIds,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Board Members'),
        backgroundColor: AppColors.background,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: memberIds.length,
        itemBuilder: (context, index) {
          final userId = memberIds[index];
          return FutureBuilder<AppUser?>(
            future: UserService.instance.findUserByUid(userId), // Fixed: use findUserByUid
            builder: (context, userSnapshot) {
              return StreamBuilder<String?>(
                stream: BoardFirestoreService.instance.myRoleStream(boardId),
                builder: (context, roleSnap) {
                  final userRole = roleSnap.data ?? 'viewer';
                  final user = userSnapshot.data;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user?.displayName?.isNotEmpty == true 
                          ? user!.displayName![0].toUpperCase()
                          : user?.email.isNotEmpty == true
                            ? user!.email[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      user?.displayName ?? user?.email ?? 'User $userId',
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      userRole,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: isOwner && userRole != 'owner'
                        ? IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                            onPressed: () async {
                              await BoardFirestoreService.instance.removeMember(
                                boardId: boardId,
                                userId: userId,
                              );
                            },
                          )
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