import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AuthFooter extends StatelessWidget {
  final VoidCallback? onTermsPressed;
  final VoidCallback? onPrivacyPressed;

  const AuthFooter({super.key, this.onTermsPressed, this.onPrivacyPressed});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: "By continuing, you agree to our ",
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        children: [
          WidgetSpan(
            child: GestureDetector(
              onTap: onTermsPressed ?? () {},
              child: Text(
                "Terms of Service",
                style: TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ),
          ),
          const TextSpan(text: " and "),
          WidgetSpan(
            child: GestureDetector(
              onTap: onPrivacyPressed ?? () {},
              child: Text(
                "Privacy Policy",
                style: TextStyle(color: AppColors.primary, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
