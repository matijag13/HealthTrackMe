import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _surface = Color(0xFF0F1624);
const _surfaceAlt = Color(0xFF121B2C);
const _border = Color(0xFF243047);
const _primaryText = Color(0xFFF5F7FB);
const _secondaryText = Color(0xFF94A3B8);
const _accent = Color(0xFF5B8DEF);
const _danger = Color(0xFFFF5C7A);

Future<TimeOfDay?> showDarkTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String title = 'Enter time',
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (_) => _DarkTimePickerDialog(
      initialTime: initialTime,
      title: title,
    ),
  );
}

class _DarkTimePickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final String title;

  const _DarkTimePickerDialog({
    required this.initialTime,
    required this.title,
  });

  @override
  State<_DarkTimePickerDialog> createState() => _DarkTimePickerDialogState();
}

class _DarkTimePickerDialogState extends State<_DarkTimePickerDialog> {
  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;
  late bool _isPm;
  String? _error;

  @override
  void initState() {
    super.initState();
    final hour = widget.initialTime.hour;
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    _hourController = TextEditingController(text: '$hour12');
    _minuteController = TextEditingController(
      text: widget.initialTime.minute.toString().padLeft(2, '0'),
    );
    _isPm = hour >= 12;
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _save() {
    final hour = int.tryParse(_hourController.text.trim());
    final minute = int.tryParse(_minuteController.text.trim());
    if (hour == null ||
        minute == null ||
        hour < 1 ||
        hour > 12 ||
        minute < 0 ||
        minute > 59) {
      setState(() => _error = 'Enter a valid time');
      return;
    }

    final normalizedHour =
        _isPm ? (hour == 12 ? 12 : hour + 12) : (hour == 12 ? 0 : hour);
    Navigator.pop(
      context,
      TimeOfDay(hour: normalizedHour, minute: minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: _border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      title: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                color: _primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _CloseButton(onTap: () => Navigator.pop(context)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TimeInputBox(
                    controller: _hourController,
                    label: 'Hour',
                    onChanged: () => setState(() => _error = null),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 26),
                  child: Text(
                    ':',
                    style: TextStyle(
                      color: _primaryText,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: _TimeInputBox(
                    controller: _minuteController,
                    label: 'Minute',
                    onChanged: () => setState(() => _error = null),
                  ),
                ),
                const SizedBox(width: 10),
                _PeriodToggle(
                  isPm: _isPm,
                  onChanged: (value) => setState(() => _isPm = value),
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: _error == null
                  ? const SizedBox(height: 20)
                  : Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: _danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: _primaryText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }
}

class _TimeInputBox extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;

  const _TimeInputBox({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 2,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => onChanged(),
          style: const TextStyle(
            color: _primaryText,
            fontSize: 38,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: _surfaceAlt,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _accent),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: _secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  final bool isPm;
  final ValueChanged<bool> onChanged;

  const _PeriodToggle({
    required this.isPm,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PeriodButton(
            label: 'AM',
            selected: !isPm,
            onTap: () => onChanged(false),
            top: true,
          ),
          Container(height: 1, color: _border),
          _PeriodButton(
            label: 'PM',
            selected: isPm,
            onTap: () => onChanged(true),
            top: false,
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool top;

  const _PeriodButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.top,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: top ? const Radius.circular(13) : Radius.zero,
          bottom: top ? Radius.zero : const Radius.circular(13),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                selected ? _accent.withValues(alpha: 0.22) : Colors.transparent,
            borderRadius: BorderRadius.vertical(
              top: top ? const Radius.circular(13) : Radius.zero,
              bottom: top ? Radius.zero : const Radius.circular(13),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _primaryText : _secondaryText,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _surfaceAlt,
            shape: BoxShape.circle,
            border: Border.all(
              color: _secondaryText.withValues(alpha: 0.34),
              width: 1.2,
            ),
          ),
          child: const Icon(
            Icons.close_rounded,
            color: _primaryText,
            size: 24,
          ),
        ),
      ),
    );
  }
}
