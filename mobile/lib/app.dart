import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'models/rewards.dart';

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
import 'services/rewardsProvider.dart';
import 'widgets/bottomnav.dart';
import 'widgets/pointsToast.dart';

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
        GoRoute(
          path: '/rewards',
          builder: (_, __) => const RewardsScreen(),
        ),
      ],
    ),
  ],
);
//app
class StudyRewardsApp extends StatefulWidget{
  const StudyRewardsApp({super.key});

  @override
  State<StudyRewardsApp> createState() => _StudyRewardsAppState();
}

class _StudyRewardsAppState extends State<StudyRewardsApp> {
  late final RewardsProvider _rewardsProvider;

  @override
  void initState() {
    super.initState();
    _rewardsProvider = RewardsProvider();
  }

  @override
  void dispose() {
    _rewardsProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    return AnimatedBuilder(
      animation: _rewardsProvider,
      builder: (_, __) {
        final activeThemeColors = _rewardsProvider.activeTheme.colors;
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: activeThemeColors.bgColor,
          systemNavigationBarIconBrightness: Brightness.light,
        ));

        return MaterialApp.router(
          title: 'StudyRewards',
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
          theme: _buildTheme(activeThemeColors),
          builder: (_, child) => RewardsScope(
            provider: _rewardsProvider,
            child: Stack(
              children: [
                child ?? const SizedBox.shrink(),
                const PointsToast(),
              ],
            ),
          ),
        ),
      },
    );
  }

  ThemeData _buildTheme(ThemeColors themeColors){
    final base = ColorScheme.dark(
      brightness: Brightness.dark,
      primary:          themeColors.primaryColor,
      onPrimary:        themeColors.textColor,
      secondary:        themeColors.accentColor,
      onSecondary:      themeColors.textColor,
      surface:          themeColors.surfaceColor,
      onSurface:        themeColors.textColor,
      error:            AppColors.error,
      onError:          themeColors.bgColor,
      primaryContainer:   themeColors.primaryColor.withOpacity(0.22),
      onPrimaryContainer: themeColors.textColor,
      surfaceContainerHighest: const Color(0xFF1A1F3A),
      onSurfaceVariant:        themeColors.textSubColor,
    );

    return ThemeData(
      colorScheme: base,
      useMaterial3: true,
      scaffoldBackgroundColor: themeColors.bgColor,
      fontFamily: 'Arial',

      appBarTheme: AppBarTheme(
        backgroundColor: themeColors.bgColor,
        foregroundColor: themeColors.textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      cardTheme: CardThemeData(
        color: themeColors.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: themeColors.borderColor),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0x1A6378FF),
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: themeColors.bgColor.withOpacity(0.7),
        hintStyle: const TextStyle(color: Color(0xFF3C4A68)),
        labelStyle: TextStyle(
          color: themeColors.textSubColor,
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
          borderSide: BorderSide(color: themeColors.primaryColor.withOpacity(0.5), width: 1.5),
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
        style: TextButton.styleFrom(foregroundColor: themeColors.primaryColor),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: themeColors.textSubColor),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: themeColors.primaryColor,
        linearTrackColor: themeColors.borderColor,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: themeColors.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: themeColors.borderColor),
        ),
        titleTextStyle: TextStyle(
          color: themeColors.textColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(
          color: themeColors.textSubColor,
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
