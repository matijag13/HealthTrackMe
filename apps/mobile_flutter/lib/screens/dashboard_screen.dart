import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardSnapshot {
  final User? user;
  final List<HealthEntry> entries;
  final List<Medicine> medicines;
  final List<HealthAlertSummary> alerts;
  final HealthShield? shield;

  const _DashboardSnapshot({
    required this.user,
    required this.entries,
    required this.medicines,
    required this.alerts,
    this.shield,
  });
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _api = ApiService.instance;
  late Future<_DashboardSnapshot> _future;
  _DashboardSnapshot? _cachedSnapshot;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardSnapshot> _load() async {
    try {
      final results = await Future.wait([
        _api.getCurrentUser().then((u) => u),
        _api.getHealthEntries(),
        _api.getMedicines(activeOnly: false),
        _api.getHealthAlerts(unreadOnly: false),
        _api.getHealthShield(),
      ]);
      final snapshot = _DashboardSnapshot(
        user: results[0] as User?,
        entries: results[1] as List<HealthEntry>,
        medicines: results[2] as List<Medicine>,
        alerts: results[3] as List<HealthAlertSummary>,
        shield: results[4] as HealthShield?,
      );
      _cachedSnapshot = snapshot;
      return snapshot;
    } catch (e) {
      return _cachedSnapshot ?? const _DashboardSnapshot(user: null, entries: [], medicines: [], alerts: []);
    }
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  String _greetingFor(User? user) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Dobro jutro'
        : hour < 18
            ? 'Dober dan'
            : 'Dober večer';
    final name = user?.firstName.isNotEmpty == true
        ? user!.firstName
        : user?.fullName.isNotEmpty == true
            ? user!.fullName
            : 'ustvari svoj račun';
    return '$greeting, $name 👋';
  }

  String _subtitleForEntry(HealthEntry entry) {
    final symptoms = entry.symptoms.isEmpty ? 'brez simptomov' : entry.symptoms.join(', ');
    final notes = (entry.notes ?? '').trim();
    if (notes.isEmpty) {
      return 'Simptomi: $symptoms';
    }
    return 'Simptomi: $symptoms · ${notes.length > 80 ? '${notes.substring(0, 80)}…' : notes}';
  }

  String _formatSleepHours(double hours) {
    final h = hours.floor();
    final minutes = ((hours - h) * 60).round();
    return '${h}h ${minutes.toString().padLeft(2, '0')}m';
  }

  Color _colorForMedicine(String value) {
    const colors = [AppColors.blue, AppColors.teal, AppColors.danger, AppColors.navy];
    return colors[value.hashCode.abs() % colors.length];
  }

  Widget _emptyCard(String title, String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            RichText(
              text: const TextSpan(
                text: 'Health',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                children: [
                  TextSpan(text: 'Track', style: TextStyle(color: AppColors.teal)),
                  TextSpan(text: 'Me'),
                ],
              ),
            ),
            const Spacer(),
            FutureBuilder<_DashboardSnapshot>(
              future: _future,
              builder: (context, snapshot) {
                final initials = snapshot.data?.user?.initials ?? 'U';
                return CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.blue,
                  child: Text(
                    initials,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_DashboardSnapshot>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text('Napaka pri nalaganju podatkov: ${snapshot.error}')),
                ],
              );
            }

            final data = snapshot.data ?? const _DashboardSnapshot(user: null, entries: [], medicines: [], alerts: []);
            final latest = data.entries.isNotEmpty ? data.entries.first : null;
            final activeMedicines = data.medicines.where((medicine) => medicine.isActive).toList();
            final latestScore = latest?.effectiveWellbeingScore ?? 0;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(14),
              children: [
                Text(
                  _greetingFor(data.user),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                WellnessRing(
                  current: latestScore,
                  total: 100,
                  title: 'Zdravstveni indeks',
                  subtitle: latest != null ? _subtitleForEntry(latest) : 'Ustvari račun in dodaj prvi vnos za osebni pregled.',
                ),
                const SizedBox(height: 12),
                HealthShieldSection(
                  shield: data.shield,
                  onRefresh: _refresh,
                ),
                const SizedBox(height: 12),
                Card(
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
                              Text('Sinhronizirani vnosi: ${data.entries.length}', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text(
                                latest != null
                                    ? 'Zadnji vnos: ${latest.entryDate.toLocal().toIso8601String().split('T').first}'
                                    : 'Ni vnosov za ta račun.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatItem(
                        icon: '✨',
                        value: '$latestScore',
                        label: 'počutje',
                        valueColor: AppColors.teal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatItem(
                        icon: '😴',
                        value: latest != null ? _formatSleepHours(latest.effectiveSleepHours) : '—',
                        label: 'spanje',
                        valueColor: AppColors.navy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatItem(
                        icon: '💊',
                        value: '${activeMedicines.length}',
                        label: 'aktivna zdravila',
                        valueColor: AppColors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatItem(
                        icon: '⚠️',
                        value: '${data.alerts.length}',
                        label: 'opozorila',
                        valueColor: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (data.alerts.isNotEmpty)
                  AlertCard(
                    icon: data.alerts.first.severity == 'critical' ? '🚨' : '⚠️',
                    title: data.alerts.first.title,
                    message: data.alerts.first.message,
                  )
                else
                  _emptyCard('Opozorila', 'Za izbran račun trenutno ni aktivnih opozoril.'),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ZDRAVILA DANES', style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: 10),
                        if (activeMedicines.isEmpty)
                          const Text('Ni aktivnih zdravil za prikaz.')
                        else
                          Column(
                            children: activeMedicines
                                .map(
                                  (med) => MedicineItem(
                                    name: med.name,
                                    time: med.scheduleLabel,
                                    dotColor: _colorForMedicine(med.name),
                                    isCompleted: med.isActive,
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('POČUTJE — ZADNJIH 7 VNOSOV', style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: 12),
                        if (data.entries.isEmpty)
                          const Text('Za graf potrebujemo vsaj en zapis v dnevniku.')
                        else
                          Builder(
                            builder: (context) {
                              final lastSeven = data.entries.take(7).toList().reversed.toList();
                              final labels = [
                                '1',
                                '2',
                                '3',
                                '4',
                                '5',
                                '6',
                                '7',
                              ];
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(lastSeven.length, (index) {
                                  final entry = lastSeven[index];
                                  final height = (entry.effectiveWellbeingScore / 100) * 48;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Container(
                                            height: height < 6 ? 6 : height,
                                            decoration: BoxDecoration(
                                              color: index == lastSeven.length - 1 ? AppColors.teal : AppColors.blue,
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            labels[index],
                                            style: Theme.of(context).textTheme.labelSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}
