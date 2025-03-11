// separate class for implementing application logic

import 'dart:convert';

import 'package:notes_v0_2/app_models.dart';
import 'package:notes_v0_2/id.dart';
import 'package:sqlite_async/sqlite_async.dart';

final _migrations = SqliteMigrations(migrationTable: "app_migrations")..add(
  SqliteMigration(1, (tx) async {
    await tx.execute('''
      CREATE TABLE app_note (
        note_uid VARCHAR(19) PRIMARY KEY NOT NULL,
        note_data BLOB NOT NULL
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

class AppDb {
  SqliteDatabase db;

  AppDb(this.db);

  Future<void> migrate() async {
    await _migrations.migrate(db);
  }

  Future<void> noteCreate(Id id) async {
    final note = Note(noteId: id);

    final res = await db.execute(
      "INSERT INTO app_note (note_uid, note_data) VALUES (?, ?) RETURNING note_data;",
      [id.toString(), jsonEncode(note.toMap())],
    );
    print('created note $res');
  }

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
      print("DB ERROR: note $id does not exist");

      // for now we just throw, but in prod its strong error messaging instead
      // its okay to have broken events, they should not prevent app operation
      // maybe these are caught on higher level and operation is continued
      throw ArgumentError('note $id does not exist');
    }

    print('got note $note for modification $fullTitle $fullBody');

    if (fullTitle.isNotEmpty) {
      note.title = fullTitle;
    }
    if (fullBody.isNotEmpty) {
      note.body = fullBody;
    }

    final updateRes = await db.execute(
      'UPDATE app_note SET note_data = ? WHERE note_uid = ? RETURNING *;',
      [jsonEncode(note.toMap()), id.toString()],
    );

    print('note updated $updateRes');
  }

  Future<Note?> noteGet(Id id) async {
    final noteRes = await db.getOptional(
      'SELECT note_data FROM app_note WHERE note_uid = ? LIMIT 1;',
      [id.toString()],
    );

    if (noteRes == null) {
      return null;
    }

    final note = Note.fromMap(jsonDecode(noteRes['note_data']));

    return note;
  }

  Future<void> noteContentResolve(Id id) async {
    // the conflicts are actually stored on the note
    // its like a pointer, saying that this clashes with that in the UI view
    // then this event will correct the note conflict!
  }
}
