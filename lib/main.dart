import 'package:notes_v0_2/app_db.dart';
import 'package:notes_v0_2/stream_id.dart';
import 'package:notes_v0_2/system_db.dart';
import 'package:notes_v0_2/events.dart';
import 'package:notes_v0_2/id.dart';

void main() async {
  final dbSystem = DbSystem(deviceUid: DeviceId(0)); // device id 0 is 111
  await dbSystem.init();

  final dbApp = AppDb(dbSystem.db);

  try {
    final noteId = dbSystem.newId();

    await dbSystem.eventLogAppend(
      streamId: StreamId.fromString("global"),
      event: NewNoteStreamCreated(streamId: StreamId("note", noteId)),
    );
    await dbSystem.eventLogAppend(
      streamId: StreamId("note", noteId),
      event: NoteBodyEdited(value: "hello world"),
    );
    await dbSystem.eventLogAppend(
      streamId: StreamId("note", noteId),
      event: NoteBodyEdited(value: "byebye"),
    );

    await Future<void>.delayed(Duration(milliseconds: 1000));
  } finally {
    await dbSystem.deinit();
  }
}
