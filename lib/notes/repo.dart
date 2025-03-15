// this is a repository which is kind of like cache. it should actually be universal?
// there should be context and in-memory store of the data
// this will allow to open a new context for event replaying
// also, this will cache the database entries for faster operation

import 'package:notes_v0_2/common/id.dart';
import 'package:notes_v0_2/notes/exceptions.dart';
import 'package:notes_v0_2/notes/model_ordering.dart';
import 'package:notes_v0_2/notes/models.dart';
import 'package:notes_v0_2/notes/storage.dart';

// how each one of this modules is done
// in order not to pollute [NotesRepo] with lots of variables
abstract class _GroupImpl {
  Future<void> flush(NotesMutationTransaction tx) async {}
  // this is done after flush. Usually touch maps are removed here
  void postFlush();
  // Undo any changes (revert modifications)
  // This is called when transaction fails, and state of the cache must be rolled back to
  // lastest storage representation
  // Usually, the referenced items are purched from the cache, so that they will be queried from db again.
  void purgeChanges();
}

class _NotesOrderingImpl extends _GroupImpl {
  final NotesStorage _storage;

  NoteOrder? _latest; // the actual upto-date copy of the database
  NoteOrder? _newest; // a copy is made when modifications are requested

  _NotesOrderingImpl(this._storage);

  // ref means get a deference copy
  Future<NoteOrder> ref() async {
    if (_newest != null) {
      return _newest!;
    }

    _latest = await _storage.noteOrderGet();
    _newest = _latest!.clone();

    return _newest!;
  }

  @override
  Future<void> flush(NotesMutationTransaction tx) async {
    if (_newest == null) {
      return;
    }
    await tx.noteOrderSave(_newest!);
  }

  @override
  void postFlush() {
    if (_newest != null) {
      _newest!.clear();
      _newest = null;
    }
  }

  @override
  void purgeChanges() {
    postFlush();
  }
}

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

  final _NotesOrderingImpl _ordering;

  // this is another way, each one of these implementations are in thier own class

  NotesRepo(this._storage)
    : _noteMap = {},
      _modifiedNotes = {},
      _deletedNotes = {},
      _tagMap = {},
      _touchedTags = {},
      _ordering = _NotesOrderingImpl(_storage);

  void noteNew(Id id) {
    final note = Note(id);
    _modifiedNotes.add(id);
    _noteMap[id] = note;
    // return note;
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

  // will return a list of tag names to the caller
  // i could just proxy this from storage
  // cause i will need to load all the tags into the map, with all their relationships
  // i think it would be more proper. Because when user wants to see all tags, that means they wanna see all
  // references too. Its actually going to be faster to get each one, as its just a map lookup
  // Future<List<String>> tagNames() async {
  //   return _storage
  //       .tagQueryAllNames(); // nope this is bad, all have to be proxied
  // }

  Future<NoteOrder> orderingGet() async {
    return await _ordering.ref();
  }

  // this is a transaction boundary
  // [flush] performs its operations in the transaction
  Future<void> flush() async {
    // something like storage.runInTransaction((tx){})
    try {
      await _storage.runMutationsInTrasaction((tx) async {
        for (var noteId in _modifiedNotes) {
          final note = _noteMap[noteId];
          assert(note != null, 'notes stored on the map cant be null');

          await tx.noteSave(note!);
        }
        for (var noteId in _deletedNotes) {
          await tx.noteDelete(noteId);
        }

        for (var tagName in _touchedTags) {
          final tag = _tagMap[tagName];
          assert(tag != null, 'tags stored on the map cant be null');

          // delete it from the database if its empty
          if (tag!.count == 0) {
            // also need to evict it from cache
            // this is getting a bit like pasta food
            await tx.tagDelete(tagName);
          } else {
            await tx.tagSave(tag);
          }
        }

        await _ordering.flush(tx);
      });
    } catch (error) {
      _purgeLocalChanges();
      _ordering.purgeChanges();
      print('failed to flush to the database: $error');
      rethrow;
    } finally {
      _modifiedNotes.clear();
      _deletedNotes.clear();

      // TODO go though the _tagMap and and delete values which have 0 notes assigned to them
      // or it could be a background task, operating on a mutex
      _touchedTags.clear();

      _ordering.postFlush();
    }
  }

  // deletes all cached data related to modified and touched things
  void _purgeLocalChanges() {
    for (var note in _modifiedNotes) {
      _noteMap.remove(note);
    }

    for (var tag in _touchedTags) {
      _tagMap.remove(tag);
    }
  }
}
