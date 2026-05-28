import 'package:kinetra/core/constants/target_latihan.dart';

class BiodataEntity {
  const BiodataEntity({
    required this.biodataId,
    required this.userId,
    required this.jenisKelamin,
    required this.usia,
    required this.targetLatihan,
    required this.updatedAt,
  });

  final String biodataId;
  final String userId;
  final String jenisKelamin;
  final int usia;
  final TargetLatihan targetLatihan;
  final DateTime updatedAt;
}
