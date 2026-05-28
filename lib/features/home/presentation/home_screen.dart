import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kinetra/core/constants/app_routes.dart';
import 'package:kinetra/core/providers/providers.dart';
import 'package:kinetra/core/theme/app_colors.dart';
import 'package:kinetra/core/utils/app_snackbar.dart';
import 'package:kinetra/core/utils/training_target.dart';
import 'package:kinetra/data/datasources/local_latihan_seed.dart';
import 'package:kinetra/domain/entities/latihan_entity.dart';
import 'package:kinetra/features/workout/widgets/latihan_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  List<LatihanEntity> _recommendations(WidgetRef ref) {
    final async = ref.watch(recommendationProvider);
    final biodata = ref.watch(biodataProvider).valueOrNull;
    return async.when(
      data: (list) {
        if (list.isNotEmpty) return list;
        if (biodata != null) {
          return LocalLatihanSeed.byTarget(biodata.targetLatihan.value);
        }
        return LocalLatihanSeed.all().take(3).toList();
      },
      loading: () => [],
      error: (_, __) {
        if (biodata != null) {
          return LocalLatihanSeed.byTarget(biodata.targetLatihan.value);
        }
        return LocalLatihanSeed.all().take(3).toList();
      },
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) {
        AppSnackbar.success(context, 'Logout berhasil');
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (context.mounted) AppSnackbar.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserDocProvider).valueOrNull;
    final recommendations = _recommendations(ref);
    final nama = user?.nama ?? 'Member';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, $nama 👋',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Siap latihan hari ini?'),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.push(AppRoutes.profile),
                          icon: const CircleAvatar(
                            backgroundColor: AppColors.surfaceLight,
                            child: Icon(Icons.person, color: AppColors.accentCyan),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Rekomendasi Latihan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final latihan = recommendations[index];
                  final biodata = ref.watch(biodataProvider).valueOrNull;
                  final target = TrainingTargetCalculator.forLatihan(
                    latihan: latihan,
                    biodata: biodata,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    child: LatihanCard(
                      latihan: latihan,
                      targetRepetisiOverride: target.repetisi,
                      targetDurasiOverride: target.durasiDetik,
                      compact: true,
                      onTap: () => context.push(
                        AppRoutes.detectionPath(latihan.latihanId),
                      ),
                    ),
                  );
                },
                childCount: recommendations.length,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Menu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                delegate: SliverChildListDelegate([
                  _MenuTile(
                    icon: Icons.play_circle_fill,
                    label: 'Mulai Workout',
                    gradient: true,
                    onTap: () => context.push(AppRoutes.workouts),
                  ),
                  _MenuTile(
                    icon: Icons.history,
                    label: 'Riwayat Latihan',
                    onTap: () => context.push(AppRoutes.history),
                  ),
                  _MenuTile(
                    icon: Icons.person,
                    label: 'Profil',
                    onTap: () => context.push(AppRoutes.profile),
                  ),
                  _MenuTile(
                    icon: Icons.logout,
                    label: 'Logout',
                    onTap: () => _logout(context, ref),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.gradient = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: gradient ? null : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient ? AppColors.gradient : null,
            color: gradient ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36,
                color: gradient ? AppColors.background : AppColors.accentCyan,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: gradient ? AppColors.background : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
