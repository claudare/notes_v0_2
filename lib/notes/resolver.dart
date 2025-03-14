import 'package:notes_v0_2/notes/events.dart';
import 'package:notes_v0_2/notes/repo.dart';
import 'package:notes_v0_2/common/stream.dart';

class NotesResolver {
  final NotesRepo _repo;

  const NotesResolver(this._repo);

  Future<void> handleEvent(Stream inStream, NotesEvent event) async {
    switch (event) {
      case NoteNewStreamCreated():
        inStream.throwIfNotNamedWithName("global");

        _repo.noteNew(event.streamId);
        break;
      case NoteBodyEditedFull():
        final noteId = inStream.getIdInScopeOrThrow("note");
        final value = event.value;

        final note = await _repo.noteGet(noteId);
        note.body = value;
        note.editedAt = DateTime.now();

        break;
      case NoteArchived():
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
