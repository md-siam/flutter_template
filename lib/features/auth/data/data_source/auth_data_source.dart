import 'package:flutter_template/core/generated/base_request_model.dart';

abstract class AuthDataSource {
  Future<String> login(LoginRequestModel inputModel);
}
