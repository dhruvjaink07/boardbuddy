import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> boards = [
    {
      'title': 'Product...',
      'icon': Icons.image,
      'color': Colors.blue,
      'updated': '2h ago',
    },
    {
      'title': 'Personal Tasks',
      'icon': Icons.star,
      'color': Colors.orange,
      'updated': '5h ago',
    },
    {
      'title': 'Design Projects',
      'icon': Icons.palette,
      'color': Colors.purple,
      'updated': '1d ago',
    },
    {
      'title': 'Meeting Notes',
      'icon': Icons.sticky_note_2,
      'color': Colors.green,
      'updated': '3h ago',
    },
    {
      'title': 'Reading List',
      'icon': Icons.book,
      'color': Colors.blue,
      'updated': '2d ago',
    },
    {
      'title': 'Team Goals',
      'icon': Icons.track_changes,
      'color': Colors.orange,
      'updated': '1h ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          // TODO: Add board creation logic
        },
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Hey Dhruv 👋',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'your boards await!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  Row(
                    children: const [
                      Icon(Icons.settings, color: Colors.white),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Grid of boards
              Expanded(
                child: GridView.builder(
                  itemCount: boards.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) {
                    final board = boards[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: board['color']),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(board['icon'], color: board['color']),
                          const Spacer(),
                          Text(
                            board['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Updated ${board['updated']}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              CircleAvatar(
                                radius: 8,
                                backgroundColor: board['color'],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
