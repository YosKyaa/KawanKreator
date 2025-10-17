import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;

class AuthService {
  final SupabaseClient _client;
  final String webClientId;
  final String? iosClientId;

  AuthService({
    required SupabaseClient client,
    required this.webClientId,
    this.iosClientId,
  }) : _client = client;

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _client.auth.signInWithOAuth(OAuthProvider.google);
      return;
    }
    if (Platform.isAndroid || Platform.isIOS) {
      final googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
        clientId: iosClientId, // for iOS
      );
      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser?.authentication;
      final accessToken = googleAuth?.accessToken;
      final idToken = googleAuth?.idToken;
      if (idToken == null || accessToken == null) {
        throw AuthException('Failed to get Google tokens');
      }
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      return;
    }
    throw AuthException('Unsupported platform for Google Sign-In');
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> sendMagicLink({required String email}) async {
    await _client.auth.signInWithOtp(email: email);
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> resetPassword({required String email}) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> verifyOtp({required String email, required String token}) async {
    await _client.auth.verifyOTP(
      type: OtpType.magiclink,
      token: token,
      email: email,
    );
  }
}
