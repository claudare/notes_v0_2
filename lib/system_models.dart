import 'dart:convert';

import 'package:notes_v0_2/events.dart';
import 'package:notes_v0_2/stream.dart';

/// minimal information needed for resolving of the event
class EventLogMinimal {
  Stream streamId;
  Event event;

  EventLogMinimal({required this.streamId, required this.event});

  // this should not be here
  // pipeThrough(DbApp db) {
  //   event.apply(streamId, db);
  // }
}

class EventLog {
  String eventUid;
  String deviceUid;
  int deviceSeq;
  Stream streamId;
  int streamSeq;
  Event event; // could use Uint8List here?

  EventLog({
    required this.eventUid,
    required this.deviceUid,
    required this.deviceSeq,
    required this.streamId,
    required this.streamSeq,
    required this.event,
  });

  EventLog.fromRow(Map<String, dynamic> map)
    : eventUid = map['event_uid'],
      deviceUid = map['device_uid'],
      deviceSeq = map['device_seq'],
      streamId = Stream.fromString(map['stream_id']),
      streamSeq = map['stream_seq'],
      event = Event.fromMap(jsonDecode(map['data']));
  // event = Event.parseEvent(jsonDecode(map['data']));
}
