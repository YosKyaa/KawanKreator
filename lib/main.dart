// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kawankreatorapps/app_router.dart';
import 'package:kawankreatorapps/modules/auth/auth_controller.dart';
import 'package:kawankreatorapps/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase config (gunakan milik Anda)
const SUPABASE_URL = 'https://loiokqbnrnsdobxgfpvg.supabase.co';
const SUPABASE_ANON_KEY =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvaW9rcWJucm5zZG9ieGdmcHZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1MzE3MjMsImV4cCI6MjA3NjEwNzcyM30.Gfypn22IY2OK-koeV8bQwfyS79mVQ8ab2GHXcGwiyjk';

// Google Client IDs
const GOOGLE_WEB_CLIENT_ID =
    '9225695991-8m8fh5balv2716kh978rg0tne0cdaj3m.apps.googleusercontent.com';
const GOOGLE_IOS_CLIENT_ID =
    '9225695991-66ed1s754fhg6ude83nogp85dkmidh78.apps.googleusercontent.com';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY);

  // pass Google IDs to AuthService provider
  initAuthServiceIds(
    webClientId: GOOGLE_WEB_CLIENT_ID,
    iosClientId: GOOGLE_IOS_CLIENT_ID,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'KawanKreator',
      theme: buildKKTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
