import 'dart:convert';

import 'package:notes_v0_2/notes/events.dart';
import 'package:notes_v0_2/common/stream.dart';

abstract class AnyEvent {
  const AnyEvent();

  AnyEvent.fromMap(Map<String, dynamic> map);

  Map<String, dynamic> toMap();
}

/// minimal information needed for resolving of the event
class EventLogMinimal {
  Stream stream;
  AnyEvent event;

  EventLogMinimal({required this.stream, required this.event});

  // this should not be here
  // pipeThrough(DbApp db) {
  //   event.apply(streamId, db);
  // }
}

class EventLog {
  String eventUid;
  String deviceUid;
  int deviceSeq;
  Stream streamName;
  int streamSeq;
  AnyEvent event; // could use Uint8List here?

  EventLog({
    required this.eventUid,
    required this.deviceUid,
    required this.deviceSeq,
    required this.streamName,
    required this.streamSeq,
    required this.event,
  });

  EventLog.fromRow(Map<String, dynamic> map)
    : eventUid = map['event_id'],
      deviceUid = map['device_id'],
      deviceSeq = map['device_seq'],
      streamName = Stream.fromString(map['stream_name']),
      streamSeq = map['stream_seq'],
      event = NotesEvent.fromMap(jsonDecode(map['data']));
  // event = Event.parseEvent(jsonDecode(map['data']));
}
