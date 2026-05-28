import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kinetra/core/constants/firestore_collections.dart';
import 'package:kinetra/data/models/riwayat_model.dart';
import 'package:kinetra/domain/entities/riwayat_entity.dart';
import 'package:kinetra/domain/entities/workout_session.dart';
import 'package:kinetra/domain/repositories/riwayat_repository.dart';
import 'package:uuid/uuid.dart';

class RiwayatRepositoryImpl implements RiwayatRepository {
  RiwayatRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  @override
  Stream<List<RiwayatEntity>> watchByUser(String userId) {
    return _firestore
        .collection(FirestoreCollections.riwayatLatihan)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RiwayatModel.fromFirestore(d).toEntity())
            .toList()
          ..sort((a, b) => b.tanggalLatihan.compareTo(a.tanggalLatihan)));
  }

  @override
  Future<RiwayatEntity?> getById(String riwayatId) async {
    final doc = await _firestore
        .collection(FirestoreCollections.riwayatLatihan)
        .doc(riwayatId)
        .get();
    if (!doc.exists) return null;
    return RiwayatModel.fromFirestore(doc).toEntity();
  }

  @override
  Future<void> saveSession(String userId, WorkoutSession session) async {
    final riwayatId = _uuid.v4();
    final model = RiwayatModel(
      riwayatId: riwayatId,
      userId: userId,
      sesiId: session.sesiId,
      tanggalLatihan: DateTime.now(),
      namaLatihan: session.namaLatihan,
      hasilRepetisi: session.repetitions,
      durasiLatihan: session.durationSeconds,
      kaloriEstimasi: session.kaloriEstimasi,
      feedbackAkhir: session.feedbackAkhir,
    );
    await _firestore
        .collection(FirestoreCollections.riwayatLatihan)
        .doc(riwayatId)
        .set(model.toFirestore());
  }
}
