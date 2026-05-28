import 'package:kinetra/domain/entities/user_entity.dart';

abstract class UserRepository {
  Stream<UserEntity?> watchUser(String userId);
  Future<UserEntity?> getUser(String userId);
}
