import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kawankreatorapps/services/analytics.dart';
import 'package:kawankreatorapps/services/preferences_service.dart';
import 'package:kawankreatorapps/theme.dart';
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
  bool _loading = true;

  final _nicheOptions = const [
    _NicheOption('Skincare', 'Skincare', Icons.face_retouching_natural),
    _NicheOption('Edukasi', 'Edukasi', Icons.school),
    _NicheOption('Kuliner', 'Kuliner', Icons.restaurant_menu),
    _NicheOption('Lifestyle', 'Lifestyle', Icons.self_improvement),
    _NicheOption('Travel', 'Travel', Icons.flight_takeoff),
    _NicheOption('Lainnya', 'Lainnya', Icons.more_horiz),
  ];

  final _platformOptions = const [
    _PlatformOption(
      id: 'Instagram',
      label: 'Instagram',
      asset: 'assets/imgs/icon/instagram.png',
    ),
    _PlatformOption(
      id: 'TikTok',
      label: 'TikTok',
      asset: 'assets/imgs/icon/tiktok.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = PreferencesService();
    final stored = await prefs.getPreferences();
    if (!mounted) return;
    final storedNiche = stored['niche'] as String?;
    final allowedNiches = _nicheOptions.map((e) => e.id).toSet();
    final initialNiche =
        storedNiche != null && allowedNiches.contains(storedNiche)
            ? storedNiche
            : null;
    setState(() {
      _niche = initialNiche;
      _platform = stored['platform'] as String?;
      final weeklyTarget = stored['weeklyTarget'] as int?;
      if (weeklyTarget != null) {
        _weekly = weeklyTarget.toDouble();
      }
      _loading = false;
    });
  }

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
          'Preferensi tersimpan. Kamu bisa ubah kapan saja.',
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
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      tooltip: 'Kembali',
                      onPressed: () => context.go('/onboarding'),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFC994),
                            Color(0xFFFCE3C7),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(48),
                          topRight: Radius.circular(32),
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Atur Preferensimu',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: KKColors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Opsional, bisa dilewati kapan saja.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: KKColors.black.withValues(alpha: 0.7),
                                ),
                          ),
                          const SizedBox(height: 24),
                          _StepTitle(
                            step: 'Step 1',
                            title: 'Pilih Niche',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _nicheOptions
                                .map(
                                  (option) => _SelectableChip(
                                    label: option.label,
                                    selected: _niche == option.id,
                                    onTap: () => setState(() {
                                      _niche =
                                          _niche == option.id ? null : option.id;
                                    }),
                                    icon: Icon(
                                      option.icon,
                                      size: 20,
                                      color: _niche == option.id
                                          ? Colors.white
                                          : KKColors.black,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                          _StepTitle(
                            step: 'Step 2',
                            title: 'Platform Utama',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            children: _platformOptions
                                .map(
                                  (option) => _SelectableChip(
                                    label: option.label,
                                    selected: _platform == option.id,
                                    onTap: () => setState(() {
                                      _platform = _platform == option.id
                                          ? null
                                          : option.id;
                                    }),
                                    icon: Image.asset(
                                      option.asset,
                                      width: 20,
                                      height: 20,
                                      color: _platform == option.id
                                          ? Colors.white
                                          : null,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                          _StepTitle(
                            step: 'Step 3',
                            title: 'Target Posting / Minggu',
                          ),
                          const SizedBox(height: 20),
                          _WeeklySlider(
                            value: _weekly,
                            onChanged: (v) => setState(() => _weekly = v),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: KKButton(
                                  label: 'Lewati',
                                  secondary: true,
                                  onPressed: () => context.go('/login'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: KKButton(
                                  label: 'Simpan & Lanjutkan',
                                  onPressed: _save,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  final String step;
  final String title;
  const _StepTitle({required this.step, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$step - $title',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: KKColors.black,
          ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget icon;
  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label ${selected ? "dipilih" : ""}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? KKColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : KKColors.black.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.18 : 0.05),
                blurRadius: selected ? 16 : 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: selected ? Colors.white : KKColors.black,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklySlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _WeeklySlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final normalized = (value.clamp(0, 7) / 7) * 2 - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment(normalized, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              value.round().toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: KKColors.primary,
            inactiveTrackColor: KKColors.black.withValues(alpha: 0.25),
            thumbColor: KKColors.primary,
            overlayColor: KKColors.primary.withValues(alpha: 0.2),
            trackHeight: 6,
            activeTickMarkColor: Colors.transparent,
            inactiveTickMarkColor: Colors.transparent,
          ),
          child: Slider(
            value: value.clamp(0, 7),
            min: 0,
            max: 7,
            divisions: 7,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('0'),
            Text('7'),
          ],
        ),
      ],
    );
  }
}

class _NicheOption {
  final String id;
  final String label;
  final IconData icon;
  const _NicheOption(this.id, this.label, this.icon);
}

class _PlatformOption {
  final String id;
  final String label;
  final String asset;
  const _PlatformOption({
    required this.id,
    required this.label,
    required this.asset,
  });
}
