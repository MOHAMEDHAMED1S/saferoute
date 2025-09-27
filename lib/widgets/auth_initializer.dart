import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Widget that ensures AuthProvider is properly initialized before showing content
class AuthInitializer extends StatefulWidget {
  final Widget child;
  final Widget? loadingWidget;

  const AuthInitializer({Key? key, required this.child, this.loadingWidget})
    : super(key: key);

  @override
  State<AuthInitializer> createState() => _AuthInitializerState();
}

class _AuthInitializerState extends State<AuthInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Wait for AuthProvider to be initialized
      while (!authProvider.isInitialized) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('AuthInitializer: خطأ في تهيئة المصادقة: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return widget.loadingWidget ?? const _DefaultLoadingWidget();
    }

    return widget.child;
  }
}

class _DefaultLoadingWidget extends StatelessWidget {
  const _DefaultLoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'جاري التحميل...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

