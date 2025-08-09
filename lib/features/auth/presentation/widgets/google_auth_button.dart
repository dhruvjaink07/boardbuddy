import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/auth/data/auth_repository.dart';
import 'package:boardbuddy/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleAuthButton extends StatelessWidget {
  final AuthRepository authRepository;
  final void Function(String? error)? onError;

  const GoogleAuthButton({Key? key, required this.authRepository, this.onError})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider with text
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.secondary)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                "Or continue with",
                style: TextStyle(color: AppColors.secondary, fontSize: 12),
              ),
            ),
            Expanded(child: Divider(color: AppColors.secondary)),
          ],
        ),

        const SizedBox(height: 20),

        // Google Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              try {
                final user = await authRepository.signInWithGoogle();
                if (user == null && onError != null) {
                  onError!("Sign in cancelled.");
                }
                // Set is_logged_in = true
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_logged_in', true);

                Get.toNamed(AppRoutes.mainScreen);
              } catch (e) {
                if (onError != null) {
                  onError!(e.toString());
                }
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google "G" icon
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      "G",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Continue with Google",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
