import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';

const _bg = Color(0xFF070B13);
const _surface = Color(0xFF0F1624);
const _surfaceAlt = Color(0xFF121B2C);
const _border = Color(0xFF243047);
const _primaryText = Color(0xFFF5F7FB);
const _secondaryText = Color(0xFF94A3B8);
const _accent = Color(0xFF5B8DEF);
const _green = Color(0xFF36D399);

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
    final messenger = ScaffoldMessenger.of(context);
    String message;
    try {
      message = await action();
    } catch (e) {
      message = 'Export failed';
    }
    if (!mounted) return;
    setState(() => _busy = null);
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _surfaceAlt,
        content: Text(message, style: const TextStyle(color: _primaryText)),
      ));
  }

  Future<String> _copySummary() async {
    final summary = await _api.getHealthSummary();
    if (summary == null || summary.isEmpty) return 'No summary available yet';
    await Clipboard.setData(ClipboardData(text: summary));
    return 'Summary copied to clipboard ✓';
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
    return 'Full data (CSV) copied to clipboard ✓';
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
