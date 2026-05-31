import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;
  final VoidCallback onSaved;

  const EditProfileScreen({
    required this.user,
    required this.onSaved,
    super.key,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _bg = Color(0xFF070B13);
  static const _surface = Color(0xFF0F1624);
  static const _surfaceAlt = Color(0xFF121B2C);
  static const _border = Color(0xFF243047);
  static const _primaryText = Color(0xFFF5F7FB);
  static const _secondaryText = Color(0xFF94A3B8);
  static const _fieldLabel = Color(0xFFC7D2E5);
  static const _fieldHint = Color(0xFFA7B4C8);
  static const _accent = Color(0xFF5B8DEF);
  static const _danger = Color(0xFFFF6B6B);

  late final ApiService _api;
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _dobController;
  late final TextEditingController _medicalController;
  late final TextEditingController _allergiesController;
  late String _userType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _api = ApiService.instance;
    _formKey = GlobalKey<FormState>();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _dobController = TextEditingController(text: widget.user.dateOfBirth);
    _medicalController =
        TextEditingController(text: widget.user.medicalConditions ?? '');
    _allergiesController =
        TextEditingController(text: widget.user.allergies ?? '');
    _userType = widget.user.userType;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _medicalController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updated = User(
        id: widget.user.id,
        email: widget.user.email,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        userType: _userType,
        medicalConditions: _medicalController.text.trim().isEmpty
            ? null
            : _medicalController.text.trim(),
        allergies: _allergiesController.text.trim().isEmpty
            ? null
            : _allergiesController.text.trim(),
        isActive: widget.user.isActive,
      );

      await _api.updateUser(widget.user.id, updated);

      if (!mounted) return;
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile was successfully updated')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: _danger),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _selectDateOfBirth() async {
    try {
      final current = DateTime.tryParse(_dobController.text);
      final picked = await showDatePicker(
        context: context,
        initialDate:
            current ?? DateTime.now().subtract(const Duration(days: 365 * 30)),
        firstDate: DateTime(1940),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: _accent,
                surface: _surface,
                onSurface: _primaryText,
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: _surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: const BorderSide(color: _border),
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        _dobController.text = picked.toIso8601String().split('T').first;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting date: $e')),
      );
    }
  }

  void _cancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _topBar(),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _profilePreviewCard(),
                  const SizedBox(height: 24),
                  _section(
                    'Personal Information',
                    [
                      _darkTextField(
                        controller: _firstNameController,
                        label: 'First name',
                        hint: 'Enter your first name',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'First name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _darkTextField(
                        controller: _lastNameController,
                        label: 'Last name',
                        hint: 'Enter your last name',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Last name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _darkTextField(
                        controller: _dobController,
                        label: 'Date of birth',
                        hint: 'YYYY-MM-DD',
                        icon: Icons.calendar_today_outlined,
                        textInputAction: TextInputAction.next,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_month_outlined),
                          onPressed: _selectDateOfBirth,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Date of birth is required';
                          }
                          if (DateTime.tryParse(value) == null) {
                            return 'Invalid date format (YYYY-MM-DD)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _userTypeDropdown(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _section(
                    'Health Information',
                    [
                      _darkTextField(
                        controller: _medicalController,
                        label: 'Medical conditions',
                        hint: 'e.g. Diabetes, asthma...',
                        icon: Icons.medical_information_outlined,
                        maxLines: 3,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _darkTextField(
                        controller: _allergiesController,
                        label: 'Allergies',
                        hint: 'e.g. Penicillin, peanuts...',
                        icon: Icons.warning_amber_outlined,
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _bottomActions(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        _IconButtonSurface(icon: Icons.arrow_back, onTap: _cancel),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Edit Profile',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _primaryText,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
          ),
        ),
      ],
    );
  }

  Widget _profilePreviewCard() {
    final fullName = [
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
    ].where((part) => part.isNotEmpty).join(' ');

    return _DarkCard(
      child: Row(
        children: [
          _Avatar(user: widget.user),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName.isEmpty ? widget.user.fullName : fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _secondaryText, fontSize: 13),
                ),
                const SizedBox(height: 10),
                _Badge(text: _userType),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            title,
            style: const TextStyle(
              color: _primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _DarkCard(
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _darkTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
    int maxLines = 1,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textInputAction: textInputAction,
      validator: validator,
      style: const TextStyle(color: _primaryText, fontWeight: FontWeight.w700),
      cursorColor: _accent,
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
        suffixIcon: suffixIcon,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        color: _fieldLabel.withValues(alpha: 0.86),
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: const TextStyle(
        color: _fieldLabel,
        fontWeight: FontWeight.w800,
      ),
      hintStyle: TextStyle(
        color: _fieldHint.withValues(alpha: 0.78),
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: _accent),
      suffixIcon: suffixIcon == null
          ? null
          : IconTheme(
              data: const IconThemeData(color: _accent), child: suffixIcon),
      filled: true,
      fillColor: _surfaceAlt,
      errorStyle: const TextStyle(color: _danger),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _accent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _danger, width: 1.4),
      ),
    );
  }

  Widget _userTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _userType,
      dropdownColor: _surfaceAlt,
      iconEnabledColor: _accent,
      style: const TextStyle(color: _primaryText, fontWeight: FontWeight.w700),
      decoration: _inputDecoration(
        label: 'User type',
        hint: 'Select user type',
        icon: Icons.category_outlined,
      ),
      items: const [
        DropdownMenuItem(value: 'PATIENT', child: Text('Patient')),
        DropdownMenuItem(value: 'ATHLETE', child: Text('Athlete')),
        DropdownMenuItem(value: 'ELDERLY', child: Text('Elderly')),
        DropdownMenuItem(
          value: 'HEALTHCARE_WORKER',
          child: Text('Healthcare worker'),
        ),
      ],
      onChanged: (value) {
        if (value != null) setState(() => _userType = value);
      },
    );
  }

  Widget _bottomActions() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 54,
            child: OutlinedButton(
              onPressed: _isSaving ? null : _cancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryText,
                disabledForegroundColor: _secondaryText.withValues(alpha: 0.55),
                backgroundColor: _surface,
                side: const BorderSide(color: _border, width: 1.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _accent.withValues(alpha: 0.38),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
        ),
      ],
    );
  }
}

class _DarkCard extends StatelessWidget {
  final Widget child;

  const _DarkCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _EditProfileScreenState._surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _EditProfileScreenState._border.withValues(alpha: 0.75),
        ),
      ),
      child: child,
    );
  }
}

class _Avatar extends StatelessWidget {
  final User user;

  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    final photo = user.profilePhotoBase64;
    if (photo != null && photo.isNotEmpty) {
      try {
        image = MemoryImage(base64Decode(photo));
      } catch (_) {
        image = null;
      }
    }

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _EditProfileScreenState._border),
      ),
      child: CircleAvatar(
        backgroundColor: _EditProfileScreenState._surfaceAlt,
        backgroundImage: image,
        child: image == null
            ? Text(
                user.initials,
                style: const TextStyle(
                  color: _EditProfileScreenState._primaryText,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              )
            : null,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _EditProfileScreenState._accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _EditProfileScreenState._accent.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _EditProfileScreenState._primaryText,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _IconButtonSurface extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButtonSurface({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _EditProfileScreenState._surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _EditProfileScreenState._border),
          ),
          child: Icon(
            icon,
            color: _EditProfileScreenState._primaryText,
            size: 21,
          ),
        ),
      ),
    );
  }
}
