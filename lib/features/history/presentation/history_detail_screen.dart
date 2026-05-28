import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kinetra/core/providers/providers.dart';
import 'package:kinetra/core/utils/duration_formatter.dart';
import 'package:kinetra/core/widgets/kinetra_card.dart';

class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({super.key, required this.riwayatId});

  final String riwayatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Riwayat')),
      body: FutureBuilder(
        future: ref.read(riwayatRepositoryProvider).getById(riwayatId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = snapshot.data;
          if (item == null) {
            return const Center(child: Text('Data tidak ditemukan'));
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: KinetraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.namaLatihan,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _detail(
                    'Tanggal',
                    DateFormat('dd MMMM yyyy, HH:mm').format(item.tanggalLatihan),
                  ),
                  _detail('Repetisi', '${item.hasilRepetisi}'),
                  _detail(
                    'Durasi',
                    DurationFormatter.mmSs(Duration(seconds: item.durasiLatihan)),
                  ),
                  if (item.kaloriEstimasi != null)
                    _detail('Kalori', '${item.kaloriEstimasi!.toStringAsFixed(1)} kcal'),
                  if (item.feedbackAkhir != null) ...[
                    const SizedBox(height: 16),
                    const Text('Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(item.feedbackAkhir!),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
