import 'package:flutter_template/core/generated/base_response_model.dart';

abstract class UserDataSource {
  Future<List<UserResponseModel>> getUserList();
  Future<UserResponseModel> getUserById({required String userId});
}
