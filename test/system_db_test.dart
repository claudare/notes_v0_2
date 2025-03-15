import 'package:notes_v0_2/common/db.dart';
import 'package:notes_v0_2/notes/events.dart';
import 'package:notes_v0_2/common/id.dart';
import 'package:notes_v0_2/common/stream.dart';
import 'package:notes_v0_2/system/repo.dart';
import 'package:notes_v0_2/system/models.dart';
import 'package:test/test.dart';

void main() {
  group('EventLogGetAllForStream', () {
    late Db databaseSystem;
    late SystemRepo systemDb;
    late Stream stream;

    setUp(() async {
      databaseSystem = Db.temporary();

      final deviceId = DeviceId(123);
      systemDb = SystemRepo(databaseSystem.underlyingDb, deviceId);
      await systemDb.init();

      // Create a test stream
      stream = Stream.named('test_stream');

      // Append some test events
      for (int i = 0; i < 5; i++) {
        final event = TestEvent(value: 'event_$i');
        final eventLogMinimal = EventLogMinimal(stream, event);
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
