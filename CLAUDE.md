# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A Flutter Clean Architecture template (created via Very Good CLI). Requires Dart SDK `^3.11.0`.

## Commands

### Running (three flavors)
```bash
flutter run --flavor development --target lib/main_development.dart  # mocked data, no backend
flutter run --flavor staging     --target lib/main_staging.dart
flutter run --flavor production   --target lib/main_production.dart
```

### First-time setup
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
./setup.sh   # installs git hooks (commit-msg + branch-name enforcement) and makes scripts executable
```

### Code generation (run after touching freezed/injectable/retrofit/json/asset code)
```bash
dart run build_runner build --delete-conflicting-outputs   # one-off
dart run build_runner watch --delete-conflicting-outputs   # continuous
```
Generated files (`*.g.dart`, `*.freezed.dart`, `injector.config.dart`, `*.gr.dart`, `assets.gen.dart`) are checked in and excluded from analysis. Do not hand-edit them.

### Testing
```bash
flutter test                                                  # all
flutter test test/features/home/presentation/user_cubit_test.dart  # single file
flutter test --plain-name "maps response models to entities"  # by name
flutter test --coverage                                       # writes coverage/lcov.info
```

### Lint
```bash
flutter analyze   # uses very_good_analysis via flutter_lints (see analysis_options.yaml)
```

### Localization
```bash
./l10n_generator.sh   # add ARB keys interactively (choose type "text"); access via context.l10n.<key>
```
ARB source: `lib/l10n/arb/app_en.arb` (template) + `app_es.arb`. Generated into `lib/l10n/gen/`.

### Scaffold a new feature
```bash
./create_feature.sh feature_name   # generates lib/features/feature_name/{domain,data,presentation} following the conventions below
```

## Architecture

Clean Architecture, organized **Feature-first, Layer-inside**: each feature owns its own `domain/`, `data/`, and `presentation/` slice, rather than one global layer housing every feature's code. Four top-level directories under `lib/`:

- **`features/<feature_name>/`** — one directory per feature (`auth`, `user`, `home`, `dashboard`, `settings`, `splash`, `architecture`, `widget_screen`). Inside each:
  - `domain/` — business core, no Flutter/data dependencies. `entity/` (freezed models — see `core/generated` note below), `repository/` (abstract interfaces), `use_cases/` (one operation each, mixing in `BaseUseCase<Output>` or `BaseUseCaseWithParams<Output, Params>` from `core/generated`), `exceptions/` where relevant.
  - `data/` — implements that feature's domain contracts. `repository_impl/` implement `domain/repository` interfaces; `data_source/` talk to APIs (Retrofit) or mocks (with `local/`, `mock/`, `remote/` subfolders as needed) — see `core/generated` note below; `models/` are request/response DTOs — see `core/generated` note below; `remapper/` are extensions mapping DTOs ↔ domain entities.
  - `presentation/` — UI via BLoC/Cubit for that feature: screens, portrait/landscape views, `components/`, `cubit(s)/`. Cubits emit freezed states wrapping a `BaseStatus`.

  A feature may depend on another feature's `domain` (and occasionally `data`) layer — e.g. `home/presentation` consumes `user`'s use cases — but should never reach into another feature's `presentation`.

- **`shared/`** — code genuinely used across multiple features, mirroring the same layer split:
  - `shared/domain/` — `enum/` (e.g. `DioClientType`).
  - `shared/data/` — `data_source/base/` (`DataSourceFactory` abstract factory plus its `mock`/`remote` implementations, `BackendErrorInterceptor`).
  - `shared/presentation/` — `app/` (root `App` widget), `route/` (auto_route config), `theme/`, `widgets/` (reusable design-system widgets), `locale/`.

- **`core/`** — cross-cutting, non-domain infrastructure, untouched by feature boundaries: `injector/` (DI), `env/` (flavors), `state_status/` (`BaseStatus`), `error/` (`ResponseError`), `helper/`, `extensions/`, `constants/`, and `generated/` (see below).

### `core/generated/` — shared base + Freezed/Retrofit aggregation
Rather than every feature's entity/model/remote-data-source file owning its own `.freezed.dart`/`.g.dart`, this project keeps the code-generation boilerplate in one place, `lib/core/generated/`, using Dart's `part`/`part of`:

- `base_use_case.dart` — `BaseUseCase<Output>` / `BaseUseCaseWithParams<Output, Params>` mixins. Not code-generated, just colocated with the rest.
- `base_entity.dart` + `base_entity.freezed.dart` — the library file `part`s in every feature's entity file (e.g. `features/auth/domain/entity/login_entity.dart`, `features/user/domain/entity/user_entity.dart`); the single `.freezed.dart` covers all of them.
- `base_request_model.dart` (+`.freezed.dart`/`.g.dart`) — same pattern for request DTOs (e.g. `features/auth/data/models/login_request_model.dart`).
- `base_response_model.dart` (+`.freezed.dart`/`.g.dart`) — same pattern for response DTOs (e.g. `features/user/data/models/user_response_model.dart`).
- `base_data_source.dart` (+`.g.dart`) — same pattern for Retrofit `@RestApi()` remote data sources (e.g. `features/auth/data/data_source/remote/auth_remote_data_source.dart`, `features/user/data/data_source/remote/user_remote_data_source.dart`).

**Important:** the actual class/interface definitions still live inside each feature's own folder — only the file starts with `part of '.../core/generated/base_x.dart';` instead of declaring its own library and generated part. Because of this, other code must import the `core/generated/base_x.dart` aggregator to use these types (e.g. `import 'package:flutter_template/core/generated/base_entity.dart';` to get `UserEntity`) — importing a `part of` file directly is a Dart compile error. `create_feature.sh` handles this automatically: it appends the new feature's `part '../../features/.../xxx.dart';` line into the relevant `core/generated/base_*.dart` file for you.

Within a feature, prefer relative imports for files in the same feature/layer; use `package:flutter_template/...` imports when crossing into `core/`, `shared/`, or another feature.

### Dependency injection (injectable + get_it)
- Global container is `injector` in [lib/core/injector/injector.dart](lib/core/injector/injector.dart). Registrations are generated into `injector.config.dart`.
- `configureDependencies(environmentName)` is called during bootstrap; the environment string gates which registrations activate.
- Annotate classes with `@singleton` / `@lazySingleton` / `@injectable` / `@Singleton(as: SomeInterface)`. Third-party/config objects are provided via `@module` classes in [lib/core/injector/module.dart](lib/core/injector/module.dart) (Dio, secure storage, logger).
- **After adding/removing any DI annotation, re-run build_runner** or the change won't take effect.

### Flavor-based data mocking (key pattern)
Data sources are obtained through an **Abstract Factory**, not injected directly, so flavor selects real vs. mocked data at DI time:
- `DataSourceFactory` interface → `createUserDataSource()`, `createAuthDataSource()`.
- [lib/shared/data/data_source/base/factory/data_source_provider.dart](lib/shared/data/data_source/base/factory/data_source_provider.dart) binds `MockDataSourceFactory` for `@Environment(development)` and `RemoteDataSourceFactory` for staging/production.
- Repository impls take `DataSourceFactory` in their constructor and call `factory.createXDataSource()` — they never know whether data is mocked.
- Each data source has an abstract interface (`features/user/data/data_source/user_data_source.dart`) plus `mock/` implementations in that feature, and a `remote/` (Retrofit `@RestApi`) implementation that's actually a `part of` file aggregated into `core/generated/base_data_source.dart` (see above).
- **Consequence:** the `development` flavor runs fully offline against mock data. Adding a data source means: interface + `mock/` impl in that feature's `data/data_source/`, a `remote/xxx_remote_data_source.dart` `part of` file wired into `core/generated/base_data_source.dart`, then both into `DataSourceProvider` and both factories in `shared/data/data_source/base/factory/`.

Environment names live in one place: `AppEnvironment` ([lib/core/env/app_environment.dart](lib/core/env/app_environment.dart)) — used for both `@Environment(...)` annotations and config classes. Each flavor has a `main_<flavor>.dart` entry that instantiates its `Env` subclass ([lib/core/env/](lib/core/env/)), which sets `Env.shared` and bootstraps the app (`configureDependencies`, `Bloc.observer`, `runApp`).

### State handling
Cubit states are freezed classes holding a `BaseStatus` (`loading` / `success` / `failure(ResponseError)`). Cubits catch `DioException` and emit `BaseStatus.failure`. Backend errors flow through `BackendErrorInterceptor` → `ResponseError`.

## Testing conventions
`test/` mirrors `lib/` layer structure; each layer is tested in isolation by mocking the layer directly beneath it (`mocktail`). No real network/storage/DI is touched. When using `any()` with a custom type, `registerFallbackValue(...)` once in `setUpAll`. See README §6 for full patterns.

## Git conventions (enforced by hooks after `./setup.sh`)
- **Branches:** `feat/`, `fix/`, `refactor/`, or `chore/` prefix (except `main`/`develop`/`master`).
- **Commits:** Conventional Commits — `type: description` (≥3 chars). Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `style`, `test`, `perf`, `ci`, `build`, `revert`, `wip`.
- CI (`.github/workflows/main.yaml`) runs on `main`: semantic-PR check, `very_good` Flutter build/test, and spell-check.
