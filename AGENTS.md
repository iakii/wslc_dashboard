# Repository Guidelines

## Project Overview

**WSL Container Dashboard** — Windows-only Flutter desktop application providing a GUI for managing WSL containers. Uses Fluent Design (`fluent_ui`) for native Windows look-and-feel, Riverpod for state management, and Freezed for immutable domain models. The Dart layer communicates with the Microsoft.WSL.Containers WinRT SDK (v2.9.3) through a Flutter MethodChannel bridge (`com.wslc.dashboard/api`) backed by C++ native code under `windows/runner/wslc/`.

Target: **Windows desktop only** — no Web, Android, iOS, Linux, or macOS support.

## Architecture & Data Flow

```
┌─ lib/presentation/ ─────────────────────────────────────┐
│  Pages (ConsumerStatefulWidget) ← ref.watch(…Provider)   │
│  Providers (Riverpod AsyncNotifierProvider / StreamProvider)│
└──────────────────────┬───────────────────────────────────┘
                       │ depends on
┌─ lib/domain/ ────────▼───────────────────────────────────┐
│  Entities (Freezed, immutable, fromJson)                 │
│  Repository interfaces (abstract class, pure Dart)       │
│  Usecases (directories exist, empty — not yet used)      │
└──────────────────────┬───────────────────────────────────┘
                       │ implemented by
┌─ lib/data/ ──────────▼───────────────────────────────────┐
│  Models (json_annotation, .toDomain() → Entity)          │
│  Datasources (WslcNativeDatasource, wraps MethodChannel) │
│  Repository impls (try/catch → NativeApiFailure mapping) │
└──────────────────────┬───────────────────────────────────┘
                       │ calls
┌─ lib/core/ ──────────▼───────────────────────────────────┐
│  Platform: WslcMethodChannel singleton (MethodChannel)   │
│  Errors: sealed class Failure + WslcException            │
│  Theme: FluentThemeData via AppTheme.light()/dark()      │
│  Utils: print-based Logger, Constants                    │
└──────────────────────┬───────────────────────────────────┘
                       │ MethodChannel invokeMethod
┌─ windows/runner/wslc/ ───────────────────────────────────┐
│  C++ native plugins → Microsoft.WSL.Containers SDK       │
│  Six bridge classes: Service, Session, Image, Container, │
│  Process, Log                                            │
└──────────────────────────────────────────────────────────┘
```

- **No dependency injection framework** — singletons and Riverpod providers handle wiring.
- **No hooks** — pages use `ConsumerStatefulWidget` (4/5) or `ConsumerWidget` (1/5).
- **Models are not entities** — JSON models live in `data/models/`, convert to domain entities via `.toDomain()`.

## Key Directories

| Directory | Purpose |
|---|---|
| `lib/main.dart` | Entry point: window init (Mica, hidden title bar), tray setup, `runApp` |
| `lib/app.dart` | Root `FluentApp` with `NavigationView` (4 panes: 概览/镜像/容器/设置) |
| `lib/core/` | Infrastructure: theme, errors, logger, platform (MethodChannel), constants |
| `lib/domain/` | Business logic: Freezed entities, abstract repository interfaces, usecase stubs |
| `lib/data/` | Implementations: JSON models, native datasource, repository impls |
| `lib/presentation/` | UI layer: pages, Riverpod providers, widgets (currently empty) |
| `windows/runner/wslc/` | C++ MethodChannel handlers for Microsoft.WSL.Containers SDK |
| `assets/` | Static assets (tray icon) |
| `test/` | Widget tests |

## Development Commands

```bash
# Dependency management
flutter pub get

# Code generation (required after entity/model/provider changes)
dart run build_runner build
# or watch mode:
dart run build_runner watch

# Run on Windows
flutter run -d windows

# Build release
flutter build windows

# Static analysis
flutter analyze

# Format
dart format lib/

# Tests
flutter test

# Lint (dead code)
dart run custom_lint  # if configured

# Packaging (via mise/fastforge)
mise run window       # package for Windows
```

## Code Conventions & Common Patterns

### Formatting & Style
- **Prefer single quotes** (`prefer_single_quotes: true`)
- **Prefer `const` constructors** and `const` literals (`prefer_const_constructors`, `prefer_const_literals_to_create_immutables`)
- **Strict casts and inference** enabled in analyzer
- **No `print` lint** (`avoid_print: false` — project uses `Logger.info/error/debug` wrapper)
- Generated files excluded from analysis: `*.g.dart`, `*.freezed.dart`

### Naming
- Files: `snake_case.dart`
- Classes: `UpperCamelCase`, prefixed with domain (`WslcRepository`, `WslContainer`, `WslImage`)
- Repository interfaces: `*Repository` (abstract class in `domain/repositories/`)
- Repository implementations: `*RepositoryImpl` (in `data/repositories/`)
- Providers: `*Provider` suffix (e.g., `sessionProvider`, `containerListProvider`)
- Freezed entities: domain-prefixed (`WslSession`, `WslContainer`, `WslImage`)

### Domain Entities (Freezed)
```dart
// lib/domain/entities/wsl_container.dart
@freezed
class WslContainer with _$WslContainer {
  const factory WslContainer({
    required String id,
    required String name,
    required String imageName,
    required ContainerStatus status,
    required DateTime createdAt,
  }) = _WslContainer;
  factory WslContainer.fromJson(Map<String, dynamic> json) =>
      _$WslContainerFromJson(json);
}
```
- All entities are `@freezed` with `const factory` and `fromJson`.
- Enums (like `ContainerStatus`) defined in the same file.
- Non-Freezed exception: `WslProcessOutput` (plain `@immutable` class for log stream items).

### JSON Models → Domain Mapping
```dart
// lib/data/models/wsl_container_model.dart
@JsonSerializable()
class WslContainerModel {
  final String id;
  final String name;
  // ... fields match JSON shape from native layer
  WslContainer toDomain() => WslContainer(
    id: id,
    name: name,
    // ... map strings to enums, etc.
  );
}
```
- `@JsonSerializable()` with `fromJson`/`toJson` via `json_serializable`.
- Each model has a `toDomain()` method returning the Freezed entity.
- String-to-enum conversion in model (e.g., `_parseStatus()`).

### Error Handling
```dart
// lib/core/errors/failures.dart
sealed class Failure {
  final String message;
  const Failure(this.message);
}
class WslcNotInstalled extends Failure { ... }
class SessionNotReady extends Failure { ... }
class NativeApiFailure extends Failure {
  final int? code;
  ...
}
class TimeoutFailure extends Failure { ... }

// lib/core/errors/wslc_exception.dart
class WslcException implements Exception {
  final String message;
  final int? code;
}
```
- **Dual error model**: `sealed class Failure` for domain-layer errors, `WslcException` for thrown exceptions.
- Repository implementations wrap datasource calls in `try/catch`, mapping exceptions to `NativeApiFailure` with Chinese error messages.

### State Management (Riverpod)
- **AsyncNotifierProvider** for async operations with loading/error/data states:
  ```dart
  // lib/presentation/providers/session_providers.dart
  final sessionProvider = AsyncNotifierProvider<SessionNotifier, WslSession>(
    SessionNotifier.new,
  );
  ```
  Notifier methods (`createSession`, `refresh`, etc.) delegate to `ref.read(wslcRepositoryProvider)`.

- **StreamProvider.family** for real-time streams (container logs via EventChannel):
  ```dart
  final containerLogsProvider =
      StreamProvider.family<WslProcessOutput, String>((ref, containerId) { ... });
  ```

- **StateProvider** for simple toggle state (`isDarkThemeProvider`, `minimizeToTrayProvider`).
- **Dependency chain**: `wslcChannelProvider` → `wslcDatasourceProvider` → `wslcRepositoryProvider`.
- **Page consumption**: `ConsumerStatefulWidget` + `ref.watch(provider)` returns `AsyncValue<T>`, pattern-matched with `.when(loading:, error:, data:)`.

### UI Patterns (Fluent UI)
- Pages use `ScaffoldPage` with `PageHeader`.
- Navigation: `NavigationView` + `NavigationPane` with `PaneItem`s in `app.dart`.
- Sub-page navigation: `Navigator.push(context, FluentPageRoute(...))`.
- Dialogs: `ContentDialog` (via `showDialog`).
- Status indicators: `ProgressRing` (loading), `InfoBar` (errors with retry).
- Container log viewer: dark terminal-style `ListView.builder` with color-coded stream output.

### Platform Communication
```dart
// lib/core/platform/wslc_method_channel.dart
class WslcMethodChannel {
  static final WslcMethodChannel instance = WslcMethodChannel._();
  final MethodChannel _channel = const MethodChannel('com.wslc.dashboard/api');
  // All WSL operations go through invokeMethod → Map<String, dynamic>
}
```
- Singleton pattern with private constructor.
- `MethodChannel` for request/response, `EventChannel` for streaming (logs, pull progress).
- Native C++ side: `windows/runner/wslc/wslc_native_plugin.h` dispatches to six bridge classes.

## Important Files

| File | Role |
|---|---|
| `lib/main.dart` | Entry point: Mica window, tray icon, `runApp` |
| `lib/app.dart` | Root widget: `FluentApp` + `NavigationView` (4 tabs) |
| `lib/core/platform/wslc_method_channel.dart` | Native MethodChannel singleton — all WSL operations |
| `lib/core/constants/app_constants.dart` | Channel names, defaults, pref keys |
| `lib/core/errors/failures.dart` | `sealed class Failure` hierarchy |
| `lib/domain/repositories/wslc_repository.dart` | WSL operations contract (12 methods) |
| `lib/domain/repositories/settings_repository.dart` | Settings persistence contract (6 methods) |
| `lib/data/datasources/wslc_native_datasource.dart` | MethodChannel adapter with type-safe casting |
| `lib/data/repositories/wslc_repository_impl.dart` | Error-mapped WSL operations |
| `lib/presentation/providers/session_providers.dart` | Session lifecycle + dependency chain |
| `lib/presentation/providers/container_providers.dart` | Container CRUD + log streaming |
| `lib/presentation/providers/image_providers.dart` | Image CRUD + pull progress |
| `lib/presentation/providers/settings_providers.dart` | Theme/tray/autostart prefs |
| `windows/runner/CMakeLists.txt` | C++ build: SDK linking, bridge sources |
| `pubspec.yaml` | Dependencies, SDK constraint (`^3.12.2`) |
| `analysis_options.yaml` | Lint rules (`flutter_lints`, strict casts) |
| `mise.toml` | Toolchain: Flutter stable, fastforge packaging tasks |

## Runtime/Tooling Preferences

- **Framework**: Flutter (stable channel, managed via `mise.toml`)
- **Dart SDK**: `^3.12.2`
- **Package manager**: `flutter pub` (pub.dev)
- **Build system**: CMake 3.14+ / C++17 / MSVC (`/W4 /WX /wd4100 /EHsc`)
- **NuGet**: `Microsoft.WSL.Containers` v2.9.3 (native SDK, `wslcsdk.dll` copied post-build)
- **Code generation**: `build_runner` + `freezed` + `json_serializable` + `riverpod_generator`
- **Lint**: `flutter_lints ^6.0.0` with `strict-casts: true`, `strict-inference: true`
- **Formatting**: `dart format lib/` (no custom line length or trailing comma rules beyond Dart defaults)
- **Packaging**: `fastforge` (via `mise run window`)
- **No CI configuration** present in repo

## Testing & QA

- **Framework**: `flutter_test` (built-in)
- **Test location**: `test/` directory
- **Widget testing**: Wrap with `ProviderScope` for Riverpod access:
  ```dart
  testWidgets('app renders', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WslcDashboardApp()));
    expect(find.byType(WslcDashboardApp), findsOneWidget);
  });
  ```
- **Mocking**: `mockito ^5.4.5` available for repository/data source mocking
- **No integration or golden tests** currently present
- **No coverage thresholds** configured
