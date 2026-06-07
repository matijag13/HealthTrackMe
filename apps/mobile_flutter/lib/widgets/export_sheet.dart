import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';

const _bg = Color(0xFF070B13);
const _surface = Color(0xFF0F1624);
const _border = Color(0xFF243047);
const _primaryText = Color(0xFFF5F7FB);
const _secondaryText = Color(0xFF94A3B8);
const _accent = Color(0xFF5B8DEF);
const _green = Color(0xFF36D399);
const _danger = Color(0xFFFF5C7A);
const _warning = Color(0xFFF5B941);

enum _ExportToastType { success, error, warning, neutral }

class _ExportToastTheme {
  final IconData icon;
  final Color accent;

  const _ExportToastTheme({required this.icon, required this.accent});
}

/// Opens the export options sheet: copy summary, email summary, or copy full CSV.
Future<void> showExportSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _ExportSheet(),
  );
}

class _ExportSheet extends StatefulWidget {
  const _ExportSheet();

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  final ApiService _api = ApiService.instance;
  String? _busy; // which action is running

  Future<void> _run(String key, Future<String> Function() action) async {
    if (_busy != null) return;
    setState(() => _busy = key);
    String message;
    var type = _ExportToastType.success;
    try {
      message = await action();
    } catch (e) {
      message = 'Export failed';
      type = _ExportToastType.error;
    }
    if (!mounted) return;
    setState(() => _busy = null);
    if (message.startsWith('No ') || message.startsWith('Please ')) {
      type = _ExportToastType.warning;
    }
    _showExportToast(message, type: type);
  }

  Future<String> _copySummary() async {
    final summary = await _api.getHealthSummary();
    if (summary == null || summary.isEmpty) return 'No summary available yet';
    await Clipboard.setData(ClipboardData(text: summary));
    return 'Summary copied to clipboard';
  }

  Future<String> _emailSummary() async {
    final result = await _api.emailHealthSummary();
    return result.message;
  }

  Future<String> _copyCsv() async {
    final id = await _api.ensureActiveUserId();
    if (id == null) return 'Please sign in first';
    final csv = await _api.exportCsv('/export/all/$id');
    if (csv == null || csv.isEmpty) return 'No data to export yet';
    await Clipboard.setData(ClipboardData(text: csv));
    return 'Full data (CSV) copied to clipboard';
  }

  void _showExportToast(
    String message, {
    _ExportToastType type = _ExportToastType.neutral,
  }) {
    final theme = switch (type) {
      _ExportToastType.success => const _ExportToastTheme(
          icon: Icons.check_circle_rounded,
          accent: _green,
        ),
      _ExportToastType.error => const _ExportToastTheme(
          icon: Icons.error_outline_rounded,
          accent: _danger,
        ),
      _ExportToastType.warning => const _ExportToastTheme(
          icon: Icons.info_outline_rounded,
          accent: _warning,
        ),
      _ExportToastType.neutral => const _ExportToastTheme(
          icon: Icons.notifications_none_rounded,
          accent: _accent,
        ),
    };

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
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.accent.withValues(alpha: 0.34)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: theme.accent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(18),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: theme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: theme.accent.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Icon(theme.icon, color: theme.accent, size: 19),
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: _border),
          left: BorderSide(color: _border),
          right: BorderSide(color: _border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _secondaryText.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Export your data',
                  style: TextStyle(
                      color: _primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Copy to clipboard or send to your email',
                  style: TextStyle(color: _secondaryText, fontSize: 13)),
              const SizedBox(height: 18),
              _ExportTile(
                icon: Icons.content_copy_rounded,
                color: _accent,
                title: 'Copy summary',
                subtitle: 'Readable health summary',
                loading: _busy == 'sum',
                onTap: () => _run('sum', _copySummary),
              ),
              _ExportTile(
                icon: Icons.mail_outline_rounded,
                color: _green,
                title: 'Email summary to me',
                subtitle: 'Sent to your account email',
                loading: _busy == 'mail',
                onTap: () => _run('mail', _emailSummary),
              ),
              _ExportTile(
                icon: Icons.table_chart_outlined,
                color: _accent,
                title: 'Copy full data (CSV)',
                subtitle: 'Entries + activities as CSV',
                loading: _busy == 'csv',
                onTap: () => _run('csv', _copyCsv),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback onTap;

  const _ExportTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: _primaryText,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              color: _secondaryText, fontSize: 12)),
                    ],
                  ),
                ),
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _accent),
                  )
                else
                  const Icon(Icons.chevron_right_rounded,
                      color: _secondaryText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
