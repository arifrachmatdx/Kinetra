import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kinetra/core/constants/firestore_collections.dart';
import 'package:kinetra/data/models/latihan_model.dart';
import 'package:kinetra/domain/entities/latihan_entity.dart';
import 'package:kinetra/domain/repositories/latihan_repository.dart';

class LatihanRepositoryImpl implements LatihanRepository {
  LatihanRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<LatihanEntity>> watchAllActive() {
    return _firestore
        .collection(FirestoreCollections.latihan)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => LatihanModel.fromFirestore(d).toEntity())
            .toList());
  }

  @override
  Stream<List<LatihanEntity>> watchByTarget(String targetLatihan) {
    return _firestore
        .collection(FirestoreCollections.latihan)
        .where('isActive', isEqualTo: true)
        .where('targetLatihan', isEqualTo: targetLatihan)
        .limit(3)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => LatihanModel.fromFirestore(d).toEntity())
            .toList());
  }

  @override
  Future<LatihanEntity?> getById(String latihanId) async {
    final query = await _firestore
        .collection(FirestoreCollections.latihan)
        .where('latihanId', isEqualTo: latihanId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      final doc = await _firestore
          .collection(FirestoreCollections.latihan)
          .doc(latihanId)
          .get();
      if (!doc.exists) return null;
      return LatihanModel.fromFirestore(doc).toEntity();
    }
    return LatihanModel.fromFirestore(query.docs.first).toEntity();
  }
}
