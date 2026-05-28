import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kinetra/domain/entities/user_entity.dart';

class UserModel {
  UserModel({
    required this.userId,
    required this.nama,
    required this.email,
    required this.isBiodataCompleted,
  });

  final String userId;
  final String nama;
  final String email;
  final bool isBiodataCompleted;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return UserModel(
      userId: data['userId'] as String? ?? doc.id,
      nama: data['nama'] as String? ?? '',
      email: data['email'] as String? ?? '',
      isBiodataCompleted: data['isBiodataCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'nama': nama,
        'email': email,
        'isBiodataCompleted': isBiodataCompleted,
      };

  UserEntity toEntity() => UserEntity(
        userId: userId,
        nama: nama,
        email: email,
        isBiodataCompleted: isBiodataCompleted,
      );
}
