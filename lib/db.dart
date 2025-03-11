import 'package:notes_v0_2/id.dart';
import 'package:notes_v0_2/db_utils.dart';
import 'package:sqlite_async/sqlite_async.dart';

final migrations =
    SqliteMigrations()..add(
      SqliteMigration(1, (tx) async {
        // this is required to know last sequence id of self
        // and of the other devices for syncing purposes
        await tx.execute('''
          CREATE TABLE devicestat (
            device_uid VARCHAR(3) PRIMARY KEY NOT NULL,
            last_seq INTEGER NOT NULL
          );
        ''');

        // this is full raw data of the event
        // it includes a lot, and is heavily indexed.
        // Heavy indexes are needed to quickly find streams
        // and be able to iterate a global view of the events
        await tx.execute('''
          CREATE TABLE eventlog (
            event_uid VARCHAR(19) NOT NULL PRIMARY KEY,
            device_uid VARCHAR(3) NOT NULL,
            device_seq INTEGER NOT NULL,
            stream_name TEXT NOT NULL,
            stream_seq INTEGER NOT NULL,
            data BLOB NOT NULL
          );
        ''');

        // An index to query a stream for a particular device
        await tx.execute('''
          CREATE INDEX idx_eventlog_device_stream ON eventlog (device_uid, stream_name, stream_seq);
        ''');
        // An index to query global ordered data from the stream
        await tx.execute('''
          CREATE INDEX idx_eventlog_global_stream ON eventlog (stream_name, event_uid);
        ''');
      }),
    );

class Db {
  late SqliteDatabase db;
  String? tempPath;

  final UidGenerator _idGen;
  late Sequence deviceSeq; // is late okay here?

  Db({String? path, required DeviceUid deviceUid})
    : _idGen = UidGenerator(deviceUid) {
    if (path == null) {
      tempPath = tempDbPath();
      // Open in-memory database
      db = SqliteDatabase(path: tempPath);
    } else {
      // Open database from a file
      db = SqliteDatabase(path: path);
      throw UnimplementedError("too early for this");
    }
  }

  Future<void> init() async {
    await migrations.migrate(db);
    final deviceUid = thisDeviceUid();

    // register our device if needed

    final existingRes = await db.execute(
      "SELECT last_seq FROM devicestat WHERE device_uid = ? LIMIT 1;",
      [
        [deviceUid],
      ],
    );

    if (existingRes.isNotEmpty) {
      final lastSeq = existingRes[0]['last_seq'] as int;
      deviceSeq = Sequence(lastSeq);
      return;
    }

    // returning is for debug only
    final insertRes = await db.execute(
      "INSERT INTO devicestat (device_uid, last_seq) VALUES (?, 0) RETURNING *;",
      [
        [deviceUid],
      ],
    );
    print('initialized devicestat to $insertRes');
    deviceSeq = Sequence(0);
    return;
  }

  Future<void> deinit() async {
    await db.close();

    if (tempPath != null) {
      tempDbCleanup(tempPath!);
    }
  }

  String thisDeviceUid() {
    return _idGen.deviceId.toString();
  }

  Uid newUid() {
    return _idGen.newUId();
  }

  // device sequence also needs to be stored in the db, as a separate table
  // Future<void> eventLogAppend() async {
  //   // need to automatically generate the Id
  //   final eventId = newUid();

  //   await db.execute('''
  //     INSERT INTO eventlog ()
  //   ''', []);
  // }
}
