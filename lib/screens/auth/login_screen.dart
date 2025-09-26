import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
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
  bool _rememberMe = true; // خيار تذكرني

  @override
  void initState() {
    super.initState();
    _loadRememberMePreference();
  }

  Future<void> _loadRememberMePreference() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final rememberMe = await authProvider.getRememberMe();
    setState(() {
      _rememberMe = rememberMe;
    });
  }

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
      
      // تحديث تفضيل "تذكرني" قبل تسجيل الدخول
      await authProvider.setRememberMe(_rememberMe);
      
      bool success = await authProvider.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (success && authProvider.isLoggedIn) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else {
          String errorMessage =
              authProvider.errorMessage ?? 'فشل في تسجيل الدخول';

          // Show more helpful error dialog for authentication issues
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('خطأ في تسجيل الدخول'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(errorMessage),
                    SizedBox(height: 16),
                    if (errorMessage.contains(
                          'بيانات تسجيل الدخول غير صحيحة',
                        ) ||
                        errorMessage.contains('INVALID_LOGIN_CREDENTIALS'))
                      Text(
                        'تأكد من:\n• صحة البريد الإلكتروني\n• صحة كلمة المرور\n• أن الحساب موجود بالفعل',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('حسناً'),
                  ),
                  if (errorMessage.contains('بيانات تسجيل الدخول غير صحيحة'))
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushNamed('/register');
                      },
                      child: Text('إنشاء حساب جديد'),
                    ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تسجيل الدخول: ${e.toString()}'),
            backgroundColor: LiquidGlassTheme.getGradientByName(
              'danger',
            ).colors.first,
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
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else {
          String errorMessage =
              authProvider.errorMessage ?? 'فشل في تسجيل الدخول بـ Google';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: LiquidGlassTheme.getGradientByName(
                'danger',
              ).colors.first,
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
            backgroundColor: LiquidGlassTheme.getGradientByName(
              'danger',
            ).colors.first,
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

  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: LiquidGlassTheme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(
                  color: LiquidGlassTheme.getGradientByName(
                    'primary',
                  ).colors.first.withOpacity(0.5),
                  width: 1,
                ),
              ),
              title: Text(
                'استرداد كلمة المرور',
                style: LiquidGlassTheme.headerTextStyle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: Container(
                width: double.maxFinite,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: LiquidGlassTheme.getGradientByName(
                            'info',
                          ).colors.first.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: LiquidGlassTheme.getGradientByName(
                                'info',
                              ).colors.first,
                              size: 24,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور',
                                style: LiquidGlassTheme.bodyTextStyle.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      CustomTextField(
                        controller: emailController,
                        label: 'البريد الإلكتروني',
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                        prefixIcon: Icons.email_outlined,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: LiquidGlassTheme.primaryGlass,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: LiquidGlassTheme.getGradientByName(
                                'primary',
                              ).colors.first.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: LiquidGlassTheme.getGradientByName(
                                'primary',
                              ).colors.first,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: LiquidGlassTheme.getTextColor(
                            'secondary',
                          ),
                        ),
                        child: Text(
                          'إلغاء',
                          style: LiquidGlassTheme.bodyTextStyle.copyWith(
                            fontSize: 16,
                          ),
                        ),
                      ),
                      isLoading
                          ? Container(
                              width: 100,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LiquidGlassTheme.getGradientByName(
                                  'primary',
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  setState(() {
                                    isLoading = true;
                                  });

                                  try {
                                    final authProvider =
                                        Provider.of<AuthProvider>(
                                          context,
                                          listen: false,
                                        );
                                    bool success = await authProvider
                                        .resetPassword(
                                          emailController.text.trim(),
                                        );

                                    if (mounted) {
                                      Navigator.of(context).pop();

                                      if (success) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
                                                  ),
                                                ),
                                              ],
                                            ),
                                            backgroundColor:
                                                LiquidGlassTheme.getGradientByName(
                                                  'success',
                                                ).colors.first,
                                            duration: const Duration(
                                              seconds: 4,
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      } else {
                                        String errorMessage =
                                            authProvider.errorMessage ??
                                            'فشل في إرسال رابط إعادة تعيين كلمة المرور';
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(errorMessage),
                                                ),
                                              ],
                                            ),
                                            backgroundColor:
                                                LiquidGlassTheme.getGradientByName(
                                                  'danger',
                                                ).colors.first,
                                            duration: const Duration(
                                              seconds: 4,
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  'خطأ في إرسال رابط إعادة تعيين كلمة المرور: ${e.toString()}',
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor:
                                              LiquidGlassTheme.getGradientByName(
                                                'danger',
                                              ).colors.first,
                                          duration: const Duration(seconds: 4),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LiquidGlassTheme.getGradientByName(
                                    'primary',
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    'إرسال',
                                    style: LiquidGlassTheme.headerTextStyle
                                        .copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              LiquidGlassTheme.whiteTextColor,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
                  width: 150,
                  height: 150,
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.security,
                        color: Colors.grey,
                        size: 150,
                      );
                    },
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
                  style: LiquidGlassTheme.bodyTextStyle.copyWith(fontSize: 16),
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
                const SizedBox(height: 16),
                // Remember Me Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? true;
                        });
                      },
                      activeColor: LiquidGlassTheme.getGradientByName('primary').colors.first,
                    ),
                    Text(
                      'تذكرني',
                      style: LiquidGlassTheme.bodyTextStyle.copyWith(fontSize: 16),
                    ),
                    const Spacer(),
                    // Forgot Password
                    TextButton(
                      onPressed: () {
                        _showForgotPasswordDialog();
                      },
                      child: Text(
                        'نسيت كلمة المرور؟',
                        style: LiquidGlassTheme.primaryTextStyle.copyWith(
                          color: LiquidGlassTheme.getTextColor('primary'),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
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
                      child: Text('أو', style: LiquidGlassTheme.bodyTextStyle),
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
                        Navigator.of(
                          context,
                        ).pushNamed(RegisterScreen.routeName);
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
