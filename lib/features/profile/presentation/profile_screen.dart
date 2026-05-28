import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kinetra/core/constants/app_routes.dart';
import 'package:kinetra/core/providers/providers.dart';
import 'package:kinetra/core/theme/app_colors.dart';
import 'package:kinetra/core/utils/app_snackbar.dart';
import 'package:kinetra/core/widgets/kinetra_card.dart';
import 'package:kinetra/core/widgets/kinetra_primary_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserDocProvider).valueOrNull;
    final biodata = ref.watch(biodataProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.surfaceLight,
              child: Icon(Icons.person, size: 48, color: AppColors.accentCyan),
            ),
            const SizedBox(height: 16),
            Text(
              user?.nama ?? '-',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(user?.email ?? ''),
            const SizedBox(height: 24),
            KinetraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Biodata', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _row('Jenis Kelamin', biodata?.jenisKelamin ?? '-'),
                  _row('Usia', biodata != null ? '${biodata.usia} tahun' : '-'),
                  _row('Target', biodata?.targetLatihan.label ?? '-'),
                ],
              ),
            ),
            const Spacer(),
            KinetraPrimaryButton(
              label: 'Logout',
              icon: Icons.logout,
              onPressed: () async {
                try {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) {
                    AppSnackbar.success(context, 'Logout berhasil');
                    context.go(AppRoutes.login);
                  }
                } catch (e) {
                  if (context.mounted) AppSnackbar.error(context, e.toString());
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
