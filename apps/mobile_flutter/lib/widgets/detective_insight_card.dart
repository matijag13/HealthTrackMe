import 'package:flutter/material.dart';
import '../config/theme.dart';

class DetectiveInsightCard extends StatelessWidget {
  final String? badge;
  final String title;
  final String description;
  final String? finding;
  final VoidCallback? onTap;

  const DetectiveInsightCard({
    super.key,
    this.badge,
    required this.title,
    required this.description,
    this.finding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          border: Border(
            left: const BorderSide(
              color: AppColors.primaryGreen,
              width: 4,
            ),
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 0.5,
            ),
            right: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 0.5,
            ),
            bottom: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            if (badge != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primaryGreen.withValues(alpha: 0.2)
                        : AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Text(
                    badge!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                  ),
                ),
              ),

            // Label
            Text(
              '🤖 AI Detective',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primaryGreen,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    height: 1.6,
                  ),
            ),

            // Finding box (if provided)
            if (finding != null) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryGreen.withValues(alpha: 0.08)
                      : AppColors.primaryGreen.withValues(alpha: 0.05),
                  border: Border(
                    left: const BorderSide(
                      color: AppColors.primaryGreen,
                      width: 3,
                    ),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Text(
                  finding!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        height: 1.5,
                      ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
