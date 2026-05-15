import 'package:flutter/material.dart';
import '../widgets/widgets.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService apiService = ApiService();
  late Future<List<HealthEntry>> healthEntries;
  late Future<List<Medicine>> medicines;
  late Future<List<HealthAlertSummary>> alerts;

  @override
  void initState() {
    super.initState();
    healthEntries = apiService.getHealthEntries();
    medicines = apiService.getMedicines();
    alerts = apiService.getHealthAlerts();
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
            CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.blue,
              child: Text(
                'MK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
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
            // Greeting
            Text(
              'Dobro jutro, Marko 👋',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: 12),

            // Wellness Ring
            WellnessRing(
              current: 75,
              total: 100,
              title: 'Zdravstveni indeks',
              subtitle: 'Danes se počutite nadpovprečno dobro. Nadaljevajte z redno aktivnostjo.',
            ),
            SizedBox(height: 12),

            FutureBuilder<List<HealthEntry>>(
              future: healthEntries,
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                final lastEntry = (snapshot.data != null && snapshot.data!.isNotEmpty)
                    ? snapshot.data!.first
                    : null;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.sync_alt, color: AppColors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sinhronizirani vnosi: $count',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lastEntry != null
                                    ? 'Zadnji vnos: ${lastEntry.date.toLocal().toString().split('.').first}'
                                    : 'Ni vnosov - demo podatki ali prva sinhronizacija.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: StatItem(
                    icon: '❤️',
                    value: '72',
                    label: 'utrip/min',
                    valueColor: AppColors.danger,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: StatItem(
                    icon: '🚶',
                    value: '6.842',
                    label: 'koraki',
                    valueColor: AppColors.blue,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: StatItem(
                    icon: '😴',
                    value: '7h 20m',
                    label: 'spanje',
                    valueColor: AppColors.navy,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Alert Card
            AlertCard(
              icon: '⚠️',
              title: 'Opozorilo — srčni utrip',
              message: 'Zadnja 3 dni je vaš utrip v mirovanju nad 85 bpm. Priporočamo obisk zdravnika.',
            ),
            SizedBox(height: 12),

            FutureBuilder<List<HealthAlertSummary>>(
              future: alerts,
              builder: (context, snapshot) {
                final alertCount = snapshot.data?.length ?? 0;
                final alertText = (snapshot.data != null && snapshot.data!.isNotEmpty)
                    ? snapshot.data!.first.message
                    : 'Ni aktivnih opozoril.';
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('OPOMBE IN OPOZORILA', style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: 8),
                        Text('Aktivna opozorila: $alertCount', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(alertText, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Medications Today
            Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ZDRAVILA DANES',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    SizedBox(height: 10),
                    FutureBuilder<List<Medicine>>(
                      future: medicines,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        return Column(
                          children: List.generate(
                            snapshot.data?.length ?? 0,
                            (index) {
                              final med = snapshot.data![index];
                              return MedicineItem(
                                name: med.name,
                                time: med.times.first,
                                dotColor: _parseColor(med.color),
                                isCompleted: index == 0,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),

            // Mood Chart (7 days)
            Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'POČUTJE — 7 DNI',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [55, 70, 45, 80, 65, 90, 75]
                          .asMap()
                          .entries
                          .map((e) {
                        final height = e.value;
                        return Expanded(
                          child: Container(
                            height: (height / 100) * 48,
                            decoration: BoxDecoration(
                              color: e.key == 6 ? AppColors.teal : AppColors.blue,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                            margin: EdgeInsets.symmetric(horizontal: 2),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        'Pon', 'Tor', 'Sre', 'Čet', 'Pet', 'Sob', 'Ned'
                      ]
                          .map((day) => Expanded(
                            child: Text(
                              day,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    if (colorString.contains('4A90D9')) return AppColors.blue;
    if (colorString.contains('E05252')) return AppColors.danger;
    if (colorString.contains('2EC4B6')) return AppColors.teal;
    return AppColors.blue;
  }
}

