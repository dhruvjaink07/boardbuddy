import 'package:flutter/material.dart';
import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:get/get.dart'; // Add this import
import 'package:boardbuddy/routes/app_routes.dart'; // Add this import

// --- COMPONENTS ---

class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hey Dhruv 👋',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Your boards await!',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }
}

class HomeAppBarActions extends StatelessWidget {
  const HomeAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.settings, color: AppColors.textPrimary),
          onPressed: () {},
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
                margin: EdgeInsets.only(
                  right: index != filters.length - 1 ? 8 : 0,
                ),
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.filterSelected
                      : AppColors.filterUnselected,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    filters[index],
                    style: TextStyle(
                      color: AppColors.textPrimary.withOpacity(
                        isSelected ? 1 : 0.7,
                      ),
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
  final Map<String, dynamic> board;
  final double height;
  
  const BoardCard({
    super.key,
    required this.board,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to BoardViewScreen with board data
        Get.toNamed(
          AppRoutes.boardViewScreen,
          arguments: {
            'boardId': board['id'] ?? board['title'], // Use ID if available, fallback to title
            'boardTitle': board['title'],
            'boardColor': board['color'],
            'boardIcon': board['icon'],
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        height: height, // Set the overall card height
        child: Row(
          children: [
            // Left colored border with matching radius
            Container(
              width: 6,
              height: height, // Use the height parameter here
              decoration: BoxDecoration(
                color: board['color'],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            // Card content
            Expanded(
              child: Container(
                height: height, // Use the height parameter here too
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
                  children: [
                    Row(
                      children: [
                        Icon(board['icon'], color: board['color'], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            board['title'],
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
                      board['subtitle'],
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
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

  final List<Map<String, dynamic>> boards = [
    {
      'id': 'board_1', // Add unique IDs
      'title': 'Product Launch 2024',
      'subtitle': 'Updated 2h ago',
      'color': Colors.blue,
      'icon': Icons.rocket_launch,
    },
    {
      'id': 'board_2',
      'title': 'Personal Tasks',
      'subtitle': 'Updated 5h ago',
      'color': Colors.orange,
      'icon': Icons.star,
    },
    {
      'id': 'board_3',
      'title': 'Design Projects',
      'subtitle': 'Updated 1d ago',
      'color': Colors.purple,
      'icon': Icons.palette,
    },
    {
      'id': 'board_4',
      'title': 'Meeting Notes',
      'subtitle': 'Updated 3h ago',
      'color': Colors.green,
      'icon': Icons.sticky_note_2,
    },
    {
      'id': 'board_5',
      'title': 'Reading List',
      'subtitle': 'Updated 2d ago',
      'color': Colors.blue,
      'icon': Icons.menu_book,
    },
    {
      'id': 'board_6',
      'title': 'Team Goals',
      'subtitle': 'Updated 1h ago',
      'color': Colors.orange,
      'icon': Icons.flag,
    },
  ];

  List<Map<String, dynamic>> getFilteredBoards() {
    if (selectedFilter == 0) {
      return boards;
    } else if (selectedFilter == 1) {
      return boards.take(3).toList();
    } else {
      return boards.reversed.take(2).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const HomeGreeting(),
        // actions: const [HomeAppBarActions()],
      ),
      body: SafeArea(
        // <-- Add this
        child: Column(
          children: [
            const SizedBox(height: 10),
            BoardFilterBar(
              filters: filters,
              selectedIndex: selectedFilter,
              onSelected: (index) {
                setState(() {
                  selectedFilter = index;
                });
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate card height: (total height - paddings) / rows
                  final double cardHeight = (constraints.maxHeight - 32) / 3;
                  
                  // Check if it's a tablet/desktop (width > 600px)
                  final bool isTablet = MediaQuery.of(context).size.width > 600;
                  
                  if (isTablet) {
                    // For tablets: Center the grid and limit its width
                    return Center(
                      child: SizedBox(
                        width: 600, // Max width for tablet layout
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.4, // Slightly wider cards for tablet
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: getFilteredBoards().length,
                          itemBuilder: (context, index) => BoardCard(
                            board: getFilteredBoards()[index],
                            height: 140, // Fixed height for tablets
                          ),
                        ),
                      ),
                    );
                  } else {
                    // For phones: Keep the responsive layout
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: getFilteredBoards().length,
                      itemBuilder: (context, index) => BoardCard(
                        board: getFilteredBoards()[index],
                        height: cardHeight,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: CircleBorder(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.textPrimary),
        onPressed: () {
                    Get.toNamed(AppRoutes.createBoard);

        },
      ),
    );
  }
}
