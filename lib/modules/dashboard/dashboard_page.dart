import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kawankreatorapps/modules/auth/auth_controller.dart';
import 'package:kawankreatorapps/modules/dashboard/widgets/calendar_peek.dart';
import 'package:kawankreatorapps/modules/dashboard/widgets/idea_suggestions.dart';
import 'package:kawankreatorapps/modules/dashboard/widgets/todays_plan_card.dart';
import 'package:kawankreatorapps/services/analytics.dart';
import 'package:kawankreatorapps/widgets/kk_button.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    Analytics.logEvent('dashboard_seen');
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = ref.watch(authControllerProvider).isGuest;

    final pages = [
      _HomeTab(isGuest: isGuest),
      const _PlannerTab(),
      const _RateCardTab(),
      _ProfileTab(isGuest: isGuest),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('KawanKreator')),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Planner',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Rate Card',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final bool isGuest;
  const _HomeTab({required this.isGuest});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KKButton(
            label: 'Buat Rencana Minggu Ini',
            onPressed: () {
              if (isGuest) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Simpan progres?'),
                    content: const Text(
                      'Daftar 10 detik dengan Google untuk menyimpan & ekspor.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Nanti saja'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Arahkan ke Login')),
                          );
                        },
                        child: const Text('Daftar'),
                      ),
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Aksi: Buat rencana')),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          const TodaysPlanCard(),
          const SizedBox(height: 12),
          const CalendarPeek(),
          const SizedBox(height: 12),
          const IdeaSuggestions(),
        ],
      ),
    );
  }
}

class _PlannerTab extends StatelessWidget {
  const _PlannerTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Planner (coming soon)'));
  }
}

class _RateCardTab extends StatelessWidget {
  const _RateCardTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Rate Card (coming soon)'));
  }
}

class _ProfileTab extends ConsumerWidget {
  final bool isGuest;
  const _ProfileTab({required this.isGuest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(isGuest ? 'Profil Tamu' : 'Profil'),
          const SizedBox(height: 12),
          if (!isGuest && auth.user != null) Text('User ID: ${auth.user!.id}'),
          const SizedBox(height: 12),
          KKButton(
            label: isGuest ? 'Daftar / Masuk' : 'Keluar',
            onPressed: () async {
              if (isGuest) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Arahkan ke Login')),
                );
              } else {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Anda telah keluar')),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 24),
          const Text('Help & FAQ (stub)'),
        ],
      ),
    );
  }
}
