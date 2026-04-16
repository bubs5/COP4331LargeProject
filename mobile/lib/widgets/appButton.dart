import 'package:flutter/material.dart';
import '../services/rewards_controller.dart';

enum AppButtonStyle { primary, secondary, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonStyle style;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.style = AppButtonStyle.primary,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rewardsController,
      builder: (context, _) {
        final colors = rewardsController.activeTheme.colors;
        final isPrimary = style == AppButtonStyle.primary;
        final isSecondary = style == AppButtonStyle.secondary;
        final isDanger = style == AppButtonStyle.danger;

        final Color fg = isPrimary
            ? colors.text
            : isDanger
            ? const Color(0xFFF87171)
            : colors.primary;

        final BoxDecoration decoration = BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primary, colors.accent],
          )
              : null,
          color: isSecondary
              ? colors.primary.withOpacity(0.10)
              : isDanger
              ? const Color(0x1AF87171)
              : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary
                ? colors.primary.withOpacity(0.35)
                : isSecondary
                ? colors.border
                : const Color(0x4DF87171),
          ),
          boxShadow: isPrimary
              ? [
            BoxShadow(
              color: colors.primary.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ]
              : null,
        );

        return SizedBox(
          width: double.infinity,
          height: 48,
          child: DecoratedBox(
            decoration: decoration,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: fg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: isLoading ? null : onPressed,
              child: isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isPrimary ? colors.text : colors.primary,
                ),
              )
                  : Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: fg,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}