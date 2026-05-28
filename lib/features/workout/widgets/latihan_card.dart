import 'package:flutter/material.dart';
import 'package:kinetra/core/theme/app_colors.dart';
import 'package:kinetra/core/widgets/kinetra_card.dart';
import 'package:kinetra/domain/entities/latihan_entity.dart';

class LatihanCard extends StatelessWidget {
  const LatihanCard({
    super.key,
    required this.latihan,
    this.onTap,
    this.compact = false,
  });

  final LatihanEntity latihan;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return KinetraCard(
      onTap: onTap,
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Row(
        children: [
          Container(
            width: compact ? 48 : 56,
            height: compact ? 48 : 56,
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.fitness_center, color: AppColors.background),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  latihan.namaLatihan,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 4),
                  Text(
                    latihan.deskripsi,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '${latihan.targetRepetisi} rep · ${latihan.targetDurasi}s',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.accentCyan,
                      ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
