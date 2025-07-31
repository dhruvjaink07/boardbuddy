import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const BoardBuddyApp());
}

class BoardBuddyApp extends StatelessWidget {
  const BoardBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BoardBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const Scaffold(
        body: Center(
          child: Text(
            'Welcome to BoardBuddy!',
            style: TextStyle(color: AppColors.primary, fontSize: 24),
          ),
        ),
      ), // Replace with your home screen
    );
  }
}
