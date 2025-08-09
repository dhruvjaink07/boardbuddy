import 'package:boardbuddy/core/utils/validators.dart';
import 'package:boardbuddy/features/auth/data/auth_repository.dart';
import 'package:boardbuddy/features/widgets/custom_text_field.dart';
import 'package:boardbuddy/features/auth/presentation/widgets/auth_button.dart';
import 'package:boardbuddy/features/auth/presentation/widgets/google_auth_button.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpForm extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onSubmit;

  const SignUpForm({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onSubmit,
  });

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = await AuthRepository().registerWithEmail(
        widget.emailController.text,
        widget.passwordController.text,
        widget.nameController.text,
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
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Name Field
            CustomTextField(
              hintText: 'Full Name',
              prefixIcon: Icons.person_outline,
              controller: widget.nameController,
              validator: FieldValidators.validateName,
            ),

            const SizedBox(height: 12),

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

            const SizedBox(height: 12),

            // Confirm Password Field
            CustomTextField(
              hintText: 'Confirm Password',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              controller: widget.confirmPasswordController,
              validator: (value) => FieldValidators.validateConfirmPassword(
                value,
                widget.passwordController.text,
              ),
            ),

            const SizedBox(height: 20),

            // Sign Up Button
            AuthButton(
              text: _isLoading ? "Signing Up..." : "Sign Up",
              onPressed: _isLoading ? null : _handleSignUp,
            ),

            const SizedBox(height: 20),

            // Google Auth Button
            GoogleAuthButton(
              authRepository: AuthRepository(),
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error ?? 'Unknown error')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
