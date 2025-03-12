import 'dart:convert';
// import 'dart:developer' as dev;

import 'package:notes_v0_2/app_models.dart';
import 'package:notes_v0_2/id.dart';
import 'package:sqlite_async/sqlite_async.dart';

final _migrations = SqliteMigrations(migrationTable: "app_migrations")..add(
  SqliteMigration(1, (tx) async {
    await tx.execute('''
      CREATE TABLE app_note (
        id VARCHAR(19) PRIMARY KEY NOT NULL,
        data BLOB NOT NULL
      );
    ''');

    // yep, noSQL life
    await tx.execute('''
      CREATE TABLE app_tags (
        data BLOB NOT NULL
      );
    ''');
  }),
);

// separate db  class for implementing application logic

class AppDb {
  SqliteDatabase db;

  bool loggingEnabled;

  void log(String message) {
    if (loggingEnabled) {
      // developer logs only work when debugging.. ha
      // dev.log(message, time: DateTime.now(), level: 100, name: "SystemDb");
      print('[AppDb] $message');
    }
  }

  AppDb(this.db, {this.loggingEnabled = false});

  Future<void> migrate() async {
    await _migrations.migrate(db);
  }

  Future<void> noteCreate(Id noteId) async {
    final note = Note(noteId);

    final res = await db.execute(
      "INSERT INTO app_note (id, data) VALUES (?, ?) RETURNING data;",
      [noteId.toString(), jsonEncode(note.toMap())],
    );
    log('note created $res');
  }

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

    final updateRes = await db.execute(
      'UPDATE app_note SET data = ? WHERE id = ? RETURNING data;',
      [jsonEncode(note.toMap()), id.toString()],
    );

    log('note updated $updateRes');
  }

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

  Future<void> noteConflictResolve(Id id) async {
    // the conflicts are actually stored on the note
    // its like a pointer, saying that this clashes with that in the UI view
    // then this event will correct the note conflict!
  }
}
