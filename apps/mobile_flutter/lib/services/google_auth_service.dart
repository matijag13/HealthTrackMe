import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/google_auth_config.dart';

class GoogleAuthCanceled implements Exception {
  const GoogleAuthCanceled();

  @override
  String toString() => 'Google sign-in was cancelled.';
}

class GoogleAuthFailure implements Exception {
  const GoogleAuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  Future<void>? _initializeFuture;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _webAuthSubscription;
  final StreamController<String> _webIdTokenController =
      StreamController<String>.broadcast();
  final StreamController<Object> _webErrorController =
      StreamController<Object>.broadcast();

  bool get usesWebSignInButton => kIsWeb;

  Stream<String> get webIdTokens => _webIdTokenController.stream;

  Stream<Object> get webErrors => _webErrorController.stream;

  Future<void> initializeForWebSignIn() async {
    if (!kIsWeb) {
      return;
    }
    if (!_isWebClientIdConfigured) {
      throw const GoogleAuthFailure('Google client ID is not configured.');
    }
    await _initialize();
  }

  Future<void> _initialize() {
    return _initializeFuture ??= () async {
      if (kIsWeb) {
        await GoogleSignIn.instance.initialize(
          clientId: GoogleAuthConfig.webClientId,
        );
        _listenForWebAuthenticationEvents();
      } else {
        await GoogleSignIn.instance.initialize(
          serverClientId: GoogleAuthConfig.webClientId,
        );
      }
    }();
  }

  bool get _isWebClientIdConfigured {
    final webClientId = GoogleAuthConfig.webClientId;
    return webClientId != null && webClientId.isNotEmpty;
  }

  void _listenForWebAuthenticationEvents() {
    if (_webAuthSubscription != null) {
      return;
    }
    _webAuthSubscription = GoogleSignIn.instance.authenticationEvents.listen(
      _handleWebAuthenticationEvent,
      onError: (Object error) {
        _logGoogleAuthError(error);
        _webErrorController.add(
          _googleAuthFailureFromError(error),
        );
      },
    );
  }

  void _handleWebAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    if (event is GoogleSignInAuthenticationEventSignOut) {
      return;
    }

    if (event is! GoogleSignInAuthenticationEventSignIn) {
      return;
    }
    final idToken = event.user.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      _webErrorController.add(
        const GoogleAuthFailure('Google did not return an ID token.'),
      );
      return;
    }
    _webIdTokenController.add(idToken);
  }

  Future<String> signInAndGetIdToken() async {
    if (!_isWebClientIdConfigured) {
      throw const GoogleAuthFailure('Google client ID is not configured.');
    }

    try {
      await _initialize();

      final supportsAuthenticate = GoogleSignIn.instance.supportsAuthenticate();
      if (!supportsAuthenticate) {
        throw const GoogleAuthFailure(
          'Google sign-in is not available on this platform yet.',
        );
      }

      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const GoogleAuthFailure(
          'Google did not return an ID token.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (error, stackTrace) {
      _logGoogleAuthError(error, stackTrace);
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleAuthCanceled();
      }
      throw _googleAuthFailureFromGoogleSignInException(error);
    } on GoogleAuthFailure {
      rethrow;
    } catch (error, stackTrace) {
      _logGoogleAuthError(error, stackTrace);
      throw GoogleAuthFailure('Google sign-in failed: ${error.toString()}');
    }
  }

  GoogleAuthFailure _googleAuthFailureFromError(Object error) {
    if (error is GoogleSignInException) {
      return _googleAuthFailureFromGoogleSignInException(error);
    }
    return GoogleAuthFailure('Google sign-in failed: ${error.toString()}');
  }

  GoogleAuthFailure _googleAuthFailureFromGoogleSignInException(
    GoogleSignInException error,
  ) {
    final description = error.description?.trim();
    final details = error.details?.toString().trim();
    final buffer = StringBuffer('Google sign-in failed: ${error.code.name}');

    if (description != null && description.isNotEmpty) {
      buffer.write(' - $description');
    }
    if (details != null && details.isNotEmpty) {
      buffer.write(' ($details)');
    }

    return GoogleAuthFailure(buffer.toString());
  }

  void _logGoogleAuthError(Object error, [StackTrace? stackTrace]) {
    if (error is GoogleSignInException) {
      debugPrint('GoogleSignInException code: ${error.code.name}');
      debugPrint(
        'GoogleSignInException description: '
        '${error.description ?? '<none>'}',
      );
      if (error.details != null) {
        debugPrint('GoogleSignInException details: ${error.details}');
      }
      if (stackTrace != null) {
        debugPrintStack(
          label: 'GoogleSignInException stacktrace',
          stackTrace: stackTrace,
        );
      }
      return;
    }

    debugPrint('Unknown Google sign-in exception: $error');
    if (stackTrace != null) {
      debugPrintStack(
        label: 'Unknown Google sign-in exception stacktrace',
        stackTrace: stackTrace,
      );
    }
  }
}
