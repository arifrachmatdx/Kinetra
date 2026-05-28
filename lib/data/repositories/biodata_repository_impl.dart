import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kinetra/core/constants/firestore_collections.dart';
import 'package:kinetra/core/constants/target_latihan.dart';
import 'package:kinetra/data/models/biodata_model.dart';
import 'package:kinetra/domain/entities/biodata_entity.dart';
import 'package:kinetra/domain/repositories/biodata_repository.dart';
import 'package:uuid/uuid.dart';

class BiodataRepositoryImpl implements BiodataRepository {
  BiodataRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  @override
  Stream<BiodataEntity?> watchBiodata(String userId) {
    return _firestore
        .collection(FirestoreCollections.biodata)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return BiodataModel.fromFirestore(snap.docs.first).toEntity();
    });
  }

  @override
  Future<void> saveBiodata({
    required String userId,
    required String jenisKelamin,
    required int usia,
    required TargetLatihan targetLatihan,
  }) async {
    final biodataId = _uuid.v4();
    final model = BiodataModel(
      biodataId: biodataId,
      userId: userId,
      jenisKelamin: jenisKelamin,
      usia: usia,
      targetLatihan: targetLatihan.value,
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection(FirestoreCollections.biodata)
        .doc(biodataId)
        .set(model.toFirestore());

    await _firestore.collection(FirestoreCollections.users).doc(userId).update({
      'isBiodataCompleted': true,
    });
  }
}
