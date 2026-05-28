class UserEntity {
  const UserEntity({
    required this.userId,
    required this.nama,
    required this.email,
    required this.isBiodataCompleted,
  });

  final String userId;
  final String nama;
  final String email;
  final bool isBiodataCompleted;
}
