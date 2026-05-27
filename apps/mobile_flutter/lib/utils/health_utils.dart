import 'dart:convert';

/// Extracts the human-written note from a HealthEntry.notes field,
/// which may be either a plain string or a JSON object with a 'notes' key.
String extractNote(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  if (!raw.startsWith('{')) return raw;
  try {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return m['notes']?.toString() ?? '';
  } catch (_) {
    return '';
  }
}

/// Extracts the full payload map from a HealthEntry.notes JSON blob.
Map<String, dynamic> extractPayload(String? raw) {
  if (raw == null || !raw.startsWith('{')) return {};
  try {
    return Map<String, dynamic>.from(jsonDecode(raw));
  } catch (_) {
    return {};
  }
}

