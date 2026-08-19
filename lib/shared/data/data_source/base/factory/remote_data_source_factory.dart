import 'package:flutter_template/core/generated/base_data_source.dart';
import 'package:flutter_template/features/auth/data/data_source/auth_data_source.dart';
import 'package:flutter_template/features/user/data/data_source/user_data_source.dart';
import 'package:flutter_template/shared/data/data_source/base/factory/data_source_factory.dart';

class RemoteDataSourceFactory implements DataSourceFactory {
  RemoteDataSourceFactory(this._userRemote, this._authRemote);

  final UserRemoteDataSource _userRemote;
  final AuthRemoteDataSource _authRemote;

  @override
  UserDataSource createUserDataSource() => _userRemote;

  @override
  AuthDataSource createAuthDataSource() => _authRemote;
}
