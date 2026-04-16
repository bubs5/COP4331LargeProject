import 'dart:convert';
import 'package:http/http.dart' as http;
import 'localstorage.dart';
import '../config.dart';

//response models
class LoginResult{
  final bool success;
  final String? error;
  final Map<String, dynamic>? userData;

  LoginResult({required this.success, this.error, this.userData});
}

class AuthResult{
  final bool success;
  final String? error;
  final String? message;

  AuthResult({required this.success, this.error, this.message});
}


//auth service
class AuthService{
  static const String _userKey = 'user_data';

  //login
  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    if (AppConfig.useMockData){
      // mock will accept any nonempty cred
      if (username.trim().isEmpty || password.trim().isEmpty){
        return LoginResult(success: false, error: 'Please enter both fields.');
      }
      final userData = {
        'id': 1,
        'firstName': 'Test',
        'lastName': 'User',
        'username': username.trim(),
        'token': 'mock-token',
      };
      await LocalStorageService.saveString(_userKey, jsonEncode(userData));
      return LoginResult(success: true, userData: userData);
    }

    try{
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/login'), //api
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'login': username.trim(), 'password': password}),
      );

      final res = jsonDecode(response.body) as Map<String, dynamic>;

      if (!response.statusCode.toString().startsWith('2') ||
          (res['id'] == null || (res['id'] as int) <= 0)){
        return LoginResult(
          success: false,
          error: res['error'] ?? 'User/Password combination incorrect',
        );
      }

      final userData = {
        'id': res['id'],
        'firstName': res['firstName'],
        'lastName': res['lastName'],
        'username': res['login'],
        'token': res['token'] ?? '',
      };

      await LocalStorageService.saveString(_userKey, jsonEncode(userData));
      return LoginResult(success: true, userData: userData);
    }
    catch (_){
      return LoginResult(success: false, error: 'Unable to connect to server.');
    }
  }

  //register
  Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    if (AppConfig.useMockData){
      await Future.delayed(const Duration(milliseconds: 500));
      return AuthResult(
        success: true,
        message: 'Account created successfully. Please log in.',
      );
    }
    //api
    try{
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'login': username.trim(),
          'email': email.trim(),
          'password': password,
        }),
      );

      final res = jsonDecode(response.body) as Map<String, dynamic>;

      if (!response.statusCode.toString().startsWith('2')){
        return AuthResult(
          success: false,
          error: res['error'] ?? 'Server error. Please try again.',
        );
      }

      if (res['error'] != null && (res['error'] as String).isNotEmpty){
        return AuthResult(success: false, error: res['error']);
      }

      return AuthResult(
        success: true,
        message: res['message'] ?? 'Account created successfully.',
      );
    } catch (_) {
      return AuthResult(success: false, error: 'Unable to connect to server.');
    }
  }

  // forgot password
  Future<AuthResult> forgotPassword({required String email}) async {
    if (AppConfig.useMockData){
      await Future.delayed(const Duration(milliseconds: 500));
      return AuthResult(success: true);
    }

    try{
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim()}),
      );

      final res = jsonDecode(response.body) as Map<String, dynamic>;

      if (!response.statusCode.toString().startsWith('2')){
        return AuthResult(
          success: false,
          error: res['error'] ?? 'Server error. Please try again.',
        );
      }

      return AuthResult(success: true);
    }
    catch (_){
      return AuthResult(success: false, error: 'Unable to connect to server.');
    }
  }

  // reset password
  Future<AuthResult> resetPassword({
    required String token,
    required String password,
  }) async{
    if (AppConfig.useMockData){
      await Future.delayed(const Duration(milliseconds: 500));
      return AuthResult(
        success: true,
        message: 'Password reset successfully.',
      );
    }

    try{
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'password': password}),
      );

      final res = jsonDecode(response.body) as Map<String, dynamic>;

      if (!response.statusCode.toString().startsWith('2')){
        return AuthResult(
          success: false,
          error: res['error'] ?? 'Server error. Please try again.',
        );
      }

      return AuthResult(
        success: true,
        message: res['message'] ?? 'Password reset successfully.',
      );
    } catch (_) {
      return AuthResult(success: false, error: 'Unable to connect to server.');
    }
  }

  //verify email
  Future<AuthResult> verifyEmail({required String token}) async{
    if (AppConfig.useMockData){
      await Future.delayed(const Duration(milliseconds: 800));
      return AuthResult(success: true, message: 'Email verified successfully!');
    }

    try{
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      final res = jsonDecode(response.body) as Map<String, dynamic>;

      if (!response.statusCode.toString().startsWith('2') ||
          (res['error'] != null && (res['error'] as String).isNotEmpty)){
        return AuthResult(
          success: false,
          error: res['error'] ?? 'Verification failed. The link may have expired.',
        );
      }

      return AuthResult(
        success: true,
        message: res['message'] ?? 'Email verified successfully!',
      );
    } catch (_) {
      return AuthResult(success: false, error: 'Unable to connect to server.');
    }
  }

  // helpers
  Future<Map<String, dynamic>?> getUser() async{
    final raw = await LocalStorageService.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> logout() async{
    await LocalStorageService.remove(_userKey);
  }
}

