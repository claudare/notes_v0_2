// repo must be simplified and resover must act on events?
// for now I am defining each event to change the app state, but I guess resolver is needed instead

import 'package:notes_v0_2/notes/events.dart';
import 'package:notes_v0_2/notes/models.dart';
import 'package:notes_v0_2/notes/repo.dart';
import 'package:notes_v0_2/notes/storage.dart';
import 'package:notes_v0_2/common/stream.dart';

class NotesResolver {
  final NotesRepo repo;

  const NotesResolver(this.repo);

  /// This takes in an event and resoves it to the repo.
  /// I want these changes to NOT be persistable
  /// They should be done on caching level 100%, and only flushed to db from the outside
  Future<void> handleEvent(Stream inStream, NotesEvent event) async {
    switch (event) {
      case NoteNewStreamCreated():
        inStream.throwIfNotNamedWithName("global");

        repo.noteNew(event.streamId);
        break;
      case NoteBodyEditedFull():
        final noteId = inStream.getIdInScopeOrThrow("note");

        final note = await repo.noteGet(noteId);
        note.body = event.value;
        note.editedAt = DateTime.now();

        break;
      case NoteArchived():
        throw UnimplementedError();
        break;
      case TagAssignedToNote():
        throw UnimplementedError();
        break;
      case TagUnassignedToNote():
        throw UnimplementedError();
        break;
      case TestEvent():
        throw UnimplementedError();
        break;
    }
  }
}
