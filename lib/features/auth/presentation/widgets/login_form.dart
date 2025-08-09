import 'package:boardbuddy/core/utils/validators.dart';
import 'package:boardbuddy/features/auth/data/auth_repository.dart';
import 'package:boardbuddy/features/widgets/custom_text_field.dart';
import 'package:boardbuddy/features/auth/presentation/widgets/auth_button.dart';
import 'package:boardbuddy/features/auth/presentation/widgets/google_auth_button.dart';
import 'package:boardbuddy/features/auth/presentation/widgets/forgot_password_link.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginForm extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;

  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = await AuthRepository().signInWithEmail(
        widget.emailController.text,
        widget.passwordController.text,
      );
      if (user != null) {
        widget.onSubmit();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email Field
          CustomTextField(
            hintText: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            controller: widget.emailController,
            validator: FieldValidators.validateEmail,
          ),

          const SizedBox(height: 12),

          // Password Field
          CustomTextField(
            hintText: 'Password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            controller: widget.passwordController,
            validator: FieldValidators.validatePassword,
          ),

          const SizedBox(height: 20),

          // Continue Button
          AuthButton(
            text: _isLoading ? "Signing In..." : "Continue",
            onPressed: _isLoading ? null : _handleSignIn,
            isLoading: _isLoading,
          ),

          const SizedBox(height: 20),

          // Google Auth Button
          GoogleAuthButton(
            authRepository: AuthRepository(),
            onError: (error) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(error ?? 'Unknown error')));
            },
          ),

          const SizedBox(height: 16),

          // Forgot Password Link
          const ForgotPasswordLink(),
        ],
      ),
    );
  }
}
