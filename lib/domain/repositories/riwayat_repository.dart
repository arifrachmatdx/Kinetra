import 'package:kinetra/domain/entities/riwayat_entity.dart';
import 'package:kinetra/domain/entities/workout_session.dart';

abstract class RiwayatRepository {
  Stream<List<RiwayatEntity>> watchByUser(String userId);
  Future<RiwayatEntity?> getById(String riwayatId);
  Future<void> saveSession(String userId, WorkoutSession session);
}
