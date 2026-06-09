import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';
import '../services/google_web_sign_in_button.dart';
import '../l10n/l10n.dart';
import '../widgets/app_logo.dart';
import '../widgets/design_system.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onSwitchToRegister;
  const LoginScreen({required this.onSwitchToRegister, super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _background = Color(0xFF070B13);
  static const _card = Color(0xFF0F1624);
  static const _field = Color(0xFF121B2C);
  static const _border = Color(0xFF243047);
  static const _mutedText = Color(0xFF94A3B8);
  static const _primaryText = Color(0xFFF5F7FB);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _api = ApiService.instance;
  final GoogleAuthService _googleAuth = GoogleAuthService.instance;
  StreamSubscription<String>? _googleWebIdTokenSubscription;
  StreamSubscription<Object>? _googleWebErrorSubscription;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _authError;

  @override
  void initState() {
    super.initState();
    if (_googleAuth.usesWebSignInButton) {
      _initializeGoogleWebSignIn();
      _googleWebIdTokenSubscription = _googleAuth.webIdTokens.listen(
        _loginWithGoogleIdToken,
      );
      _googleWebErrorSubscription = _googleAuth.webErrors.listen((error) {
        if (!mounted) return;
        setState(() => _authError = _formatGoogleAuthError(error));
      });
    }
  }

  @override
  void dispose() {
    _googleWebIdTokenSubscription?.cancel();
    _googleWebErrorSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _initializeGoogleWebSignIn() async {
    try {
      await _googleAuth.initializeForWebSignIn();
    } catch (error) {
      if (!mounted) return;
      setState(() => _authError = _formatGoogleAuthError(error));
    }
  }

  String? _validateEmail(String? value) {
    final l10n = context.l10n;
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return l10n.emailRequired;
    }
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email)) {
      return l10n.enterValidEmail;
    }
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _authError = null;
      _isLoading = true;
    });
    try {
      final email = _emailController.text.trim();
      final user = await _api.login(
        email: email,
        password: _passwordController.text,
      );
      await _api.setActiveUserId(null);
      await _api.setActiveUserId(user.id);
      if (!mounted) return;
      context.goNamed('home');
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().contains('Invalid email or password')
          ? context.l10n.invalidEmailOrPassword
          : error.toString().replaceFirst('Exception: ', '');
      setState(() => _authError = message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _authError = null;
      _isGoogleLoading = true;
    });

    try {
      final idToken = await _googleAuth.signInAndGetIdToken();
      await _loginWithGoogleIdToken(idToken);
    } on GoogleAuthCanceled {
      if (!mounted) return;
      setState(() => _authError = context.l10n.googleSignInCancelled);
    } catch (error) {
      if (!mounted) return;
      setState(() => _authError = _formatGoogleAuthError(error));
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _loginWithGoogleIdToken(String idToken) async {
    if (!mounted) return;
    setState(() {
      _authError = null;
      _isGoogleLoading = true;
    });

    try {
      final user = await _api.loginWithGoogle(idToken);
      await _api.setActiveUserId(null);
      await _api.setActiveUserId(user.id);
      if (!mounted) return;
      context.goNamed('home');
    } catch (error) {
      if (!mounted) return;
      setState(() => _authError = _formatGoogleAuthError(error));
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  String _formatGoogleAuthError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.contains('Google client ID is not configured')) {
      return context.l10n.googleClientIdNotConfigured;
    }
    if (message.contains('Google sign-in was cancelled')) {
      return context.l10n.googleSignInCancelled;
    }
    if (message.contains('Google did not return an ID token')) {
      return context.l10n.googleNoIdToken;
    }
    if (message.contains('not available on this platform')) {
      return context.l10n.googleSignInUnavailable;
    }
    if (message.startsWith('Google sign-in failed:')) {
      return message;
    }
    return message.isEmpty
        ? context.l10n.googleSignInFailedTryAgain
        : context.l10n.googleSignInFailed(message);
  }

  void _clearAuthError() {
    if (_authError != null) {
      setState(() => _authError = null);
    }
  }

  Widget _authErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFFF8A8A),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFFC4C4),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: _primaryText,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _border),
    );

    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: _mutedText),
      prefixIcon: Icon(prefixIcon, color: _mutedText, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.2),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
      ),
    );
  }

  Widget _orDivider() {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: _border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            l10n.or,
            style: const TextStyle(
              color: _mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: _border)),
      ],
    );
  }

  Widget _googleButton() {
    final l10n = context.l10n;
    if (_googleAuth.usesWebSignInButton) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: Center(child: buildGoogleWebSignInButton()),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: (_isLoading || _isGoogleLoading) ? null : _loginWithGoogle,
        icon: _isGoogleLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'G',
                style: TextStyle(
                  color: _primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
        label: Text(
          _isGoogleLoading ? l10n.connecting : l10n.continueWithGoogle,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryText,
          side: const BorderSide(color: _border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        children: [
                          AppLogo(size: 32),
                          SizedBox(width: 10),
                          Text(
                            'HealthTrackMe',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.logIn,
                        style: const TextStyle(
                          color: _primaryText,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.enterCredentialsToContinue,
                        style: const TextStyle(
                          color: _mutedText,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _fieldLabel(l10n.email),
                      TextFormField(
                        controller: _emailController,
                        onChanged: (_) => _clearAuthError(),
                        validator: _validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: _primaryText),
                        decoration: _inputDecoration(
                          hintText: 'you@example.com',
                          prefixIcon: Icons.mail_outline,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _fieldLabel(l10n.password),
                      TextFormField(
                        controller: _passwordController,
                        onChanged: (_) => _clearAuthError(),
                        obscureText: _obscurePassword,
                        validator: (v) => (v == null || v.isEmpty)
                            ? l10n.passwordRequired
                            : null,
                        style: const TextStyle(color: _primaryText),
                        decoration: _inputDecoration(
                          hintText: l10n.enterYourPassword,
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _mutedText,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                      ),
                      if (_authError != null) ...[
                        const SizedBox(height: 18),
                        _authErrorBanner(_authError!),
                      ],
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? LoadingSkeleton.buttonSmall(context)
                              : Text(
                                  l10n.logIn,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _orDivider(),
                      const SizedBox(height: 18),
                      _googleButton(),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              l10n.dontHaveAccount,
                              style: const TextStyle(color: _mutedText),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: widget.onSwitchToRegister,
                            child: Text(
                              l10n.register,
                              style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
