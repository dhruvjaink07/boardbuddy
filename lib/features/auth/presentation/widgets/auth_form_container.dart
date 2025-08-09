import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/features/auth/presentation/widgets/login_form.dart';
import 'package:boardbuddy/features/auth/presentation/widgets/signup_form.dart';
import 'package:flutter/material.dart';

class AuthFormContainer extends StatelessWidget {
  final TabController tabController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController nameController;
  final VoidCallback onTabChanged;
  final VoidCallback onSubmit;

  const AuthFormContainer({
    super.key,
    required this.tabController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.nameController,
    required this.onTabChanged,
    required this.onSubmit,
  });

  double _getCurrentTabHeight() {
    if (tabController.index == 0) {
      return 380; // Login form height
    } else {
      return 480; // Sign up form height (more fields)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.all(16),
            child: TabBar(
              controller: tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.secondary,
              indicatorColor: AppColors.primary,
              dividerColor: Colors.transparent,
              onTap: (index) => onTabChanged(),
              tabs: const [
                Tab(text: "Login"),
                Tab(text: "Sign Up"),
              ],
            ),
          ),

          // Form Content
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _getCurrentTabHeight(),
            child: TabBarView(
              controller: tabController,
              children: [
                // Login Form
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: LoginForm(
                    emailController: emailController,
                    passwordController: passwordController,
                    onSubmit: onSubmit,
                  ),
                ),
                // Sign Up Form
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: SignUpForm(
                    nameController: nameController,
                    emailController: emailController,
                    passwordController: passwordController,
                    confirmPasswordController: confirmPasswordController,
                    onSubmit: onSubmit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
