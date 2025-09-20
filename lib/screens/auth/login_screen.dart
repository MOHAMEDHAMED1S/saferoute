import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/validators.dart';
import 'register_screen.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/liquid_glass_widgets.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success = await authProvider.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (success && authProvider.isLoggedIn) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          String errorMessage = authProvider.errorMessage ?? 'فشل في تسجيل الدخول';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: LiquidGlassTheme.getGradientByName('danger').colors.first,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الدخول: ${e.toString()}'),
            backgroundColor: LiquidGlassTheme.getGradientByName('danger').colors.first,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success = await authProvider.signInWithGoogle();

      if (mounted) {
        if (success && authProvider.isLoggedIn) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          String errorMessage = authProvider.errorMessage ?? 'فشل في تسجيل الدخول بـ Google';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: LiquidGlassTheme.getGradientByName('danger').colors.first,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الدخول بـ Google: ${e.toString()}'),
            backgroundColor: LiquidGlassTheme.getGradientByName('danger').colors.first,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiquidGlassTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                // Logo
                Container(
                  height: 120,
                  child: Icon(
                    Icons.security,
                    size: 80,
                    color: LiquidGlassTheme.getTextColor('primary'),
                  ),
                ),
                const SizedBox(height: 40),
                // Title
                Text(
                  'مرحباً بك',
                  style: LiquidGlassTheme.headerTextStyle.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'سجل دخولك للمتابعة',
                  style: LiquidGlassTheme.bodyTextStyle.copyWith(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Email Field
                CustomTextField(
                  controller: _emailController,
                  label: 'البريد الإلكتروني',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  label: 'كلمة المرور',
                  obscureText: !_isPasswordVisible,
                  validator: Validators.validatePassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // Login Button
                LiquidGlassButton(
                  text: 'تسجيل الدخول',
                  onPressed: _isLoading ? null : _handleLogin,
                  type: LiquidGlassType.primary,
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                const SizedBox(height: 16),
                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'أو',
                        style: LiquidGlassTheme.bodyTextStyle,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                // Google Sign In Button
                LiquidGlassButton(
                  text: 'تسجيل الدخول بـ Google',
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  type: LiquidGlassType.secondary,
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  icon: Icons.login,
                ),
                const SizedBox(height: 24),
                // Forgot Password
                TextButton(
                  onPressed: () {
                    // TODO: Implement forgot password
                  },
                  child: Text(
                    'نسيت كلمة المرور؟',
                    style: LiquidGlassTheme.primaryTextStyle.copyWith(
                      color: LiquidGlassTheme.getTextColor('primary'),
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ليس لديك حساب؟ ',
                      style: LiquidGlassTheme.bodyTextStyle.copyWith(
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(RegisterScreen.routeName);
                      },
                      child: Text(
                        'إنشاء حساب',
                        style: LiquidGlassTheme.headerTextStyle.copyWith(
          color: LiquidGlassTheme.getTextColor('primary'),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}