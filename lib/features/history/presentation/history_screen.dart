import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kinetra/core/constants/app_routes.dart';
import 'package:kinetra/core/providers/providers.dart';
import 'package:kinetra/core/theme/app_colors.dart';
import 'package:kinetra/core/utils/duration_formatter.dart';
import 'package:kinetra/core/widgets/kinetra_card.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Latihan')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('Belum ada riwayat latihan'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final dateStr =
                  DateFormat('dd MMM yyyy, HH:mm').format(item.tanggalLatihan);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: KinetraCard(
                  onTap: () => context.push(
                    AppRoutes.historyDetailPath(item.riwayatId),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: AppColors.accentGreen,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.namaLatihan,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(dateStr, style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text(
                              '${item.hasilRepetisi} rep · ${DurationFormatter.mmSs(Duration(seconds: item.durasiLatihan))}',
                              style: const TextStyle(color: AppColors.accentCyan),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
