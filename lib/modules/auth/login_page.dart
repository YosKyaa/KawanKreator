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
                  Transform.translate(
                    offset: const Offset(0, -32),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      child: form,
                    ),
                  ),
                  const SizedBox(height: 32),
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
    Future<void> sendMagicLink() async {
      final email = _emailCtrl.text.trim();
      if (!email.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Masukkan email valid dulu ya.')),
        );
        return;
      }
      setState(() => _sendingMagic = true);
      await ref.read(authControllerProvider.notifier).signInWithMagicLink(email);
      if (!context.mounted) {
        return;
      }
      setState(() => _sendingMagic = false);
      final error = ref.read(authControllerProvider).error;
      if (error == null && context.mounted) {
        context.push('/otp', extra: email);
      }
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        decoration: BoxDecoration(
          color: KKColors.secondary.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Masuk',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: KKColors.black,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hi, selamat datang kembali.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: KKColors.black.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 24),
            KKTextField(
              controller: _emailCtrl,
              hint: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  v != null && v.contains('@') ? null : 'Email tidak valid',
            ),
            const SizedBox(height: 12),
            KKTextField(
              controller: _passwordCtrl,
              hint: 'Password',
              obscure: true,
              validator: (v) =>
                  v != null && v.length >= 6 ? null : 'Min 6 karakter',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _sendingMagic ? null : sendMagicLink,
                  icon: _sendingMagic
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: KKColors.primary,
                          ),
                        )
                      : const Icon(Icons.mail_outline),
                  label: const Text('Kirim Magic Link'),
                ),
                const Spacer(),
                KKTextButton(
                  label: 'Lupa Password?',
                  onPressed: () => context.push('/forgot-password'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            KKButton(
              label: 'Masuk',
              loading: auth.loading,
              onPressed: () {
                final email = _emailCtrl.text.trim();
                final password = _passwordCtrl.text;
                if (!email.contains('@') || password.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Periksa kembali email dan password (min 6 karakter).',
                      ),
                    ),
                  );
                  return;
                }
                ref
                    .read(authControllerProvider.notifier)
                    .signInWithEmail(email, password);
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'atau',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: KKColors.black.withValues(alpha: 0.6),
                        ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialIconButton(
                  icon: const Icon(Icons.facebook_rounded,
                      color: KKColors.black, size: 22),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Login Facebook segera hadir.'),
                    ),
                  ),
                  semanticLabel: 'Login dengan Facebook (segera)',
                ),
                const SizedBox(width: 18),
                _SocialIconButton(
                  asset: 'codex/Login/GOOGLE.png',
                  onTap: auth.loading
                      ? null
                      : () => ref
                          .read(authControllerProvider.notifier)
                          .signInWithGoogle(),
                  semanticLabel: 'Masuk dengan Google',
                ),
                const SizedBox(width: 18),
                _SocialIconButton(
                  icon: const Icon(Icons.apple, color: KKColors.black, size: 24),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Login Apple segera hadir.'),
                    ),
                  ),
                  semanticLabel: 'Login dengan Apple (segera)',
                ),
              ],
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 12),
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
      ),
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final String? asset;
  final Widget? icon;
  final VoidCallback? onTap;
  final String semanticLabel;

  const _SocialIconButton({
    this.asset,
    this.icon,
    required this.onTap,
    required this.semanticLabel,
  }) : assert(asset != null || icon != null, 'Provide asset or icon');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: asset != null
              ? Image.asset(asset!)
              : Center(child: icon),
        ),
      ),
    );
  }
}
