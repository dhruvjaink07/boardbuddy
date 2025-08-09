import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ForgotPasswordLink extends StatelessWidget {
  final VoidCallback? onPressed;

  const ForgotPasswordLink({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: onPressed ?? () {},
        child: Text(
          "Forgot Password?",
          style: TextStyle(color: AppColors.primary, fontSize: 14),
        ),
      ),
    );
  }
}
