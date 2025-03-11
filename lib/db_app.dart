// separate class for implementing application logic

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

class DbApp {
  SqliteDatabase db;

  DbApp(this.db);

  Future<void> migrate() async {
    await _migrations.migrate(db);
  }
}
