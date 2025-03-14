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
  final s = TestAllSystemsInOne(deviceId: DeviceId(42));

  await s.init();
  try {
    final noteId = s.sysRepo.newId("note");

    final globalStreamId = Stream.named("global");
    final noteStreamId = Stream.id(noteId);

    // sysRepo.eventLogAppend(EventLogMinimal(stream:globalStreamId, event:))

    await testSaveEventLogAndResolve(
      s.sysRepo,
      s.notesResolver,
      EventLogMinimal(
        stream: globalStreamId,
        event: NoteNewStreamCreated(streamId: noteId),
      ),
    );
    await s.notesRepo.flush();
    await testSaveEventLogAndResolve(
      s.sysRepo,
      s.notesResolver,
      EventLogMinimal(
        stream: noteStreamId,
        event: NoteBodyEditedFull(value: "hello world"),
      ),
    );
    await s.notesRepo.flush();

    var note = await s.notesStorage.noteGet(noteId);

    print("latest note state $note");
  } finally {
    await s.sysDb.deinit();
    await s.notesDb.deinit();
  }
}
