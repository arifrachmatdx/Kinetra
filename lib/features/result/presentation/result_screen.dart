import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kinetra/core/constants/app_routes.dart';
import 'package:kinetra/core/theme/app_colors.dart';
import 'package:kinetra/core/utils/duration_formatter.dart';
import 'package:kinetra/core/widgets/kinetra_card.dart';
import 'package:kinetra/core/widgets/kinetra_gradient.dart';
import 'package:kinetra/core/widgets/kinetra_primary_button.dart';
import 'package:kinetra/domain/entities/workout_session.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              KinetraGradient(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events, size: 48, color: AppColors.background),
                    const SizedBox(height: 12),
                    const Text(
                      'Latihan Selesai!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.background,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.namaLatihan,
                      style: const TextStyle(color: AppColors.background),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              KinetraCard(
                child: Column(
                  children: [
                    _row('Total Repetisi', '${session.repetitions}'),
                    _row(
                      'Durasi',
                      DurationFormatter.mmSs(
                        Duration(seconds: session.durationSeconds),
                      ),
                    ),
                    _row(
                      'Kalori Estimasi',
                      '${session.kaloriEstimasi.toStringAsFixed(1)} kcal',
                    ),
                    const Divider(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        session.feedbackAkhir,
                        style: const TextStyle(color: AppColors.accentGreen),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              KinetraPrimaryButton(
                label: 'Kembali ke Menu',
                onPressed: () => context.go(AppRoutes.home),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push(AppRoutes.history),
                child: const Text('Lihat Riwayat'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
