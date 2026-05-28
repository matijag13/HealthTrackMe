import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../widgets/design_system.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onSwitchToLogin;
  const RegisterScreen({required this.onSwitchToLogin, super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final ApiService _api = ApiService.instance;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedUserType = 'PATIENT';
  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedDay;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email is required.';
    }
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email)) {
      return 'Enter a valid email.';
    }
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedYear == null ||
        _selectedMonth == null ||
        _selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please select your date of birth.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final dateOfBirth =
          '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-${_selectedDay.toString().padLeft(2, '0')}';
      final user = await _api.createUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dateOfBirth: dateOfBirth,
        userType: _selectedUserType,
      );
      await _api.setActiveUserId(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Account created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.goNamed('home');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $error'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D2137), AppColors.navy, Color(0xFF0F4C75)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'Health',
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                        children: [
                          TextSpan(
                              text: 'Track',
                              style: TextStyle(color: AppColors.teal)),
                          const TextSpan(text: 'Me'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Create your health account',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 32)
                      ],
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Register',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy)),
                          const SizedBox(height: 4),
                          const Text('Enter your details',
                              style: TextStyle(color: AppColors.muted)),
                          const SizedBox(height: 24),
                          Row(children: [
                            Expanded(
                                child: TextFormField(
                                    controller: _firstNameController,
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'Required'
                                        : null,
                                    decoration: InputDecoration(
                                        labelText: 'First name',
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: TextFormField(
                                    controller: _lastNameController,
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'Required'
                                        : null,
                                    decoration: InputDecoration(
                                        labelText: 'Last name',
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)))))
                          ]),
                          const SizedBox(height: 16),
                          TextFormField(
                              controller: _emailController,
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)))),
                          const SizedBox(height: 16),
                          const Text('Date of birth',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted)),
                          const SizedBox(height: 8),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final narrow = constraints.maxWidth < 420;

                              final yearField = DropdownButtonFormField<int>(
                                value: _selectedYear,
                                hint: const Text('Year'),
                                items: List.generate(100,
                                        (i) => DateTime.now().year - 80 + i)
                                    .map((y) => DropdownMenuItem(
                                        value: y, child: Text(y.toString())))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedYear = v),
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                              );
                              final monthField = DropdownButtonFormField<int>(
                                value: _selectedMonth,
                                hint: const Text('Month'),
                                items: List.generate(12, (i) => i + 1)
                                    .map((m) => DropdownMenuItem(
                                        value: m,
                                        child:
                                            Text(m.toString().padLeft(2, '0'))))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedMonth = v),
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                              );
                              final dayField = DropdownButtonFormField<int>(
                                value: _selectedDay,
                                hint: const Text('Day'),
                                items: List.generate(31, (i) => i + 1)
                                    .map((d) => DropdownMenuItem(
                                        value: d,
                                        child:
                                            Text(d.toString().padLeft(2, '0'))))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedDay = v),
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                              );

                              if (narrow) {
                                return Column(
                                  children: [
                                    yearField,
                                    const SizedBox(height: 8),
                                    monthField,
                                    const SizedBox(height: 8),
                                    dayField,
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: yearField),
                                  const SizedBox(width: 8),
                                  Expanded(child: monthField),
                                  const SizedBox(width: 8),
                                  Expanded(child: dayField),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedUserType,
                            items: const [
                              DropdownMenuItem(
                                  value: 'PATIENT', child: Text('Patient')),
                              DropdownMenuItem(
                                  value: 'ATHLETE', child: Text('Athlete')),
                              DropdownMenuItem(
                                  value: 'ELDERLY', child: Text('Elderly')),
                              DropdownMenuItem(
                                  value: 'HEALTHCARE_WORKER',
                                  child: Text('Healthcare worker')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedUserType = value);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'User type',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Password is required.'
                                  : null,
                              decoration: InputDecoration(
                                  labelText: 'Password',
                                  suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility),
                                      onPressed: () => setState(() =>
                                          _obscurePassword =
                                              !_obscurePassword)),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)))),
                          const SizedBox(height: 24),
                          SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                  onPressed: _isLoading ? null : _register,
                                  child: _isLoading
                                      ? LoadingSkeleton.buttonSmall(context)
                                      : const Text('Create account'))),
                          const SizedBox(height: 16),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Already have an account?',
                                    style: TextStyle(color: AppColors.muted)),
                                TextButton(
                                    onPressed: widget.onSwitchToLogin,
                                    child: const Text('Sign In',
                                        style: TextStyle(
                                            color: AppColors.blue,
                                            fontWeight: FontWeight.w600)))
                              ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
