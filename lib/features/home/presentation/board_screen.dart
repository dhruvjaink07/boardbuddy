import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:boardbuddy/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boardbuddy/features/board/data/board_firestore_service.dart';
import 'package:boardbuddy/features/board/models/board.dart';
import 'package:boardbuddy/features/board/presentation/board_view_screen.dart';

// --- COMPONENTS ---

class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'there';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hey $name 👋',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Your boards await!',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

class BoardFilterBar extends StatelessWidget {
  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const BoardFilterBar({
    super.key,
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        children: List.generate(filters.length, (index) {
          final bool isSelected = selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: Container(
                margin: EdgeInsets.only(right: index != filters.length - 1 ? 8 : 0),
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.filterSelected : AppColors.filterUnselected,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    filters[index],
                    style: TextStyle(
                      color: AppColors.textPrimary.withOpacity(isSelected ? 1 : 0.7),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class BoardCard extends StatelessWidget {
  final Board board;
  final double height;

  const BoardCard({super.key, required this.board, this.height = 120});

  Color _themeColor(String theme) {
    switch (theme.toLowerCase()) {
      case 'forest':
      case 'green':
        return Colors.green;
      case 'purple galaxy':
      case 'purple':
        return Colors.purple;
      case 'neon red':
      case 'red':
        return Colors.redAccent;
      case 'sky blue':
      case 'blue':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }

  String _relativeTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Updated just now';
    if (d.inMinutes < 60) return 'Updated ${d.inMinutes}m ago';
    if (d.inHours < 24) return 'Updated ${d.inHours}h ago';
    return 'Updated ${d.inDays}d ago';
    }

  @override
  Widget build(BuildContext context) {
    final color = _themeColor(board.theme);
    return GestureDetector(
      onTap: () {
        // Pass typed model directly
        Get.to(() => BoardViewScreen(board: board));
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        height: height,
        child: Row(
          children: [
            // Left colored border with matching radius
            Container(
              width: 6,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            // Card content
            Expanded(
              child: Container(
                height: height,
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.dashboard, color: color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            board.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      board.description.isNotEmpty ? board.description : _relativeTime(board.lastUpdated),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- MAIN SCREEN ---

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  int selectedFilter = 0;
  final List<String> filters = ['All Boards', 'Recent', 'Favorites'];

  List<Board> _applyFilter(List<Board> boards) {
    if (selectedFilter == 0) {
      return boards;
    } else if (selectedFilter == 1) {
      // Recent
      final copy = List<Board>.from(boards);
      copy.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
      return copy.take(6).toList();
    } else {
      // Favorites placeholder (none marked yet)
      return const <Board>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const HomeGreeting(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            BoardFilterBar(
              filters: filters,
              selectedIndex: selectedFilter,
              onSelected: (index) => setState(() => selectedFilter = index),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: userId.isEmpty
                  ? _NotLoggedInEmptyState()
                  : StreamBuilder<List<Board>>(
                      stream: BoardFirestoreService.instance.streamBoardsForUser(userId),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                        }
                        if (snap.hasError) {
                          return _ErrorState(
                            message: 'Failed to load boards: ${snap.error}',
                            onRetry: () => setState(() {}),
                          );
                        }
                        final items = _applyFilter(snap.data ?? const []);
                        if (items.isEmpty) {
                          return _EmptyBoardsState();
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final double cardHeight = (constraints.maxHeight - 32) / 3;
                            final bool isTablet = MediaQuery.of(context).size.width > 600;

                            if (isTablet) {
                              return Center(
                                child: SizedBox(
                                  width: 600,
                                  child: GridView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 1.4,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                    ),
                                    itemCount: items.length,
                                    itemBuilder: (context, index) => BoardCard(
                                      board: items[index],
                                      height: 140,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.2,
                                ),
                                itemCount: items.length,
                                itemBuilder: (context, index) => BoardCard(
                                  board: items[index],
                                  height: cardHeight,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.textPrimary),
        onPressed: () => Get.toNamed(AppRoutes.createBoard),
      ),
    );
  }
}

class _EmptyBoardsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.dashboard_customize, color: AppColors.textSecondary, size: 48),
        const SizedBox(height: 8),
        const Text('No boards yet', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        const SizedBox(height: 4),
        const Text('Create your first board to get started', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => Get.toNamed(AppRoutes.createBoard),
          icon: const Icon(Icons.add, color: AppColors.textPrimary),
          label: const Text('Create Board', style: TextStyle(color: AppColors.textPrimary)),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
        ),
      ]),
    );
  }
}

class _NotLoggedInEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Please sign in to see your boards', style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 40),
        const SizedBox(height: 8),
        Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onRetry,
          child: const Text('Retry', style: TextStyle(color: AppColors.textPrimary)),
        ),
      ]),
    );
  }
}
