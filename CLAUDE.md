# Flock Mobile

> Flutter app for iOS and Android, consuming the Flock API.

---

## Stack

| Layer | Technology | Version |
|-------|------------|---------|
| Framework | Flutter | 3.38+ |
| Language | Dart | 3.10+ |
| State | Bloc / Cubit | 9.x |
| DI | get_it + injectable | Latest |
| HTTP | dio + retrofit | Latest |
| Local Storage | drift (SQLite) | Latest |
| Functional | fpdart | Latest |
| Testing | bloc_test, mocktail | Latest |

### Platform Requirements

| Platform | Requirement |
|----------|-------------|
| Android | Java 17+, NDK r28, 16KB page alignment, targetSdk 35 |
| iOS | Xcode 26+, UIScene lifecycle |
| Dart SDK | `sdk: '^3.10.0'` |

---

## Dart 3.10 — Use These Features

### Dot Shorthands (Flagship Feature)
```dart
// ✅ Always — omit type when compiler knows it
Column(mainAxisAlignment: .center, children: [...])
Container(color: .blue, padding: .all(16))
emit(.loading())

// ❌ Never — verbose repetition
Column(mainAxisAlignment: MainAxisAlignment.center)
```

### Pattern Matching
- **Sealed classes** for states/events — enables exhaustive `switch`
- **`switch` expressions** over if/else chains
- **Destructuring** in case clauses: `case AuthSuccess(:final user):`

### Class Modifiers
- `sealed` — States, events, failures (exhaustive switching)
- `final` — Concrete implementations that shouldn't be extended
- `base` — Base classes that must be extended, not implemented

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  PRESENTATION — Pages, Blocs, Widgets                       │
├─────────────────────────────────────────────────────────────┤
│  DOMAIN — Entities, Repositories (abstract), UseCases       │
├─────────────────────────────────────────────────────────────┤
│  DATA — Models, Repositories (impl), DataSources            │
└─────────────────────────────────────────────────────────────┘
       ↑ Dependencies point inward. Domain knows nothing external.
```

### Project Structure
```
lib/
├── core/           # DI, network, storage, router, theme
├── features/       # Feature modules (auth/, church/, feed/, etc.)
│   └── {feature}/
│       ├── data/           # Models, datasources, repository impl
│       ├── domain/         # Entities, repository interface, usecases
│       └── presentation/   # Bloc, pages, widgets
└── shared/         # Cross-feature widgets, extensions, utils

test/               # Mirrors lib/ structure
integration_test/   # E2E flows
```

---

## Bloc Rules

### Event Transformers (bloc_concurrency)
| Transformer | Use Case | Example |
|-------------|----------|---------|
| `droppable()` | Prevent double-tap | Login, form submit, payment |
| `restartable()` | Cancel previous | Search, autocomplete |
| `sequential()` | Ordered execution | Rarely needed |

### State Design
- States are `sealed class` hierarchies
- Use factory constructors: `.initial()`, `.loading()`, `.success(data)`, `.failure(error)`
- Emit with dot shorthands: `emit(.loading())`

### Selectors
- Use `BlocSelector` for surgical rebuilds — extract only what the widget needs
- Split complex UIs into small widgets, each with its own selector

---

## Functional Programming (fpdart)

### Either Handling
```dart
// ✅ Pattern match with switch — exhaustive, readable
switch (result) {
  case Left(:final value): emit(.failure(value.message));
  case Right(:final value): emit(.success(value));
}

// ❌ Avoid .fold() — less readable, not exhaustive
result.fold((l) => ..., (r) => ...);
```

### Core Types
| Type | Purpose |
|------|---------|
| `Either<Failure, T>` | Sync operations that can fail |
| `TaskEither<Failure, T>` | Async operations that can fail |
| `Option<T>` | Nullable alternatives |

---

## Network Layer (ApiClient)

The `ApiClient` wraps Dio with automatic auth token injection and consistent error handling.

### Usage in Data Sources
```dart
final class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  @override
  TaskEither<Failure, ProfileModel> getProfile() => _client
      .get('/profile')
      .map((json) => ProfileModel.fromJson(json['data'] as Map<String, dynamic>));
}
```

### Failure Types (sealed class)
```dart
sealed class Failure extends Equatable {
  const Failure(this.message);
  final String message;
}

final class NetworkFailure extends Failure { ... }
final class ServerFailure extends Failure { ... }
final class AuthFailure extends Failure { ... }
final class ValidationFailure extends Failure { ... }
final class NotFoundFailure extends Failure { ... }
final class UnexpectedFailure extends Failure { ... }
```

### Use Case Pattern
```dart
final class CreateProfile {
  const CreateProfile(this._repository);
  final ProfileRepository _repository;

  TaskEither<Failure, Profile> call(CreateProfileParams params) =>
      _repository.createProfile(params);
}
```

### Bloc with Use Cases
```dart
Future<void> _onSubmitted(...) async {
  final result = await _createProfile(params).run();

  emit(switch (result) {
    Right(:final value) => state.copyWith(status: .success, profile: value),
    Left(:final value) => state.copyWith(status: .failure, errorMessage: value.message),
  });
}
```

---

## Offline-First (drift)

- **Local-first**: Read from drift, sync with API in background
- **Optimistic updates**: Update UI immediately, reconcile on sync
- **Conflict resolution**: Server wins, or timestamp-based merge
- **Sync queue**: Failed writes queued for retry with exponential backoff

---

## Testing

### Approach
1. **TDD** — Write failing test first, always
2. **Unit tests** — Blocs, UseCases, Repositories
3. **Widget tests** — Critical UI flows
4. **Integration tests** — E2E journeys (auth flow, core features)
5. **Golden tests** — Visual regression for design system components

### Test Patterns
- Mock with `mocktail` — `class MockRepo extends Mock implements Repo {}`
- fpdart returns: `right(value)` for success, `left(Failure(...))` for failure
- Verify event transformers: test that duplicate rapid events are dropped/restarted

### Edge Cases to Always Cover
- Empty/null/whitespace inputs
- Network timeout, no connection, 5xx, 4xx
- Expired/revoked tokens
- Rapid successive events (double-tap)
- Malformed API responses

---

## Navigation (go_router)

### Guards
- `redirect` for auth protection — check auth state, redirect to login
- Deep links: `/:churchId/events/:eventId` — validate IDs, handle not-found

### Patterns
- Declarative routes with `GoRoute`
- Nested navigation with `ShellRoute` for bottom nav persistence
- Type-safe routes with code generation or sealed route classes

---

## Security

- **Tokens**: Store in `flutter_secure_storage`, never in SharedPreferences
- **Biometrics**: Gate sensitive actions (payment, account deletion)
- **Certificate pinning**: For production API calls
- **No logging**: Never log tokens, passwords, or PII

---

## Performance

- **const everything**: Widgets, EdgeInsets, TextStyles
- **BlocSelector**: Rebuild only what changes
- **RepaintBoundary**: Around animations and frequently updating widgets
- **Image caching**: `CachedNetworkImage` with size constraints
- **Dispose**: Cancel subscriptions, close controllers

---

## Localization

- Use `flutter_localizations` + ARB files
- Keys: `snake_case` descriptive (`login_button_submit`, not `btn1`)
- Plurals/gender: Use ICU message format
- No hardcoded strings in widgets

---

## Commands

```bash
# Verify environment
java --version                      # Must be 17+
flutter doctor -v

# Development
flutter run --dart-define=ENV=dev
flutter run --profile               # Performance profiling

# Testing
flutter test
flutter test --coverage
flutter test integration_test/

# Code generation
dart run build_runner build --delete-conflicting-outputs

# Quality
flutter analyze
dart format . --set-exit-if-changed
dart fix --apply

# Build
flutter build apk --analyze-size
flutter build appbundle
flutter build ipa
```

---

## Key Principles

1. **Dart 3.10** — Dot shorthands everywhere, sealed classes, exhaustive switches
2. **fpdart** — `Either`/`TaskEither` with switch expressions, not fold
3. **Bloc discipline** — Event transformers on all user-triggered events
4. **Offline-first** — Drift as source of truth, API syncs in background
5. **TDD** — Failing test first, no exceptions
6. **Performance** — const widgets, BlocSelector, dispose properly
7. **Security** — Secure storage, no PII logging, certificate pinning
8. **Accessibility** — Semantic labels, sufficient contrast, screen reader support
