import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import '../config/theme.dart';
import '../models/models.dart';

export '../config/theme.dart';
export 'design_system.dart';
export 'health_metric_card.dart';
export 'detective_insight_card.dart';
export 'detective_insight_detail.dart';
export 'dashboard_bottom_nav.dart';
export 'quick_log_fab.dart';

// Wellness Ring Widget - Progress indicator with circular design
class WellnessRing extends StatelessWidget {
  final int current;
  final int total;
  final String title;
  final String subtitle;

  const WellnessRing({
    super.key,
    required this.current,
    required this.total,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final progress = current / total;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, Color(0xFF2a5298)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Circular progress ring
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.teal),
                  ),
                ),
                // Center text
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$current',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '/ $total',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Stat Item Widget
class StatItem extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color valueColor;

  const StatItem({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor = AppColors.navy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Alert Card Widget
class AlertCard extends StatelessWidget {
  final String icon;
  final String title;
  final String message;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;

  const AlertCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.backgroundColor = const Color(0xFFFFF8E8),
    this.borderColor = AppColors.warning,
    this.textColor = const Color(0xFF7A5000),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor ?? AppColors.warning, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Medicine Item Widget
class MedicineItem extends StatelessWidget {
  final String name;
  final String time;
  final Color dotColor;
  final bool isCompleted;

  const MedicineItem({
    super.key,
    required this.name,
    required this.time,
    required this.dotColor,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.success : AppColors.border,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isCompleted ? '✓' : '○',
                style: TextStyle(
                  fontSize: 11,
                  color: isCompleted ? Colors.white : AppColors.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Mood Button Widget
class MoodButton extends StatelessWidget {
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const MoodButton({
    super.key,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.softBlue : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.blue : AppColors.border,
            width: 2.5,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}

// Chip Widget for symptoms
class SymptomChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SymptomChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.softBlue : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.blue : AppColors.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.blue : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

// Custom Slider Widget
class HealthSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final String leftLabel;
  final String rightLabel;
  final Color? sliderColor;

  const HealthSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.leftLabel,
    required this.rightLabel,
    this.sliderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: const SliderThemeData(
            trackHeight: 6,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: 9,
              elevation: 2,
            ),
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
            min: 0,
            max: 100,
            activeColor: sliderColor ?? AppColors.blue,
            inactiveColor: AppColors.border,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              leftLabel,
              style: const TextStyle(fontSize: 9, color: AppColors.muted),
            ),
            Text(
              rightLabel,
              style: const TextStyle(fontSize: 9, color: AppColors.muted),
            ),
          ],
        ),
      ],
    );
  }
}

// Bottom Navigation Item
class NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? AppColors.blue : AppColors.muted,
            ),
          ),
          if (isActive)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            )
        ],
      ),
    );
  }
}

// Trend Item for Reports
class TrendItem extends StatelessWidget {
  final String icon;
  final String name;
  final String value;
  final String badge;
  final Color badgeColor;
  final Color badgeTextColor;

  const TrendItem({
    super.key,
    required this.icon,
    required this.name,
    required this.value,
    required this.badge,
    required this.badgeColor,
    required this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          )
      ],
    );
  }
}

class HealthShieldSection extends StatelessWidget {
  final HealthShield? shield;
  final VoidCallback? onRefresh;

  const HealthShieldSection({
    super.key,
    required this.shield,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Health Shield',
              subtitle: shield != null
                  ? 'Your 7-stage digital protection journey.'
                  : 'Data will appear once your shield is calculated.',
              actionLabel: onRefresh != null ? 'Refresh' : null,
              onAction: onRefresh,
            ),
            const SizedBox(height: 12),
            if (shield == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined,
                        size: 28, color: AppColors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Shield unavailable',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try refreshing, and make sure an active account is selected.',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                                height: 1.4),
                          ),
                          const SizedBox(height: 10),
                          if (onRefresh != null)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: onRefresh,
                                    child: const Text('Refresh now'),
                                  ),
                                ),
                              ],
                            )
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              HealthShieldCard(
                level: shield!.level,
                levelName: shield!.levelName,
                totalPoints: shield!.totalConsistencyPoints,
                progressPercent: shield!.progressPercent,
                pointsToNextLevel: shield!.pointsToNextLevel,
                todayPoints: shield!.todayPoints,
                completedHabits: shield!.completedHabitsCount,
                penaltyPoints: shield!.penaltyPoints,
                consecutiveFailedDays: shield!.consecutiveFailedDays,
                dailyBreakdown: shield!.dailyBreakdown,
              )
          ],
        ),
      ),
    );
  }
}

// Loading skeleton widgets (shimmer)
class LoadingSkeleton {
  static Color _base(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade800
          : Colors.grey.shade300;
  static Color _highlight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade700
          : Colors.grey.shade100;

  static Widget dashboard(BuildContext context) {
    final base = _base(context);
    final highlight = _highlight(context);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(children: [
        // ring placeholder
        Container(
            height: 180,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
                color: base, borderRadius: BorderRadius.circular(12))),
        const SizedBox(height: 12),
        // stat cards
        Row(
          children: List.generate(
              4,
              (_) => Expanded(
                  child: Container(
                      height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(12))))),
        ),
        const SizedBox(height: 12),
        // chart placeholder
        Container(
            height: 200,
            decoration: BoxDecoration(
                color: base, borderRadius: BorderRadius.circular(12))),
      ]),
    );
  }

  static Widget health(BuildContext context) {
    final base = _base(context);
    final highlight = _highlight(context);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
          children: List.generate(
              3,
              (_) => Container(
                  height: 120,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                      color: base, borderRadius: BorderRadius.circular(12))))),
    );
  }

  static Widget medicines(BuildContext context) {
    final base = _base(context);
    final highlight = _highlight(context);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
          children: List.generate(
              6,
              (_) => Container(
                  height: 56,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                      color: base, borderRadius: BorderRadius.circular(8))))),
    );
  }

  static Widget profile(BuildContext context) {
    final base = _base(context);
    final highlight = _highlight(context);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(children: [
          Container(
              height: 96,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                  color: base, borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 12),
          Column(
              children: List.generate(
                  6,
                  (_) => Container(
                      height: 48,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(8))))),
        ]),
      ),
    );
  }

  static Widget buttonSmall(BuildContext context) {
    final base = _base(context);
    final highlight = _highlight(context);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(color: base, shape: BoxShape.circle)),
    );
  }
}

// Reusable empty state with Lottie animation, helpful text and CTA
class EmptyState extends StatelessWidget {
  final String animationUrl;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  const EmptyState(
      {super.key,
      required this.animationUrl,
      required this.title,
      required this.subtitle,
      required this.buttonLabel,
      required this.onPressed});

  Widget _fallbackArt() {
    return Container(
      width: 140,
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.self_improvement_rounded,
          size: 56, color: AppColors.blue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 180,
              height: 140,
              child: animationUrl.trim().isEmpty
                  ? _fallbackArt()
                  : Lottie.network(
                      animationUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _fallbackArt(),
                    ),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.muted)),
            const SizedBox(height: 12),
            SizedBox(
                width: 180,
                child: ElevatedButton(
                    onPressed: onPressed, child: Text(buttonLabel))),
          ],
        ),
      ),
    );
  }
}

class HealthShieldCard extends StatelessWidget {
  final int level;
  final String levelName;
  final int totalPoints;
  final int progressPercent;
  final int pointsToNextLevel;
  final int todayPoints;
  final int completedHabits;
  final int penaltyPoints;
  final int consecutiveFailedDays;
  final HealthShieldDailyBreakdown? dailyBreakdown;

  const HealthShieldCard({
    super.key,
    required this.level,
    required this.levelName,
    required this.totalPoints,
    required this.progressPercent,
    required this.pointsToNextLevel,
    required this.todayPoints,
    required this.completedHabits,
    required this.penaltyPoints,
    required this.consecutiveFailedDays,
    required this.dailyBreakdown,
  });

  static const List<String> _stageNames = [
    'Start',
    'Insight',
    'Consistency',
    'Protection',
    'Optimization',
    'Intelligence',
    'Mastery'
  ];

  int get _stageIndex {
    if (level <= 1) {
      return 0;
    }
    if (level <= 3) {
      return 1;
    }
    if (level <= 6) {
      return 2;
    }
    if (level <= 9) {
      return 3;
    }
    if (level <= 14) {
      return 4;
    }
    if (level <= 20) {
      return 5;
    }
    return 6;
  }

  Color get _accent {
    if (_stageIndex >= 6) {
      return const Color(0xFFE4AF3A);
    }
    if (_stageIndex >= 4) {
      return AppColors.teal;
    }
    return AppColors.blue;
  }

  Widget _statCell(
      {required IconData icon,
      required String label,
      required String value,
      required Color valueColor}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: valueColor)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _stageNode(int index) {
    final complete = index < _stageIndex;
    final current = index == _stageIndex;
    final border = complete || current ? _accent : AppColors.border;
    final textColor = complete || current ? _accent : AppColors.muted;

    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: border.withValues(alpha: current ? 0.15 : 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: border, width: current ? 2 : 1.3),
            ),
            alignment: Alignment.center,
            child: Icon(complete ? Icons.check : Icons.shield_outlined,
                size: 16, color: textColor),
          ),
          const SizedBox(height: 6),
          Text('Stage ${index + 1}',
              style: TextStyle(
                  fontSize: 10, color: textColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(_stageNames[index],
              style: TextStyle(fontSize: 10, color: textColor),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _breakdownBadge(String label, int value) {
    final positive = value >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (positive ? AppColors.success : AppColors.danger)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label ${positive ? '+' : ''}$value',
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: positive ? AppColors.success : AppColors.danger),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressValue = (progressPercent.clamp(0, 100)) / 100;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accent.withValues(alpha: 0.14),
            _accent.withValues(alpha: 0.05)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.35), width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded, color: AppColors.navy),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Digital Shield',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600)),
                    Text(levelName,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _accent)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: _accent, borderRadius: BorderRadius.circular(8)),
                child: Text('Level $level',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              separatorBuilder: (context, index) => Icon(Icons.chevron_right,
                  size: 16,
                  color: index < _stageIndex ? _accent : AppColors.border),
              itemBuilder: (context, index) => _stageNode(index),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progress to next stage',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('$progressPercent%',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _accent)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 10,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(_accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pointsToNextLevel > 0
                ? '$pointsToNextLevel points to the next stage'
                : 'Next stage reached. Great work!',
            style: TextStyle(
                fontSize: 12,
                color:
                    pointsToNextLevel > 0 ? AppColors.muted : AppColors.success,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                _statCell(
                    icon: Icons.auto_graph,
                    label: 'Total',
                    value: '$totalPoints',
                    valueColor: AppColors.navy),
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.flash_on,
                          size: 16, color: AppColors.muted),
                      const SizedBox(height: 4),
                      if (todayPoints < 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$todayPoints',
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(width: 4),
                            const Tooltip(
                              message:
                                  'Penalty points for missed habits or unhealthy patterns today',
                              child: Icon(Icons.info_outline,
                                  size: 14, color: Colors.red),
                            ),
                          ],
                        )
                      else
                        Text('${todayPoints >= 0 ? '+' : ''}$todayPoints',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: todayPoints >= 0
                                    ? AppColors.success
                                    : AppColors.danger)),
                      const SizedBox(height: 2),
                      const Text('Today',
                          style:
                              TextStyle(fontSize: 10, color: AppColors.muted),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
                _statCell(
                    icon: Icons.task_alt,
                    label: 'Habits',
                    value: '$completedHabits/5',
                    valueColor: AppColors.teal),
                _statCell(
                    icon: Icons.warning_amber_rounded,
                    label: 'Fails',
                    value: '$consecutiveFailedDays',
                    valueColor: consecutiveFailedDays > 0
                        ? AppColors.warning
                        : AppColors.muted),
              ],
            ),
          ),
          if (dailyBreakdown != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _breakdownBadge('Sleep', dailyBreakdown!.sleepPoints),
                _breakdownBadge('Activity', dailyBreakdown!.activityPoints),
                _breakdownBadge('Wellbeing', dailyBreakdown!.wellbeingPoints),
                _breakdownBadge(
                    'Supplements', dailyBreakdown!.supplementsPoints),
                _breakdownBadge('Symptoms', dailyBreakdown!.symptomsPoints),
                _breakdownBadge(
                    'Stability', dailyBreakdown!.routineStabilityPoints),
                _breakdownBadge('Penalty', -penaltyPoints),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
