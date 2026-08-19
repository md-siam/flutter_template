part of '../../../../../core/generated/base_data_source.dart';

@RestApi()
@LazySingleton()
abstract class UserRemoteDataSource implements UserDataSource {
  @factoryMethod
  factory UserRemoteDataSource(@Named(DioClientType.unauthenticated) Dio dio) =
      _UserRemoteDataSource;

  @override
  @GET('/users')
  Future<List<UserResponseModel>> getUserList();

  @override
  @GET('/users/{id}')
  Future<UserResponseModel> getUserById({@Path('id') required String userId});
}
