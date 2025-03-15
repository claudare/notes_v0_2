import 'package:notes_v0_2/notes/events.dart';
import 'package:notes_v0_2/notes/model_ordering.dart';
import 'package:notes_v0_2/notes/repo.dart';
import 'package:notes_v0_2/common/stream.dart';
import 'package:notes_v0_2/notes/streams.dart';

class NotesResolver {
  final NotesRepo _repo;

  const NotesResolver(this._repo);

  Future<void> handleEvent(Stream inStream, NotesEvent event) async {
    switch (event) {
      case NoteNewStreamCreated():
        inStream.throwIfNotNamedWithName("global");
        final order = await _repo.orderingGet();
        final noteId = event.streamId;

        _repo.noteNew(noteId);
        order.append(noteId, Category.main);
        break;
      case NoteBodyEditedFull():
        final noteId = inStream.getIdInScopeOrThrow("note");
        final value = event.value;

        final note = await _repo.noteGet(noteId);

        note.body = value;
        note.editedAt = DateTime.now();
        break;
      case NoteReordered():
        inStream.throwIfNotNamedWithName(streamNameNoteOrder);
        final order = await _repo.orderingGet();

        final noteId = event.noteId;
        final beforeNoteId = event.beforeNoteId;

        order.rearrange(noteId, beforeNoteId);
        break;
      case NotePinned():
        final order = await _repo.orderingGet();

        final noteId = event.noteId;
        order.moveToOtherCategory(noteId, Category.pinned);

        break;
      case NoteUnarchived():
        throw UnimplementedError();
        break;
      case TagAssignedToNote():
        final noteId = inStream.getIdInScopeOrThrow("note");
        final tagName = event.tagName;

        final note = await _repo.noteGet(noteId);
        note.tags.add(tagName);

        final tag = await _repo.tagGet(tagName);
        tag.assignedToNotes.add(noteId);

        break;
      case TagUnassignedToNote():
        final noteId = inStream.getIdInScopeOrThrow("note");
        final tagName = event.tagName;

        final note = await _repo.noteGet(noteId);
        note.tags.remove(tagName);

        final tag = await _repo.tagGet(tagName);
        tag.assignedToNotes.remove(noteId);

        break;
      case TestEvent():
        throw Exception('whatcha looking at?');
    }
  }
}
