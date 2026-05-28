import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kinetra/data/repositories/auth_repository_impl.dart';
import 'package:kinetra/data/repositories/biodata_repository_impl.dart';
import 'package:kinetra/data/repositories/latihan_repository_impl.dart';
import 'package:kinetra/data/repositories/riwayat_repository_impl.dart';
import 'package:kinetra/data/repositories/user_repository_impl.dart';
import 'package:kinetra/domain/entities/biodata_entity.dart';
import 'package:kinetra/domain/entities/latihan_entity.dart';
import 'package:kinetra/domain/entities/riwayat_entity.dart';
import 'package:kinetra/domain/entities/user_entity.dart';
import 'package:kinetra/domain/repositories/auth_repository.dart';
import 'package:kinetra/domain/repositories/biodata_repository.dart';
import 'package:kinetra/domain/repositories/latihan_repository.dart';
import 'package:kinetra/domain/repositories/riwayat_repository.dart';
import 'package:kinetra/domain/repositories/user_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(firestoreProvider));
});

final biodataRepositoryProvider = Provider<BiodataRepository>((ref) {
  return BiodataRepositoryImpl(ref.watch(firestoreProvider));
});

final latihanRepositoryProvider = Provider<LatihanRepository>((ref) {
  return LatihanRepositoryImpl(ref.watch(firestoreProvider));
});

final riwayatRepositoryProvider = Provider<RiwayatRepository>((ref) {
  return RiwayatRepositoryImpl(ref.watch(firestoreProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserDocProvider = StreamProvider<UserEntity?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(user.uid);
});

final biodataProvider = StreamProvider<BiodataEntity?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  return ref.watch(biodataRepositoryProvider).watchBiodata(user.uid);
});

final latihanListProvider = StreamProvider<List<LatihanEntity>>((ref) {
  return ref.watch(latihanRepositoryProvider).watchAllActive();
});

final recommendationProvider = StreamProvider<List<LatihanEntity>>((ref) {
  final biodata = ref.watch(biodataProvider).valueOrNull;
  if (biodata == null) {
    return ref.watch(latihanRepositoryProvider).watchAllActive();
  }
  return ref
      .watch(latihanRepositoryProvider)
      .watchByTarget(biodata.targetLatihan.value);
});

final historyProvider = StreamProvider<List<RiwayatEntity>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(riwayatRepositoryProvider).watchByUser(user.uid);
});
