import 'dart:convert';
// import 'dart:developer' as dev;

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

// separate db  class for implementing application logic

class NotesRepo {
  SqliteDatabase db;

  bool loggingEnabled;

  void log(String message) {
    if (loggingEnabled) {
      // developer logs only work when debugging.. ha
      // dev.log(message, time: DateTime.now(), level: 100, name: "SystemDb");
      print('[AppDb] $message');
    }
  }

  NotesRepo(this.db, {this.loggingEnabled = false});

  Future<void> migrate() async {
    await _migrations.migrate(db);
  }

  // call it fetch?
  // does caching happen inside the repo?
  Future<Note?> noteGet(Id id) async {
    final noteRes = await db.getOptional(
      'SELECT data FROM app_note WHERE id = ? LIMIT 1;',
      [id.toString()],
    );

    if (noteRes == null) {
      log('note $id not found');
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

  Future<bool> _noteDelete(SqliteWriteContext tx, Id id) async {
    final res = await tx.execute(
      'DELETE FROM app_note WHERE id = ? RETURNING id;',
      [id.toString()],
    );
    return res.isNotEmpty;
  }

  Future<bool> noteDelete(Id id) async {
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

  // there is no tags delete, as they always exist in the database

  // all functions below do not belong to this abstraction level

  // TODO: aquire note mutex for this operation, im trying to make this atomic
  // i could do json type of manipulations, but they are ctoo complex
  Future<void> noteContentUpdate(
    Id id, {
    String fullTitle = "",
    String fullBody = "",
  }) async {
    if (fullTitle.isEmpty && fullBody.isEmpty) {
      throw ArgumentError("title and body are both empty");
    }
    // also need to update the timestamp each time this is played
    // timestamp should be extracted from the id

    var note = await noteGet(id);

    if (note == null) {
      throw ArgumentError('note $id does not exist');
    }

    if (fullTitle.isNotEmpty) {
      note.title = fullTitle;
    }
    if (fullBody.isNotEmpty) {
      note.body = fullBody;
    }
    note.editedAt = DateTime.now(); // this is hardly testable

    // final updateRes = await db.execute(
    //   'UPDATE app_note SET data = ? WHERE id = ? RETURNING data;',
    //   [jsonEncode(note.toMap()), id.toString()],
    // );

    _noteSave(db, note);

    log('note updated $note');
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
