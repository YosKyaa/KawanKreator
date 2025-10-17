import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kawankreatorapps/services/analytics.dart';
import 'package:kawankreatorapps/services/preferences_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'auth_service.dart';

class AuthUiState {
  final supabase.User? user;
  final bool loading;
  final String? error;
  final bool isGuest;

  const AuthUiState({
    this.user,
    this.loading = false,
    this.error,
    this.isGuest = false,
  });

  AuthUiState copyWith({
    supabase.User? user,
    bool? loading,
    String? error,
    bool? isGuest,
  }) {
    return AuthUiState(
      user: user ?? this.user,
      loading: loading ?? this.loading,
      error: error,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}

class AuthController extends AutoDisposeNotifier<AuthUiState> {
  late final AuthService _service;
  late final PreferencesService _prefs;
  StreamSubscription<supabase.AuthState>? _sub;

  @override
  AuthUiState build() {
    _service = ref.read(authServiceProvider);
    _prefs = ref.read(preferencesServiceProvider);

    final user = supabase.Supabase.instance.client.auth.currentUser;
    _sub = supabase.Supabase.instance.client.auth.onAuthStateChange.listen((
      event,
    ) {
      final session = event.session;
      if (session?.user != null) {
        state = state.copyWith(
          user: session!.user,
          loading: false,
          isGuest: false,
          error: null,
        );
      } else if (event.event == supabase.AuthChangeEvent.signedOut) {
        state = state.copyWith(user: null, loading: false);
      }
    });

    ref.onDispose(() {
      _sub?.cancel();
    });

    _prefs.getIsGuest().then(
      (isGuest) => state = state.copyWith(isGuest: isGuest),
    );

    return AuthUiState(user: user, loading: false);
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _service.signInWithGoogle();
      Analytics.logEvent('auth_google_success');
      state = state.copyWith(loading: false, isGuest: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> signInWithMagicLink(String email) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _service.sendMagicLink(email: email);
      await _prefs.rememberEmail(email);
      Analytics.logEvent('magiclink_sent');
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _service.signUpWithEmail(email: email, password: password);
      await _prefs.rememberEmail(email);
      Analytics.logEvent('email_signup_success');
      state = state.copyWith(loading: false, isGuest: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _service.signInWithEmail(email: email, password: password);
      await _prefs.rememberEmail(email);
      Analytics.logEvent('email_login_success');
      state = state.copyWith(loading: false, isGuest: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _service.resetPassword(email: email);
      Analytics.logEvent('reset_password_sent');
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> verifyOtp(String email, String token) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _service.verifyOtp(email: email, token: token);
      Analytics.logEvent('otp_verified');
      state = state.copyWith(loading: false, isGuest: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> enterAsGuest() async {
    await _prefs.setIsGuest(true);
    state = state.copyWith(isGuest: true);
    Analytics.logEvent('guest_entered');
  }

  Future<void> signOut() async {
    await _service.signOut();
    await _prefs.setIsGuest(false);
    state = const AuthUiState();
  }
}

final preferencesServiceProvider = Provider<PreferencesService>(
  (ref) => PreferencesService(),
);

final authServiceProvider = Provider<AuthService>((ref) {
  final client = supabase.Supabase.instance.client;
  return AuthService(
    client: client,
    webClientId: _googleWebClientId,
    iosClientId: _googleIosClientId,
  );
});

String _googleWebClientId = '';
String? _googleIosClientId;
void initAuthServiceIds({required String webClientId, String? iosClientId}) {
  _googleWebClientId = webClientId;
  _googleIosClientId = iosClientId;
}

final authControllerProvider =
    AutoDisposeNotifierProvider<AuthController, AuthUiState>(
      () => AuthController(),
    );
