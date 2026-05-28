import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorMapper {
  static String message(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'empty-email':
          return 'Email tidak boleh kosong';
        case 'empty-password':
          return 'Password tidak boleh kosong';
        case 'empty-name':
          return 'Nama tidak boleh kosong';
        case 'user-not-found':
          return 'Akun tidak ditemukan';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Password salah';
        case 'email-already-in-use':
          return 'Email sudah terdaftar';
        case 'weak-password':
          return 'Password terlalu lemah';
        case 'invalid-email':
          return 'Format email tidak valid';
        default:
          return error.message ?? 'Terjadi kesalahan autentikasi';
      }
    }
    return error.toString();
  }
}
