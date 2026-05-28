import 'package:kinetra/domain/entities/latihan_entity.dart';

abstract class LatihanRepository {
  Stream<List<LatihanEntity>> watchAllActive();
  Stream<List<LatihanEntity>> watchByTarget(String targetLatihan);
  Future<LatihanEntity?> getById(String latihanId);
}
