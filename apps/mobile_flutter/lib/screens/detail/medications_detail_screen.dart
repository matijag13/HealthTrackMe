import 'package:flutter/material.dart';
import '../../config/theme.dart';

class MedicationsDetailScreen extends StatefulWidget {
  const MedicationsDetailScreen({super.key});

  @override
  State<MedicationsDetailScreen> createState() =>
      _MedicationsDetailScreenState();
}

class _MedicationsDetailScreenState extends State<MedicationsDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Medications',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAdherenceCard(context),
            const SizedBox(height: 20),
            _buildTodaysMedsCard(context),
            const SizedBox(height: 20),
            _buildActiveMedicationsCard(context),
            const SizedBox(height: 20),
            _buildAdherenceHistoryCard(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryGreen.withValues(alpha: 0.08)
            : AppColors.primaryGreen.withValues(alpha: 0.05),
        border: Border.all(
          color: isDark
              ? AppColors.primaryGreen.withValues(alpha: 0.2)
              : AppColors.primaryGreen.withValues(alpha: 0.15),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medication Adherence',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '100%',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This month',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.darkTextSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔥 18',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Day streak',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.darkTextSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Excellent consistency! Keep up your perfect adherence streak.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.darkTextSecondary,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysMedsCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Medications",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        _buildMedicationItem(
          context,
          'Metformin',
          '500 mg',
          '8:00 AM',
          '✓ Taken',
          true,
        ),
        const SizedBox(height: 10),
        _buildMedicationItem(
          context,
          'Lisinopril',
          '10 mg',
          '12:00 PM',
          '✓ Taken',
          true,
        ),
        const SizedBox(height: 10),
        _buildMedicationItem(
          context,
          'Atorvastatin',
          '20 mg',
          '8:00 PM',
          '⏱ Due',
          false,
        ),
      ],
    );
  }

  Widget _buildMedicationItem(
    BuildContext context,
    String medName,
    String dose,
    String time,
    String status,
    bool taken,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor =
        taken ? AppColors.primaryGreen : AppColors.primaryOrange;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
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
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medName,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dose • $time',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMedicationsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Medications',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          _buildMedInfo(
              context, 'Metformin', 'Type 2 Diabetes', '500 mg, 2x daily'),
          const SizedBox(height: 14),
          _buildMedInfo(
              context, 'Lisinopril', 'High Blood Pressure', '10 mg, 1x daily'),
          const SizedBox(height: 14),
          _buildMedInfo(
              context, 'Atorvastatin', 'High Cholesterol', '20 mg, 1x daily'),
        ],
      ),
    );
  }

  Widget _buildMedInfo(
      BuildContext context, String name, String indication, String dosage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          indication,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.darkTextSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          dosage,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildAdherenceHistoryCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adherence History (Last 30 Days)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          // Day-by-day calendar view
          GridView.count(
            crossAxisCount: 7,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(30, (index) {
              final taken = index % 3 != 2; // 2 out of 3 days taken
              return Container(
                decoration: BoxDecoration(
                  color:
                      taken ? AppColors.primaryGreen : AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 9,
                      ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(context, '✓ Taken', AppColors.primaryGreen),
              _buildLegendItem(context, 'Missed', AppColors.primaryOrange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.darkTextSecondary,
              ),
        ),
      ],
    );
  }
}
