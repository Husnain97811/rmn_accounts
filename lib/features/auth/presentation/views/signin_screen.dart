import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:rmn_accounts/utils/views.dart';
import 'package:url_launcher/url_launcher.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final loadingProvider = context.read<LoadingProvider>();
    final authProvider = context.read<AuthProvider>();

    try {
      loadingProvider.startLoading();

      await authProvider
          .signIn(
            context,
            _emailController.text.trim(),
            _passwordController.text.trim(),
          )
          .then((_) async {
            // In your auth handler or login success callback:
            await Provider.of<ProfileProvider>(
              context,
              listen: false,
            ).loadProfile();
          });

      if (context.mounted) {
        SupabaseExceptionHandler.showSuccessSnackbar(
          context,
          'Signed in successfully!',
        );
        Navigator.pushReplacementNamed(context, RouteNames.sidebar);
      }
    } catch (e) {
      if (context.mounted) {
        SupabaseExceptionHandler.showErrorSnackbar(
          context,
          SupabaseExceptionHandler.handleSupabaseError(e),
        );
      }
    } finally {
      if (context.mounted) {
        loadingProvider.stopLoading();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadingProvider = context.watch<LoadingProvider>();

    return Scaffold(
      // appBar: AppBar(title: const Text('Sign In')),
      body: LoadingOverlay(
        child: Form(
          key: _formKey,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Welcome Back!',
                  style: GoogleFonts.akayaKanadaka(
                    fontSize: 25.sp,

                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 20.sp),

                CustomTextFormField(
                  maxLines: 1,
                  contentpadding: EdgeInsets.symmetric(vertical: 14.sp),
                  controller: _emailController,
                  labelText: 'Email',

                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),
                CustomTextFormField(
                  maxLines: 1,
                  controller: _passwordController,
                  contentpadding: EdgeInsets.symmetric(vertical: 11.5.sp),
                  // textAlignVertical: TextAlignVertical.center, // Added this line
                  labelText: 'Password',
                  prefixIcon: Icons.lock,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed:
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                const SizedBox(height: 40),
                AuthRoundBtn(
                  title: 'Sign in',
                  // loading: loadingProvider.isLoading,
                  onTap: _submitForm,
                ),
                const SizedBox(height: 20),

                const SizedBox(height: 20),
                TextButton(
                  onPressed:
                      () => Navigator.pushNamed(context, RouteNames.forgotPass),

                  child: const Text('Forgot Password?'),
                ),
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: Container(
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () async {
            const url = 'https://www.inoverstudio.com/';
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );
            }
          },
          label: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: [
                  Colors.blueAccent,
                  Color.fromRGBO(98, 34, 148, 1),
                  Color.fromRGBO(98, 34, 148, 1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: Text(
              '@ Inover Studio',
              style: GoogleFonts.akayaKanadaka(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white, // This will be masked by the shader
              ),
              overflow: TextOverflow.visible,
              softWrap: true,
            ),
          ),
        ),
      ),
    );
  }
}
