import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kawankreatorapps/modules/auth/auth_controller.dart';
import 'package:kawankreatorapps/services/preferences_service.dart';
import 'package:kawankreatorapps/theme.dart';
import 'package:kawankreatorapps/widgets/auth_hero.dart';
import 'package:kawankreatorapps/widgets/kk_button.dart';
import 'package:kawankreatorapps/widgets/kk_textfield.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showEmailPassword = false;
  bool _sendingMagic = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final last = await PreferencesService().getLastEmail();
      if (last != null && mounted) {
        setState(() => _emailCtrl.text = last);
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
      if (next.user != null && context.mounted) {
        context.go('/dashboard');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final hero = const AuthHero(
              imageAsset: 'assets/imgs/splash/hero-4.png',
              semanticsLabel:
                  'Ilustrasi kreator konten mempersiapkan peralatan shooting.',
              title: 'Masuk & lanjutkan progresmu',
              description:
                  'KawanKreator menyimpan ide, kalender, dan rate card agar kamu bisa fokus berkarya.',
            );
            final form = _buildForm(context, auth: auth);

            if (isWide) {
              return Row(
                children: [
                  Expanded(child: hero),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 32,
                        ),
                        child: form,
                      ),
                    ),
                  ),
                ],
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  hero,
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: form,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context, {
    required AuthUiState auth,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Masuk ke KawanKreator',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gunakan akun Google atau metode lain yang nyaman bagimu.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          KKButton(
            label: 'Lanjut dengan Google',
            semanticsLabel: 'Masuk dengan Google',
            leading: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.g_mobiledata,
                color: KKColors.primary,
                size: 24,
              ),
            ),
            loading: auth.loading,
            onPressed: () => ref
                .read(authControllerProvider.notifier)
                .signInWithGoogle(),
          ),
          const SizedBox(height: 12),
          if (!_showEmailPassword) ...[
            KKButton(
              label: 'Kirim Magic Link',
              secondary: true,
              loading: _sendingMagic,
              onPressed: _sendingMagic
                  ? null
                  : () async {
                      final email = _emailCtrl.text.trim();
                      if (!email.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Masukkan email valid untuk menerima link.',
                            ),
                          ),
                        );
                        return;
                      }
                      setState(() => _sendingMagic = true);
                      await ref
                          .read(authControllerProvider.notifier)
                          .signInWithMagicLink(email);
                      if (!context.mounted) {
                        return;
                      }
                      setState(() => _sendingMagic = false);
                      final error = ref.read(authControllerProvider).error;
                      if (error == null) {
                        if (!context.mounted) {
                          return;
                        }
                        context.push('/otp', extra: email);
                      }
                    },
            ),
            const SizedBox(height: 8),
            KKTextField(
              controller: _emailCtrl,
              hint: 'Email kerja kamu',
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  v != null && v.contains('@') ? null : 'Email tidak valid',
            ),
            const SizedBox(height: 8),
            KKTextButton(
              label: 'Masuk dengan Email + Password',
              onPressed: () => setState(() => _showEmailPassword = true),
            ),
          ] else ...[
            KKTextField(
              controller: _emailCtrl,
              hint: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  v != null && v.contains('@') ? null : 'Email tidak valid',
            ),
            const SizedBox(height: 8),
            KKTextField(
              controller: _passwordCtrl,
              hint: 'Password',
              obscure: true,
              validator: (v) =>
                  v != null && v.length >= 6 ? null : 'Min 6 karakter',
            ),
            const SizedBox(height: 12),
            KKButton(
              label: 'Masuk',
              loading: auth.loading,
              onPressed: () => ref
                  .read(authControllerProvider.notifier)
                  .signInWithEmail(
                    _emailCtrl.text.trim(),
                    _passwordCtrl.text,
                  ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: KKTextButton(
                label: 'Lupa Password?',
                onPressed: () => context.push('/forgot-password'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Belum punya akun? '),
              InkWell(
                onTap: () => context.push('/signup'),
                child: const Text(
                  'Daftar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          KKButton(
            label: 'Masuk sebagai Tamu',
            secondary: true,
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).enterAsGuest();
              if (!context.mounted) {
                return;
              }
              context.go('/dashboard');
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.center,
            child: KKTextButton(
              label: 'Butuh bantuan?',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Tim KawanKreator siap membantu lewat support@kawankreator.id',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
