import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  final _fullNameCtrl = TextEditingController();
  DateTime? _dob;
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  int _stepsGoal = 10000;

  final List<String> _chronic = [];

  bool _diaryEnabled = true;

  @override
  void dispose() {
    _controller.dispose();
    _fullNameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _skipButton() {
    if (_page == 0 || _page == 4) return const SizedBox.shrink();
    return TextButton(onPressed: _finish, child: const Text('Skip'));
  }

  Widget _progressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: _page == i ? 14 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _page == i ? Colors.white : Colors.white54,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              // ================= PAGE 1 =================
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0A84FF), Color(0xFF6C63FF)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: Lottie.network(
                            'https://assets5.lottiefiles.com/packages/lf20_jcikwtux.json',
                            width: 300,
                          ),
                        ),
                      ),
                      const Text(
                        'Your Health, One Place',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Track everything from sleep to blood pressure.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        child: const Text('Get Started'),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // ================= PAGE 2 =================
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                          alignment: Alignment.topRight, child: _skipButton()),
                      const Text('Set up profile',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                      TextField(controller: _fullNameCtrl),
                      const SizedBox(height: 10),
                      ListTile(
                        title: const Text('Date of birth'),
                        subtitle: Text(
                            _dob?.toIso8601String().split('T').first ??
                                'Select'),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _pickDob,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                ),
              ),

              // ================= PAGE 3 =================
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                          alignment: Alignment.topRight, child: _skipButton()),
                      const Text('Health goals',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                      Slider(
                        value: _stepsGoal.toDouble(),
                        min: 5000,
                        max: 20000,
                        divisions: 15,
                        onChanged: (v) =>
                            setState(() => _stepsGoal = v.round()),
                      ),
                      ElevatedButton(
                        onPressed: () => _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                ),
              ),

              // ================= PAGE 4 =================
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                          alignment: Alignment.topRight, child: _skipButton()),
                      const Text('Medical info'),
                      TextField(
                        decoration:
                            const InputDecoration(hintText: 'Add condition'),
                        onSubmitted: (v) {
                          if (v.isNotEmpty) setState(() => _chronic.add(v));
                        },
                      ),
                      ElevatedButton(
                        onPressed: () => _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                ),
              ),

              // ================= PAGE 5 =================
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('Notifications',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                      SwitchListTile(
                        value: _diaryEnabled,
                        onChanged: (v) => setState(() => _diaryEnabled = v),
                        title: const Text('Diary reminder'),
                      ),
                      ElevatedButton(
                        onPressed: _finish,
                        child: const Text('Finish'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: _progressDots(),
          ),
        ],
      ),
    );
  }
}
