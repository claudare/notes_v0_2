import 'dart:convert';

import 'package:notes_v0_2/db.dart';
import 'package:notes_v0_2/events.dart';
import 'package:notes_v0_2/id.dart';
import 'package:notes_v0_2/stream.dart';
import 'package:notes_v0_2/system_db.dart';
import 'package:notes_v0_2/system_models.dart';
import 'package:test/test.dart';

void main() {
  group('EventLogGetAllForStream', () {
    late Database databaseSystem;
    late SystemDb systemDb;
    late Stream stream;

    setUp(() async {
      databaseSystem = Database.temporary();

      final deviceId = DeviceId(123);
      systemDb = SystemDb(databaseSystem.db, deviceId: deviceId);
      await systemDb.init();

      // Create a test stream
      stream = Stream.named('test_stream');

      // Append some test events
      for (int i = 0; i < 5; i++) {
        final event = TestEvent(value: 'event_$i');
        final eventLogMinimal = EventLogMinimal(stream: stream, event: event);
        await systemDb.eventLogAppend(eventLogMinimal);
      }
    });

    tearDown(() async {
      await databaseSystem.deinit();
    });

    test('should return all events for a given stream', () async {
      final eventLogs = await systemDb.eventLogGetAllForStream(stream);

      expect(eventLogs.length, 5);
      for (int i = 0; i < 5; i++) {
        final eventLog = eventLogs[i];

        final event = eventLog.event as TestEvent;

        expect(event.value, 'event_$i');
      }
    });
  });
}
