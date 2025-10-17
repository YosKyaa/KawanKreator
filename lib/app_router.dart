import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kawankreatorapps/modules/auth/forgot_password_page.dart';
import 'package:kawankreatorapps/modules/auth/login_page.dart';
import 'package:kawankreatorapps/modules/auth/otp_page.dart';
import 'package:kawankreatorapps/modules/auth/signup_page.dart';
import 'package:kawankreatorapps/modules/dashboard/dashboard_page.dart';
import 'package:kawankreatorapps/modules/onboarding/onboarding_page.dart';
import 'package:kawankreatorapps/modules/onboarding/preference_setup_page.dart';
import 'package:kawankreatorapps/modules/auth/auth_controller.dart';
import 'package:kawankreatorapps/services/preferences_service.dart';
import 'package:kawankreatorapps/theme.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _SplashPage()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingPage()),
      GoRoute(
        path: '/preference-setup',
        builder: (c, s) => const PreferenceSetupPage(),
      ),
      GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
      GoRoute(path: '/signup', builder: (c, s) => const SignupPage()),
      GoRoute(
        path: '/otp',
        builder: (c, s) {
          final email = s.extra as String? ?? '';
          return OtpPage(email: email);
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (c, s) => const ForgotPasswordPage(),
      ),
      GoRoute(path: '/dashboard', builder: (c, s) => const DashboardPage()),
    ],
  );
});

class _SplashPage extends ConsumerStatefulWidget {
  const _SplashPage();
  @override
  ConsumerState<_SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<_SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = PreferencesService();
    final isFirst = await prefs.getIsFirstOpen();
    final auth = ref.read(authControllerProvider);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    if (isFirst) {
      context.go('/onboarding');
    } else if (auth.user != null) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KKColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Semantics(
                      label: 'Logo Kawan Kreator',
                      image: true,
                      child: Image.asset(
                        'assets/imgs/logo/kk-white.png',
                        width: 148,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Temukan ritme berkarya yang lebih terarah.',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kami sedang menyiapkan ruang kerja kamu.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 6,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Memuat preferensi & status masuk',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
