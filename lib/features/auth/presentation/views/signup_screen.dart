import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rmn_accounts/utils/views.dart';
import '../../../../core/config/app_constants.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmpasswordController = TextEditingController();
  String _selectedRole = UserRole.accountant.name;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final loadingProvider = context.read<LoadingProvider>();
    loadingProvider.startLoading();
    try {
      await Future.delayed((Duration(seconds: 3)));
      await authProvider
          .signUp(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _confirmpasswordController.text.trim(),
            _selectedRole,
          )
          .then((_) {
            loadingProvider.stopLoading();
          });
    } catch (e) {
      loadingProvider.stopLoading();
    } finally {
      loadingProvider.stopLoading();
    }

    if (authProvider.errorMessage == null && context.mounted) {
      Navigator.pushReplacementNamed(context, RouteNames.signin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // appBar: AppBar(title: const Text('Create Account')),
      body: LoadingOverlay(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.sp),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blueAccent,
                const Color.fromARGB(173, 245, 127, 23),
                Color.fromRGBO(234, 206, 280, 1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Dont have Account?',
                  style: GoogleFonts.chewy(
                    letterSpacing: 2,
                    fontSize: 18.sp,

                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 5.sp),
                Text('Sign Up here', style: TextStyle(fontSize: 13.sp)),
                SizedBox(height: 20.sp),
                CustomTextFormField(
                  controller: _nameController,
                  labelText: 'Name',
                  prefixIcon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextFormField(
                  controller: _emailController,
                  labelText: 'Email',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    // if (!RegExp(
                    //   r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    // ).hasMatch(value)) {
                    //   return 'Please enter a valid email';
                    // }
                    // return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextFormField(
                  controller: _passwordController,
                  labelText: 'Password',
                  prefixIcon: Icons.lock,
                  obscureText: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextFormField(
                  controller: _confirmpasswordController,
                  labelText: 'Confirm Password',
                  prefixIcon: Icons.lock,
                  obscureText: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Container(
                  width: 60.sp,
                  child: DropdownButtonFormField<String>(
                    value: _selectedRole.isEmpty ? null : _selectedRole,
                    items:
                        UserRole.signUpRoles
                            .map(
                              (role) => DropdownMenuItem<String>(
                                value: role.name,
                                child: Text(role.displayName),
                              ),
                            )
                            .toList(),
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    onChanged:
                        (value) => setState(() => _selectedRole = value ?? ''),
                  ),
                ),

                const SizedBox(height: 40),
                if (authProvider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      authProvider.errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                AuthRoundBtn(
                  title: 'Create Account',
                  // loading: authProvider.isLoading,
                  onTap: _submitForm,
                ),
                // ElevatedButton(
                //   onPressed: authProvider.isLoading ? null : _submitForm,
                //   child: const Text('Create Account'),
                // ),
                // TextButton(
                //   onPressed:
                //       () => Navigator.pushReplacementNamed(
                //         context,
                //         RouteNames.signin,
                //       ),
                //   child: const Text('Already have an account? Sign In'),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
