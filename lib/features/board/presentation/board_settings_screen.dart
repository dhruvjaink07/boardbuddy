import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/board/models/board.dart';
import 'package:boardbuddy/features/board/presentation/board_members_screen.dart';
import 'package:boardbuddy/features/board/presentation/widgets/invite_member_dialog.dart';
import 'package:boardbuddy/features/board/data/board_firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BoardSettingsScreen extends StatefulWidget {
  final String boardId;
  const BoardSettingsScreen({super.key, required this.boardId});

  @override
  State<BoardSettingsScreen> createState() => _BoardSettingsScreenState();
}

class _BoardSettingsScreenState extends State<BoardSettingsScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _maxEditors = TextEditingController(text: '5');
  String _theme = 'forest';
  bool _seeded = false;

  int? _colCount;
  int? _cardCount;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _maxEditors.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final s = BoardFirestoreService.instance;
    final cols = await s.countColumns(widget.boardId);
    final cards = await s.countCards(widget.boardId);
    if (!mounted) return;
    setState(() {
      _colCount = cols;
      _cardCount = cards;
    });
  }

  Future<void> _save(Board b) async {
    final parsedMax = int.tryParse(_maxEditors.text.trim());
    await BoardFirestoreService.instance.updateBoardMeta(
      boardId: b.boardId,
      name: _name.text.trim().isEmpty ? null : _name.text.trim(),
      description: _desc.text.trim(),
      theme: _theme,
      maxEditors: parsedMax,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Board settings saved')),
    );
  }

  void _openInvite(Board b) {
    showDialog(
      context: context,
      builder: (_) => InviteMemberDialog(
        onInvite: (userIdOrEmail, role) async {
          final result = await BoardFirestoreService.instance.inviteMember(
            boardId: b.boardId,
            email: userIdOrEmail,
            role: role,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result == 'added'
                  ? 'Member added as $role'
                  : 'Invitation sent'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Allowed themes + labels (include forest_green to match existing boards)
    const themeLabels = <String, String>{
      'forest': 'Forest',
      'forest_green': 'Forest Green',
      'space': 'Space',
      'neon': 'Neon',
      'default': 'Default',
    };
    final themeKeys = themeLabels.keys.toList();

    final df = DateFormat.yMMMd().add_jm();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Board Settings'),
        backgroundColor: AppColors.background,
      ),
      body: StreamBuilder<Board>(
        stream: BoardFirestoreService.instance.streamBoard(widget.boardId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          final b = snap.data!;
          if (!_seeded) {
            _seeded = true;
            _name.text = b.name;
            _desc.text = b.description;
            _theme = b.theme;
            _maxEditors.text = '${b.maxEditors ?? 5}';
            // load stats once
            _loadStats();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Meta
              const Text('General', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              _tile(
                label: 'Board Name',
                child: TextField(
                  controller: _name,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('Project Alpha'),
                ),
              ),
              const SizedBox(height: 10),
              _tile(
                label: 'Description',
                child: TextField(
                  controller: _desc,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('What is this board about?'),
                ),
              ),
              const SizedBox(height: 10),
              _tile(
                label: 'Theme',
                child: DropdownButtonFormField<String>(
                  value: themeKeys.contains(_theme) ? _theme : 'default',
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: themeKeys
                      .map((k) => DropdownMenuItem(value: k, child: Text(themeLabels[k]!)))
                      .toList(),
                  onChanged: (v) => setState(() => _theme = v ?? 'default'),
                ),
              ),
              const SizedBox(height: 10),
              _tile(
                label: 'Max Editors',
                child: TextField(
                  controller: _maxEditors,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('5'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _save(b),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Save Changes', style: TextStyle(color: AppColors.textPrimary)),
                ),
              ),

              const SizedBox(height: 22),
              // Members
              const Text('Members', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _openInvite(b),
                    icon: const Icon(Icons.person_add, color: AppColors.textPrimary),
                    label: const Text('Invite', style: TextStyle(color: AppColors.textPrimary)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  StreamBuilder<int>(
                    stream: BoardFirestoreService.instance.membersCountStream(b.boardId),
                    builder: (context, countSnap) {
                      final count = countSnap.data ?? b.memberIds.length;
                      return OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => BoardMembersScreen(
                              boardId: b.boardId,
                              memberIds: b.memberIds, // kept for backward compat; list view will stream
                              isOwner: FirebaseAuth.instance.currentUser?.uid == b.ownerId,
                            ),
                          ));
                        },
                        icon: const Icon(Icons.group_outlined, color: AppColors.textPrimary),
                        label: Text('Manage ($count)', style: const TextStyle(color: AppColors.textPrimary)),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 22),
              // Info
              const Text('Details', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              _infoRow('Created', df.format(b.createdAt)),
              _infoRow('Updated', df.format(b.lastUpdated)),
              _infoRow('Theme', themeLabels[b.theme] ?? 'Default'),
              _infoRow('Members', '${b.memberIds.length}'),
              _infoRow('Columns', _colCount?.toString() ?? '…'),
              _infoRow('Cards', _cardCount?.toString() ?? '…'),
            ]),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }

  Widget _tile({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _infoRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(k, style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(child: Text(v, style: const TextStyle(color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}