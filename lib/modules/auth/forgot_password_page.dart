import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kawankreatorapps/modules/auth/auth_controller.dart';
import 'package:kawankreatorapps/widgets/kk_button.dart';
import 'package:kawankreatorapps/widgets/kk_textfield.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (prev, next) {
      if (!_submitted) return;
      if (next.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
        _submitted = false;
      } else if (!next.loading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link reset dikirim jika email terdaftar'),
          ),
        );
        _submitted = false;
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            KKTextField(
              controller: _emailCtrl,
              hint: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  v != null && v.contains('@') ? null : 'Email tidak valid',
            ),
            const SizedBox(height: 16),
            KKButton(
              label: 'Kirim Link Reset',
              loading: auth.loading,
              onPressed: () {
                final email = _emailCtrl.text.trim();
                if (!email.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Masukkan email valid dulu ya.'),
                    ),
                  );
                  return;
                }
                _submitted = true;
                ref.read(authControllerProvider.notifier).resetPassword(email);
              },
            ),
          ],
        ),
      ),
    );
  }
}
