import 'package:better_auth_flutter/better_auth_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PluginContext', () {
    test('holds dio, storage, and state functions', () {
      final dio = Dio();
      final storage = MemoryStorageImpl();
      var emittedState = const AuthInitial() as AuthState;
      var currentState = const AuthInitial() as AuthState;

      final ctx = PluginContext(
        dio: dio,
        storage: storage,
        emitState: (state) => emittedState = state,
        currentState: () => currentState,
      );

      expect(ctx.dio, same(dio));
      expect(ctx.storage, same(storage));

      ctx.emitState(const AuthLoading());
      expect(emittedState, isA<AuthLoading>());

      currentState = const Unauthenticated();
      expect(ctx.currentState(), isA<Unauthenticated>());
    });

    test('is provided by BetterAuthClientImpl', () {
      final client = BetterAuthClientImpl(
        baseUrl: 'https://api.example.com',
        storage: MemoryStorageImpl(),
      );

      final ctx = client.pluginContext;

      expect(ctx.dio, isNotNull);
      expect(ctx.storage, isNotNull);
      expect(ctx.currentState(), isA<AuthInitial>());

      ctx.emitState(const AuthLoading());
      expect(client.currentState, isA<AuthLoading>());
    });
  });
}
