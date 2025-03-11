import 'package:notes_v0_2/app_db.dart';
import 'package:notes_v0_2/stream_id.dart';
import 'package:notes_v0_2/system_db.dart';
import 'package:notes_v0_2/events.dart';
import 'package:notes_v0_2/id.dart';
import 'package:notes_v0_2/system_models.dart';

void main() async {
  final systemDb = DbSystem(deviceUid: DeviceId(0)); // device id 0 is 111
  await systemDb.init();

  final appDb = AppDb(systemDb.db);

  Future<void> appendLogAndApply(EventLogMinimal min) async {
    print('doing event log min ${min.streamId}');
    await systemDb.eventLogAppend(min);
    await min.event.apply(min.streamId, appDb);
  }

  try {
    await appDb.migrate();

    final noteId = systemDb.newId();

    final globalStreamId = StreamIdGlobal();
    final noteStreamId = StreamIdNote(noteId);

    await appendLogAndApply(
      EventLogMinimal(
        streamId: globalStreamId,
        event: NewNoteStreamCreated(streamId: noteStreamId),
      ),
    );
    await appendLogAndApply(
      EventLogMinimal(
        streamId: noteStreamId,
        event: NoteBodyEdited(value: "hello world"),
      ),
    );
    // await systemDb.eventLogAppend(
    //   EventLogMinimal(
    //     streamId: noteStreamId,
    //     event: NoteBodyEdited(value: "byebye"),
    //   ),
    // );
    //
    final note = await appDb.noteGet(noteId);

    print("latest note state $note");
  } finally {
    await systemDb.deinit();
  }
}
