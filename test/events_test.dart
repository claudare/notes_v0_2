import 'package:notes_v0_2/common/id.dart';
import 'package:notes_v0_2/common/stream.dart';
import 'package:notes_v0_2/notes/events.dart';
import 'package:notes_v0_2/notes/streams.dart';
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
    late TestAllSystemsInOne aio;

    setUp(() async {
      aio = TestAllSystemsInOne();
      await aio.init();
    });

    tearDown(() async {
      await aio.deinit();
    });

    test('Create new note stream', () async {
      final noteId = aio.sysRepo.newId('note');

      final globalStreamId = Stream.named("global");

      await testApplyEventLog(
        aio,
        EventLogMinimal(globalStreamId, NoteNewStreamCreated(streamId: noteId)),
        flush: true,
      );

      // Verify that the note has been created
      final note = await aio.notesStorage.noteGet(noteId);
      expect(note, isNotNull);

      // assert the ordering of the notes
      final order = await aio.notesStorage.noteOrderGet();
      final orderedIds = order.main.map((e) => e.id).toList();

      expect(orderedIds, equals([noteId]));
    });

    test('Edit the body of a note', () async {
      final noteId = aio.sysRepo.newId('note');

      final globalStreamId = Stream.named("global");
      final noteStreamId = Stream.id(noteId);

      // First create the note stream
      await testSaveEventLogAndResolve(
        aio.sysRepo,
        aio.notesResolver,
        EventLogMinimal(globalStreamId, NoteNewStreamCreated(streamId: noteId)),
      );

      // Edit the note body
      await testSaveEventLogAndResolve(
        aio.sysRepo,
        aio.notesResolver,
        EventLogMinimal(noteStreamId, NoteBodyEditedFull(value: "hello world")),
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
        EventLogMinimal(globalStreamId, NoteNewStreamCreated(streamId: noteId)),
      );
      await aio.notesRepo.flush();

      // Assign a tag to the note
      const tagName = 'testTag';
      await testSaveEventLogAndResolve(
        aio.sysRepo,
        aio.notesResolver,
        EventLogMinimal(noteStreamId, TagAssignedToNote(tagName: tagName)),
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
        EventLogMinimal(globalStreamId, NoteNewStreamCreated(streamId: noteId)),
      );

      // Assign a tag to the note
      const tagName = 'testTag';
      await testSaveEventLogAndResolve(
        aio.sysRepo,
        aio.notesResolver,
        EventLogMinimal(noteStreamId, TagAssignedToNote(tagName: tagName)),
      );
      await aio.notesRepo.flush();

      // Unassign the tag from the note
      await testSaveEventLogAndResolve(
        aio.sysRepo,
        aio.notesResolver,
        EventLogMinimal(noteStreamId, TagUnassignedToNote(tagName: tagName)),
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

    test('Reorder a note', () async {
      final noteId1 = TestIdGenerator.newIdNumber(0);
      final noteId2 = TestIdGenerator.newIdNumber(1);

      await testApplyEventLog(
        aio,
        EventLogMinimal(streamGlobal, NoteNewStreamCreated(streamId: noteId1)),
        flush: true,
      );
      await testApplyEventLog(
        aio,
        EventLogMinimal(streamGlobal, NoteNewStreamCreated(streamId: noteId2)),
        flush: true,
      );

      var order = await aio.notesStorage.noteOrderGet();
      var items = order.main.map((e) => e.id).toList();
      expect(items, equals([noteId1, noteId2]));

      await testApplyEventLog(
        aio,
        EventLogMinimal(
          streamNoteOrder,
          NoteReordered(noteId: noteId1, beforeNoteId: noteId2),
        ),
        flush: true,
      );

      order = await aio.notesStorage.noteOrderGet();
      items = order.main.map((e) => e.id).toList();
      expect(items, equals([noteId2, noteId1]));
    });

    test('Archive a note', () async {
      final noteId1 = TestIdGenerator.newIdNumber(0);
      final noteId2 = TestIdGenerator.newIdNumber(1);

      final globalStreamId = Stream.named("global");

      await testApplyEventLog(
        aio,
        EventLogMinimal(
          globalStreamId,
          NoteNewStreamCreated(streamId: noteId1),
        ),
      );
      await testApplyEventLog(
        aio,
        EventLogMinimal(
          globalStreamId,
          NoteNewStreamCreated(streamId: noteId2),
        ),
      );

      // assert all are in main
      var order = await aio.notesStorage.noteOrderGet();
      expect(order.main.length, equals(2));

      await testApplyEventLog(
        aio,
        EventLogMinimal(streamNoteOrder, NotePinned(noteId: noteId1)),
      );

      order = await aio.notesStorage.noteOrderGet();
      expect(order.pinned.length, equals(1));
      expect(order.pinned.single.id, equals(noteId1));
      expect(order.main.length, equals(1));
      expect(order.main.single.id, equals(noteId2));
    });
  });
}
