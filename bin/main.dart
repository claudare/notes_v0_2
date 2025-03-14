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

    await testSaveEventLogAndResolve(
      aio.sysRepo,
      aio.notesResolver,
      EventLogMinimal(
        stream: globalStreamId,
        event: NoteNewStreamCreated(streamId: noteId),
      ),
    );
    await aio.notesRepo.flush();
    await testSaveEventLogAndResolve(
      aio.sysRepo,
      aio.notesResolver,
      EventLogMinimal(
        stream: noteStreamId,
        event: NoteBodyEditedFull(value: "hello world"),
      ),
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
