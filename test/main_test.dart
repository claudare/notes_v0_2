import 'package:notes_v0_2/notes/repo.dart';
import 'package:notes_v0_2/common/db.dart';
import 'package:notes_v0_2/common/stream.dart';
import 'package:notes_v0_2/system/repo.dart';
import 'package:notes_v0_2/notes/events.dart';
import 'package:notes_v0_2/common/id.dart';
import 'package:notes_v0_2/system/models.dart';
import 'package:notes_v0_2/system/utils.dart';
import 'package:test/test.dart';

void main() async {
  group('Event Tests', () {
    late Db databaseSystem;
    late Db databaseApp;
    late SystemRepo systemDb;
    late NotesRepo appDb;

    setUp(() async {
      databaseSystem = Db.temporary();
      databaseApp = Db.temporary();

      systemDb = SystemRepo(
        databaseSystem.db,
        deviceId: DeviceId(0),
      ); // device id 0 is 111
      await systemDb.init();
      appDb = NotesRepo(databaseApp.db);
      await appDb.migrate();
    });

    tearDown(() async {
      await databaseSystem.deinit();
      await databaseApp.deinit();
    });

    test('Create a new note stream', () async {
      final noteId = systemDb.newId('note');

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

      // Verify that the note has been created
      final note = await appDb.noteGet(noteId);
      expect(note, isNotNull);
    });

    test('Edit the body of a note', () async {
      final noteId = systemDb.newId('note');

      final globalStreamId = Stream.named("global");
      final noteStreamId = Stream.id(noteId);

      // First create the note stream
      await appendEventLogMinimalAndApply(
        systemDb,
        appDb,
        EventLogMinimal(
          stream: globalStreamId,
          event: NoteNewStreamCreated(streamId: noteId),
        ),
      );

      // Edit the note body
      await appendEventLogMinimalAndApply(
        systemDb,
        appDb,
        EventLogMinimal(
          stream: noteStreamId,
          event: NoteBodyEditedFull(value: "hello world"),
        ),
      );

      // Verify that the note body has been updated
      final note = await appDb.noteGet(noteId);

      expect(note, isNotNull);
      expect(note!.body, equals("hello world"));
      // TODO: fix the potentially flaky time tests
      expect(note.editedAt.compareTo(note.createdAt), equals(1));
    });

    test('Assign a tag to a note', () async {
      final noteId = systemDb.newId('note');

      final globalStreamId = Stream.named("global");
      final noteStreamId = Stream.id(noteId);

      // First create the note stream
      await appendEventLogMinimalAndApply(
        systemDb,
        appDb,
        EventLogMinimal(
          stream: globalStreamId,
          event: NoteNewStreamCreated(streamId: noteId),
        ),
      );

      // Assign a tag to the note
      const tagName = 'testTag';
      await appendEventLogMinimalAndApply(
        systemDb,
        appDb,
        EventLogMinimal(
          stream: noteStreamId,
          event: TagAssignedToNote(tagName: tagName),
        ),
      );

      // Verify that the tag has been assigned to the note
      final note = await appDb.noteGet(noteId);
      expect(note, isNotNull);
      expect(note!.tags.length, equals(1));
      expect(note.tags.contains(tagName), isTrue);

      // Verify that the tag exists in the general list
      final tags = await appDb.tagsGet();
      expect(tags.toList().length, equals(1));
      expect(tags.toList().contains(tagName), isTrue);
    });

    test('Unassign a tag from a note', () async {
      final noteId = systemDb.newId('note');

      final globalStreamId = Stream.named("global");
      final noteStreamId = Stream.id(noteId);

      // First create the note stream
      await appendEventLogMinimalAndApply(
        systemDb,
        appDb,
        EventLogMinimal(
          stream: globalStreamId,
          event: NoteNewStreamCreated(streamId: noteId),
        ),
      );

      // Assign a tag to the note
      const tagName = 'testTag';
      await appendEventLogMinimalAndApply(
        systemDb,
        appDb,
        EventLogMinimal(
          stream: noteStreamId,
          event: TagAssignedToNote(tagName: tagName),
        ),
      );

      // Unassign the tag from the note
      await appendEventLogMinimalAndApply(
        systemDb,
        appDb,
        EventLogMinimal(
          stream: noteStreamId,
          event: TagUnassignedToNote(tagName: tagName),
        ),
      );

      // Verify that the tag has been unassigned from the note
      final note = await appDb.noteGet(noteId);
      expect(note, isNotNull);
      expect(note!.tags.isEmpty, isTrue);

      // Verify that the tag no longer exists in the general list
      final tags = await appDb.tagsGet();
      expect(tags.toList().length, equals(0));
    });
  });
}
