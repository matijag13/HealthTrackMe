import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../config/theme.dart';
import '../services/haptics_service.dart';

typedef QuickLogCallback = void Function(String logType);

class QuickLogOption {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  QuickLogOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class QuickLogFAB extends StatefulWidget {
  final QuickLogCallback onOptionSelected;

  const QuickLogFAB({
    Key? key,
    required this.onOptionSelected,
  }) : super(key: key);

  @override
  State<QuickLogFAB> createState() => _QuickLogFABState();
}

class _QuickLogFABState extends State<QuickLogFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = false;

  final List<QuickLogOption> options = [
    QuickLogOption(
      id: 'mood',
      label: 'Mood',
      icon: Icons.sentiment_satisfied,
      color: AppColors.primaryOrange,
    ),
    QuickLogOption(
      id: 'water',
      label: 'Water',
      icon: Icons.water_drop,
      color: AppColors.primaryBlue,
    ),
    QuickLogOption(
      id: 'medication',
      label: 'Medication',
      icon: Icons.medication,
      color: AppColors.primaryGreen,
    ),
    QuickLogOption(
      id: 'symptom',
      label: 'Symptom',
      icon: Icons.health_and_safety,
      color: AppColors.primaryOrange,
    ),
    QuickLogOption(
      id: 'sleep',
      label: 'Sleep',
      icon: Icons.bedtime,
      color: AppColors.primaryGreen,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isExpanded) {
      _animationController.reverse();
      HapticsService.collapse();
    } else {
      _animationController.forward();
      HapticsService.expand();
    }
    setState(() => _isExpanded = !_isExpanded);
  }

  void _selectOption(String optionId) {
    HapticsService.success();
    widget.onOptionSelected(optionId);
    _toggleMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop
        if (_isExpanded)
          GestureDetector(
            onTap: _toggleMenu,
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),

        // Menu items
        if (_isExpanded) ..._buildMenuItems(context),

        // Main FAB
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'main_fab',
            backgroundColor: AppColors.primaryBlue,
            onPressed: _toggleMenu,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animationController.value * 3.14159,
                  child: Icon(
                    _isExpanded ? Icons.close : Icons.add,
                    size: 28,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    final itemCount = options.length;
    final angleSlice = 360.0 / itemCount;

    return List.generate(itemCount, (index) {
      final angle = (angleSlice * index) * (3.14159 / 180);
      const radius = 120.0;
      final dx = radius * Math.cos(angle);
      final dy = radius * Math.sin(angle);

      return Positioned(
        bottom: 16 + dy,
        right: 16 - dx,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval(index * 0.1, 0.8 + index * 0.1,
                  curve: Curves.easeOut),
            ),
          ),
          child: _buildMenuItem(context, options[index]),
        ),
      );
    });
  }

  Widget _buildMenuItem(BuildContext context, QuickLogOption option) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'fab_${option.id}',
          mini: true,
          backgroundColor: option.color.withValues(alpha: 0.2),
          onPressed: () => _selectOption(option.id),
          child: Icon(
            option.icon,
            color: option.color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkCard
                : AppColors.lightCard,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            option.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

// Math helper for circular layout
class Math {
  static double cos(double angle) => math.cos(angle);
  static double sin(double angle) => math.sin(angle);
}
