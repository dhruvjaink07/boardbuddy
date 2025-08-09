import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo
        SizedBox(
          width: 50,
          height: 50,

          child: Image.asset('assets/icons/logo.png', fit: BoxFit.cover),
        ),

        const SizedBox(height: 20),

        // Title
        const Text(
          "Boardbuddy",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 4),

        // Subtitle
        Text(
          "Your AI Productivity Assistant",
          style: TextStyle(fontSize: 16, color: AppColors.secondary),
        ),
      ],
    );
  }
}
