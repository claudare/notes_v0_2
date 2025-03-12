import 'package:notes_v0_2/app_db.dart';
import 'package:notes_v0_2/stream_id.dart';
import 'package:notes_v0_2/system_db.dart';
import 'package:notes_v0_2/events.dart';
import 'package:notes_v0_2/id.dart';
import 'package:notes_v0_2/system_models.dart';
import 'package:notes_v0_2/utils.dart';

void main() async {
  final systemDb = SystemDb(deviceUid: DeviceId(0)); // device id 0 is 111
  await systemDb.init();

  final appDb = AppDb(systemDb.db, loggingEnabled: true);

  try {
    await appDb.migrate();

    final noteId = systemDb.newId();

    final globalStreamId = StreamIdGlobal();
    final noteStreamId = StreamIdNote(noteId);

    await appendEventLogMinimalAndApply(
      systemDb,
      appDb,
      EventLogMinimal(
        streamId: globalStreamId,
        event: NoteNewStreamCreated(streamId: noteStreamId),
      ),
    );
    await appendEventLogMinimalAndApply(
      systemDb,
      appDb,
      EventLogMinimal(
        streamId: noteStreamId,
        event: NoteBodyEdited(value: "hello world"),
      ),
    );

    final note = await appDb.noteGet(noteId);

    print("latest note state $note");
  } finally {
    await systemDb.deinit();
  }
}
