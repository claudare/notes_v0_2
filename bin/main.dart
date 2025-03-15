import 'package:notes_v0_2/notes/repo.dart';
import 'package:notes_v0_2/notes/resolver.dart';
import 'package:notes_v0_2/notes/storage.dart';
import 'package:notes_v0_2/common/db.dart';
import 'package:notes_v0_2/common/stream.dart';
import 'package:notes_v0_2/system/repo.dart';
import 'package:notes_v0_2/notes/events.dart';
import 'package:notes_v0_2/common/id.dart';
import 'package:notes_v0_2/system/models.dart';
import '../lib/test_utils.dart';

// run with dart --enable-asserts bin/main.dart
void main() async {
  final aio = TestAllSystemsInOne(deviceId: DeviceId(42));

  await aio.init();
  try {
    final noteId = aio.sysRepo.newId("note");

    final globalStreamId = Stream.named("global");
    final noteStreamId = Stream.id(noteId);

    // sysRepo.eventLogAppend(EventLogMinimal(stream:globalStreamId, event:))

    await testApplyEventLog(
      aio,
      EventLogMinimal(globalStreamId, NoteNewStreamCreated(streamId: noteId)),
      flush: false,
    );
    await testApplyEventLog(
      aio,
      EventLogMinimal(noteStreamId, NoteBodyEditedFull(value: "hello world")),
      flush: false,
    );

    await aio.notesRepo.flush();

    var note = await aio.notesStorage.noteGet(noteId);

    print("latest note state $note");

    await aio.notesStorage.dumpPrint();
  } finally {
    await aio.sysDb.deinit();
    await aio.notesDb.deinit();
  }
}
