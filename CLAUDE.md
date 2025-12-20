# Flock Mobile

> Flutter application for iOS and Android, consuming the Flock API.

---

## Stack

| Layer | Technology | Version |
|-------|------------|---------|
| Framework | Flutter | 3.24+ |
| Language | Dart | 3.5+ |
| State | Bloc / Cubit | Latest |
| DI | get_it + injectable | Latest |
| HTTP | dio | Latest |
| Local Storage | drift (SQLite) | Latest |
| Testing | bloc_test, mocktail | Latest |

**Always use the latest stable versions.** Check for updates regularly.

---

## Modern Dart Features

We use Dart 3.5+ features extensively. This is non-negotiable.

### Records

```dart
// ✅ Use records for multiple return values
(User user, String token) parseAuthResponse(Map<String, dynamic> json) {
  return (
    User.fromJson(json['user']),
    json['token'] as String,
  );
}

// ✅ Named fields for clarity
({int page, int pageSize, bool hasMore}) parsePagination(Map<String, dynamic> meta) {
  return (
    page: meta['page'] as int,
    pageSize: meta['pageSize'] as int,
    hasMore: meta['hasMore'] as bool,
  );
}
```

### Patterns & Exhaustive Switching

```dart
// ✅ Sealed classes for state
sealed class AuthState {}

final class AuthInitial extends AuthState {}
final class AuthLoading extends AuthState {}
final class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
}
final class AuthUnauthenticated extends AuthState {}
final class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// ✅ Exhaustive switch expressions
Widget buildAuthContent(AuthState state) => switch (state) {
  AuthInitial() => const SplashScreen(),
  AuthLoading() => const LoadingScreen(),
  AuthAuthenticated(:final user) => HomeScreen(user: user),
  AuthUnauthenticated() => const LoginScreen(),
  AuthError(:final message) => ErrorScreen(message: message),
};
```

### Pattern Matching

```dart
// ✅ Destructuring in conditions
void handleResponse(ApiResponse response) {
  if (response case ApiSuccess(:final data, :final meta)) {
    processData(data, meta);
  } else if (response case ApiError(:final message, code: >= 500)) {
    showServerError(message);
  } else if (response case ApiError(:final message)) {
    showClientError(message);
  }
}

// ✅ Guard clauses with patterns
String formatMember(Member? member) => switch (member) {
  null => 'Unknown',
  Member(displayName: '') => 'Anonymous',
  Member(:final displayName) => displayName,
};
```

### Class Modifiers

```dart
// ✅ Use appropriate modifiers
sealed class Event {}           // Can only be extended in this file
final class SpecificEvent {}    // Cannot be extended
base class BaseRepository {}    // Must be extended, not implemented
interface class Cacheable {}    // Can only be implemented
mixin class Disposable {}       // Can be used as mixin or class
```

---

## Project Structure

```
lib/
├── main.dart
├── app.dart                    # MaterialApp configuration
│
├── core/                       # App-wide utilities
│   ├── di/                     # Dependency injection
│   │   ├── injection.dart
│   │   └── injection.config.dart
│   ├── error/                  # Error handling
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/                # HTTP client, interceptors
│   │   ├── api_client.dart
│   │   ├── api_client.g.dart
│   │   └── interceptors/
│   ├── storage/                # Local persistence
│   │   ├── secure_storage.dart
│   │   └── preferences.dart
│   ├── router/                 # Navigation
│   │   ├── app_router.dart
│   │   └── routes.dart
│   └── theme/                  # App theme
│       ├── app_theme.dart
│       ├── colors.dart
│       └── typography.dart
│
├── features/                   # Feature-based organization
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   └── auth_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── login.dart
│   │   │       ├── register.dart
│   │   │       └── logout.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   ├── auth_state.dart
│   │       │   └── auth_bloc_test.dart
│   │       ├── pages/
│   │       │   ├── login_page.dart
│   │       │   └── register_page.dart
│   │       └── widgets/
│   │           └── ...
│   │
│   ├── church/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── feed/
│   ├── groups/
│   ├── events/
│   └── profile/
│
└── shared/                     # Shared across features
    ├── widgets/                # Reusable widgets
    │   ├── buttons/
    │   ├── inputs/
    │   ├── cards/
    │   └── ...
    ├── extensions/             # Dart extensions
    │   ├── context_extensions.dart
    │   └── string_extensions.dart
    └── utils/                  # Utilities
        ├── validators.dart
        └── formatters.dart

test/
├── core/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── ...
├── fixtures/                   # Test data
│   └── fixture_reader.dart
├── helpers/                    # Test utilities
│   ├── test_injection.dart
│   └── mock_factories.dart
└── widget_test.dart
```

---

## Clean Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                      PRESENTATION                           │
│                                                             │
│    Pages ←→ Bloc/Cubit ←→ UseCases                         │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                        DOMAIN                               │
│                                                             │
│    Entities    Repositories (abstract)    UseCases          │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                         DATA                                │
│                                                             │
│    Models    Repositories (impl)    DataSources            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

Dependencies point inward. Domain knows nothing about data or presentation.

---

## Bloc Pattern

### Events, States, Bloc

```dart
// features/auth/presentation/bloc/auth_event.dart

sealed class AuthEvent {}

final class AuthCheckRequested extends AuthEvent {}

final class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  
  AuthLoginRequested({required this.email, required this.password});
}

final class AuthLogoutRequested extends AuthEvent {}
```

```dart
// features/auth/presentation/bloc/auth_state.dart

sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthAuthenticated extends AuthState {
  final User user;
  
  AuthAuthenticated(this.user);
}

final class AuthUnauthenticated extends AuthState {}

final class AuthFailure extends AuthState {
  final String message;
  
  AuthFailure(this.message);
}
```

```dart
// features/auth/presentation/bloc/auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  
  AuthBloc({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }
  
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _getCurrentUserUseCase();
    
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) => emit(AuthAuthenticated(user)),
    );
  }
  
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    final result = await _loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );
    
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }
  
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUseCase();
    emit(AuthUnauthenticated());
  }
}
```

### Using Bloc in UI

```dart
// features/auth/presentation/pages/login_page.dart

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state case AuthAuthenticated()) {
          context.go('/dashboard');
        } else if (state case AuthFailure(:final message)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        
        return Scaffold(
          body: LoginForm(
            isLoading: isLoading,
            onSubmit: (email, password) {
              context.read<AuthBloc>().add(
                AuthLoginRequested(email: email, password: password),
              );
            },
          ),
        );
      },
    );
  }
}
```

---

## Test-Driven Development

**Every feature starts with a test.** This is how we work.

### The TDD Cycle

```
1. RED    → Write a failing test
2. GREEN  → Write minimum code to pass
3. REFACTOR → Improve while staying green
4. EDGE CASES → Add tests for boundaries, errors, edge cases
```

### Test File Naming

Tests mirror the lib structure in the test directory:

```
lib/features/auth/presentation/bloc/auth_bloc.dart
test/features/auth/presentation/bloc/auth_bloc_test.dart

lib/features/auth/domain/usecases/login.dart
test/features/auth/domain/usecases/login_test.dart
```

### Bloc Test Example

```dart
// test/features/auth/presentation/bloc/auth_bloc_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

void main() {
  late AuthBloc authBloc;
  late MockLoginUseCase mockLoginUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  
  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    
    authBloc = AuthBloc(
      loginUseCase: mockLoginUseCase,
      logoutUseCase: mockLogoutUseCase,
      getCurrentUserUseCase: mockGetCurrentUserUseCase,
    );
  });
  
  tearDown(() {
    authBloc.close();
  });
  
  group('AuthLoginRequested', () {
    const email = 'test@example.com';
    const password = 'password123';
    final user = User(id: 'usr_123', email: email, displayName: 'Test');
    
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when login succeeds',
      build: () {
        when(() => mockLoginUseCase(any()))
            .thenAnswer((_) async => Right(user));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        AuthLoginRequested(email: email, password: password),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having((s) => s.user, 'user', user),
      ],
      verify: (_) {
        verify(() => mockLoginUseCase(
          LoginParams(email: email, password: password),
        )).called(1);
      },
    );
    
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when login fails',
      build: () {
        when(() => mockLoginUseCase(any()))
            .thenAnswer((_) async => Left(AuthFailure('Invalid credentials')));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        AuthLoginRequested(email: email, password: password),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>().having((s) => s.message, 'message', 'Invalid credentials'),
      ],
    );
    
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when network error occurs',
      build: () {
        when(() => mockLoginUseCase(any()))
            .thenAnswer((_) async => Left(NetworkFailure('No connection')));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        AuthLoginRequested(email: email, password: password),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>().having((s) => s.message, 'message', 'No connection'),
      ],
    );
  });
  
  group('AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] when logout succeeds',
      build: () {
        when(() => mockLogoutUseCase()).thenAnswer((_) async => {});
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthLogoutRequested()),
      expect: () => [isA<AuthUnauthenticated>()],
      verify: (_) {
        verify(() => mockLogoutUseCase()).called(1);
      },
    );
  });
}
```

### UseCase Test Example

```dart
// test/features/auth/domain/usecases/login_test.dart

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;
  
  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });
  
  group('LoginUseCase', () {
    const email = 'test@example.com';
    const password = 'password123';
    const params = LoginParams(email: email, password: password);
    final user = User(id: 'usr_123', email: email, displayName: 'Test');
    
    test('should return User when login is successful', () async {
      // Arrange
      when(() => mockRepository.login(email: email, password: password))
          .thenAnswer((_) async => Right(user));
      
      // Act
      final result = await useCase(params);
      
      // Assert
      expect(result, Right(user));
      verify(() => mockRepository.login(email: email, password: password)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
    
    test('should return AuthFailure when credentials are invalid', () async {
      // Arrange
      when(() => mockRepository.login(email: email, password: password))
          .thenAnswer((_) async => Left(AuthFailure('Invalid credentials')));
      
      // Act
      final result = await useCase(params);
      
      // Assert
      expect(result, isA<Left>());
      result.fold(
        (failure) => expect(failure.message, 'Invalid credentials'),
        (_) => fail('Expected failure'),
      );
    });
    
    test('should return NetworkFailure when no connection', () async {
      // Arrange
      when(() => mockRepository.login(email: any, password: any))
          .thenAnswer((_) async => Left(NetworkFailure('No connection')));
      
      // Act
      final result = await useCase(params);
      
      // Assert
      expect(result, isA<Left>());
    });
  });
}
```

### Edge Cases to Always Consider

```dart
// ✅ Always test these scenarios:

group('Edge Cases', () {
  // Input validation
  test('handles empty email');
  test('handles empty password');
  test('handles whitespace-only input');
  test('handles very long input');
  test('handles special characters');
  test('handles unicode');
  test('handles null values where applicable');
  
  // Network conditions
  test('handles timeout');
  test('handles no connection');
  test('handles server error (5xx)');
  test('handles client error (4xx)');
  test('handles malformed response');
  
  // State transitions
  test('handles rapid successive events');
  test('handles event during loading');
  test('handles duplicate events');
  
  // Auth specific
  test('handles expired token');
  test('handles revoked token');
  test('handles concurrent sessions');
  
  // Data integrity
  test('handles missing required fields');
  test('handles extra unexpected fields');
  test('handles type mismatches');
});
```

### Repository Test Example

```dart
// test/features/auth/data/repositories/auth_repository_impl_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  
  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
    );
  });
  
  group('login', () {
    const email = 'test@example.com';
    const password = 'password123';
    final userModel = UserModel(
      id: 'usr_123',
      email: email,
      displayName: 'Test',
    );
    const token = 'jwt_token_here';
    
    test('should cache token and return user when login succeeds', () async {
      // Arrange
      when(() => mockRemoteDataSource.login(email: email, password: password))
          .thenAnswer((_) async => (user: userModel, token: token));
      when(() => mockLocalDataSource.cacheToken(token))
          .thenAnswer((_) async => {});
      when(() => mockLocalDataSource.cacheUser(userModel))
          .thenAnswer((_) async => {});
      
      // Act
      final result = await repository.login(email: email, password: password);
      
      // Assert
      expect(result, isA<Right>());
      verify(() => mockLocalDataSource.cacheToken(token)).called(1);
      verify(() => mockLocalDataSource.cacheUser(userModel)).called(1);
    });
    
    test('should return failure and not cache when login fails', () async {
      // Arrange
      when(() => mockRemoteDataSource.login(email: email, password: password))
          .thenThrow(UnauthorizedException('Invalid credentials'));
      
      // Act
      final result = await repository.login(email: email, password: password);
      
      // Assert
      expect(result, isA<Left>());
      verifyNever(() => mockLocalDataSource.cacheToken(any()));
      verifyNever(() => mockLocalDataSource.cacheUser(any()));
    });
  });
}
```

### Widget Test Example

```dart
// test/features/auth/presentation/pages/login_page_test.dart

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  
  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });
  
  Widget buildTestWidget() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const LoginPage(),
      ),
    );
  }
  
  group('LoginPage', () {
    testWidgets('displays login form', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthUnauthenticated());
      
      await tester.pumpWidget(buildTestWidget());
      
      expect(find.byType(TextFormField), findsNWidgets(2)); // email + password
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
    
    testWidgets('shows loading indicator when AuthLoading', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthLoading());
      
      await tester.pumpWidget(buildTestWidget());
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('dispatches AuthLoginRequested on form submit', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthUnauthenticated());
      
      await tester.pumpWidget(buildTestWidget());
      
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );
      await tester.tap(find.byType(ElevatedButton));
      
      verify(() => mockAuthBloc.add(
        AuthLoginRequested(email: 'test@example.com', password: 'password123'),
      )).called(1);
    });
    
    testWidgets('shows error snackbar on AuthFailure', (tester) async {
      whenListen(
        mockAuthBloc,
        Stream.fromIterable([
          AuthUnauthenticated(),
          AuthFailure('Invalid credentials'),
        ]),
        initialState: AuthUnauthenticated(),
      );
      
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(); // Process stream
      
      expect(find.text('Invalid credentials'), findsOneWidget);
    });
    
    testWidgets('disables submit button when fields are empty', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthUnauthenticated());
      
      await tester.pumpWidget(buildTestWidget());
      
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
    
    testWidgets('enables submit button when fields are filled', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthUnauthenticated());
      
      await tester.pumpWidget(buildTestWidget());
      
      await tester.enterText(find.byKey(const Key('email_field')), 'a@b.c');
      await tester.enterText(find.byKey(const Key('password_field')), '123');
      await tester.pump();
      
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });
  });
}
```

---

## Commands

```bash
# Development
flutter run                         # Run on connected device
flutter run -d chrome               # Run on web (for debugging)
flutter run --release               # Run release build

# Testing
flutter test                        # Run all tests
flutter test --coverage             # Run with coverage
flutter test test/features/auth/    # Run specific directory

# Code generation
dart run build_runner build         # One-time generation
dart run build_runner watch         # Watch mode

# Quality
flutter analyze                     # Static analysis
dart format .                       # Format code

# Build
flutter build apk                   # Android APK
flutter build appbundle             # Android App Bundle
flutter build ios                   # iOS
flutter build ipa                   # iOS for distribution
```

---

## Dependencies

```yaml
# pubspec.yaml

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.0
  bloc: ^8.1.0
  
  # Dependency Injection
  get_it: ^7.6.0
  injectable: ^2.3.0
  
  # Network
  dio: ^5.4.0
  retrofit: ^4.0.0
  
  # Functional Programming
  dartz: ^0.10.1
  
  # Local Storage
  drift: ^2.14.0
  sqlite3_flutter_libs: ^0.5.0
  shared_preferences: ^2.2.0
  flutter_secure_storage: ^9.0.0
  
  # Navigation
  go_router: ^13.0.0
  
  # UI
  flutter_screenutil: ^5.9.0
  cached_network_image: ^3.3.0
  
  # Utils
  equatable: ^2.0.5
  intl: ^0.19.0
  logger: ^2.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Testing
  bloc_test: ^9.1.0
  mocktail: ^1.0.0
  
  # Code Generation
  build_runner: ^2.4.0
  injectable_generator: ^2.4.0
  retrofit_generator: ^8.0.0
  drift_dev: ^2.14.0
  
  # Linting
  flutter_lints: ^3.0.0
  very_good_analysis: ^5.1.0
```

---

## Key Reminders

1. **Modern Dart only** — Use records, patterns, sealed classes
2. **Bloc for state** — Events in, states out, predictable
3. **Clean Architecture** — Dependencies point inward
4. **TDD always** — Write failing test first
5. **Test edge cases** — Network errors, invalid input, state transitions
6. **Exhaustive switches** — Sealed classes make this safe
7. **Immutable state** — Never mutate, always emit new state
