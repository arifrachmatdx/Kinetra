import 'package:kinetra/core/constants/target_latihan.dart';
import 'package:kinetra/domain/entities/biodata_entity.dart';

abstract class BiodataRepository {
  Stream<BiodataEntity?> watchBiodata(String userId);
  Future<void> saveBiodata({
    required String userId,
    required String jenisKelamin,
    required int usia,
    required TargetLatihan targetLatihan,
  });
}
