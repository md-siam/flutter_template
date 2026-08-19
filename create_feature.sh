#!/bin/bash
set -e

FEATURE_NAME=$1

if [ -z "$FEATURE_NAME" ]; then
  echo "❌ Usage: ./create_feature.sh <feature_name>"
  echo "Example: ./create_feature.sh test_feature"
  exit 1
fi

# Convert feature name to snake case (all lowercase, underscores)
FEATURE_SNAKE=$(echo "$FEATURE_NAME" | tr '[:upper:]' '[:lower:]')
ENTITY_CAMEL=$(echo "$FEATURE_NAME" | sed -r 's/(^|_)([a-zA-Z])/\U\2/g')

# ---------------------------
# Paths (Feature-first, Layer-inside: everything for a feature lives
# under lib/features/<feature_name>/{domain,data,presentation}/...)
# ---------------------------
FEATURE_DIR="lib/features/$FEATURE_SNAKE"

DOMAIN_ENTITY_DIR="$FEATURE_DIR/domain/entity"
DOMAIN_REPO_DIR="$FEATURE_DIR/domain/repository"
DOMAIN_USECASE_DIR="$FEATURE_DIR/domain/use_cases"

DATA_MODEL_DIR="$FEATURE_DIR/data/models"
DATA_REPO_IMPL_DIR="$FEATURE_DIR/data/repository_impl"
DATA_REMAPPER_DIR="$FEATURE_DIR/data/remapper"
DATA_DS_DIR="$FEATURE_DIR/data/data_source"

PRESENTATION_DIR="$FEATURE_DIR/presentation"
CUBIT_DIR="$PRESENTATION_DIR/cubit"
COMPONENTS_DIR="$PRESENTATION_DIR/components"

# ---------------------------
# Files
# ---------------------------
DOMAIN_ENTITY_FILE="$DOMAIN_ENTITY_DIR/${FEATURE_SNAKE}_entity.dart"
DOMAIN_REPO_FILE="$DOMAIN_REPO_DIR/${FEATURE_SNAKE}_repository.dart"
DOMAIN_USECASE_FILE="$DOMAIN_USECASE_DIR/get_${FEATURE_SNAKE}_usecase.dart"

DATA_MODEL_FILE="$DATA_MODEL_DIR/${FEATURE_SNAKE}_model.dart"
DATA_REPO_IMPL_FILE="$DATA_REPO_IMPL_DIR/${FEATURE_SNAKE}_repository_impl.dart"
DATA_REMAPPER_FILE="$DATA_REMAPPER_DIR/${FEATURE_SNAKE}_remapper.dart"
DATA_REMOTE_DS_FILE="$DATA_DS_DIR/${FEATURE_SNAKE}_remote_data_source.dart"
DATA_LOCAL_DS_FILE="$DATA_DS_DIR/${FEATURE_SNAKE}_local_data_source.dart"

CUBIT_FILE="$CUBIT_DIR/${FEATURE_SNAKE}_cubit.dart"
STATE_FILE="$CUBIT_DIR/${FEATURE_SNAKE}_state.dart"

SCREEN_FILE="$PRESENTATION_DIR/${FEATURE_SNAKE}_screen.dart"
PORTRAIT_VIEW_FILE="$PRESENTATION_DIR/${FEATURE_SNAKE}_portrait_view.dart"
LANDSCAPE_VIEW_FILE="$PRESENTATION_DIR/${FEATURE_SNAKE}_landscape_view.dart"
LIST_VIEW_FILE="$COMPONENTS_DIR/${FEATURE_SNAKE}_list_view.dart"

# ---------------------------
# Create directories
# ---------------------------
mkdir -p "$DOMAIN_ENTITY_DIR" "$DOMAIN_REPO_DIR" "$DOMAIN_USECASE_DIR"
mkdir -p "$DATA_MODEL_DIR" "$DATA_REPO_IMPL_DIR" "$DATA_REMAPPER_DIR" "$DATA_DS_DIR"
mkdir -p "$CUBIT_DIR"
mkdir -p "$PRESENTATION_DIR" "$COMPONENTS_DIR"

# ---------------------------
# Domain Entity — a `part of` file, generated together via
# lib/core/generated/base_entity.dart (single shared freezed output for
# every feature's entities). The class itself still lives in this feature's
# own domain/entity folder.
# ---------------------------
mkdir -p lib/core/generated
BASE_ENTITY_FILE="lib/core/generated/base_entity.dart"
if [ ! -f "$BASE_ENTITY_FILE" ]; then
  cat <<'EOF' > "$BASE_ENTITY_FILE"
import 'package:freezed_annotation/freezed_annotation.dart';

// Add your new entity part below
part 'base_entity.freezed.dart';
EOF
fi
ENTITY_PART_LINE="part '../../features/$FEATURE_SNAKE/domain/entity/${FEATURE_SNAKE}_entity.dart';"
if ! grep -Fxq "$ENTITY_PART_LINE" "$BASE_ENTITY_FILE"; then
  sed -i "/^\/\/ Add your new entity part below\$/a $ENTITY_PART_LINE" "$BASE_ENTITY_FILE"
fi

cat <<EOF > "$DOMAIN_ENTITY_FILE"
part of '../../../../core/generated/base_entity.dart';

@freezed
abstract class ${ENTITY_CAMEL}Entity with _\$${ENTITY_CAMEL}Entity {
  const factory ${ENTITY_CAMEL}Entity({
    required String id,
    required String title,
  }) = _${ENTITY_CAMEL}Entity;
}
EOF
echo "⚠️  Run build_runner to (re)generate lib/core/generated/base_entity.freezed.dart."

# ---------------------------
# Domain Repository
# ---------------------------
cat <<EOF > "$DOMAIN_REPO_FILE"
import 'package:flutter_template/core/generated/base_entity.dart';

abstract class ${ENTITY_CAMEL}Repository {
  Future<List<${ENTITY_CAMEL}Entity>> getAll();
  Future<${ENTITY_CAMEL}Entity> getById({required String id});
}
EOF

# ---------------------------
# Domain UseCase
# ---------------------------
cat <<EOF > "$DOMAIN_USECASE_FILE"
import 'package:injectable/injectable.dart';
import 'package:flutter_template/core/generated/base_entity.dart';
import 'package:flutter_template/features/$FEATURE_SNAKE/domain/repository/${FEATURE_SNAKE}_repository.dart';

@singleton
class Get${ENTITY_CAMEL}UseCase {
  final ${ENTITY_CAMEL}Repository repository;

  Get${ENTITY_CAMEL}UseCase(this.repository);

  Future<List<${ENTITY_CAMEL}Entity>> call() async {
    return await repository.getAll();
  }
}
EOF

# ---------------------------
# Data Model — a `part of` file, generated together via
# lib/core/generated/base_response_model.dart (single shared freezed/json
# output for every feature's response models). The class itself still lives
# in this feature's own data/models folder.
# ---------------------------
BASE_RESPONSE_FILE="lib/core/generated/base_response_model.dart"
if [ ! -f "$BASE_RESPONSE_FILE" ]; then
  cat <<'EOF' > "$BASE_RESPONSE_FILE"
import 'package:freezed_annotation/freezed_annotation.dart';

// Add your new response model part below
part 'base_response_model.freezed.dart';
part 'base_response_model.g.dart';
EOF
fi
MODEL_PART_LINE="part '../../features/$FEATURE_SNAKE/data/models/${FEATURE_SNAKE}_model.dart';"
if ! grep -Fxq "$MODEL_PART_LINE" "$BASE_RESPONSE_FILE"; then
  sed -i "/^\/\/ Add your new response model part below\$/a $MODEL_PART_LINE" "$BASE_RESPONSE_FILE"
fi

cat <<EOF > "$DATA_MODEL_FILE"
part of '../../../../core/generated/base_response_model.dart';

@freezed
abstract class ${ENTITY_CAMEL}ResponseModel with _\$${ENTITY_CAMEL}ResponseModel {
  const factory ${ENTITY_CAMEL}ResponseModel({
    required String id,
    required String title,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _${ENTITY_CAMEL}ResponseModel;

  factory ${ENTITY_CAMEL}ResponseModel.fromJson(Map<String, dynamic> json) =>
      _\$${ENTITY_CAMEL}ResponseModelFromJson(json);
}
EOF
echo "⚠️  Run build_runner to (re)generate lib/core/generated/base_response_model.{freezed,g}.dart."

# ---------------------------
# Repository Implementation
# ---------------------------
cat <<EOF > "$DATA_REPO_IMPL_FILE"
import 'package:injectable/injectable.dart';
import 'package:flutter_template/core/generated/base_data_source.dart';
import 'package:flutter_template/core/generated/base_entity.dart';
import 'package:flutter_template/features/$FEATURE_SNAKE/data/data_source/${FEATURE_SNAKE}_local_data_source.dart';
import 'package:flutter_template/features/$FEATURE_SNAKE/data/remapper/${FEATURE_SNAKE}_remapper.dart';
import 'package:flutter_template/features/$FEATURE_SNAKE/domain/repository/${FEATURE_SNAKE}_repository.dart';

@Singleton(as: ${ENTITY_CAMEL}Repository)
class ${ENTITY_CAMEL}RepositoryImpl implements ${ENTITY_CAMEL}Repository {
  final ${ENTITY_CAMEL}RemoteDataSource remoteDataSource;
  final ${ENTITY_CAMEL}LocalDataSource localDataSource;

  ${ENTITY_CAMEL}RepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<List<${ENTITY_CAMEL}Entity>> getAll() async {
    // Use local data for now
    final localData = await localDataSource.fetchCachedData();
    return localData.map((m) => m.toEntity()).toList();
  }

  @override
  Future<${ENTITY_CAMEL}Entity> getById({required String id}) async {
    final localData = await localDataSource.fetchCachedData();
    return localData.firstWhere((e) => e.id == id).toEntity();
  }
}
EOF

# ---------------------------
# Remapper
# ---------------------------
cat <<EOF > "$DATA_REMAPPER_FILE"
import 'package:flutter_template/core/generated/base_response_model.dart';
import 'package:flutter_template/core/generated/base_entity.dart';

extension ${ENTITY_CAMEL}Mapper on ${ENTITY_CAMEL}ResponseModel {
  ${ENTITY_CAMEL}Entity toEntity() => ${ENTITY_CAMEL}Entity(id: id, title: title);
}

extension ${ENTITY_CAMEL}ListMapper on List<${ENTITY_CAMEL}ResponseModel> {
  List<${ENTITY_CAMEL}Entity> toEntityList() => map((e) => e.toEntity()).toList();
}
EOF

# ---------------------------
# Remote Data Source — a `part of` file, generated together via
# lib/core/generated/base_data_source.dart (single shared Retrofit output
# for every feature's remote data sources). The interface itself still lives
# in this feature's own data/data_source folder.
# ---------------------------
BASE_DATA_SOURCE_FILE="lib/core/generated/base_data_source.dart"
if [ ! -f "$BASE_DATA_SOURCE_FILE" ]; then
  cat <<'EOF' > "$BASE_DATA_SOURCE_FILE"
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';
import 'package:flutter_template/core/generated/base_response_model.dart';
import 'package:flutter_template/shared/domain/enum/dio_client_type.dart';

// Add your new remote data source part below
part 'base_data_source.g.dart';
EOF
fi
DS_RESPONSE_MODEL_IMPORT_LINE="import 'package:flutter_template/core/generated/base_response_model.dart';"
if ! grep -Fxq "$DS_RESPONSE_MODEL_IMPORT_LINE" "$BASE_DATA_SOURCE_FILE"; then
  sed -i "1i $DS_RESPONSE_MODEL_IMPORT_LINE" "$BASE_DATA_SOURCE_FILE"
fi
DS_PART_LINE="part '../../features/$FEATURE_SNAKE/data/data_source/${FEATURE_SNAKE}_remote_data_source.dart';"
if ! grep -Fxq "$DS_PART_LINE" "$BASE_DATA_SOURCE_FILE"; then
  sed -i "/^\/\/ Add your new remote data source part below\$/a $DS_PART_LINE" "$BASE_DATA_SOURCE_FILE"
fi

cat <<EOF > "$DATA_REMOTE_DS_FILE"
part of '../../../../core/generated/base_data_source.dart';

@RestApi()
@singleton
abstract class ${ENTITY_CAMEL}RemoteDataSource {
  @factoryMethod
  factory ${ENTITY_CAMEL}RemoteDataSource(
    @Named(DioClientType.unauthenticated) Dio dio,
  ) = _${ENTITY_CAMEL}RemoteDataSource;

  @GET("/path-of-your-end-point")
  Future<${ENTITY_CAMEL}ResponseModel> fetchData();
}
EOF
echo "⚠️  Run build_runner to (re)generate lib/core/generated/base_data_source.g.dart."

# ---------------------------
# Local Data Source
# ---------------------------
cat <<EOF > "$DATA_LOCAL_DS_FILE"
import 'package:injectable/injectable.dart';
import 'package:flutter_template/core/generated/base_response_model.dart';

@singleton
class ${ENTITY_CAMEL}LocalDataSource {
  Future<List<${ENTITY_CAMEL}ResponseModel>> fetchCachedData() async {
    // Dummy data for UI
    return [
      ${ENTITY_CAMEL}ResponseModel(id: '1', title: 'Item 1', createdAt: '2026-01-07'),
      ${ENTITY_CAMEL}ResponseModel(id: '2', title: 'Item 2', createdAt: '2026-01-07'),
    ];
  }
}
EOF

# ---------------------------
# Cubit
# ---------------------------
cat <<EOF > "$CUBIT_FILE"
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:flutter_template/core/error/response_error.dart';
import 'package:flutter_template/core/state_status/base_status.dart';
import 'package:flutter_template/features/$FEATURE_SNAKE/domain/use_cases/get_${FEATURE_SNAKE}_usecase.dart';
import '${FEATURE_SNAKE}_state.dart';

@injectable
class ${ENTITY_CAMEL}Cubit extends Cubit<${ENTITY_CAMEL}State> {
  final Get${ENTITY_CAMEL}UseCase useCase;
  final _logger = Logger();

  ${ENTITY_CAMEL}Cubit(this.useCase) : super(${ENTITY_CAMEL}State());

  Future<void> fetchAll() async {
    emit(state.copyWith(status: BaseStatus<${ENTITY_CAMEL}State>.loading()));
    try {
      final list = await useCase.call();
      emit(
        state.copyWith(
          status: BaseStatus<${ENTITY_CAMEL}State>.success(),
          featureEntities: list,
        ),
      );
    } on DioException catch (e) {
      _logger.e(e);
      emit(
        state.copyWith(status: BaseStatus.failure(e.error as ResponseError)),
      );
    }
  }
}
EOF

# ---------------------------
# State
# ---------------------------
cat <<EOF > "$STATE_FILE"
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_template/core/state_status/base_status.dart';
import 'package:flutter_template/core/generated/base_entity.dart';

part '${FEATURE_SNAKE}_state.freezed.dart';

@freezed
sealed class ${ENTITY_CAMEL}State with _\$${ENTITY_CAMEL}State {
  const factory ${ENTITY_CAMEL}State({
    @Default([]) List<${ENTITY_CAMEL}Entity> featureEntities,
    @Default(BaseStatus<${ENTITY_CAMEL}State>.initial())
    BaseStatus<${ENTITY_CAMEL}State> status,
  }) = _${ENTITY_CAMEL}State;
}
EOF

# ---------------------------
# Screens
# ---------------------------
cat <<EOF > "$SCREEN_FILE"
import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_template/core/injector/injector.dart';

import '../../../shared/presentation/widgets/widgets.dart';
import 'cubit/${FEATURE_SNAKE}_cubit.dart';
import '${FEATURE_SNAKE}_landscape_view.dart';
import '${FEATURE_SNAKE}_portrait_view.dart';

@RoutePage()
class ${ENTITY_CAMEL}Screen extends Screen {
  const ${ENTITY_CAMEL}Screen({super.key});

  @override
  Widget buildViewWrapper({required Widget child}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => injector<${ENTITY_CAMEL}Cubit>()..fetchAll()),
      ],
      child: child,
    );
  }

  @override
  Widget buildMobilePortraitView(BuildContext context) {
    return const ${ENTITY_CAMEL}PortraitView();
  }

  @override
  Widget buildMobileLandscapeView(BuildContext context) {
    return const ${ENTITY_CAMEL}LandScapeView();
  }
}
EOF

# Portrait View
cat <<EOF > "$PORTRAIT_VIEW_FILE"
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_template/core/state_status/base_status.dart';

import '../../../shared/presentation/theme/text/app_text.dart';
import 'components/${FEATURE_SNAKE}_list_view.dart';
import 'cubit/${FEATURE_SNAKE}_cubit.dart';
import 'cubit/${FEATURE_SNAKE}_state.dart';

class ${ENTITY_CAMEL}PortraitView extends StatelessWidget {
  const ${ENTITY_CAMEL}PortraitView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: AppText.titleLargeBold("$ENTITY_CAMEL Name")),
      body: BlocBuilder<${ENTITY_CAMEL}Cubit, ${ENTITY_CAMEL}State>(
        builder: (context, state) {
          return switch (state.status) {
            Loading() => const Center(child: CircularProgressIndicator()),
            Success() =>
              state.featureEntities.isEmpty
                  ? const Center(child: Text("No items found"))
                  : ${ENTITY_CAMEL}ListView(items: state.featureEntities),
            Failure(:final responseError) => Center(
              child: AppText.bodyMedium(responseError.toString()),
            ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }
}
EOF

# Landscape View
cat <<EOF > "$LANDSCAPE_VIEW_FILE"
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_template/core/state_status/base_status.dart';

import '../../../shared/presentation/theme/text/app_text.dart';
import 'components/${FEATURE_SNAKE}_list_view.dart';
import 'cubit/${FEATURE_SNAKE}_cubit.dart';
import 'cubit/${FEATURE_SNAKE}_state.dart';

class ${ENTITY_CAMEL}LandScapeView extends StatelessWidget {
  const ${ENTITY_CAMEL}LandScapeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: AppText.titleLargeBold("$ENTITY_CAMEL Name")),
      body: BlocBuilder<${ENTITY_CAMEL}Cubit, ${ENTITY_CAMEL}State>(
        builder: (context, state) {
          return switch (state.status) {
            Loading() => const Center(child: CircularProgressIndicator()),
            Success() =>
              state.featureEntities.isEmpty
                  ? const Center(child: Text("No items found"))
                  : ${ENTITY_CAMEL}ListView(items: state.featureEntities),
            Failure(:final responseError) => Center(
              child: AppText.bodyMedium(responseError.toString()),
            ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }
}
EOF

# ---------------------------
# ListView Component
# ---------------------------
cat <<EOF > "$LIST_VIEW_FILE"
import 'package:flutter/material.dart';
import 'package:flutter_template/core/generated/base_entity.dart';

class ${ENTITY_CAMEL}ListView extends StatelessWidget {
  final List<${ENTITY_CAMEL}Entity> items;
  const ${ENTITY_CAMEL}ListView({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          title: Text(item.title),
          subtitle: Text('ID: \${item.id}'),
        );
      },
    );
  }
}
EOF

# ---------------------------
# Run build_runner
# ---------------------------
echo "🔹 Running build_runner..."
if command -v flutter >/dev/null 2>&1; then
  flutter pub get
  flutter pub run build_runner build --delete-conflicting-outputs
else
  dart pub get
  dart run build_runner build --delete-conflicting-outputs
fi

# ---------------------------
# Add route to app_router.dart
# ---------------------------
APP_ROUTER_FILE="lib/shared/presentation/route/app_router.dart"
ROUTE_LINE="AutoRoute(page: ${ENTITY_CAMEL}Route.page),"

# Insert before the closing bracket of the routes list (assumes last line with '];')
if ! grep -Fxq "$ROUTE_LINE" "$APP_ROUTER_FILE"; then
  sed -i "/List<AutoRoute> get routes => \[/,/];/ s/];/    $ROUTE_LINE\n  ];/" "$APP_ROUTER_FILE"
  echo "Added ${ENTITY_CAMEL}Screen route to app_router.dart"
fi

echo "🎉 Feature '$FEATURE_NAME' generated successfully!"
