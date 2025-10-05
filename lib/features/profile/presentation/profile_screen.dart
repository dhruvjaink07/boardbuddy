import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/user/data/user_service.dart';
import 'package:boardbuddy/features/auth/models/user_model.dart';
import 'package:boardbuddy/features/board/data/board_firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _photo = TextEditingController();
  bool _seeded = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _photo.dispose();
    super.dispose();
  }

  Future<void> _save(String uid) async {
    setState(() => _saving = true);
    try {
      await UserService.instance.updateProfile(
        uid: uid,
        displayName: _name.text.trim().isEmpty ? null : _name.text.trim(),
        photoUrl: _photo.text.trim().isEmpty ? null : _photo.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _acceptAllInvites(String email) async {
    try {
      await BoardFirestoreService.instance.processPendingInvitations(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitations accepted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Please sign in', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: StreamBuilder<AppUser?>(
        stream: UserService.instance.streamUser(u.uid),
        builder: (context, snap) {
          final appUser = snap.data;
          if (appUser == null) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (!_seeded) {
            _seeded = true;
            _name.text = appUser.displayName ?? '';
            _photo.text = appUser.photoUrl ?? '';
          }

          final avatar = (appUser.photoUrl?.isNotEmpty ?? false)
              ? CircleAvatar(radius: 28, backgroundImage: NetworkImage(appUser.photoUrl!))
              : CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (appUser.displayName?.isNotEmpty == true
                            ? appUser.displayName![0]
                            : (appUser.email.isNotEmpty ? appUser.email[0] : 'U'))
                        .toUpperCase(),
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                avatar,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(appUser.displayName ?? 'Your Name', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(appUser.email, style: const TextStyle(color: AppColors.textSecondary)),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),

              const Text('Display name', style: TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: _name,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _decoration('e.g., Alex'),
              ),
              const SizedBox(height: 12),

              const Text('Photo URL', style: TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: _photo,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _decoration('https://...'),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _save(appUser.uid),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: _saving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary))
                      : const Text('Save', style: TextStyle(color: AppColors.textPrimary)),
                ),
              ),

              const SizedBox(height: 24),
              const Text('Invitations', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              StreamBuilder(
                stream: UserService.instance.invitationsStream(appUser.email),
                builder: (context, snapInv) {
                  final invites = (snapInv.data as List?)?.cast<dynamic>() ?? const [];
                  if (invites.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                      child: const Text('No pending invitations', style: TextStyle(color: AppColors.textSecondary)),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                        child: Column(
                          children: [
                            for (final inv in invites)
                              ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(inv.boardName, style: const TextStyle(color: AppColors.textPrimary)),
                                subtitle: Text('Role: ${inv.role}', style: const TextStyle(color: AppColors.textSecondary)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _acceptAllInvites(appUser.email),
                          icon: const Icon(Icons.check, color: AppColors.textPrimary),
                          label: const Text('Accept all', style: TextStyle(color: AppColors.textPrimary)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ]),
          );
        },
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }
}