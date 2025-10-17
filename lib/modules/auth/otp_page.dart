import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kawankreatorapps/modules/auth/auth_controller.dart';
import 'package:kawankreatorapps/widgets/kk_button.dart';
import 'package:kawankreatorapps/widgets/otp_input.dart';

class OtpPage extends ConsumerStatefulWidget {
  final String email;
  const OtpPage({super.key, required this.email});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  late Timer _timer;
  int _seconds = 60;
  int _resendCount = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) {
        t.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
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
      } else if (next.user != null && mounted) {
        context.go('/dashboard');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Masukkan kode yang dikirim ke ${widget.email}'),
            const SizedBox(height: 12),
            OtpInput(
              onCompleted: (code) {
                ref
                    .read(authControllerProvider.notifier)
                    .verifyOtp(widget.email, code);
              },
            ),
            if (auth.loading) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 16),
            Text('Kirim ulang dalam ${_seconds}s'),
            const SizedBox(height: 8),
            KKButton(
              label: 'Kirim Ulang',
              secondary: true,
              onPressed: (_seconds == 0 && _resendCount < 5)
                  ? () async {
                      await ref
                          .read(authControllerProvider.notifier)
                          .signInWithMagicLink(widget.email);
                      setState(() {
                        _resendCount++;
                        _startTimer();
                      });
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
