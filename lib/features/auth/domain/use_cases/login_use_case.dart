import 'package:injectable/injectable.dart';
import 'package:flutter_template/core/generated/base_entity.dart';
import 'package:flutter_template/features/auth/domain/repository/auth_repository.dart';
import 'package:flutter_template/core/generated/base_use_case.dart';

@singleton
class LoginUseCase with BaseUseCaseWithParams<void, LoginEntity> {
  LoginUseCase(this._authRepository);

  final AuthRepository _authRepository;

  @override
  Future<void> execute(LoginEntity params) {
    return _authRepository.login(inputModel: params);
  }
}
