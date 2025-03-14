import 'package:notes_v0_2/notes/repo.dart';
import 'package:notes_v0_2/common/db.dart';
import 'package:notes_v0_2/common/stream.dart';
import 'package:notes_v0_2/system/repo.dart';
import 'package:notes_v0_2/notes/events.dart';
import 'package:notes_v0_2/common/id.dart';
import 'package:notes_v0_2/system/models.dart';
import 'package:notes_v0_2/system/utils.dart';

// run with dart --enable-asserts bin/main.dart
void main() async {
  final sysDb = Db.temporary();
  final notesDb = Db.temporary();

  final sysRepo = SystemRepo(sysDb.underlyingDb, deviceId: DeviceId(0));
  final notesRepo = NotesRepo(notesDb.underlyingDb, loggingEnabled: true);

  try {
    await sysRepo.init();
    await notesRepo.migrate();

    final noteId = sysRepo.newId("note");

    final globalStreamId = Stream.named("global");
    final noteStreamId = Stream.id(noteId);

    await appendEventLogMinimalAndApply(
      sysRepo,
      notesRepo,
      EventLogMinimal(
        stream: globalStreamId,
        event: NoteNewStreamCreated(streamId: noteId),
      ),
    );
    await appendEventLogMinimalAndApply(
      sysRepo,
      notesRepo,
      EventLogMinimal(
        stream: noteStreamId,
        event: NoteBodyEditedFull(value: "hello world"),
      ),
    );

    var note = await notesRepo.noteGet(noteId);

    print("latest note state $note");

    // final badNoteId = sysRepo.newId("note");
    final result = await notesRepo.noteDelete(noteId);

    print("delete result $result");
    note = await notesRepo.noteGet(noteId);

    print("AFTER DELETE $note");
  } finally {
    await sysDb.deinit();
    await notesDb.deinit();
  }
}
