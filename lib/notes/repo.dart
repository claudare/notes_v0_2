// this is a repository which is kind of like cache. it should actually be universal?
// there should be context and in-memory store of the data
// this will allow to open a new context for event replaying
// also, this will cache the database entries for faster operation

import 'package:notes_v0_2/common/id.dart';
import 'package:notes_v0_2/notes/exceptions.dart';
import 'package:notes_v0_2/notes/models.dart';
import 'package:notes_v0_2/notes/storage.dart';

class NotesRepo {
  final NotesStorage _storage;

  final Map<Id, Note> _noteMap;
  final Set<Id> _modifiedNotes;
  final Set<Id> _deletedNotes;

  final Tags _tags;
  final bool _touchedTagsHmm;

  NotesRepo(this._storage)
    : _noteMap = {},
      _modifiedNotes = {},
      _deletedNotes = {},
      _tags = Tags.empty(),
      _touchedTagsHmm = false;

  Note? noteNew(Id id) {
    final note = Note(id);
    _modifiedNotes.add(id);
    _noteMap[id] = note;
    return note;
  }

  // assume that getting the note is like touching it
  Future<Note> noteGet(Id id) async {
    // this is a cache implementation
    final thisValue = _noteMap[id];
    if (thisValue != null) {
      return thisValue;
    }

    if (_deletedNotes.contains(id)) {
      // this needs a little bit of a different approach
      //
      throw ItemWasAlreadyDeletedException(id.toString());
    }

    // otherwise lets consult the storage
    // i could optimize this as I know which notes are definately not in storage
    final storedNote = await _storage.noteGet(id);

    if (storedNote != null) {
      _modifiedNotes.add(id);
      _noteMap[id] = storedNote;
      return storedNote;
    }
    throw ItemNotFoundException(id.toString());
  }

  void noteDelete(Id id) {
    _deletedNotes.add(id);
    _modifiedNotes.remove(id); // it doesnt matter anymore
    _noteMap.remove(id);
  }

  // this is a transaction boundary
  // [flush] performs its operations in the transaction
  Future<void> flush() async {
    // something like storage.runInTransaction((tx){})
    for (var noteId in _modifiedNotes) {
      // flush them all
      final note = _noteMap[noteId];
      assert(note != null, 'notes stored on the map cant be null');

      await _storage.noteSave(note!);
    }
    for (var noteId in _deletedNotes) {
      await _storage.noteDelete(noteId);
    }

    // do the same for tags

    _modifiedNotes.clear();
    _deletedNotes.clear();
  }
}
