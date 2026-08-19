import 'package:flutter_template/core/generated/base_request_model.dart';
import 'package:flutter_template/core/generated/base_entity.dart';

extension LoginEntityMapper on LoginEntity {
  /// Maps a LoginEntity to a LoginRequestModel
  LoginRequestModel toRequestModel() {
    return LoginRequestModel(email: email, pin: pin);
  }
}
