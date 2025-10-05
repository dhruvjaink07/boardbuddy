import 'package:boardbuddy/features/auth/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/user/data/user_service.dart';

class InviteMemberDialog extends StatefulWidget {
  final Function(String userId, String role) onInvite;

  const InviteMemberDialog({super.key, required this.onInvite});

  @override
  State<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<InviteMemberDialog> {
  final TextEditingController _emailController = TextEditingController();
  String _selectedRole = 'editor';
  bool _isSearching = false;
  AppUser? _foundUser;
  String? _errorMessage;
  bool _userExists = false;

  Future<void> _searchUser() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _foundUser = null;
      _userExists = false;
    });

    try {
      final user = await UserService.instance.findUserByEmail(email);
      setState(() {
        _foundUser = user;
        _userExists = user != null;
        if (user == null) {
          _errorMessage = null; // Clear error - we'll show invitation option
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching for user: $e';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _inviteUser() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      if (_foundUser != null) {
        // Existing user
        widget.onInvite(_foundUser!.uid, _selectedRole);
      } else {
        // Send email invitation
        widget.onInvite(email, _selectedRole); // Pass email instead of UID
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _emailController.text.trim();
    final canInvite = email.isNotEmpty && (email.contains('@') && email.contains('.'));

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Invite Member',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter email address:',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'user@example.com',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _searchUser(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSearching ? null : _searchUser,
                  icon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // User status display
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (email.isNotEmpty && canInvite) ...[
              const SizedBox(height: 12),
              if (_foundUser != null)
                // User found - show existing user
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          (_foundUser!.displayName ?? _foundUser!.email)[0].toUpperCase(),
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _foundUser!.displayName ?? 'User',
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _foundUser!.email,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle, color: AppColors.success),
                    ],
                  ),
                )
              else
                // User not found - show invitation option
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined, color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Send Invitation',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'User will be invited via email to join $email',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.send, color: AppColors.primary),
                    ],
                  ),
                ),
            ],

            // Role selection (show if user found OR valid email for invitation)
            if ((_foundUser != null || (email.isNotEmpty && canInvite && !_isSearching))) ...[
              const SizedBox(height: 16),
              const Text(
                'Select role:',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                dropdownColor: AppColors.background,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'editor', child: Text('Editor - Can edit board and tasks')),
                  DropdownMenuItem(value: 'viewer', child: Text('Viewer - Can only view')),
                ],
                onChanged: (value) => setState(() => _selectedRole = value ?? 'editor'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: canInvite ? _inviteUser : null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(
            _foundUser != null ? 'Add to Board' : 'Send Invitation',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}