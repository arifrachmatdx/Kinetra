import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kinetra/core/constants/app_routes.dart';
import 'package:kinetra/core/providers/providers.dart';
import 'package:kinetra/domain/entities/workout_session.dart';
import 'package:kinetra/features/auth/presentation/login_screen.dart';
import 'package:kinetra/features/auth/presentation/register_screen.dart';
import 'package:kinetra/features/biodata/presentation/biodata_screen.dart';
import 'package:kinetra/features/detection/presentation/detection_screen.dart';
import 'package:kinetra/features/history/presentation/history_detail_screen.dart';
import 'package:kinetra/features/history/presentation/history_screen.dart';
import 'package:kinetra/features/home/presentation/home_screen.dart';
import 'package:kinetra/features/profile/presentation/profile_screen.dart';
import 'package:kinetra/features/result/presentation/result_screen.dart';
import 'package:kinetra/features/splash/presentation/splash_screen.dart';
import 'package:kinetra/features/workout/presentation/workout_list_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userDoc = ref.watch(currentUserDocProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final path = state.matchedLocation;
      final isSplash = path == AppRoutes.splash;
      final isAuthRoute =
          path == AppRoutes.login || path == AppRoutes.register;

      if (authState.isLoading) {
        return isSplash ? null : AppRoutes.splash;
      }

      final user = authState.valueOrNull;
      if (user == null) {
        if (isAuthRoute || isSplash) return null;
        return AppRoutes.login;
      }

      if (userDoc.isLoading) {
        return isSplash ? null : AppRoutes.splash;
      }

      final profile = userDoc.valueOrNull;
      final biodataComplete = profile?.isBiodataCompleted ?? false;

      if (!biodataComplete) {
        if (path == AppRoutes.biodata) return null;
        if (isAuthRoute || isSplash) return AppRoutes.biodata;
        return AppRoutes.biodata;
      }

      if (isAuthRoute || path == AppRoutes.biodata || isSplash) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.biodata,
        builder: (_, __) => const BiodataScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.workouts,
        builder: (_, __) => const WorkoutListScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.detection}/:latihanId',
        builder: (_, state) => DetectionScreen(
          latihanId: state.pathParameters['latihanId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.result,
        builder: (_, state) => ResultScreen(
          session: state.extra as WorkoutSession,
        ),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (_, __) => const HistoryScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => HistoryDetailScreen(
              riwayatId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _authSub = _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _userDocSub =
        _ref.listen(currentUserDocProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
  late final ProviderSubscription _authSub;
  late final ProviderSubscription _userDocSub;

  @override
  void dispose() {
    _authSub.close();
    _userDocSub.close();
    super.dispose();
  }
}
