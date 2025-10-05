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

  Future<void> _searchUser() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _foundUser = null;
    });

    try {
      final user = await UserService.instance.findUserByEmail(email);
      setState(() {
        _foundUser = user;
        if (user == null) {
          _errorMessage = 'User not found. They need to sign up first.';
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
    if (_foundUser != null) {
      widget.onInvite(_foundUser!.uid, _selectedRole);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
            
            // User found/error display
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_foundUser != null)
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
              ),
            
            if (_foundUser != null) ...[
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
          onPressed: _foundUser != null ? _inviteUser : null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Invite', style: TextStyle(color: AppColors.textPrimary)),
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