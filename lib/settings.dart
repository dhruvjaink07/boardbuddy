import 'package:flutter/material.dart';

void main() {
  runApp(const BoardSettingsApp());
}

class BoardSettingsApp extends StatelessWidget {
  const BoardSettingsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          centerTitle: true,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: const BoardSettingsScreen(),
    );
  }
}

class BoardSettingsScreen extends StatelessWidget {
  const BoardSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {},
        ),
        title: const Text('Board Settings', style: TextStyle(fontSize: 18.0)),
        // Added a thin horizontal line at the bottom of the AppBar.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color.fromARGB(255, 69, 69, 69),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'CHANGE THEME'),
            const SizedBox(height: 16),
            const ThemeSelector(),
            const SizedBox(height: 32),
            const SectionHeader(title: 'RENAME BOARD'),
            const SizedBox(height: 16),
            const RenameBoardField(),
            const SizedBox(height: 32),
            const SectionHeader(title: 'DANGER ZONE'),
            const SizedBox(height: 16),
            const DeleteBoardButton(),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Colors.orange, // Changed the color to orange
      ),
    );
  }
}

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          // Wrap ThemeCard in Expanded to fit in the row
          child: ThemeCard(
            imagePath: 'assets/images/dark_theme.jpg',
            themeName: 'Dark',
            isActive: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          // Wrap ThemeCard in Expanded to fit in the row
          child: ThemeCard(
            imagePath: 'assets/images/light_theme.jpg',
            themeName: 'Light',
            isActive: false,
          ),
        ),
      ],
    );
  }
}

class ThemeCard extends StatelessWidget {
  final String imagePath;
  final String themeName;
  final bool isActive;

  const ThemeCard({
    super.key,
    required this.imagePath,
    required this.themeName,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          height:
              180, // Removed fixed width and used Expanded in ThemeSelector instead
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(color: Colors.orange, width: 2)
                : Border.all(color: Colors.transparent),
            image: DecorationImage(
              image: AssetImage(
                imagePath,
              ), // Use AssetImage and the imagePath parameter
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.0),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            child: Text(
              themeName,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class RenameBoardField extends StatelessWidget {
  const RenameBoardField({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Product Roadmap',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          const TextField(
            decoration: InputDecoration(
              hintText: 'Enter a new name for your board',
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
            ),
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class DeleteBoardButton extends StatelessWidget {
  const DeleteBoardButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0), // Added padding inside the container
      decoration: BoxDecoration(
        color: const Color(
          0xFF2B2B2B,
        ), // Changed to the correct dark gray color
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Delete Board',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0), // Adjusted padding
            child: Text(
              'This action cannot be undone',
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center, // Added to center the text
            ),
          ),
        ],
      ),
    );
  }
}
