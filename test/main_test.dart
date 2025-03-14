import 'package:notes_v0_2/notes/repo.dart';
import 'package:notes_v0_2/notes/resolver.dart';
import 'package:notes_v0_2/notes/storage.dart';
import 'package:notes_v0_2/common/db.dart';
import 'package:notes_v0_2/common/stream.dart';
import 'package:notes_v0_2/system/repo.dart';
import 'package:notes_v0_2/notes/events.dart';
import 'package:notes_v0_2/common/id.dart';
import 'package:notes_v0_2/system/models.dart';
import 'package:notes_v0_2/test_utils.dart';
import 'package:test/test.dart';
import 'package:logging/logging.dart';

// Logger.root.level = Level.ALL; // defaults to Level.INFO
// Logger.root.onRecord.listen((record) {
//   print('${record.level.name}: ${record.time}: ${record.message}');
// });

void main() async {
  Logger.root.level = Level.SEVERE;
  Logger.root.onRecord.listen((record) {
    print(
      '[${record.loggerName}] ${record.level.name}: ${record.time}: ${record.message}',
    );
  });
  group('Event Tests', () {
    late TestAllSystemsInOne aio; // s stands for aio Systems

    setUp(() async {
      aio = TestAllSystemsInOne();
      await aio.init();
    });

    tearDown(() async {
      await aio.deinit();
    });

    test('Create a new note stream', () async {
      final noteId = aio.sysRepo.newId('note');

      final globalStreamId = Stream.named("global");
      final noteStreamId = Stream.id(noteId);

      await testSaveEventLogAndResolve(
        aio.sysRepo,
        aio.notesResolver,
        EventLogMinimal(
          stream: globalStreamId,
          event: NoteNewStreamCreated(streamId: noteId),
        ),
      );
      await aio.notesRepo.flush();

      // Verify that the note has been created
      final note = await aio.notesStorage.noteGet(noteId);
      expect(note, isNotNull);
    });

    test('Edit the body of a note', () async {
      final noteId = aio.sysRepo.newId('note');

      final globalStreamId = Stream.named("global");
      final noteStreamId = Stream.id(noteId);

      // First create the note stream
      await testSaveEventLogAndResolve(
        aio.sysRepo,
        aio.notesResolver,
        EventLogMinimal(
          stream: globalStreamId,
          event: NoteNewStreamCreated(streamId: noteId),
        ),
      );

      // Edit the note body
      await testSaveEventLogAndResolve(
        aio.sysRepo,
        aio.notesResolver,
        EventLogMinimal(
          stream: noteStreamId,
          event: NoteBodyEditedFull(value: "hello world"),
        ),
      );
      await aio.notesRepo.flush();

      // Verify that the note body has been updated
      final note = await aio.notesRepo.noteGet(noteId);

      expect(note, isNotNull);
      expect(note.body, equals("hello world"));
      // TODO: fix the potentiaioy flaky time tests
      expect(note.editedAt.compareTo(note.createdAt), equals(1));
    });

    test('Assign a tag to a note', () async {
      final noteId = aio.sysRepo.newId('note');

      final globalStreamId = Stream.named("global");
      final noteStreamId = Stream.id(noteId);

      // First create the note stream
      await testSaveEventLogAndResolve(
        aio.sysRepo,
        aio.notesResolver,
        EventLogMinimal(
          stream: globalStreamId,
          event: NoteNewStreamCreated(streamId: noteId),
        ),
      );
      await aio.notesRepo.flush();

      // Assign a tag to the note
      const tagName = 'testTag';
      await testSaveEventLogAndResolve(
        aio.sysRepo,
        aio.notesResolver,
        EventLogMinimal(
          stream: noteStreamId,
          event: TagAssignedToNote(tagName: tagName),
        ),
      );
      await aio.notesRepo.flush();

      // Verify that the tag has been assigned to the note
      final note = await aio.notesStorage.noteGet(noteId);
      expect(note, isNotNull);
      expect(note!.tags.length, equals(1));
      expect(note.tags.contains(tagName), isTrue);

      // Verify that the tag exists in the general list
      final tags = await aio.notesStorage.tagGet(tagName);
      expect(tags, isNotNull);
      expect(tags!.count, equals(1));
      expect(tags.assignedToNotes.contains(noteId), isTrue);
    });

    test('Unassign a tag from a note', () async {
      final noteId = aio.sysRepo.newId('note');

      final globalStreamId = Stream.named("global");
      final noteStreamId = Stream.id(noteId);

      // First create the note stream
      await testSaveEventLogAndResolve(
        aio.sysRepo,
        aio.notesResolver,
        EventLogMinimal(
          stream: globalStreamId,
          event: NoteNewStreamCreated(streamId: noteId),
        ),
      );

      // Assign a tag to the note
      const tagName = 'testTag';
      await testSaveEventLogAndResolve(
        aio.sysRepo,
        aio.notesResolver,
        EventLogMinimal(
          stream: noteStreamId,
          event: TagAssignedToNote(tagName: tagName),
        ),
      );
      await aio.notesRepo.flush();

      // Unassign the tag from the note
      await testSaveEventLogAndResolve(
        aio.sysRepo,
        aio.notesResolver,
        EventLogMinimal(
          stream: noteStreamId,
          event: TagUnassignedToNote(tagName: tagName),
        ),
      );
      await aio.notesRepo.flush();

      // Verify that the tag has been unassigned from the note
      final note = await aio.notesStorage.noteGet(noteId);
      expect(note, isNotNull);
      expect(note!.tags.isEmpty, isTrue);

      // Verify that the tag no longer exists in the general list
      final tags = await aio.notesStorage.tagGet(tagName);
      expect(tags, isNull);
    });
  });
}
