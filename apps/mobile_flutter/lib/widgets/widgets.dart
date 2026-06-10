import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import '../config/theme.dart';

export '../config/theme.dart';
export 'design_system.dart';
export 'dashboard_bottom_nav.dart';

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

