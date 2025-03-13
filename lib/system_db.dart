import 'dart:convert';

import 'package:notes_v0_2/id.dart';
import 'package:notes_v0_2/db_utils.dart';
import 'package:notes_v0_2/sequence.dart';
import 'package:notes_v0_2/system_models.dart';
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
        event_id VARCHAR(24) PRIMARY KEY NOT NULL,
        device_id VARCHAR(3) NOT NULL,
        device_seq INTEGER NOT NULL,
        stream_name TEXT NOT NULL,
        stream_seq INTEGER NOT NULL,
        data BLOB NOT NULL
      );
    ''');

    // An index to query a stream for a particular device
    await tx.execute('''
      CREATE INDEX sys_idx_eventlog_device_stream ON sys_eventlog (device_id, stream_name, stream_seq);
    ''');
    // An index to query global ordered data from the stream
    await tx.execute('''
      CREATE INDEX sys_idx_eventlog_global_stream ON sys_eventlog (stream_name, event_id);
    ''');
  }),
);

class SystemDb {
  late SqliteDatabase db;
  String? tempPath;

  final IdGenerator _idGenerator;

  late DbSequences dbSequences;

  bool loggingEnabled;

  void log(String message) {
    if (loggingEnabled) {
      print('[SystemDb] $message');
    }
  }

  SystemDb({
    String? path,
    required DeviceId deviceId,
    this.loggingEnabled = false,
  }) : _idGenerator = IdGenerator(deviceId) {
    if (path == null) {
      tempPath = tempDbPath();
      // Open temporary database
      db = SqliteDatabase(path: tempPath);
    } else {
      // Open database from a file
      db = SqliteDatabase(path: path);
      throw UnimplementedError("too early for this");
    }
  }

  Future<void> init() async {
    await _migrations.migrate(db);

    final oneData = await db.getOptional("SELECT data from sys_dbsequences;");

    if (oneData != null) {
      dbSequences = DbSequences.fromMap(oneData['data']);
    } else {
      // create and store the first one
      dbSequences = DbSequences();
      // register outselves
      dbSequences.addDevice(thisDeviceId.toString(), 0);

      final data = jsonEncode(dbSequences.toMap());
      final res = await db.execute(
        "INSERT INTO sys_dbsequences (data) VALUES (?) RETURNING *;",
        [
          [data],
        ],
      );
      log('initialized dbserquences to $res');
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
    log("updated sequences in db $res");
  }

  Future<void> deinit() async {
    await db.close();

    if (tempPath != null) {
      tempDbCleanup(tempPath!);
    }
  }

  DeviceId get thisDeviceId => _idGenerator.deviceId;

  Id newId(String scope) {
    return _idGenerator.newId(scope);
  }

  // should data really be string, or should it be actual event?
  Future<void> eventLogAppend(EventLogMinimal eventLogMinimal) async {
    final event = eventLogMinimal.event;
    final stream = eventLogMinimal.stream;

    final dataStr = jsonEncode(event.toMap());
    final streamName = stream.name;
    final eventId = newId("ev").toString();
    final deviceId = thisDeviceId.toString();
    final deviceSeq = dbSequences.getDeviceSequence(deviceId).next();
    final streamSeq = dbSequences.nextStreamSequence(deviceId, streamName);

    await db.writeTransaction((tx) async {
      final res = await tx.execute(
        '''
          INSERT INTO sys_eventlog
            (event_id, device_id, device_seq, stream_name, stream_seq, data)
          VALUES
            (?, ?, ?, ?, ?, ?)
          RETURNING *;
        ''',
        [eventId, deviceId, deviceSeq, streamName, streamSeq, dataStr],
      );
      // if sequences are properly defined, then a trascation could be used!
      log('appended event $res');
    });

    // update persistent sequences. This is very ugly.
    // FIXME: implement proper denormalized tables for this and use transactions
    await updateSequencesInDb();
  }

  // returns all the events for a given stream
  // if sequenceId is provided it will return up-to that point
  // otherwise all events are returned
  // Future<List<Event>> eventLogGetEventsForStream(
  //   StreamName streamName, {
  //   int sequenceId = -1,
  // }) {}
}
