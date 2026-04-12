import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/authService.dart';
import '../widgets/appButton.dart';
import '../widgets/appField.dart';
import '../widgets/authWidgets.dart';
import '../app.dart';

class ResetPasswordScreen extends StatefulWidget{
  final String? token;
  const ResetPasswordScreen({super.key, this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>{
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _auth = AuthService();

  bool _isLoading = false;
  bool _success   = false;
  String _message = '';

  @override
  void dispose(){
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async{
    setState(() { _message = ''; _isLoading = true; });

    if (_passwordCtrl.text.isEmpty || _confirmCtrl.text.isEmpty){
      setState(() { _message = 'Please fill in all fields.'; _isLoading = false; });
      return;
    }
    if (_passwordCtrl.text != _confirmCtrl.text){
      setState(() { _message = 'Passwords do not match.'; _isLoading = false; });
      return;
    }


    final result = await _auth.resetPassword(
      token: widget.token ?? '',
      password: _passwordCtrl.text,
    );
    if (!mounted) return;

    if (result.success){
      setState(() { _success = true; _isLoading = false; });
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) context.go('/login');
    }
    else{
      setState((){
        _message = result.error ?? 'Server error. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context){
    //invalid
    if (widget.token == null || widget.token!.isEmpty){
      return AuthScaffold(
        child: AuthCard(
          children: [
            const Center(child: AuthTitle('RESET PASSWORD')),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x4DF87171)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Invalid or expired reset link. Please request a new one.',
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Request New Link',
              onPressed: () => context.go('/forgot-password'),
            ),
          ],
        ),
      );
    }

    return AuthScaffold(
      child: AuthCard(
        children: [
          BackCircleButton(onPressed: () => context.go('/login')),
          const SizedBox(height: 24),
          const Center(child: AuthTitle('RESET PASSWORD')),
          const SizedBox(height: 28),

          if (!_success) ...[
            AppField(
              label: 'New Password',
              placeholder: 'Enter new password',
              controller: _passwordCtrl,
              obscureText: true,
            ),
            AppField(
              label: 'Confirm New Password',
              placeholder: 'Confirm new password',
              controller: _confirmCtrl,
              obscureText: true,
            ),
            AppButton(
              label: _isLoading ? 'Resetting' : 'Reset Password',
              isLoading: _isLoading,
              onPressed: _handleSubmit,
            ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Center(child: StatusText(_message, isError: true)),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x1A86EFAC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x3386EFAC)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Password reset successfully! Redirecting to login.',
                      style: TextStyle(color: AppColors.success, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
