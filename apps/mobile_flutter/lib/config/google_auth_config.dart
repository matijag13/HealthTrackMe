class GoogleAuthConfig {
  // TODO: Set with --dart-define=GOOGLE_WEB_CLIENT_ID=<web-client-id>.apps.googleusercontent.com
  // The OAuth Web client ID is public; the backend still validates it through
  // GOOGLE_OAUTH_ALLOWED_CLIENT_IDS.
  static const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static String? get webClientId {
    final value = _webClientId.trim();
    return value.isEmpty ? null : value;
  }
}
