import 'package:flutter/material.dart';
import '../app.dart';
import '../models/studyset.dart';

class SetCard extends StatelessWidget {
  final StudySet studySet;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const SetCard({
    super.key,
    required this.studySet,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: AppColors.primarySoft,
          highlightColor: AppColors.primarySoft.withOpacity(0.3),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon badge
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x334F6FFF)),
                  ),
                  child: const Icon(
                    Icons.style_rounded,
                    color: AppColors.textLink,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studySet.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        studySet.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSub,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${studySet.cardCount} cards',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textLink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error, size: 18),
                    onPressed: onDelete,
                  ),
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
