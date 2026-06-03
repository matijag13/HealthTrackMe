import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../widgets/design_system.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';
import '../services/google_web_sign_in_button.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onSwitchToLogin;
  const RegisterScreen({required this.onSwitchToLogin, super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _background = Color(0xFF070B13);
  static const _card = Color(0xFF0F1624);
  static const _field = Color(0xFF121B2C);
  static const _border = Color(0xFF243047);
  static const _mutedText = Color(0xFF94A3B8);
  static const _primaryText = Color(0xFFF5F7FB);
  static const _toastSurface = Color(0xFF0F1624);
  static const _successAccent = Color(0xFF36D399);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final ApiService _api = ApiService.instance;
  final GoogleAuthService _googleAuth = GoogleAuthService.instance;
  StreamSubscription<String>? _googleWebIdTokenSubscription;
  StreamSubscription<Object>? _googleWebErrorSubscription;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _submitted = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _authError;
  static const _defaultUserType = 'PATIENT';
  DateTime? _selectedDateOfBirth;

  bool get _isDateOfBirthComplete => _selectedDateOfBirth != null;

  bool get _showDateOfBirthError => _submitted && !_isDateOfBirthComplete;

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
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
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
    setState(() {
      _submitted = true;
      _authError = null;
    });
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_isDateOfBirthComplete) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      final dateOfBirth = _formatDateForApi(_selectedDateOfBirth!);
      final user = await _api.createUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dateOfBirth: dateOfBirth,
        userType: _defaultUserType,
      );
      await _api.setActiveUserId(user.id);
      if (!mounted) return;
      _showAuthToast(context, 'Account created successfully');
      context.goNamed('home');
    } catch (error) {
      if (!mounted) return;
      setState(() => _authError = _formatAuthError(error));
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
      setState(() => _authError = 'Google sign-in was cancelled.');
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

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required.';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  String _formatAuthError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '').trim();
    if (text.contains('Email already exists')) {
      return 'Email already exists.';
    }
    return text.isEmpty ? 'Could not create account.' : text;
  }

  String _formatGoogleAuthError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.contains('Google client ID is not configured')) {
      return 'Google client ID is not configured.';
    }
    if (message.contains('Google sign-in was cancelled')) {
      return 'Google sign-in was cancelled.';
    }
    if (message.contains('Google did not return an ID token')) {
      return 'Google did not return an ID token.';
    }
    if (message.contains('not available on this platform')) {
      return 'Google sign-in is not available on this platform yet.';
    }
    if (message.startsWith('Google sign-in failed:')) {
      return message;
    }
    return message.isEmpty
        ? 'Google sign-in failed. Please try again.'
        : 'Google sign-in failed: $message';
  }

  void _clearAuthError() {
    if (_authError != null) {
      setState(() => _authError = null);
    }
  }

  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateForField(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        DateTime draft = _selectedDateOfBirth ?? DateTime(2000);
        if (draft.isAfter(now)) {
          draft = now;
        }

        return Theme(
          data: Theme.of(dialogContext).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              surface: _card,
              onSurface: _primaryText,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: _card),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: _card,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: _card,
              headerForegroundColor: _primaryText,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return _mutedText.withValues(alpha: 0.35);
                }
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return _primaryText;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primaryBlue;
                }
                return Colors.transparent;
              }),
              todayForegroundColor:
                  WidgetStateProperty.all(AppColors.primaryBlue),
              todayBorder:
                  const BorderSide(color: AppColors.primaryBlue, width: 1.2),
              yearForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return _primaryText;
              }),
              yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primaryBlue;
                }
                return Colors.transparent;
              }),
              weekdayStyle: const TextStyle(color: _mutedText),
              dividerColor: _border,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          child: Dialog(
            backgroundColor: _card,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          color: AppColors.primaryBlue,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Date of birth',
                            style: TextStyle(
                              color: _primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: CalendarDatePicker(
                        initialDate: draft,
                        firstDate: DateTime(1900),
                        lastDate: now,
                        currentDate: now,
                        onDateChanged: (date) {
                          Navigator.of(dialogContext).pop<DateTime>(date);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (picked == null || !mounted) return;
    setState(() {
      _selectedDateOfBirth = picked;
      _authError = null;
    });
  }

  void _showAuthToast(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        dismissDirection: DismissDirection.horizontal,
        content: Container(
          decoration: BoxDecoration(
            color: _toastSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _successAccent.withValues(alpha: 0.34),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: [
                Container(width: 4, height: 60, color: _successAccent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _successAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: _successAccent.withValues(alpha: 0.22),
                            ),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: _successAccent,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: _primaryText,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    bool hasError = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: hasError ? AppColors.danger : _border,
        width: hasError ? 1.2 : 1,
      ),
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
        borderSide: BorderSide(
          color: hasError ? AppColors.danger : AppColors.primaryBlue,
          width: 1.2,
        ),
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
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: _border)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Or',
            style: TextStyle(color: _mutedText, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Container(height: 1, color: _border)),
      ],
    );
  }

  Widget _googleButton() {
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
          _isGoogleLoading ? 'Connecting...' : 'Continue with Google',
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
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
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
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'HealthTrackMe',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Create account',
                        style: TextStyle(
                          color: _primaryText,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Set up your health profile to continue.',
                        style: TextStyle(color: _mutedText, fontSize: 15),
                      ),
                      const SizedBox(height: 30),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final narrow = constraints.maxWidth < 430;
                          final firstName = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('First name'),
                              TextFormField(
                                controller: _firstNameController,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Required'
                                    : null,
                                style: const TextStyle(color: _primaryText),
                                decoration: _inputDecoration(
                                  hintText: 'First name',
                                  prefixIcon: Icons.person_outline,
                                ),
                              ),
                            ],
                          );
                          final lastName = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('Last name'),
                              TextFormField(
                                controller: _lastNameController,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Required'
                                    : null,
                                style: const TextStyle(color: _primaryText),
                                decoration: _inputDecoration(
                                  hintText: 'Last name',
                                  prefixIcon: Icons.person_outline,
                                ),
                              ),
                            ],
                          );

                          if (narrow) {
                            return Column(
                              children: [
                                firstName,
                                const SizedBox(height: 18),
                                lastName,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: firstName),
                              const SizedBox(width: 14),
                              Expanded(child: lastName),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      _fieldLabel('Email'),
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
                      _fieldLabel('Date of birth'),
                      TextFormField(
                        key: ValueKey(
                          _selectedDateOfBirth?.toIso8601String() ?? 'empty',
                        ),
                        readOnly: true,
                        initialValue: _selectedDateOfBirth == null
                            ? ''
                            : _formatDateForField(_selectedDateOfBirth!),
                        onTap: _pickDateOfBirth,
                        style: const TextStyle(color: _primaryText),
                        decoration: _inputDecoration(
                          hintText: 'Select date',
                          prefixIcon: Icons.calendar_today_outlined,
                          suffixIcon: IconButton(
                            onPressed: _pickDateOfBirth,
                            icon: const Icon(
                              Icons.expand_more_rounded,
                              color: _mutedText,
                            ),
                          ),
                          hasError: _showDateOfBirthError,
                        ),
                      ),
                      if (_showDateOfBirthError) ...[
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text(
                            'Date of birth is required.',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _fieldLabel('Password'),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onChanged: (_) {
                          if (_submitted) {
                            _formKey.currentState?.validate();
                          }
                        },
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Password is required.'
                            : null,
                        style: const TextStyle(color: _primaryText),
                        decoration: _inputDecoration(
                          hintText: 'Create a password',
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
                      const SizedBox(height: 18),
                      _fieldLabel('Confirm password'),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        onChanged: (_) {
                          if (_submitted) {
                            _formKey.currentState?.validate();
                          }
                        },
                        validator: _validateConfirmPassword,
                        style: const TextStyle(color: _primaryText),
                        decoration: _inputDecoration(
                          hintText: 'Confirm your password',
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _mutedText,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
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
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? LoadingSkeleton.buttonSmall(context)
                              : const Text(
                                  'Create account',
                                  style: TextStyle(
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
                          const Flexible(
                            child: Text(
                              'Already have an account?',
                              style: TextStyle(color: _mutedText),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: widget.onSwitchToLogin,
                            child: const Text(
                              'Log in',
                              style: TextStyle(
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
