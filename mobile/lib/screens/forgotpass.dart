import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/authService.dart';
import '../widgets/appButton.dart';
import '../widgets/appField.dart';
import '../widgets/authWidgets.dart';
import '../app.dart';

class ForgotPasswordScreen extends StatefulWidget{
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>{
  final _emailCtrl = TextEditingController();
  final _auth = AuthService();

  bool _isLoading = false;
  bool _submitted = false;
  String _message = '';

  @override
  void dispose(){
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async{
    setState((){
      _message = '';
      _isLoading = true;
    });

    if (_emailCtrl.text.trim().isEmpty){
      setState(() {
        _message = 'Please enter your email address.';
        _isLoading = false;
      });
      return;
    }

    final result = await _auth.forgotPassword(email: _emailCtrl.text);
    if (!mounted) return;

    if (result.success){
      setState(() {
        _submitted = true;
        _isLoading = false;
      });
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
    return AuthScaffold(
      child: AuthCard(
        children: [
          BackCircleButton(onPressed: () => context.go('/')),
          const SizedBox(height: 24),

          const Center(child: AuthTitle('FORGOT PASSWORD')),
          const SizedBox(height: 16),

          if (!_submitted) ...[
            const Text(
              'Enter the email associated with your account and we\'ll send you a link to reset your password.',
              style: TextStyle(
                  fontSize: 14, color: AppColors.textSub, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            AppField(
              label: 'Email',
              placeholder: 'Enter your email',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
            ),

            AppButton(
              label: _isLoading ? 'Sending...' : 'Send Reset Link',
              isLoading: _isLoading,
              onPressed: _handleSubmit,
            ),

            if (_message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Center(child: StatusText(_message, isError: true)),
            ],
          ] else ...[
            //success state
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x1A86EFAC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x3386EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Email Sent',
                          style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'If an account exists for ${_emailCtrl.text.trim()}, a password reset link has been sent.',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSub),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Back to Login',
              onPressed: () => context.go('/login'),
            ),
          ],
        ],
      ),
    );
  }
}
