import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kinetra/core/constants/app_routes.dart';
import 'package:kinetra/core/providers/providers.dart';
import 'package:kinetra/core/theme/app_colors.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  void _maybeRedirect(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading) return;

    final user = auth.valueOrNull;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.login);
      });
      return;
    }

    final profileAsync = ref.watch(currentUserDocProvider);
    if (profileAsync.isLoading) return;

    final profile = profileAsync.valueOrNull;
    final biodataComplete = profile?.isBiodataCompleted ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.go(biodataComplete ? AppRoutes.home : AppRoutes.biodata);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _maybeRedirect(context, ref);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, Color(0xFF0D1B2A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppColors.gradient.createShader(bounds),
              child: const Icon(
                Icons.fitness_center,
                size: 88,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'KINETRA',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Smart Workout Assistant',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: AppColors.accentCyan),
          ],
        ),
      ),
    );
  }
}
