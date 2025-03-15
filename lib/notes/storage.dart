import 'dart:convert';
// import 'dart:developer' as dev;

import 'package:logging/logging.dart';
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
      CREATE TABLE app_tag (
        name TEXT PRIMARY KEY NOT NULL,
        data BLOB NOT NULL
      );
    ''');
  }),
);

// This does interfacing with the database
// If support for multiple databases is required,
// then StorageImpl can be passed to interface properly.
// I need to figureout where the transaction boundary is.
class NotesStorage {
  SqliteDatabase db;

  Logger log;

  NotesStorage(this.db) : log = Logger('NotesStorage');

  Future<void> migrate() async {
    await _migrations.migrate(db);
  }

  Future<void> runMutationsInTrasaction(
    Future<void> Function(NotesMutationTransaction tx) fn,
  ) async {
    // just wrap it up
    await db.writeTransaction((sqliteTx) async {
      await fn(NotesMutationTransaction(sqliteTx));
    });
  }

  Future<Note?> noteGet(Id id) async {
    log.finer('getting note $id');
    final noteRes = await db.getOptional(
      'SELECT data FROM app_note WHERE id = ? LIMIT 1;',
      [id.toString()],
    );

    if (noteRes == null) {
      log.warning('note $id not found');
      return null;
    }

    final note = Note.fromMap(jsonDecode(noteRes['data']));

    return note;
  }

  Future<Tag?> tagGet(String name) async {
    log.finer('getting tag $name');
    final row = await db.getOptional(
      'SELECT data FROM app_tag WHERE name = ? LIMIT 1;',
      [name],
    );

    if (row == null) {
      log.warning('tag $name not found');
      return null;
    }
    return Tag.fromJson(jsonDecode(row['data']));
  }

  // functions which are labeled as xQuery are optimized/simple queries
  Future<List<String>> tagQueryAllNames() async {
    final rows = await db.getAll('SELECT name FROM app_tag;');

    return rows.map((row) => row['name'] as String).toList();
  }

  Future<void> dumpPrint() async {
    print('-----DATABASE DUMP START---');

    final noteRows = await db.getAll('SELECT id FROM app_note');
    print('${noteRows.length} notes.');
    for (final row in noteRows) {
      final id = Id.fromString(row['id']);
      final note = await noteGet(id);
      if (note != null) {
        print('  $note');
      }
    }

    final tagRows = await db.getAll('SELECT name FROM app_tag');
    print('${tagRows.length} tags.');
    for (final row in tagRows) {
      final tagName = row['name'];
      final tag = await tagGet(tagName);
      if (tag != null) {
        print('  $tag');
      }
    }

    print('-----DATABASE DUMP END-----');
  }
}

class NotesMutationTransaction {
  final SqliteWriteContext _tx;

  const NotesMutationTransaction(this._tx);

  /// save is an upsert. all functions here should have tx and nontx versions?
  /// maybe all are tx, and the resolver actually holds the database? it will never
  /// use it directly, but it will need it to trasact many changes
  Future<void> noteSave(Note note) async {
    await _tx.execute(
      'INSERT OR REPLACE INTO app_note (id, data) VALUES (?, ?);',
      [note.noteId.toString(), jsonEncode(note.toMap())],
    );
  }

  Future<void> noteDelete(Id id) async {
    final res = await _tx.execute(
      'DELETE FROM app_note WHERE id = ? RETURNING id;',
      [id.toString()],
    );
    if (res.isEmpty) {
      throw ItemNotFoundException(id.toString());
    }
  }

  Future<void> tagSave(Tag tag) async {
    await _tx.execute(
      'INSERT OR REPLACE INTO app_tag (name, data) VALUES (?, ?);',
      [tag.name, jsonEncode(tag)],
    );
  }

  Future<void> tagDelete(String tagName) async {
    final row = await _tx.execute(
      'DELETE FROM app_tag WHERE name = ? RETURNING name;',
      [tagName],
    );
    if (row.isEmpty) {
      throw ItemNotFoundException('tag with name "$tagName"');
    }
  }
}
