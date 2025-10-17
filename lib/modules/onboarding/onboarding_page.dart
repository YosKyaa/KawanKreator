import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kawankreatorapps/services/analytics.dart';
import 'package:kawankreatorapps/services/preferences_service.dart';
import 'package:kawankreatorapps/theme.dart';
import 'package:kawankreatorapps/widgets/kk_button.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  final List<_SlideData> _slides = const [
    _SlideData(
      title: 'KawanKreator',
      description: 'Tempat berkumpulnya kreator untuk tumbuh bersama.',
      backgroundColor: KKColors.primary,
      isIntro: true,
    ),
    _SlideData(
      imageAsset: 'assets/imgs/splash/hero-1.png',
      semanticsLabel: 'Ilustrasi kreator membuat konten audio dengan mikrofon.',
      title: 'Temukan Nilai Karyamu',
      description:
          'Pantau performa dan potensi monetisasi tanpa perlu spreadsheet.',
    ),
    _SlideData(
      imageAsset: 'assets/imgs/splash/hero-2.png',
      semanticsLabel: 'Ilustrasi kreator memantau kalender konten di laptop.',
      title: 'Jadwalkan Konten Tanpa Pusing',
      description: 'Rancang kalender mingguan, delegasikan tugas, selesai.',
    ),
    _SlideData(
      imageAsset: 'assets/imgs/splash/hero-3.png',
      semanticsLabel: 'Ilustrasi kreator berdiskusi tentang ide konten.',
      title: 'Kembangkan Ide Segar',
      description: 'Terima rekomendasi ide sesuai niche dan platform pilihan.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return _OnboardingSlide(
                slide: slide,
                pageIndex: index,
                total: _slides.length,
                currentPage: _page,
                onPrimaryTap: () async {
                  if (_page == _slides.length - 1) {
                    final prefs = PreferencesService();
                    await prefs.setIsFirstOpen(false);
                    Analytics.logEvent('onboarding_complete');
                    if (!context.mounted) {
                      return;
                    }
                    context.go('/preference-setup');
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
                onSkip: () async {
                  await PreferencesService().setIsFirstOpen(false);
                  if (!context.mounted) {
                    return;
                  }
                  context.go('/preference-setup');
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SlideData {
  final String title;
  final String description;
  final String? imageAsset;
  final String? semanticsLabel;
  final Color? backgroundColor;
  final bool isIntro;

  const _SlideData({
    required this.title,
    required this.description,
    this.imageAsset,
    this.semanticsLabel,
    this.backgroundColor,
    this.isIntro = false,
  });
}

class _OnboardingSlide extends StatelessWidget {
  final _SlideData slide;
  final int pageIndex;
  final int total;
  final int currentPage;
  final VoidCallback onPrimaryTap;
  final VoidCallback onSkip;

  const _OnboardingSlide({
    required this.slide,
    required this.pageIndex,
    required this.total,
    required this.currentPage,
    required this.onPrimaryTap,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final background = slide.isIntro
        ? Container(color: slide.backgroundColor ?? KKColors.primary)
        : Semantics(
            label: slide.semanticsLabel,
            image: true,
            child: Image.asset(
              slide.imageAsset!,
              fit: BoxFit.cover,
            ),
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        background,
        if (!slide.isIntro)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: _SkipChip(onPressed: onSkip),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (slide.isIntro) ...[
                        Semantics(
                          label: 'Logo Kawan Kreator',
                          image: true,
                          child: Image.asset(
                            'assets/imgs/logo/kk-white.png',
                            width: 132,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Text(
                        slide.title,
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        slide.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                      ),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.center,
                        child: _PageDots(
                          currentPage: currentPage,
                          total: total,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (pageIndex == total - 1)
                        KKButton(
                          label: 'Mulai',
                          semanticsLabel: 'Mulai menggunakan Kawan Kreator',
                          onPressed: onPrimaryTap,
                        )
                      else
                        Align(
                          alignment: Alignment.bottomRight,
                          child: _ArrowButton(onPressed: onPrimaryTap),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  final int currentPage;
  final int total;
  const _PageDots({required this.currentPage, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 18 : 8,
          height: 8,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: active ? 1 : 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _SkipChip extends StatelessWidget {
  final VoidCallback onPressed;
  const _SkipChip({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Lewati onboarding',
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.3),
          foregroundColor: KKColors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: const Text(
          'Lewati',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _ArrowButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Lanjut onboarding',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: KKColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
