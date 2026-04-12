import 'package:flutter/material.dart';
import '../app.dart';

enum AppButtonStyle { primary, secondary, danger }

class AppButton extends StatelessWidget{
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
  Widget build(BuildContext context){
    final isPrimary   = style == AppButtonStyle.primary;
    final isSecondary = style == AppButtonStyle.secondary;
    final isDanger    = style == AppButtonStyle.danger;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xE64F6FFF), Color(0xD98B6FFF)],
          )
              : null,
          color: isSecondary
              ? const Color(0x1A6378FF)
              : isDanger
              ? const Color(0x1AF87171)
              : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary
                ? const Color(0x666378FF)
                : isSecondary
                ? const Color(0x2D6378FF)
                : const Color(0x4DF87171),
          ),
          boxShadow: isPrimary
              ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ]
              : null,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: isPrimary
                ? AppColors.textPrimary
                : isDanger
                ? AppColors.error
                : AppColors.textLink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isPrimary ? AppColors.textPrimary : AppColors.primary,
            ),
          )
              : Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isPrimary
                  ? AppColors.textPrimary
                  : isDanger
                  ? AppColors.error
                  : AppColors.textLink,
            ),
          ),
        ),
      ),
    );
  }
}
