// this is a repository which is kind of like cache. it should actually be universal?
// there should be context and in-memory store of the data
// this will allow to open a new context for event replaying
// also, this will cache the database entries for faster operation

import 'package:notes_v0_2/common/id.dart';
import 'package:notes_v0_2/notes/exceptions.dart';
import 'package:notes_v0_2/notes/models.dart';
import 'package:notes_v0_2/notes/storage.dart';

/// A repo is a cache/runtime modification layer for the underlying data
/// The objects returned from the get functions are modified directly
/// The get functions throw and this is intentional. If eventlog defined some id, then it must be
/// present in the latest projections. If it is not, then it means there is a logical bug.
/// The event resolver should not catch these errors and instead it should let outerscope capture them.
/// The main controller will skip failing event and move on.
/// In the future, when the bug is fixed, hopefully event resolution will work without throws.
/// NOTE: this must be used with a mutex, as concurrent operations break this stateful system.
class NotesRepo {
  final NotesStorage _storage;

  final Map<Id, Note> _noteMap;
  final Set<Id> _modifiedNotes;
  final Set<Id> _deletedNotes;

  final Map<String, Tag> _tagMap;
  final Set<String> _touchedTags;

  NotesRepo(this._storage)
    : _noteMap = {},
      _modifiedNotes = {},
      _deletedNotes = {},
      _tagMap = {},
      _touchedTags = {};

  Note? noteNew(Id id) {
    final note = Note(id);
    _modifiedNotes.add(id);
    _noteMap[id] = note;
    return note;
  }

  Future<Note> noteGet(Id id) async {
    // this is a cache implementation
    final cached = _noteMap[id];
    if (cached != null) {
      _modifiedNotes.add(id);
      return cached;
    }

    // this could also be a programming bug (or it could be a LOGICAL BUG)
    // so assertion here is a bad strategy, instead need to throw
    // but i still assert for easier testing
    assert(
      !_deletedNotes.contains(id),
      'cannot get note $id which was already deleted',
    );
    if (_deletedNotes.contains(id)) {
      throw ItemWasAlreadyDeletedException(id.toString());
    }

    // otherwise lets consult the storage
    // i could optimize this as I know which notes are definately not in storage from previous lookups
    final stored = await _storage.noteGet(id);
    if (stored == null) {
      throw ItemNotFoundException(id.toString());
    }

    _modifiedNotes.add(id);
    _noteMap[id] = stored;
    return stored;
  }

  void noteDelete(Id id) {
    _deletedNotes.add(id);
    _modifiedNotes.remove(id); // it doesnt matter anymore
    _noteMap.remove(id);
  }

  // rags cannot be created as new
  Future<Tag> tagGet(String name) async {
    final cached = _tagMap[name];
    if (cached != null) {
      _touchedTags.add(name);
      return cached;
    }

    final stored = await _storage.tagGet(name);
    final value = stored ?? Tag(name, {});

    _tagMap[name] = value;
    _touchedTags.add(name);
    return value;
  }

  // this is a transaction boundary
  // [flush] performs its operations in the transaction
  Future<void> flush() async {
    // something like storage.runInTransaction((tx){})
    //
    try {
      for (var noteId in _modifiedNotes) {
        final note = _noteMap[noteId];
        assert(note != null, 'notes stored on the map cant be null');

        await _storage.noteSave(note!);
      }
      for (var noteId in _deletedNotes) {
        await _storage.noteDelete(noteId);
      }

      for (var tagName in _touchedTags) {
        final tag = _tagMap[tagName];
        assert(tag != null, 'tags stored on the map cant be null');

        // delete it from the database if its empty
        if (tag!.count == 0) {
          // also need to evict it from cache
          // this is getting a bit like pasta food
          await _storage.tagDelete(tagName);
        } else {
          await _storage.tagSave(tag);
        }
      }
    } catch (error) {
      _undoLocalChanges();
      print('failed to flush to the database');
      rethrow;
    } finally {
      _modifiedNotes.clear();
      _deletedNotes.clear();

      // TODO go though the _tagMap and and delete values which have 0 notes assigned to them
      // or it could be a background task, operating on a mutex
      _touchedTags.clear();
    }
  }

  // deletes all cached data related to modified and touched things
  void _undoLocalChanges() {
    for (var note in _modifiedNotes) {
      _noteMap.remove(note);
    }

    for (var tag in _touchedTags) {
      _tagMap.remove(tag);
    }
  }
}
