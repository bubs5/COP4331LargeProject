import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/authService.dart';
import '../widgets/appButton.dart';
import '../widgets/appField.dart';
import '../widgets/authWidgets.dart';
import '../app.dart';

class RegisterScreen extends StatefulWidget{
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>{
  final _firstNameCtrl      = TextEditingController();
  final _lastNameCtrl       = TextEditingController();
  final _usernameCtrl       = TextEditingController();
  final _emailCtrl          = TextEditingController();
  final _passwordCtrl       = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _auth = AuthService();

  bool _isLoading = false;
  String _message = '';
  bool _isSuccess = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async{
    setState(() {
      _message = '';
      _isLoading = true;
    });

    final fields = [
      _firstNameCtrl.text,
      _lastNameCtrl.text,
      _usernameCtrl.text,
      _emailCtrl.text,
      _passwordCtrl.text,
      _confirmPasswordCtrl.text,
    ];

    if (fields.any((f) => f.trim().isEmpty)){
      setState(() {
        _message = 'Please fill in all fields.';
        _isLoading = false;
      });
      return;
    }

    if (_passwordCtrl.text != _confirmPasswordCtrl.text){
      setState(() {
        _message = 'Passwords do not match.';
        _isLoading = false;
      });
      return;
    }

    final result = await _auth.register(
      firstName: _firstNameCtrl.text,
      lastName:  _lastNameCtrl.text,
      username:  _usernameCtrl.text,
      email:     _emailCtrl.text,
      password:  _passwordCtrl.text,
    );

    if (!mounted) return;

    if (result.success){
      setState((){
        _isSuccess = true;
        _message = result.message ?? 'Account created! Please log in.';
        _isLoading = false;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) context.go('/login');
    }
    else{
      setState((){
        _message = result.error ?? 'Registration failed.';
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

          const Center(child: AuthTitle('SIGN UP')),
          const SizedBox(height: 28),


          Row(
            children: [
              Expanded(
                child: AppField(
                  label: 'First Name',
                  placeholder: 'First name',
                  controller: _firstNameCtrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppField(
                  label: 'Last Name',
                  placeholder: 'Last name',
                  controller: _lastNameCtrl,
                ),
              ),
            ],
          ),

          AppField(
            label: 'Username',
            placeholder: 'Create username',
            controller: _usernameCtrl,
          ),
          AppField(
            label: 'Email',
            placeholder: 'Enter email',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
          AppField(
            label: 'Password',
            placeholder: 'Create password',
            controller: _passwordCtrl,
            obscureText: true,
          ),
          AppField(
            label: 'Confirm Password',
            placeholder: 'Confirm password',
            controller: _confirmPasswordCtrl,
            obscureText: true,
          ),

          AppButton(
            label: _isLoading ? 'Creating Account' : 'Create Account',
            isLoading: _isLoading,
            onPressed: _handleRegister,
          ),
          const SizedBox(height: 18),

          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textMuted),
                ),
                LinkText('Login', onTap: () => context.go('/login')),
              ],
            ),
          ),

          if (_message.isNotEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: StatusText(
                _message,
                isSuccess: _isSuccess,
                isError: !_isSuccess,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
