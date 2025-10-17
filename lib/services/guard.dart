import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'preferences_service.dart';

final isLoggedInProvider = Provider<bool>(
  (ref) => Supabase.instance.client.auth.currentUser != null,
);
final isGuestProvider = FutureProvider<bool>(
  (ref) async => await PreferencesService().getIsGuest(),
);
