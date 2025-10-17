import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kawankreatorapps/modules/auth/auth_controller.dart';
import 'package:kawankreatorapps/theme.dart';
import 'package:kawankreatorapps/widgets/auth_hero.dart';
import 'package:kawankreatorapps/widgets/kk_button.dart';
import 'package:kawankreatorapps/widgets/kk_textfield.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

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
      if (next.user != null && mounted) {
        context.go('/dashboard');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final hero = const AuthHero(
              imageAsset: 'assets/imgs/splash/hero-2.png',
              semanticsLabel:
                  'Ilustrasi kreator mengatur kalender konten di laptop.',
              title: 'Buat akun KawanKreator',
              description:
                  'Kami bantu kamu merencanakan konten dan kolaborasi tanpa ribet.',
            );
            final form = _buildForm(context, auth);

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

  Widget _buildForm(BuildContext context, AuthUiState auth) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                color: KKColors.black,
                tooltip: 'Kembali',
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
              Text(
                'Daftar',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          KKTextField(
            controller: _emailCtrl,
            hint: 'Email kerja kamu',
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                v != null && v.contains('@') ? null : 'Email tidak valid',
          ),
          const SizedBox(height: 12),
          KKTextField(
            controller: _passwordCtrl,
            hint: 'Password (min 6 karakter)',
            obscure: true,
            validator: (v) =>
                v != null && v.length >= 6 ? null : 'Min 6 karakter',
          ),
          const SizedBox(height: 24),
          KKButton(
            label: 'Daftar',
            loading: auth.loading,
            onPressed: () => ref
                .read(authControllerProvider.notifier)
                .signUpWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text),
          ),
          const SizedBox(height: 16),
          KKButton(
            label: 'Daftar dengan Google',
            secondary: true,
            leading: const Icon(Icons.g_translate, color: KKColors.primary),
            onPressed: () => ref
                .read(authControllerProvider.notifier)
                .signInWithGoogle(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Sudah punya akun? '),
              InkWell(
                onTap: () => context.go('/login'),
                child: const Text(
                  'Masuk',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.center,
            child: KKTextButton(
              label: 'Butuh bantuan?',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Hubungi support@kawankreator.id untuk panduan pendaftaran.',
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
