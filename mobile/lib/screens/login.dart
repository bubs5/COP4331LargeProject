import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/rewards_controller.dart';
import '../services/authService.dart';
import '../widgets/appButton.dart';
import '../widgets/appField.dart';
import '../widgets/authWidgets.dart';
import '../app.dart';

class LoginScreen extends StatefulWidget{
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>{
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _auth = AuthService();

  bool _isLoading = false;
  String _message = '';

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    setState(() {
      _message = '';
      _isLoading = true;
    });

    if (_usernameCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.trim().isEmpty) {
      setState(() {
        _message = 'Please enter both username and password.';
        _isLoading = false;
      });
      return;
    }

    final result = await _auth.login(
      username: _usernameCtrl.text,
      password: _passwordCtrl.text,
    );

    if (!mounted) return;

    if (result.success) {
      await rewardsController.init();
      await rewardsController.award('daily_login');
      if (!mounted) return;
      context.go('/dashboard');
    }
    else {
      setState(() {
        _message = result.error ?? 'Login failed.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context){
    return AuthScaffold(
      child: AuthCard(
        children: [
          //back button
          BackCircleButton(onPressed: () => context.go('/')),
          const SizedBox(height: 24),

          //title
          const Center(child: AuthTitle('LOGIN')),
          const SizedBox(height: 28),

          //fields
          AppField(
            label: 'Username',
            placeholder: 'Enter username',
            controller: _usernameCtrl,
          ),
          AppField(
            label: 'Password',
            placeholder: 'Enter password',
            controller: _passwordCtrl,
            obscureText: true,
          ),

          //forgot password
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => context.go('/forgot-password'),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textLink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          AppButton(
            label: _isLoading ? 'Logging In' : 'Login',
            isLoading: _isLoading,
            onPressed: _doLogin,
          ),
          const SizedBox(height: 18),

          //sign up link
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textMuted),
                ),
                LinkText('Sign up', onTap: () => context.go('/register')),
              ],
            ),
          ),

          //error
          if (_message.isNotEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: StatusText(_message, isError: true),
            ),
          ],
        ],
      ),
    );
  }
}
