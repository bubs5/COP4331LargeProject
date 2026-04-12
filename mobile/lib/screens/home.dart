import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Glow blobs matching web CSS radial-gradients
          Positioned(
            left: -100,
            top: MediaQuery.of(context).size.height * 0.05,
            child: _glowBlob(const Color(0x244F6FFF), 320),
          ),
          Positioned(
            right: -100,
            bottom: MediaQuery.of(context).size.height * 0.1,
            child: _glowBlob(const Color(0x1C8B6FFF), 300),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),

                  // App name + tagline
                  const Text(
                    'StudyRewards',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -1.2,
                      shadows: [
                        Shadow(
                          color: Color(0x594F6FFF),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Study with flashcards, take quizzes, and earn rewards while you study.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSub,
                      height: 1.6,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Login button (primary)
                  _HomeButton(
                    label: 'Login',
                    isPrimary: true,
                    onTap: () => context.go('/login'),
                  ),
                  const SizedBox(height: 12),

                  // Register button (secondary/ghost)
                  _HomeButton(
                    label: 'Create Account',
                    isPrimary: false,
                    onTap: () => context.go('/register'),
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowBlob(Color color, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent]),
    ),
  );
}

class _HomeButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _HomeButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: isPrimary
          ? DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xE64F6FFF), Color(0xD98B6FFF)],
          ),
          borderRadius: BorderRadius.circular(999),
          border:
          Border.all(color: const Color(0x666378FF)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          onPressed: onTap,
          child: const Text(
            'Login',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      )
          : OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSub,
          side: const BorderSide(color: Color(0x1FFFFFFF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        onPressed: onTap,
        child: const Text(
          'Create Account',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
