import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../widgets/design_system.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onSwitchToRegister;
  const LoginScreen({required this.onSwitchToRegister, super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _api = ApiService.instance;
  bool _isLoading = false;
  bool _obscurePassword = true;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required.';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email)) return 'Enter a valid email.';
    return null;
  }
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final users = await _api.getUsers();
      final user = users.firstWhere(
        (u) => u.email == email,
        orElse: () => throw Exception('Account not found. Please register first.'),
      );
      await _api.setActiveUserId(user.id);
      if (!mounted) return;
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
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D2137), AppColors.navy, Color(0xFF0F4C75)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Health',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
                      children: [
                        TextSpan(text: 'Track', style: TextStyle(color: AppColors.teal)),
                        TextSpan(text: 'Me'),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('Your personal health platform', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 48),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 32)],
                    ),
                    padding: EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sign In', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.navy)),
                          SizedBox(height: 4),
                          Text('Enter your credentials', style: TextStyle(color: AppColors.muted)),
                          SizedBox(height: 24),
                          TextFormField(controller: _emailController, validator: _validateEmail, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                          SizedBox(height: 16),
                          TextFormField(controller: _passwordController, obscureText: _obscurePassword, validator: (v) => (v == null || v.isEmpty) ? 'Password is required.' : null, decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                          SizedBox(height: 24),
                          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _login, child: _isLoading ? LoadingSkeleton.buttonSmall(context) : const Text('Sign In'))),
                          SizedBox(height: 16),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Don\'t have an account?'), TextButton(onPressed: widget.onSwitchToRegister, child: Text('Register'))]),
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
