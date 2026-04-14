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
import 'screens/rewards.dart';
import 'widgets/bottomnav.dart';
import 'services/rewards_controller.dart';

// default app colors
class AppColors {
  static const bg = Color(0xFF080B1C);
  static const surface = Color(0xFF0C1022);
  static const card = Color(0xFF0F1428);
  static const cardBorder = Color(0x2D6378FF);

  static const primary = Color(0xFF4F6FFF);
  static const primarySoft = Color(0x384F6FFF);
  static const accent = Color(0xFF8B6FFF);

  static const textPrimary = Color(0xFFE8EAF6);
  static const textSub = Color(0xFF7B8CAD);
  static const textMuted = Color(0xFF5F708A);
  static const textLink = Color(0xFF818CF8);

  static const success = Color(0xFF86EFAC);
  static const error = Color(0xFFF87171);
  static const errorBg = Color(0x1AF87171);
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
        GoRoute(
          path: '/rewards',
          builder: (_, __) => const RewardsScreen(),
        ),
      ],
    ),
  ],
);

class StudyRewardsApp extends StatefulWidget {
  const StudyRewardsApp({super.key});

  @override
  State<StudyRewardsApp> createState() => _StudyRewardsAppState();
}

class _StudyRewardsAppState extends State<StudyRewardsApp> {
  @override
  void initState() {
    super.initState();
    rewardsController.init();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rewardsController,
      builder: (context, _) {
        final active = rewardsController.activeTheme.colors;

        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: active.bg,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
        );

        final scheme = ColorScheme.dark(
          brightness: Brightness.dark,
          primary: active.primary,
          onPrimary: active.text,
          secondary: active.accent,
          onSecondary: active.text,
          surface: active.surface,
          onSurface: active.text,
          error: AppColors.error,
          onError: active.bg,
        );

        return MaterialApp.router(
          title: 'StudyRewards',
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
          theme: ThemeData(
            colorScheme: scheme,
            useMaterial3: true,
            scaffoldBackgroundColor: active.bg,
            fontFamily: 'Arial',
            appBarTheme: AppBarTheme(
              backgroundColor: active.bg,
              foregroundColor: active.text,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            textTheme: TextTheme(
              displayLarge: TextStyle(color: active.text, fontWeight: FontWeight.w800),
              displayMedium: TextStyle(color: active.text, fontWeight: FontWeight.w800),
              headlineLarge: TextStyle(color: active.text, fontWeight: FontWeight.w700),
              headlineMedium: TextStyle(color: active.text, fontWeight: FontWeight.w700),
              titleLarge: TextStyle(color: active.text, fontWeight: FontWeight.w600),
              titleMedium: TextStyle(color: active.text, fontWeight: FontWeight.w600),
              bodyLarge: TextStyle(color: active.text),
              bodyMedium: TextStyle(color: active.textSub),
              bodySmall: TextStyle(color: active.textSub),
              labelLarge: TextStyle(color: active.text, fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }
}