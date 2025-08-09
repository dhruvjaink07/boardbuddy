import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/core/utils/validators.dart';
import 'package:boardbuddy/features/auth/presentation/widgets/auth_header.dart';
import 'package:boardbuddy/features/auth/presentation/widgets/auth_form_container.dart';
import 'package:boardbuddy/features/auth/presentation/widgets/auth_footer.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    _tabController?.addListener(() {
      setState(() {}); // Trigger rebuild when tab changes
    });
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      // Handle login/signup logic here
      print('Form is valid!');
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _nameController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Header with logo and title
                  const AuthHeader(),

                  const SizedBox(height: 60),

                  // Form container with tabs and forms
                  AuthFormContainer(
                    tabController: _tabController!,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    nameController: _nameController,
                    onTabChanged: _clearForm,
                    onSubmit: _handleSubmit,
                  ),

                  const SizedBox(height: 20),

                  // Footer with terms and privacy
                  const AuthFooter(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
