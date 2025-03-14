import 'dart:convert';
// import 'dart:developer' as dev;

import 'package:notes_v0_2/notes/exceptions.dart';
import 'package:notes_v0_2/notes/models.dart';
import 'package:notes_v0_2/common/id.dart';
import 'package:sqlite_async/sqlite_async.dart';

final _migrations = SqliteMigrations(migrationTable: "app_migrations")..add(
  SqliteMigration(1, (tx) async {
    await tx.execute('''
      CREATE TABLE app_note (
        id VARCHAR(24) PRIMARY KEY NOT NULL,
        data BLOB NOT NULL
      );
    ''');

    // yep, noSQL life
    await tx.execute('''
      CREATE TABLE app_tags (
        data BLOB NOT NULL
      );
    ''');

    await tx.execute(
      '''
      INSERT INTO app_tags (data) VALUES(?);
    ''',
      [jsonEncode({})],
    );
  }),
);

// This does interfacing with the database
// If support for multiple databases is required,
// then StorageImpl can be passed to interface properly.
// I need to figureout where the transaction boundary is.
class NotesStorage {
  SqliteDatabase db;

  bool loggingEnabled;

  void log(String message) {
    if (loggingEnabled) {
      // developer logs only work when debugging.. ha
      // dev.log(message, time: DateTime.now(), level: 100, name: "SystemDb");
      print('[AppStorage] $message');
    }
  }

  NotesStorage(this.db, {this.loggingEnabled = false});

  Future<void> migrate() async {
    await _migrations.migrate(db);
  }

  // call it fetch?
  // it would be interesting to throw if the note was not found
  // instead of returning null. As trying to get note which does not exist
  // is a fatal bug. the event will be simply disgarded
  // a bug fix can bring that event back to life, as all events are preserved
  Future<Note?> noteGet(Id id) async {
    final noteRes = await db.getOptional(
      'SELECT data FROM app_note WHERE id = ? LIMIT 1;',
      [id.toString()],
    );

    if (noteRes == null) {
      return null;
    }

    final note = Note.fromMap(jsonDecode(noteRes['data']));

    return note;
  }

  /// save is an upsert. all functions here should have tx and nontx versions?
  /// maybe all are tx, and the resolver actually holds the database? it will never
  /// use it directly, but it will need it to trasact many changes
  static Future<void> _noteSave(SqliteWriteContext tx, Note note) async {
    await tx.execute(
      'INSERT OR REPLACE INTO app_note (id, data) VALUES (?, ?);',
      [note.noteId.toString(), jsonEncode(note.toMap())],
    );
  }

  Future<void> noteSave(Note note) async {
    await _noteSave(db, note);
  }

  Future<void> _noteDelete(SqliteWriteContext tx, Id id) async {
    final res = await tx.execute(
      'DELETE FROM app_note WHERE id = ? RETURNING id;',
      [id.toString()],
    );
    if (res.isEmpty) {
      // should this throw or just be asserted?
      throw ItemNotFoundException(id.toString());
    }
  }

  Future<void> noteDelete(Id id) async {
    return await _noteDelete(db, id);
  }

  Future<Tags> tagsGet() async {
    final tagsRes = await db.getOptional("SELECT data FROM app_tags LIMIT 1;");

    if (tagsRes == null) {
      throw Exception('tags were not initialized');
    }

    return Tags.fromMap(jsonDecode(tagsRes['data']));
  }

  static Future<void> _tagsSave(SqliteWriteContext tx, Tags tags) async {
    await tx.execute('UPDATE app_tags SET data = ?;', [
      jsonEncode(tags.toMap()),
    ]);
  }

  Future<void> tagsSave(Tags tags) async {
    _tagsSave(db, tags);
  }

  Future<void> noteConflictResolve(Id id) async {
    // the conflicts are actually stored on the note
    // its like a pointer, saying that this clashes with that in the UI view
    // then this event will correct the note conflict!
  }

  Future<void> tagActionOnNote(Id noteId, String tag, TagAction action) async {
    // TODO: could implement in the same transaction, these global gets need a tx
    final note = await noteGet(noteId);
    if (note == null) {
      throw ArgumentError('note $noteId does not exist', 'noteId');
    }
    final tags = await tagsGet();

    switch (action) {
      case TagAction.add:
        note.tags.add(tag);
        tags.add(tag);
      case TagAction.remove:
        note.tags.remove(tag);
        tags.remove(tag);
    }

    // serialize both
    await db.writeTransaction((tx) async {
      _noteSave(tx, note);
      _tagsSave(tx, tags);
    });
  }
}
