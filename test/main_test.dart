import 'package:notes_v0_2/app_db.dart';
import 'package:notes_v0_2/stream_id.dart';
import 'package:notes_v0_2/system_db.dart';
import 'package:notes_v0_2/events.dart';
import 'package:notes_v0_2/id.dart';
import 'package:notes_v0_2/system_models.dart';
import 'package:notes_v0_2/utils.dart';
import 'package:test/test.dart';

void main() async {
  group('Event Tests', () {
    late SystemDb systemDb;
    late AppDb appDb;

    setUp(() async {
      systemDb = SystemDb(deviceUid: DeviceId(0)); // device id 0 is 111
      await systemDb.init();
      appDb = AppDb(systemDb.db);
      await appDb.migrate();
    });

    tearDown(() async {
      await systemDb.deinit();
    });

    test('Create a new note stream', () async {
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

      // Verify that the note has been created
      final note = await appDb.noteGet(noteId);
      expect(note, isNotNull);
    });

    test('Edit the body of a note', () async {
      final noteId = systemDb.newId();

      final globalStreamId = StreamIdGlobal();
      final noteStreamId = StreamIdNote(noteId);

      // First create the note stream
      await appendEventLogMinimalAndApply(
        systemDb,
        appDb,
        EventLogMinimal(
          streamId: globalStreamId,
          event: NoteNewStreamCreated(streamId: noteStreamId),
        ),
      );

      // Edit the note body
      await appendEventLogMinimalAndApply(
        systemDb,
        appDb,
        EventLogMinimal(
          streamId: noteStreamId,
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
      final noteId = systemDb.newId();

      final globalStreamId = StreamIdGlobal();
      final noteStreamId = StreamIdNote(noteId);

      // First create the note stream
      await appendEventLogMinimalAndApply(
        systemDb,
        appDb,
        EventLogMinimal(
          streamId: globalStreamId,
          event: NoteNewStreamCreated(streamId: noteStreamId),
        ),
      );

      // Assign a tag to the note
      const tagName = 'testTag';
      await appendEventLogMinimalAndApply(
        systemDb,
        appDb,
        EventLogMinimal(
          streamId: noteStreamId,
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
      final noteId = systemDb.newId();

      final globalStreamId = StreamIdGlobal();
      final noteStreamId = StreamIdNote(noteId);

      // First create the note stream
      await appendEventLogMinimalAndApply(
        systemDb,
        appDb,
        EventLogMinimal(
          streamId: globalStreamId,
          event: NoteNewStreamCreated(streamId: noteStreamId),
        ),
      );

      // Assign a tag to the note
      const tagName = 'testTag';
      await appendEventLogMinimalAndApply(
        systemDb,
        appDb,
        EventLogMinimal(
          streamId: noteStreamId,
          event: TagAssignedToNote(tagName: tagName),
        ),
      );

      // Unassign the tag from the note
      await appendEventLogMinimalAndApply(
        systemDb,
        appDb,
        EventLogMinimal(
          streamId: noteStreamId,
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
