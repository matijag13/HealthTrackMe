import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/models.dart';

export '../config/theme.dart';

// Wellness Ring Widget - Progress indicator with circular design
class WellnessRing extends StatelessWidget {
  final int current;
  final int total;
  final String title;
  final String subtitle;

  const WellnessRing({
    Key? key,
    required this.current,
    required this.total,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = current / total;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, Color(0xFF2a5298)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
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
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal),
                  ),
                ),
                // Center text
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$current',
                      style: TextStyle(
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
          SizedBox(width: 14),
          // Text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
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
    Key? key,
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor = AppColors.navy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          children: [
            Text(icon, style: TextStyle(fontSize: 16)),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
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
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.backgroundColor = const Color(0xFFFFF8E8),
    this.borderColor = AppColors.warning,
    this.textColor = const Color(0xFF7A5000),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor ?? AppColors.warning, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: TextStyle(fontSize: 18)),
          SizedBox(width: 10),
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
                SizedBox(height: 2),
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
    Key? key,
    required this.name,
    required this.time,
    required this.dotColor,
    required this.isCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
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
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
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
            style: TextStyle(
              fontSize: 11,
              color: AppColors.muted,
            ),
          ),
          SizedBox(width: 10),
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
    Key? key,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

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
          child: Text(emoji, style: TextStyle(fontSize: 20)),
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
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
    Key? key,
    required this.value,
    required this.onChanged,
    required this.leftLabel,
    required this.rightLabel,
    this.sliderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
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
        SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              leftLabel,
              style: TextStyle(fontSize: 9, color: AppColors.muted),
            ),
            Text(
              rightLabel,
              style: TextStyle(fontSize: 9, color: AppColors.muted),
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
    Key? key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 3),
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
              padding: EdgeInsets.only(top: 3),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
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
    Key? key,
    required this.icon,
    required this.name,
    required this.value,
    required this.badge,
    required this.badgeColor,
    required this.badgeTextColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
    Key? key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  }) : super(key: key);

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
          ),
      ],
    );
  }
}

class HealthShieldSection extends StatelessWidget {
  final HealthShield? shield;
  final VoidCallback? onRefresh;

  const HealthShieldSection({
    Key? key,
    required this.shield,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Zdravstveni ščit',
              subtitle: shield != null
                  ? 'Tvoj dnevni napredek, nivo in navade na enem mestu.'
                  : 'Ščit še ni na voljo. Ko bo backend vrnil podatke, se bo prikazal tukaj.',
              actionLabel: onRefresh != null ? 'Osveži' : null,
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
                    const Text('🛡️', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ščit trenutno ni povezan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Preveri, ali je izbran aktiven uporabnik in ali backend na portu 8080 vrača Health Shield podatke.',
                            style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: onRefresh,
                                  child: const Text('Ponovi osvežitev'),
                                ),
                              ),
                            ],
                          ),
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
              ),
          ],
        ),
      ),
    );
  }
}

// Health Shield Widget - Displays shield level, points, and daily progress
class HealthShieldCard extends StatelessWidget {
  final int level;
  final String levelName;
  final int totalPoints;
  final int progressPercent;
  final int pointsToNextLevel;
  final int todayPoints;
  final int completedHabits;

  const HealthShieldCard({
    Key? key,
    required this.level,
    required this.levelName,
    required this.totalPoints,
    required this.progressPercent,
    required this.pointsToNextLevel,
    required this.todayPoints,
    required this.completedHabits,
  }) : super(key: key);

  Color get _shieldColor {
    if (level <= 3) return AppColors.blue;
    if (level <= 6) return AppColors.teal;
    return const Color(0xFF00BCD4);
  }

  String get _shieldEmoji {
    if (level <= 3) return '🛡️';
    if (level <= 6) return '✨';
    return '👑';
  }

  @override
  Widget build(BuildContext context) {
    final progressValue = (progressPercent.clamp(0, 100)) / 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_shieldEmoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Zdravstveni ščit', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Text(
                        levelName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _shieldColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _shieldColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Nivo $level',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _shieldColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Napredek do naslednjega nivoja',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                    Text(
                      '$progressPercent%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _shieldColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 8,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(_shieldColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pointsToNextLevel <= 0
                  ? 'Dosežen je naslednji nivo'
                  : '$pointsToNextLevel točk do naslednjega nivoja',
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Skupno točk', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                      const SizedBox(height: 2),
                      Text(
                        '$totalPoints',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Danes', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                      const SizedBox(height: 2),
                      Text(
                        '+$todayPoints točk',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Navade', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                      const SizedBox(height: 2),
                      Text(
                        '$completedHabits/5',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
