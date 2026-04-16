import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/authService.dart';
import '../widgets/appButton.dart';
import '../widgets/authWidgets.dart';
import '../app.dart';

class VerifyEmailScreen extends StatefulWidget{
  final String? token;
  const VerifyEmailScreen({super.key, this.token});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>{
  final _auth = AuthService();
  String _status = 'loading';
  String _message = '';

  @override
  void initState() {
    super.initState();
    _verifyToken();
  }

  Future<void> _verifyToken() async{
    if (widget.token == null || widget.token!.isEmpty){
      setState(() {
        _status = 'error';
        _message = 'Invalid or missing verification link. Please register again.';
      });
      return;
    }

    final result = await _auth.verifyEmail(token: widget.token!);
    if (!mounted) return;

    if (result.success){
      setState((){
        _status = 'success';
        _message = result.message ?? 'Email verified successfully!';
      });
    }
    else{
      setState((){
        _status = 'error';
        _message = result.error ?? 'Verification failed. The link may have expired.';
      });
    }
  }

  @override
  Widget build(BuildContext context){
    return AuthScaffold(
      child: AuthCard(
        children: [
          const Center(child: AuthTitle('EMAIL VERIFICATION')),
          const SizedBox(height: 32),

          if (_status == 'loading') ...[
            const Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Verifying your email',
                style: TextStyle(color: AppColors.textSub, fontSize: 14),
              ),
            ),
          ] else if (_status == 'success') ...[
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
                    child: Text(
                      _message,
                      style: const TextStyle(
                          color: AppColors.success, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'You can now log in to your account.',
              style: TextStyle(color: AppColors.textSub, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Go to Login',
              onPressed: () => context.go('/login'),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x4DF87171)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _message,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Back to Sign Up',
              onPressed: () => context.go('/register'),
            ),
          ],
        ],
      ),
    );
  }
}
