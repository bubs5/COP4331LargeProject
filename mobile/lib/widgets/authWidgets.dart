///shared between all auth screens
import 'package:flutter/material.dart';
import '../app.dart';


class AuthScaffold extends StatelessWidget {
  final Widget child;

  const AuthScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // glow blobs
          Positioned(
            left: -80,
            top: -60,
            child: _glowBlob(const Color(0x244F6FFF), 300),
          ),
          Positioned(
            right: -80,
            bottom: -60,
            child: _glowBlob(const Color(0x1C8B6FFF), 280),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowBlob(Color color, double size){
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}


class AuthCard extends StatelessWidget{
  final List<Widget> children;

  const AuthCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
      decoration: BoxDecoration(
        color: const Color(0xE00C1022),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 60,
            spreadRadius: 0,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

///small circular back button
class BackCircleButton extends StatelessWidget {
  final VoidCallback onPressed;

  const BackCircleButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primarySoft,
          border: Border.all(color: const Color(0x336378FF)),
        ),
        child: const Icon(
          Icons.arrow_back,
          color: AppColors.textLink,
          size: 18,
        ),
      ),
    );
  }
}

/// title texr
class AuthTitle extends StatelessWidget {
  final String text;
  const AuthTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      ),
    );
  }
}

///status message widget
class StatusText extends StatelessWidget {
  final String message;
  final bool isSuccess;
  final bool isError;

  const StatusText(
      this.message, {
        super.key,
        this.isSuccess = false,
        this.isError = false,
      });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox(height: 14);
    final color = isSuccess
        ? AppColors.success
        : isError
        ? AppColors.error
        : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        message,
        style: TextStyle(fontSize: 13, color: color),
        textAlign: TextAlign.center,
      ),
    );
  }
}

///inline link text
class LinkText extends StatelessWidget{
  final String text;
  final VoidCallback onTap;

  const LinkText(this.text, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context){
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textLink,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          decoration: TextDecoration.underline,
          decorationColor: Color(0x59818CF8),
        ),
      ),
    );
  }
}
