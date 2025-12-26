# Plugin Architecture Refactor

> Elevating code quality from 7.5/10 to 10/10

## Problems

1. **`internalXxx` accessor pattern** - Plugins reach into client implementation details
2. **Duplicated error mapping** - `_mapError`/`_mapStatusToError` copied across 3+ files
3. **Verbose test setup** - 30+ lines of boilerplate repeated in every test file

## Solutions

### 1. PluginContext

Replace `internalXxx` accessors with a formal abstraction:

```dart
@immutable
final class PluginContext {
  const PluginContext({
    required this.dio,
    required this.storage,
    required this.emitState,
    required this.currentState,
  });

  final Dio dio;
  final AuthStorage storage;
  final void Function(AuthState state) emitState;
  final AuthState Function() currentState;
}
```

**Client provides it:**
```dart
PluginContext get pluginContext => PluginContext(
  dio: _dio,
  storage: _storage,
  emitState: _stateController.add,
  currentState: () => _stateController.value,
);
```

**Plugins receive it:**
```dart
final class SSO {
  SSO(this._ctx);
  final PluginContext _ctx;
}
```

### 2. ErrorMapper

Centralized error mapping with plugin extension points:

```dart
abstract final class ErrorMapper {
  static AuthError map(Object error, StackTrace stackTrace) {
    if (error is AuthError) return error;
    if (error is DioException) {
      if (error.response != null) return mapResponse(error.response!);
      if (_isConnectionError(error)) return const NetworkError();
    }
    return UnknownError(message: error.toString());
  }

  static AuthError mapResponse(
    Response<dynamic> response, {
    AuthError Function(String code, String? message)? onCode,
  }) {
    // Extract code/message from response
    // Let plugin handle specific codes via onCode callback
    // Fall back to standard status code mappings
  }
}
```

**Plugins extend for specific errors:**
```dart
ErrorMapper.mapResponse(response, onCode: (code, msg) => switch (code) {
  'SSO_PROVIDER_NOT_FOUND' => const SSOProviderNotFound(),
  _ => UnknownError(message: msg ?? 'Unknown', code: code),
});
```

### 3. AuthTestHarness

Test utility that eliminates boilerplate:

```dart
final class AuthTestHarness {
  AuthTestHarness() {
    dio = Dio(BaseOptions(baseUrl: baseUrl));
    dioAdapter = DioAdapter(dio: dio);
    storage = MemoryStorageImpl();
    client = BetterAuthClientImpl(baseUrl: baseUrl, storage: storage, dio: dio);
    client.authStateChanges.listen(emittedStates.add);
  }

  static const baseUrl = 'https://api.example.com';
  late final Dio dio;
  late final DioAdapter dioAdapter;
  late final MemoryStorageImpl storage;
  late final BetterAuthClientImpl client;
  final emittedStates = <AuthState>[];

  void reset() { ... }
}

abstract final class AuthFixtures {
  static Map<String, dynamic> user({...}) => {...};
  static Map<String, dynamic> session({...}) => {...};
  static Map<String, dynamic> authSuccess({...}) => {...};
}
```

**Before:** 30+ lines per test file
**After:** 3 lines

## Files to Change

| File | Change |
|------|--------|
| `lib/src/client/plugin_context.dart` | NEW - PluginContext class |
| `lib/src/client/error_mapper.dart` | NEW - ErrorMapper utility |
| `lib/src/client/better_auth_client_impl.dart` | Add `pluginContext` getter, remove error mapping duplication |
| `lib/src/passkey/passkey.dart` | Use PluginContext + ErrorMapper |
| `lib/src/sso/sso.dart` | Use PluginContext + ErrorMapper |
| `lib/src/magic_link/magic_link.dart` | Use PluginContext + ErrorMapper (if applicable) |
| `lib/src/anonymous/anonymous.dart` | Use PluginContext + ErrorMapper (if applicable) |
| `lib/src/two_factor/two_factor.dart` | Use PluginContext + ErrorMapper (if applicable) |
| `test/helpers/auth_test_harness.dart` | NEW - Test harness |
| `test/helpers/auth_fixtures.dart` | NEW - Shared fixtures |
| All test files | Migrate to use harness |

## Not Changing

- **Handler injection pattern** - Keep per-method injection (explicit > hidden state)
- **Extension + Expando pattern** - Already elegant
- **Sealed error hierarchy** - Already excellent

## Success Criteria

- [ ] No `internalXxx` usage in any plugin
- [ ] Zero duplicated error mapping code
- [ ] All test files use AuthTestHarness
- [ ] All existing tests still pass
- [ ] flutter analyze clean
