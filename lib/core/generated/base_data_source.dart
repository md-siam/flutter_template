import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:flutter_template/features/auth/data/data_source/auth_data_source.dart';
import 'package:flutter_template/features/user/data/data_source/user_data_source.dart';
import 'package:flutter_template/core/generated/base_request_model.dart';
import 'package:flutter_template/core/generated/base_response_model.dart';
import 'package:flutter_template/shared/domain/enum/dio_client_type.dart';

// Add your new remote data source part below
part '../../features/auth/data/data_source/remote/auth_remote_data_source.dart';
part '../../features/user/data/data_source/remote/user_remote_data_source.dart';

part 'base_data_source.g.dart';
