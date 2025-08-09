import 'package:boardbuddy/core/theme/app_colors.dart';
import 'package:boardbuddy/core/utils/validators.dart';
import 'package:boardbuddy/features/widgets/custom_text_field.dart';
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

                  SizedBox(
                    width: 50,
                    height: 50,

                    child: Image.asset(
                      'assets/icons/logo.png',
                      fit: BoxFit.cover,
                    ),
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
                  Text(
                    "Your AI Productivity Assistant",
                    style: TextStyle(fontSize: 16, color: AppColors.secondary),
                  ),

                  const SizedBox(height: 60),

                  Container(
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
                            controller: _tabController,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.secondary,
                            indicatorColor: AppColors.primary,
                            dividerColor: Colors.transparent,
                            onTap: (index) {
                              // Clear form when switching tabs
                              _formKey.currentState?.reset();
                              _emailController.clear();
                              _passwordController.clear();
                              _confirmPasswordController.clear();
                              _nameController.clear();
                            },
                            tabs: const [
                              Tab(text: "Login"),
                              Tab(text: "Sign Up"),
                            ],
                          ),
                        ),

                        // Form Content with proper height management
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: _getCurrentTabHeight(),
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Login Form
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  20,
                                ),
                                child: _buildLoginForm(),
                              ),
                              // Sign Up Form
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  20,
                                ),
                                child: _buildSignUpForm(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Terms and Privacy
                  Text.rich(
                    TextSpan(
                      text: "By continuing, you agree to our ",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: "Terms of Service",
                          style: TextStyle(color: AppColors.primary),
                        ),
                        const TextSpan(text: " and "),
                        TextSpan(
                          text: "Privacy Policy",
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Dynamic height calculation
  double _getCurrentTabHeight() {
    if (_tabController?.index == 0) {
      return 380; // Login form height
    } else {
      return 480; // Sign up form height (more fields)
    }
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // Email Field
        CustomTextField(
          hintText: 'Email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          controller: _emailController,
          validator: FieldValidators.validateEmail,
        ),

        const SizedBox(height: 12),

        // Password Field
        CustomTextField(
          hintText: 'Password',
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          controller: _passwordController,
          validator: FieldValidators.validatePassword,
        ),

        const SizedBox(height: 20),

        // Continue Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: _handleSubmit,
            child: const Text(
              "Continue",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        const SizedBox(height: 20),
        _buildDividerAndGoogleButton(),
        const SizedBox(height: 16),
        _buildForgotPassword(),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Name Field
          CustomTextField(
            hintText: 'Full Name',
            prefixIcon: Icons.person_outline,
            controller: _nameController,
            validator: FieldValidators.validateName,
          ),

          const SizedBox(height: 12),

          // Email Field
          CustomTextField(
            hintText: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
            validator: FieldValidators.validateEmail,
          ),

          const SizedBox(height: 12),

          // Password Field
          CustomTextField(
            hintText: 'Password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            controller: _passwordController,
            validator: FieldValidators.validatePassword,
          ),

          const SizedBox(height: 12),

          // Confirm Password Field
          CustomTextField(
            hintText: 'Confirm Password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            controller: _confirmPasswordController,
            validator: (value) => FieldValidators.validateConfirmPassword(
              value,
              _passwordController.text,
            ),
          ),

          const SizedBox(height: 20),

          // Sign Up Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: _handleSubmit,
              child: const Text(
                "Sign Up",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 20),
          _buildDividerAndGoogleButton(),
        ],
      ),
    );
  }

  Widget _buildDividerAndGoogleButton() {
    return Column(
      children: [
        // Or Continue with
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
            onPressed: () {},
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Simple Google "G" icon
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

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {},
        child: Text(
          "Forgot Password?",
          style: TextStyle(color: AppColors.primary, fontSize: 14),
        ),
      ),
    );
  }
}
