import 'package:notes_v0_2/app_db.dart';
import 'package:notes_v0_2/db.dart';
import 'package:notes_v0_2/stream.dart';
import 'package:notes_v0_2/system_db.dart';
import 'package:notes_v0_2/events.dart';
import 'package:notes_v0_2/id.dart';
import 'package:notes_v0_2/system_models.dart';
import 'package:notes_v0_2/utils.dart';

// run with dart --enable-asserts bin/main.dart
void main() async {
  final databaseSystem = Database.temporary();
  final systemDb = SystemDb(databaseSystem.db, deviceId: DeviceId(0));
  await systemDb.init();

  final databaseApp = Database.temporary();
  final appDb = AppDb(databaseApp.db, loggingEnabled: true);

  try {
    await appDb.migrate();

    final noteId = systemDb.newId("note");

    final globalStreamId = Stream.named("global");
    final noteStreamId = Stream.id(noteId);

    await appendEventLogMinimalAndApply(
      systemDb,
      appDb,
      EventLogMinimal(
        stream: globalStreamId,
        event: NoteNewStreamCreated(streamId: noteId),
      ),
    );
    await appendEventLogMinimalAndApply(
      systemDb,
      appDb,
      EventLogMinimal(
        stream: noteStreamId,
        event: NoteBodyEditedFull(value: "hello world"),
      ),
    );

    final note = await appDb.noteGet(noteId);

    print("latest note state $note");
  } finally {
    await databaseSystem.deinit();
    await databaseApp.deinit();
  }
}
