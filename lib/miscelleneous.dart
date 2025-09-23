import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.orange,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isOffline = false; // toggle to show the offline screen

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isOffline ? _offlineView() : _emptyBoardView(),
    );
  }

  Widget _emptyBoardView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment, size: 80, color: Colors.orange),
          const SizedBox(height: 20),
          const Text(
            'No Boards Yet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first board to get started',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => setState(() => isOffline = true),
            child: const Text('+ Create Board',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _offlineView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.grey[900],
          padding: const EdgeInsets.all(12),
          child: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "You're offline – showing cached boards",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off,
                    size: 60, color: Colors.orangeAccent),
                const SizedBox(height: 12),
                const Text(
                  'No connection',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please reconnect to sync your boards',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  ),
                  onPressed: () => setState(() => isOffline = false),
                  child: const Text('Retry Now',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}