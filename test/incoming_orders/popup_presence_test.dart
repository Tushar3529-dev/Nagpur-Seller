import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/service/popup_presence_service.dart';

import 'helpers.dart';

/// Presence for the main seller owner needs no location: `{active: true}`
/// straight away and on every heartbeat. Location is denied and off here,
/// as for an owner who never granted it.
void main() {
  final service = PopupPresenceService();
  late List<Map<String, dynamic>> sent;
  late int probes;
  late List<String> geolocatorCalls;
  const geolocator = MethodChannel('flutter.baseflow.com/geolocator');

  setUpAll(() => initTestHive());

  setUp(() {
    sent = [];
    probes = 0;
    geolocatorCalls = [];
    service.postPresence = (body) async => sent.add(body);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geolocator, (call) async {
          geolocatorCalls.add(call.method);
          return switch (call.method) {
            'checkPermission' => 0, // LocationPermission.denied
            'isLocationServiceEnabled' => false,
            _ => null,
          };
        });
  });

  tearDown(() async {
    await service.stop(notifyServer: false);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geolocator, null);
  });

  Future<void> signInAs(WidgetTester tester, int id) => tester.runAsync(
    () => HiveStorage.setUserData({...testUser, 'id': id}),
  );

  testWidgets('the owner reports active without coordinates and keeps it '
      'fresh', (tester) async {
    await signInAs(tester, 101);
    service.ownerProbe = () async {
      probes++;
      return true;
    };

    await service.sync(requestPermission: true);
    await tester.pump();

    expect(service.isOwnerMode, isTrue);
    expect(service.status.value, PopupPresenceStatus.active);
    expect(sent, [
      {'active': true},
    ]);
    expect(geolocatorCalls, isNot(contains('requestPermission')));

    await tester.pump(PopupPresenceService.heartbeatInterval);
    await tester.pump(PopupPresenceService.heartbeatInterval);
    expect(sent, List.filled(3, {'active': true}));
    expect(
      PopupPresenceService.heartbeatInterval,
      lessThanOrEqualTo(const Duration(seconds: 60)),
    );

    await service.stop();
    expect(sent.last, {'active': false});
    await tester.pump(PopupPresenceService.heartbeatInterval);
    expect(sent.length, 4, reason: 'no heartbeat after stop');
  });

  testWidgets('a system user is not treated as the owner and needs '
      'location', (tester) async {
    await signInAs(tester, 102);
    service.ownerProbe = () async {
      probes++;
      return false;
    };

    await service.sync();
    await tester.pump(PopupPresenceService.heartbeatInterval);

    expect(service.isOwnerMode, isFalse);
    expect(sent.where((b) => b['active'] == true), isEmpty);
    expect(service.status.value, PopupPresenceStatus.serviceDisabled);

    await service.sync();
    expect(probes, 1, reason: 'the answer is kept for this user');
  });

  testWidgets('an unknown answer (offline) is asked again next time', (
    tester,
  ) async {
    await signInAs(tester, 103);
    service.ownerProbe = () async {
      probes++;
      return null;
    };

    await service.sync();
    await service.sync();

    expect(probes, 2);
    expect(service.isOwnerMode, isFalse);
  });

  testWidgets('a role named seller is the owner without asking the server', (
    tester,
  ) async {
    await tester.runAsync(
      () => HiveStorage.setUserData({
        ...testUser,
        'id': 104,
        'roles': [
          {'name': 'seller'},
        ],
      }),
    );
    service.ownerProbe = () async {
      probes++;
      return false;
    };

    await service.sync();
    await tester.pump();

    expect(probes, 0);
    expect(service.isOwnerMode, isTrue);
    expect(sent, [
      {'active': true},
    ]);
    // Widget tests reject timers still pending when the body ends.
    await service.stop(notifyServer: false);
    await tester.runAsync(() => HiveStorage.setUserData(Map.of(testUser)));
  });
}
