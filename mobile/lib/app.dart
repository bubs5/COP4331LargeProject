import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/forgotpass.dart';
import 'screens/resetpass.dart';
import 'screens/verifyemail.dart';
import 'screens/dashboard.dart';
import 'screens/sets.dart';
import 'screens/setsDetail.dart';
import 'screens/flashcards.dart';
import 'screens/quiz.dart';
import 'widgets/bottomnav.dart';

// match web css
class AppColors {
  static const bg          = Color(0xFF080B1C);
  static const surface     = Color(0xFF0C1022);
  static const card        = Color(0xFF0F1428);
  static const cardBorder  = Color(0x2D6378FF);

  static const primary     = Color(0xFF4F6FFF);
  static const primarySoft = Color(0x384F6FFF);
  static const accent      = Color(0xFF8B6FFF);

  static const textPrimary = Color(0xFFE8EAF6);
  static const textSub     = Color(0xFF7B8CAD);
  static const textMuted   = Color(0xFF5F708A);
  static const textLink    = Color(0xFF818CF8);

  static const success     = Color(0xFF86EFAC);
  static const error       = Color(0xFFF87171);
  static const errorBg     = Color(0x1AF87171);

  //Gradient stops used across screens
  static const List<Color> bgGradient = [
    Color(0xFF080B1C),
    Color(0xFF0A0E22),
  ];
}


final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (_, __) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (_, state) => ResetPasswordScreen(
        token: state.uri.queryParameters['token'],
      ),
    ),
    GoRoute(
      path: '/verify-email',
      builder: (_, state) => VerifyEmailScreen(
        token: state.uri.queryParameters['token'],
      ),
    ),

    ShellRoute(
      builder: (_, __, child) => BottomNav(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/sets/new',
          builder: (_, __) => const SetsScreen(),
        ),
        GoRoute(
          path: '/sets/:setId',
          builder: (_, state) => SetDetailScreen(
            setId: state.pathParameters['setId']!,
          ),
        ),
        GoRoute(
          path: '/flashcards',
          builder: (_, state) => FlashcardsScreen(
            setId: state.uri.queryParameters['setId'],
          ),
        ),
        GoRoute(
          path: '/quiz',
          builder: (_, state) => QuizScreen(
            setId: state.uri.queryParameters['setId'],
          ),
        ),
      ],
    ),
  ],
);
//app
class StudyRewardsApp extends StatelessWidget{
  const StudyRewardsApp({super.key});

  @override
  Widget build(BuildContext context){
    //make the status bar transparent so background shows
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return MaterialApp.router(
      title: 'StudyRewards',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: _buildTheme(),
    );
  }

  ThemeData _buildTheme(){
    final base = ColorScheme.dark(
      brightness: Brightness.dark,
      primary:          AppColors.primary,
      onPrimary:        AppColors.textPrimary,
      secondary:        AppColors.accent,
      onSecondary:      AppColors.textPrimary,
      surface:          AppColors.surface,
      onSurface:        AppColors.textPrimary,
      error:            AppColors.error,
      onError:          AppColors.bg,
      primaryContainer:   AppColors.primarySoft,
      onPrimaryContainer: AppColors.textPrimary,
      surfaceContainerHighest: const Color(0xFF1A1F3A),
      onSurfaceVariant:        AppColors.textSub,
    );

    return ThemeData(
      colorScheme: base,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Arial',

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0x1A6378FF),
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xB3080B1C),
        hintStyle: const TextStyle(color: Color(0xFF3C4A68)),
        labelStyle: const TextStyle(
          color: AppColors.textSub,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x2D6378FF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x726378FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.textLink),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: AppColors.textSub),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: Color(0x2D6378FF),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.textSub,
          fontSize: 14,
        ),
      ),

      textTheme: const TextTheme(
        displayLarge:  TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
        displayMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
        headlineLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        headlineMedium:TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        titleLarge:    TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleMedium:   TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge:     TextStyle(color: AppColors.textPrimary),
        bodyMedium:    TextStyle(color: AppColors.textSub),
        bodySmall:     TextStyle(color: AppColors.textMuted),
        labelLarge:    TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      ),
    );
  }
}
