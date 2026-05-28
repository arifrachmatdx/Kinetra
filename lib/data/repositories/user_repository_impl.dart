import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kinetra/core/constants/firestore_collections.dart';
import 'package:kinetra/data/models/user_model.dart';
import 'package:kinetra/domain/entities/user_entity.dart';
import 'package:kinetra/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<UserEntity?> watchUser(String userId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc).toEntity() : null);
  }

  @override
  Future<UserEntity?> getUser(String userId) async {
    final doc =
        await _firestore.collection(FirestoreCollections.users).doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc).toEntity();
  }
}
