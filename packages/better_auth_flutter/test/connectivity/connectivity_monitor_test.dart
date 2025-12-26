import 'dart:async';

import 'package:better_auth_flutter/src/connectivity/connectivity_monitor.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  group('ConnectivityMonitor', () {
    late MockConnectivity mockConnectivity;
    late StreamController<List<ConnectivityResult>> connectivityController;
    late ConnectivityMonitor monitor;

    setUp(() {
      mockConnectivity = MockConnectivity();
      connectivityController = StreamController<List<ConnectivityResult>>();

      when(() => mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => connectivityController.stream);
    });

    tearDown(() async {
      await connectivityController.close();
      await monitor.dispose();
    });

    test('isOnline returns true when connected via wifi', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);

      monitor = ConnectivityMonitor(connectivity: mockConnectivity);
      await monitor.initialize();

      expect(monitor.isOnline, isTrue);
    });

    test('isOnline returns true when connected via mobile', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.mobile]);

      monitor = ConnectivityMonitor(connectivity: mockConnectivity);
      await monitor.initialize();

      expect(monitor.isOnline, isTrue);
    });

    test('isOnline returns false when no connection', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);

      monitor = ConnectivityMonitor(connectivity: mockConnectivity);
      await monitor.initialize();

      expect(monitor.isOnline, isFalse);
    });

    test('onConnectivityChanged emits when connectivity changes', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);

      monitor = ConnectivityMonitor(connectivity: mockConnectivity);
      await monitor.initialize();

      final events = <bool>[];
      monitor.onConnectivityChanged.listen(events.add);

      // Simulate going online
      connectivityController.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);

      // Simulate going offline
      connectivityController.add([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);

      expect(events, [true, false]);
    });

    test('onOnline emits when transitioning from offline to online', () async {
      when(() => mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);

      monitor = ConnectivityMonitor(connectivity: mockConnectivity);
      await monitor.initialize();

      var onlineCount = 0;
      monitor.onOnline.listen((_) => onlineCount++);

      // Go online
      connectivityController.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);

      // Stay online (different type)
      connectivityController.add([ConnectivityResult.mobile]);
      await Future<void>.delayed(Duration.zero);

      // Should only emit once (transition, not staying online)
      expect(onlineCount, 1);
    });
  });
}
