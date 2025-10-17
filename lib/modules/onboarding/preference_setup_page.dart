import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kawankreatorapps/services/analytics.dart';
import 'package:kawankreatorapps/services/preferences_service.dart';
import 'package:kawankreatorapps/widgets/kk_button.dart';

class PreferenceSetupPage extends StatefulWidget {
  const PreferenceSetupPage({super.key});

  @override
  State<PreferenceSetupPage> createState() => _PreferenceSetupPageState();
}

class _PreferenceSetupPageState extends State<PreferenceSetupPage> {
  String? _niche;
  String? _platform;
  double _weekly = 3;

  final niches = const ['Travel', 'Food', 'Education', 'Lifestyle'];
  final platforms = const ['Instagram', 'TikTok'];

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final prefs = PreferencesService();
    final previous = await prefs.getPreferences();
    final newNiche = _niche ?? 'Lifestyle';
    final newPlatform = _platform ?? 'Instagram';
    final newTarget = _weekly.round();

    await prefs.savePreferences(
      niche: newNiche,
      platform: newPlatform,
      weeklyTarget: newTarget,
    );
    Analytics.logEvent('preferences_saved', {
      'niche': newNiche,
      'platform': newPlatform,
      'weeklyTarget': newTarget,
    });

    bool undone = false;
    if (!context.mounted) {
      return;
    }
    final controller = messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: const Text(
          'Preferensi tersimpan. Anda dapat ubah kapan saja.',
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            undone = true;
            final prevNiche = (previous['niche'] as String?) ?? 'Lifestyle';
            final prevPlatform =
                (previous['platform'] as String?) ?? 'Instagram';
            final prevTarget = (previous['weeklyTarget'] as int?) ?? 3;
            await prefs.savePreferences(
              niche: prevNiche,
              platform: prevPlatform,
              weeklyTarget: prevTarget,
            );
            Analytics.logEvent('preferences_undo');
            if (context.mounted) {
              setState(() {
                _niche = prevNiche;
                _platform = prevPlatform;
                _weekly = prevTarget.toDouble();
              });
            }
          },
        ),
      ),
    );

    controller.closed.then((reason) {
      if (!context.mounted) {
        return;
      }
      if (!undone) {
        router.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferensi Awal'),
        actions: [
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Lewati'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Niche', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: niches
                  .map(
                    (n) => ChoiceChip(
                      label: Text(n),
                      selected: _niche == n,
                      onSelected: (v) => setState(() => _niche = v ? n : null),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Platform Utama',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: platforms
                  .map(
                    (p) => ChoiceChip(
                      label: Text(p),
                      selected: _platform == p,
                      onSelected: (v) =>
                          setState(() => _platform = v ? p : null),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text('Target posting/minggu: ${_weekly.round()}'),
            Slider(
              value: _weekly,
              onChanged: (v) => setState(() => _weekly = v),
              min: 1,
              max: 14,
              divisions: 13,
              label: _weekly.round().toString(),
            ),
            const Spacer(),
            KKButton(label: 'Simpan & Lanjutkan', onPressed: _save),
            const SizedBox(height: 12),
            KKButton(
              label: 'Lewati',
              secondary: true,
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}
