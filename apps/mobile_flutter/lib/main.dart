import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/diary_screen.dart';
import 'screens/reports_screen.dart';
import 'widgets/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.instance.init();
  runApp(const HealthTrackMeApp());
}

class HealthTrackMeApp extends StatelessWidget {
  const HealthTrackMeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthTrackMe',
      theme: AppTheme.lightTheme,
      home: const MainApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const DiaryScreen(),
    const MedicinesScreen(),
    const ReportsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.blue,
        unselectedItemColor: AppColors.muted,
        backgroundColor: AppColors.card,
        elevation: 1,
        items: [
          BottomNavigationBarItem(
            icon: Text('🏠', style: TextStyle(fontSize: 18)),
            label: 'Domov',
          ),
          BottomNavigationBarItem(
            icon: Text('📓', style: TextStyle(fontSize: 18)),
            label: 'Dnevnik',
          ),
          BottomNavigationBarItem(
            icon: Text('💊', style: TextStyle(fontSize: 18)),
            label: 'Zdravila',
          ),
          BottomNavigationBarItem(
            icon: Text('📊', style: TextStyle(fontSize: 18)),
            label: 'Poročila',
          ),
          BottomNavigationBarItem(
            icon: Text('👤', style: TextStyle(fontSize: 18)),
            label: 'Profil',
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

// Medicines Screen
class MedicinesScreen extends StatelessWidget {
  const MedicinesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Zdravila'),
      ),
      body: Center(
        child: Text('Zdravila Screen - Coming Soon'),
      ),
    );
  }
}

// Profile / Settings Screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _baseUrlController = TextEditingController();
  final ApiService _apiService = ApiService.instance;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _baseUrlController.text =
        _apiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveBaseUrl() async {
    await _apiService.setBaseUrl(_baseUrlController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Shranjeno: ${_apiService.baseUrl}')),
    );
    setState(() {});
  }

  Future<void> _resetBaseUrl() async {
    await _apiService.resetBaseUrl();
    _baseUrlController.text =
        _apiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vrnjeno na privzeto nastavitev')),
    );
    setState(() {});
  }

  Future<void> _testConnection() async {
    setState(() => _checking = true);
    final reachable = await _apiService.canReachBackend();
    if (!mounted) return;
    setState(() => _checking = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(reachable ? 'Backend dosegljiv ✅' : 'Backend ni dosegljiv ❌'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nastavitve'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Povezava do API strežnika',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu nastaviš, kam se frontend povezuje. Za emulator in računalnik je pogosto dovolj lokalni naslov. Za fizični telefon uporabi LAN IP računalnika (npr. 192.168.1.20).',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trenutni naslov',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _baseUrlController,
                      decoration: const InputDecoration(
                        hintText: 'http://192.168.1.20:8080',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _saveBaseUrl,
                          child: const Text('Shrani'),
                        ),
                        OutlinedButton(
                          onPressed: _resetBaseUrl,
                          child: const Text('Privzeto'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _checking ? null : _testConnection,
                          icon: _checking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.wifi_tethering),
                          label: const Text('Test povezave'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aktivno: ${_apiService.baseUrl}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kako testiraš app',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 8),
                    Text(
                        '• računalnik: zaženi v Chrome/Edge, osnovni naslov je localhost'),
                    Text('• Android emulator: uporabi 10.0.2.2 ali Privzeto'),
                    Text(
                        '• fizični telefon: uporabi LAN IP tvojega računalnika'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
