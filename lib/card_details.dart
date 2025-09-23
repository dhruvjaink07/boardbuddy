import 'package:flutter/material.dart';

void main() => runApp(const BoardBuddyTaskPage());

class BoardBuddyTaskPage extends StatelessWidget {
  const BoardBuddyTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(primary: Colors.orangeAccent),
      ),
      home: const TaskDetailsScreen(),
    );
  }
}

class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subtasks = [
      {'title': 'Research existing systems', 'done': true},
      {'title': 'Create component library', 'done': true},
      {'title': 'Design documentation template', 'done': false},
      {'title': 'Write style guidelines', 'done': true},
      {'title': 'Review with team', 'done': false},
      {'title': 'Finalize documentation', 'done': false},
    ];
    final doneCount = subtasks.where((t) => t['done'] as bool).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
        title: const Text('Task Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Design System Documentation',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 80,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Add description...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Chip(
                  label: const Text('High Priority'),
                  backgroundColor: Colors.deepOrange,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: const Text('Design'),
                  backgroundColor: Colors.orangeAccent,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Icon(Icons.calendar_today, color: Colors.orangeAccent),
                SizedBox(width: 8),
                Text('Due: Oct 15, 2023'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                CircleAvatar(
                  backgroundImage: AssetImage('assets/sarah.jpg'),
                  radius: 18,
                ),
                SizedBox(width: 8),
                Text('Sarah Cooper',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(width: 6),
                Text('Lead Designer', style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Subtasks (${doneCount}/${subtasks.length})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: doneCount / subtasks.length,
              color: Colors.orangeAccent,
              backgroundColor: Colors.grey[800],
              minHeight: 6,
            ),
            const SizedBox(height: 16),
            ...subtasks.map((task) => SubtaskTile(
                  title: task['title'] as String,
                  done: task['done'] as bool,
                )),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, color: Colors.orangeAccent),
              label: const Text(
                'Add Subtask',
                style: TextStyle(color: Colors.orangeAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubtaskTile extends StatelessWidget {
  final String title;
  final bool done;
  const SubtaskTile({super.key, required this.title, required this.done});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: done,
        activeColor: Colors.orangeAccent,
        onChanged: (_) {},
      ),
      title: Text(
        title,
        style: TextStyle(
          decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
          color: done ? Colors.grey : Colors.white,
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
