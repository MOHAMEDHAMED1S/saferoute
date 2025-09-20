import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/validators.dart';
import '../../theme/liquid_glass_theme.dart';
import '../../widgets/liquid_glass_widgets.dart';

class RegisterScreen extends StatefulWidget {
  static const String routeName = '/register';

  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('يجب الموافقة على الشروط والأحكام'),
          backgroundColor: LiquidGlassTheme.getGradientByName('danger').colors.first,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success = await authProvider.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (mounted && success && authProvider.isLoggedIn) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء الحساب: ${e.toString()}'),
            backgroundColor: LiquidGlassTheme.getGradientByName('danger').colors.first,
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: LiquidGlassTheme.getTextColor('primary'),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  'إنشاء حساب جديد',
                  style: LiquidGlassTheme.headerTextStyle.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'أدخل بياناتك لإنشاء حساب جديد',
                  style: LiquidGlassTheme.bodyTextStyle.copyWith(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Name Field
                CustomTextField(
                  controller: _nameController,
                  label: 'الاسم الكامل',
                  validator: Validators.validateName,
                  prefixIcon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                // Email Field
                CustomTextField(
                  controller: _emailController,
                  label: 'البريد الإلكتروني',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                // Phone Field
                CustomTextField(
                  controller: _phoneController,
                  label: 'رقم الهاتف',
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                  prefixIcon: Icons.phone_outlined,
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
                const SizedBox(height: 16),
                // Confirm Password Field
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'تأكيد كلمة المرور',
                  obscureText: !_isConfirmPasswordVisible,
                  validator: (value) => Validators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // Terms and Conditions
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                      activeColor: LiquidGlassTheme.getTextColor('primary'),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _acceptTerms = !_acceptTerms;
                          });
                        },
                        child: Text(
                          'أوافق على الشروط والأحكام وسياسة الخصوصية',
                          style: LiquidGlassTheme.headerTextStyle.copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Register Button
                LiquidGlassButton(
                  text: 'إنشاء الحساب',
                  onPressed: _isLoading ? null : _handleRegister,
                  type: LiquidGlassType.primary,
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                const SizedBox(height: 24),
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'لديك حساب بالفعل؟ ',
                      style: LiquidGlassTheme.bodyTextStyle.copyWith(
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'تسجيل الدخول',
                        style: LiquidGlassTheme.primaryTextStyle.copyWith(
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