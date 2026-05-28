import 'package:firebase_auth/firebase_auth.dart';
import 'package:kinetra/core/constants/firestore_collections.dart';
import 'package:kinetra/data/models/user_model.dart';
import 'package:kinetra/domain/entities/user_entity.dart';
import 'package:kinetra/domain/repositories/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty) {
      throw FirebaseAuthException(code: 'empty-email');
    }
    if (password.isEmpty) {
      throw FirebaseAuthException(code: 'empty-password');
    }
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user!.uid;
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .get();
      if (!doc.exists) {
        final user = UserModel(
          userId: uid,
          nama: cred.user!.displayName ?? 'Member',
          email: email.trim(),
          isBiodataCompleted: false,
        );
        await doc.reference.set(user.toFirestore());
        return user.toEntity();
      }
      return UserModel.fromFirestore(doc).toEntity();
    } on FirebaseAuthException {
      rethrow;
    }
  }

  @override
  Future<UserEntity> signUp({
    required String nama,
    required String email,
    required String password,
  }) async {
    if (nama.trim().isEmpty) {
      throw FirebaseAuthException(code: 'empty-name');
    }
    if (email.trim().isEmpty) {
      throw FirebaseAuthException(code: 'empty-email');
    }
    if (password.isEmpty) {
      throw FirebaseAuthException(code: 'empty-password');
    }
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    final user = UserModel(
      userId: uid,
      nama: nama.trim(),
      email: email.trim(),
      isBiodataCompleted: false,
    );
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .set(user.toFirestore());
    return user.toEntity();
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
