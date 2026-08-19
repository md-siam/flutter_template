part of '../../../../../core/generated/base_data_source.dart';

@RestApi()
@LazySingleton()
abstract class AuthRemoteDataSource implements AuthDataSource {
  @factoryMethod
  factory AuthRemoteDataSource(@Named(DioClientType.unauthenticated) Dio dio) =
      _AuthRemoteDataSource;

  @override
  @POST('/login')
  Future<String> login(@Body() LoginRequestModel inputModel);
}
