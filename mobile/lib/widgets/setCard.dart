import 'package:flutter/material.dart';
import '../models/studyset.dart';
import '../services/rewards_controller.dart';

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
    return AnimatedBuilder(
      animation: rewardsController,
      builder: (context, _) {
        final colors = rewardsController.activeTheme.colors;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              splashColor: colors.primary.withOpacity(0.12),
              highlightColor: colors.primary.withOpacity(0.08),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: colors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studySet.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.text,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            studySet.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSub,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${studySet.cardCount} cards',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFF87171),
                          size: 18,
                        ),
                        onPressed: onDelete,
                      ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: colors.textSub,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}