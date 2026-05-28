import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kinetra/core/constants/app_routes.dart';
import 'package:kinetra/core/providers/providers.dart';
import 'package:kinetra/core/utils/training_target.dart';
import 'package:kinetra/data/datasources/local_latihan_seed.dart';
import 'package:kinetra/domain/entities/latihan_entity.dart';
import 'package:kinetra/features/workout/widgets/latihan_card.dart';

class WorkoutListScreen extends ConsumerWidget {
  const WorkoutListScreen({super.key});

  List<LatihanEntity> _latihanList(WidgetRef ref) {
    return ref.watch(latihanListProvider).when(
          data: (list) => list.isNotEmpty ? list : LocalLatihanSeed.all(),
          loading: () => LocalLatihanSeed.all(),
          error: (_, __) => LocalLatihanSeed.all(),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latihanList = _latihanList(ref);
    final biodata = ref.watch(biodataProvider).valueOrNull;
    final grouped = <String, List<LatihanEntity>>{};
    for (final l in latihanList) {
      grouped.putIfAbsent(l.kategoriLatihan, () => []).add(l);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Latihan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              ...entry.value.map(
                (latihan) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Builder(
                    builder: (context) {
                      final target = TrainingTargetCalculator.forLatihan(
                        latihan: latihan,
                        biodata: biodata,
                      );
                      return LatihanCard(
                        latihan: latihan,
                        targetRepetisiOverride: target.repetisi,
                        targetDurasiOverride: target.durasiDetik,
                        onTap: () => context.push(
                          AppRoutes.detectionPath(latihan.latihanId),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      ),
    );
  }
}
