import 'package:flutter/material.dart';
import '../widgets/widgets.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiService apiService = ApiService();
  late Future<HealthReport> report;

  @override
  void initState() {
    super.initState();
    report = apiService.getMonthlyReport(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            RichText(
              text: TextSpan(
                text: 'Health',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                children: [
                  TextSpan(
                    text: 'Track',
                    style: TextStyle(color: AppColors.teal),
                  ),
                  TextSpan(text: 'Me'),
                ],
              ),
            ),
            Spacer(),
            Text(
              'Maj 2025',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Header
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.teal, Color(0xFF1a9e94)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📄 Poročilo za zdravnika',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Mesečni povzetek · Maj 2025',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.download, size: 16),
                      label: Text('Izvozi PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),

            // Trends
            FutureBuilder<HealthReport>(
              future: report,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final data = snapshot.data!;

                return Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TRENDI TA MESEC',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            SizedBox(height: 12),
                            TrendItem(
                              icon: '❤️',
                              name: 'Srčni utrip',
                              value:
                                  'Povp. ${data.averageHeartRate.toStringAsFixed(0)} bpm · Max ${data.maxHeartRate} bpm',
                              badge: '↑ Povišan',
                              badgeColor: Color(0xFFFFF3E0),
                              badgeTextColor: Color(0xFFE67E22),
                            ),
                            Divider(height: 1, color: AppColors.border),
                            TrendItem(
                              icon: '😴',
                              name: 'Spanje',
                              value:
                                  'Povp. ${(data.averageSleep.inHours)}h ${(data.averageSleep.inMinutes % 60).toString().padLeft(2, '0')}min',
                              badge: '✓ Normalno',
                              badgeColor: Color(0xFFE8F8F0),
                              badgeTextColor: AppColors.success,
                            ),
                            Divider(height: 1, color: AppColors.border),
                            TrendItem(
                              icon: '🚶',
                              name: 'Dnevni koraki',
                              value: 'Povp. ${data.averageSteps} korakov',
                              badge: '↑ Dobro',
                              badgeColor: AppColors.softBlue,
                              badgeTextColor: AppColors.blue,
                            ),
                            Divider(height: 1, color: AppColors.border),
                            TrendItem(
                              icon: '💊',
                              name: 'Adherenca zdravil',
                              value:
                                  '${(data.medicationAdherence * 100).toStringAsFixed(0)}% upoštevanje terapije',
                              badge: '✓ Dobro',
                              badgeColor: Color(0xFFE8F8F0),
                              badgeTextColor: AppColors.success,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Common Symptoms
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'POGOSTI SIMPTOMI',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            SizedBox(height: 12),
                            ...data.symptomFrequency.entries.map((e) {
                              final maxCount = data.symptomFrequency.values
                                  .reduce((a, b) => a > b ? a : b);
                              final percentage =
                                  (e.value / maxCount * 100).toInt();
                              return Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        e.key,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.navy,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Container(
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: AppColors.border,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          Container(
                                            width: (percentage / 100) *
                                                (MediaQuery.of(context)
                                                        .size
                                                        .width -
                                                    140),
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: AppColors.blue,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    SizedBox(
                                      width: 24,
                                      child: Text(
                                        '${e.value}x',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Share Report
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.softBlue,
                        border: Border.all(
                          color: Color(0xFFBDD9F2),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📤 Pošlji zdravniku',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'PDF poročilo bo vključevalo vse trende, zdravila in simptome.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Email',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: AppColors.blue,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'WhatsApp',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
