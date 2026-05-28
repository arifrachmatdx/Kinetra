import 'package:firebase_auth/firebase_auth.dart';
import 'package:kinetra/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();
  User? get currentUser;
  Future<UserEntity> signIn({required String email, required String password});
  Future<UserEntity> signUp({
    required String nama,
    required String email,
    required String password,
  });
  Future<void> signOut();
}
