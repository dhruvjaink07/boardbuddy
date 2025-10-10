import 'package:boardbuddy/features/board/presentation/board_analytics_screen.dart';
import 'package:boardbuddy/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:boardbuddy/features/home/presentation/board_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1;

  // Replace these with your actual screens
  static final List<Widget> _screens = <Widget>[
    BoardAnalyticsScreen(),
    BoardScreen(),
    ProfileScreen()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: AppColors.secondary,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'Boards'),
          // BottomNavigationBarItem(
          //   icon: Image.asset(
          //     'assets/icons/assistant.png',
          //     width: 24,
          //     height: 24,
          //     color: _selectedIndex == 2 ? Colors.white : AppColors.secondary,
          //   ),
          //   label: 'Assistant',
          // ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.notifications_none_sharp),
          //   label: 'Notifications',
          // ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class BoardCard extends StatelessWidget {
  final Map<String, dynamic> board;
  const BoardCard({super.key, required this.board});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Left colored border
          Container(
            width: 6,
            decoration: BoxDecoration(
              color: board['color'],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          // Card content (NO fixed height!)
          Expanded(
            child: Container(
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
                mainAxisSize: MainAxisSize.min, // <-- Important!
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
                  // ...other content...
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
