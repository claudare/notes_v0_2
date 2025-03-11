import 'package:notes_v0_2/app_db.dart';
import 'package:notes_v0_2/stream_id.dart';
import 'package:notes_v0_2/system_db.dart';
import 'package:notes_v0_2/events.dart';
import 'package:notes_v0_2/id.dart';
import 'package:notes_v0_2/system_models.dart';

void main() async {
  final dbSystem = DbSystem(deviceUid: DeviceId(0)); // device id 0 is 111
  await dbSystem.init();

  final dbApp = AppDb(dbSystem.db);

  try {
    final noteId = dbSystem.newId();

    final noteStreamId = StreamIdNote(noteId);
    final globalStramId = StreamIdGlobal();

    await dbSystem.eventLogAppend(
      EventLogMinimal(
        streamId: globalStramId,
        event: NewNoteStreamCreated(streamIdNote: noteStreamId),
      ),
    );

    await dbSystem.eventLogAppend(
      EventLogMinimal(
        streamId: noteStreamId,
        event: NoteBodyEdited(value: "hello world"),
      ),
    );

    await dbSystem.eventLogAppend(
      EventLogMinimal(
        streamId: noteStreamId,
        event: NoteBodyEdited(value: "byebye"),
      ),
    );
  } finally {
    await dbSystem.deinit();
  }
}
