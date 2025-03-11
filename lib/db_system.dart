import 'dart:convert';

import 'package:notes_v0_2/id.dart';
import 'package:notes_v0_2/db_utils.dart';
import 'package:notes_v0_2/sequence.dart';
import 'package:sqlite_async/sqlite_async.dart';

final _migrations = SqliteMigrations(migrationTable: "sys_migrations")..add(
  SqliteMigration(1, (tx) async {
    // instead, nosql to store the latest sequence data in the db
    // this is rebuilable by replaying all the events
    // maybe doing a "proper" normal table system is beneficial for performance in this case
    // execution of this can be async. as all the sequences are stored in memory
    await tx.execute('''
          CREATE TABLE sys_dbsequences (
            data BLOB NOT NULL
          );
        ''');

    // this is full raw data of the event
    // it includes a lot, and is heavily indexed.
    // Heavy indexes are needed to quickly find streams
    // and be able to iterate a global view of the events
    await tx.execute('''
          CREATE TABLE sys_eventlog (
            event_uid VARCHAR(19) PRIMARY KEY NOT NULL,
            device_uid VARCHAR(3) NOT NULL,
            device_seq INTEGER NOT NULL,
            stream_name TEXT NOT NULL,
            stream_seq INTEGER NOT NULL,
            data BLOB NOT NULL
          );
        ''');

    // An index to query a stream for a particular device
    await tx.execute('''
          CREATE INDEX sys_idx_eventlog_device_stream ON sys_eventlog (device_uid, stream_name, stream_seq);
        ''');
    // An index to query global ordered data from the stream
    await tx.execute('''
          CREATE INDEX sys_idx_eventlog_global_stream ON sys_eventlog (stream_name, event_uid);
        ''');
  }),
);

class DbSystem {
  late SqliteDatabase db;
  String? tempPath;

  final UidGenerator _idGen;

  late DbSequences dbSequences;

  DbSystem({String? path, required DeviceUid deviceUid})
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
    await _migrations.migrate(db);

    // go though the whole event log and find all the devices (ouch... keep thier sequences here)
    // register our device if needed

    final oneData = await db.getOptional("SELECT data from sys_dbsequences;");

    if (oneData != null) {
      dbSequences = DbSequences.fromMap(oneData['data']);
    } else {
      // create and store the first one
      dbSequences = DbSequences();
      // register outselves
      dbSequences.addDevice(thisDeviceUid.toString(), 0);

      final data = jsonEncode(dbSequences.toMap());
      final res = await db.execute(
        "INSERT INTO sys_dbsequences (data) VALUES (?) RETURNING *;",
        [
          [data],
        ],
      );
      print('initialized dbserquences to $res');
    }
  }

  Future<void> updateSequencesInDb() async {
    final data = jsonEncode(dbSequences.toMap());

    final res = await db.execute(
      "UPDATE sys_dbsequences SET data = ? RETURNING *;",
      [
        [data],
      ],
    );
    print("updated sequences in db $res");
  }

  Future<void> deinit() async {
    await db.close();

    if (tempPath != null) {
      tempDbCleanup(tempPath!);
    }
  }

  DeviceUid get thisDeviceUid => _idGen.deviceUid;

  Uid newUid() {
    return _idGen.newUId();
  }

  // device sequence also needs to be stored in the db, as a separate table
  Future<void> eventLogAppend({
    required String streamName,
    required String data,
  }) async {
    // need to automatically generate the Id
    final eventUid = newUid().toString();
    final deviceUid = thisDeviceUid.toString();
    final deviceSeq = dbSequences.getDeviceSequence(deviceUid).next();
    final streamSeq = dbSequences.nextStreamSequence(deviceUid, streamName);

    // also will need to update the index of the last stream ids and stuff

    await db.writeTransaction((tx) async {
      final res = await tx.execute(
        '''
          INSERT INTO sys_eventlog
            (event_uid, device_uid, device_seq, stream_name, stream_seq, data)
          VALUES
            (?, ?, ?, ?, ?, ?)
          RETURNING *;
        ''',
        [eventUid, deviceUid, deviceSeq, streamName, streamSeq, data],
      );
      // if sequences are properly defined, then a trascation could be used!
      print('appended event $res');
    });

    // do this without waiting? what can go wrong :D
    // FIXME: implement proper denormalized tables for this and use transactions
    updateSequencesInDb();
  }
}
