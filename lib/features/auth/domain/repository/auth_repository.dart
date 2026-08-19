import 'package:flutter_template/core/generated/base_entity.dart';

abstract class AuthRepository {
  Future<void> login({required LoginEntity inputModel});
}
